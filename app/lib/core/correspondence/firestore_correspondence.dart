/// The only file in the Correspondence that knows Firestore exists.
///
/// Same reasoning as `sync/firestore_mirror.dart`: everything above talks to
/// [CorrespondenceGateway], so what may cross and when is tested against a map
/// with no project and no network.
///
/// Unlike the mirror, these paths are **not** scoped to `users/{uid}` — that is
/// the whole point of the feature and the whole risk of it. `firestore.rules`
/// carries the matching half, and it is the strict one: a line document may
/// hold exactly a date and a sentence, membership can never change, and a code
/// can be fetched by name but never listed.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'correspondence.dart';
import 'correspondence_service.dart';

class FirestoreCorrespondence implements CorrespondenceGateway {
  FirestoreCorrespondence({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  String? get userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _pairs =>
      _firestore.collection('correspondences');

  CollectionReference<Map<String, dynamic>> get _invitations =>
      _firestore.collection('invitations');

  @override
  Future<void> offerCode(String code, {required DateTime expiresAt}) =>
      _guard(() => _invitations.doc(code).set({
            'from': userId,
            // A string, like every other timestamp that crosses in this app:
            // the offset survives the round trip and a server clock is not
            // needed to read it.
            'expiresAt': expiresAt.toUtc().toIso8601String(),
          }));

  @override
  Future<String?> readOffer(String code) => _guard(() async {
        final document = await _invitations.doc(code).get();
        final data = document.data();
        if (data == null) return null;
        // Expiry is enforced here rather than in the rule, because a rule
        // cannot read the clock without trusting a client-supplied `now`. The
        // worst a stale document can do is sit there unredeemed.
        final expires = DateTime.tryParse('${data['expiresAt']}');
        if (expires != null && DateTime.now().toUtc().isAfter(expires)) {
          return null;
        }
        final from = data['from'];
        return from is String ? from : null;
      });

  @override
  Future<void> withdrawCode(String code) =>
      _guard(() => _invitations.doc(code).delete());

  @override
  Future<String> createPair(List<String> members) => _guard(() async {
        final document = _pairs.doc();
        await document.set({
          'members': members,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });
        return document.id;
      });

  @override
  Future<void> endPair(String pairId) => _guard(() async {
        // The line documents go first. Deleting the parent in Firestore leaves
        // a subcollection orphaned and still readable by anybody the rules
        // still consider a member — and after the parent is gone, the rule
        // that answers that question cannot be evaluated at all.
        for (final line in (await _pairs.doc(pairId).collection('lines').get())
            .docs) {
          // Only our own is ours to delete; the rule refuses the other, which
          // is correct and not an error worth surfacing.
          if (line.id == userId) await line.reference.delete();
        }
        await _pairs.doc(pairId).delete();
      });

  @override
  Future<void> putLine(String pairId, CorrespondenceLine line) => _guard(
        () => _pairs
            .doc(pairId)
            .collection('lines')
            .doc(userId)
            .set(line.toJson()),
      );

  @override
  Future<CorrespondenceLine?> readLine(String pairId, String authorId) =>
      _guard(() async {
        final document =
            await _pairs.doc(pairId).collection('lines').doc(authorId).get();
        final data = document.data();
        if (data == null) return null;
        // Straight into the policy. Whatever is in their document, it is not
        // shown until it has been checked here as well as by the rule.
        return CorrespondenceLine.fromJson(data);
      });

  @override
  Future<List<String>?> membersOf(String pairId) => _guard(() async {
        final document = await _pairs.doc(pairId).get();
        final members = document.data()?['members'];
        if (members is! List) return null;
        return [
          for (final member in members)
            if (member is String) member,
        ];
      });

  /// Firestore's codes, turned into the one failure this feature has.
  ///
  /// [CorrespondenceRefusal] passes through untouched: a line that failed the
  /// policy is not a network problem, and calling it one would send somebody
  /// to check their signal over a sentence Eter refused on purpose.
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on CorrespondenceRefusal {
      rethrow;
    } on FirebaseException catch (error) {
      throw CorrespondenceRefusal(switch (error.code) {
        'permission-denied' =>
          'That correspondence is not yours to read. Nothing was changed.',
        'unavailable' || 'deadline-exceeded' =>
          'No connection. Nothing was sent, and nothing was lost.',
        'resource-exhausted' => 'Too many attempts today. Try again tomorrow.',
        _ => 'That did not go through. Nothing was changed.',
      });
    } catch (_) {
      throw const CorrespondenceRefusal(
        'That did not go through. Nothing was changed.',
      );
    }
  }
}
