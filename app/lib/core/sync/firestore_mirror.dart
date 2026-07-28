import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloud_mirror.dart';

/// The only file in the app that knows Firestore exists.
///
/// Everything above it talks to [CloudMirror], which is why the sync rules —
/// what travels, what is withheld, what a failure costs — are tested against a
/// fake with no project, no network and no emulator.
///
/// Every path is scoped to `users/{uid}`, and the security rules enforce the
/// same thing server-side. Both, because a client-side scope is a convention
/// and a rule is a guarantee.
class FirestoreCloudMirror implements CloudMirror {
  FirestoreCloudMirror({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Firestore's own ceiling is 500 operations per batch.
  static const _batchLimit = 400;

  CollectionReference<Map<String, dynamic>> _collection(
    String userId,
    String collection,
  ) =>
      _firestore.collection('users').doc(userId).collection(collection);

  @override
  Future<void> put({
    required String userId,
    required String collection,
    required String id,
    required MirrorDocument data,
  }) =>
      _guard(() => _collection(userId, collection).doc(id).set(data));

  @override
  Future<void> putAll({
    required String userId,
    required String collection,
    required Map<String, MirrorDocument> documents,
  }) =>
      _guard(() async {
        final entries = documents.entries.toList();
        for (var start = 0; start < entries.length; start += _batchLimit) {
          final batch = _firestore.batch();
          for (final entry in entries.skip(start).take(_batchLimit)) {
            batch.set(_collection(userId, collection).doc(entry.key), entry.value);
          }
          await batch.commit();
        }
      });

  @override
  Future<List<MirrorDocument>> readAll({
    required String userId,
    required String collection,
  }) =>
      _guard(() async {
        final snapshot = await _collection(userId, collection).get();
        return [for (final document in snapshot.docs) document.data()];
      });

  @override
  Future<void> deleteEverything(String userId) => _guard(() async {
        // Firestore does not delete subcollections with their parent, so
        // withdrawing has to walk them. Missing one would leave a copy behind
        // after someone asked for it to be gone.
        for (final collection in const [
          'profile',
          'weights',
          'nutrition',
          'lifestyle',
          'sessions',
          'strength',
          'days',
          'journal',
        ]) {
          final snapshot = await _collection(userId, collection).get();
          for (var start = 0;
              start < snapshot.docs.length;
              start += _batchLimit) {
            final batch = _firestore.batch();
            for (final document
                in snapshot.docs.skip(start).take(_batchLimit)) {
              batch.delete(document.reference);
            }
            await batch.commit();
          }
        }
      });

  /// Turns Firestore's codes into the mirror's own failure, so the sync
  /// service never has to know what a `permission-denied` is.
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on FirebaseException catch (error) {
      throw MirrorException(switch (error.code) {
        'permission-denied' =>
          'The mirror refused the write. Sign in again and try once more.',
        'unavailable' || 'deadline-exceeded' =>
          'No connection to the mirror. Nothing was lost; it will go again.',
        'resource-exhausted' =>
          'The mirror is over quota today. Nothing was lost.',
        _ => 'The mirror could not be written to. Nothing was lost.',
      });
    } catch (_) {
      throw const MirrorException(
        'The mirror could not be written to. Nothing was lost.',
      );
    }
  }
}
