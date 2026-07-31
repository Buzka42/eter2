/// Pairing, and the one sentence a day that crosses once paired.
///
/// The transport is behind [CorrespondenceGateway] so this whole file runs in a
/// test with no Firestore. What it is protecting is in
/// `correspondence.dart` — this part only sequences it.
library;

import 'dart:math';

import 'package:drift/drift.dart' show Value;

import '../clock.dart';
import '../db/app_database.dart';
import 'correspondence.dart';

/// The remote half. Firestore in the app; a map in a test.
abstract interface class CorrespondenceGateway {
  /// The signed-in user, or null. Pairing needs an account — it is the only
  /// feature in Eter that does, because it is the only one with two people in
  /// it.
  String? get userId;

  Future<void> offerCode(String code, {required DateTime expiresAt});

  /// Who offered [code], or null if nobody did or it has been redeemed.
  Future<String?> readOffer(String code);

  Future<void> withdrawCode(String code);

  /// Creates the pair and returns its id.
  Future<String> createPair(List<String> members);

  Future<void> endPair(String pairId);

  /// Writes this device's line for the day, replacing any earlier one.
  Future<void> putLine(String pairId, CorrespondenceLine line);

  /// The other member's line, or null when they have not written one today.
  Future<CorrespondenceLine?> readLine(String pairId, String authorId);

  /// The pair's members, or null if it is gone — the other person may have
  /// ended it, which is unilateral by design.
  Future<List<String>?> membersOf(String pairId);
}

class CorrespondenceService {
  CorrespondenceService({
    required this.database,
    required this.gateway,
    Random? random,
  }) : _random = random ?? Random.secure();

  final AppDatabase database;
  final CorrespondenceGateway gateway;
  final Random _random;

  /// How long a code is good for. Long enough to read down a phone line,
  /// short enough that an abandoned one is not left lying around.
  static const codeLifetime = Duration(hours: 24);

  /// Offers a code for somebody to redeem. Returns it so it can be shown.
  Future<String> offer({required DateTime now}) async {
    final me = gateway.userId;
    if (me == null) {
      throw const CorrespondenceRefusal('Pairing needs an account.');
    }
    final code = _code();
    await gateway.offerCode(code, expiresAt: now.add(codeLifetime));
    return code;
  }

  /// Redeems somebody else's code and creates the pair.
  Future<void> accept(String typed, {required DateTime now}) async {
    final me = gateway.userId;
    if (me == null) {
      throw const CorrespondenceRefusal('Pairing needs an account.');
    }
    final code = PairingCode.normalise(typed);
    if (!PairingCode.isWellFormed(code)) {
      throw const CorrespondenceRefusal('That is not a pairing code.');
    }
    final from = await gateway.readOffer(code);
    if (from == null) {
      throw const CorrespondenceRefusal(
        'That code has been used, or has expired.',
      );
    }
    if (from == me) {
      // Pairing with yourself would work perfectly and mean nothing, and the
      // resulting single-member-twice pair would fail the rule's size check
      // with a message nobody could act on.
      throw const CorrespondenceRefusal('That is your own code.');
    }
    final pairId = await gateway.createPair([from, me]);
    await _remember(pairId);
    // A code is good exactly once.
    await gateway.withdrawCode(code);
  }

  /// Ends it, from this side. Unilateral by design: leaving must never need
  /// the other person's agreement.
  Future<void> end() async {
    final pairId = (await database.loadProfile())?.correspondencePairId;
    await _remember(null);
    if (pairId != null) await gateway.endPair(pairId);
  }

  /// Publishes today's sentence and reads back the other person's.
  ///
  /// Returns null when there is no pair, nothing composed yet, or the other
  /// side has not written today — all of which are ordinary, and none of which
  /// is an error worth putting on a screen.
  Future<CorrespondenceLine?> exchange({
    required DateTime now,
    required String? todaysSentence,
  }) async {
    final me = gateway.userId;
    final profile = await database.loadProfile();
    final pairId = profile?.correspondencePairId;
    if (me == null || pairId == null) return null;

    final members = await gateway.membersOf(pairId);
    if (members == null) {
      // The other person ended it. Forget it here too rather than retrying a
      // document that is gone.
      await _remember(null);
      return null;
    }

    final today = eterIsoDate(now);
    if (todaysSentence != null && todaysSentence.trim().isNotEmpty) {
      try {
        await gateway.putLine(
          pairId,
          CorrespondencePolicy.check(
            CorrespondenceLine(date: today, sentence: todaysSentence.trim()),
          ),
        );
      } on CorrespondenceRefusal {
        // Our own sentence failed the policy. Nothing is sent, and the read
        // below still happens: being unable to share today is not a reason to
        // stop receiving.
      }
    }

    final other = members.firstWhere((member) => member != me, orElse: () => '');
    if (other.isEmpty) return null;
    try {
      final line = await gateway.readLine(pairId, other);
      if (line == null) return null;
      return CorrespondencePolicy.isCurrent(line, today: today) ? line : null;
    } on CorrespondenceRefusal {
      // Whatever is in their document, it is not a line this build will show.
      return null;
    }
  }

  Future<void> _remember(String? pairId) async {
    final current = await database.loadProfile();
    if (current == null) return;
    await (database.update(database.profiles)
          ..where((row) => row.id.equals(current.id)))
        .write(ProfilesCompanion(correspondencePairId: Value(pairId)));
  }

  String _code() => List.generate(
        PairingCode.length,
        (_) => PairingCode.alphabet[_random.nextInt(PairingCode.alphabet.length)],
      ).join();
}
