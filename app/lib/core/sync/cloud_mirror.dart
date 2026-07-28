/// The copy of the record that survives losing the phone, and its limits.
///
/// What this is *not*: a database the app reads from. The local store stays
/// canonical, every surface reads from it, and nothing waits on a network.
/// The mirror is written to when there is a connection and read from exactly
/// once — when a signed-in person opens Eter on a device with no history.
///
/// That asymmetry is the whole design. It means sync can never make the app
/// slower, can never make it wrong while offline, and can never lose a local
/// record to a stale remote one.
library;

/// One document, as it travels.
typedef MirrorDocument = Map<String, Object?>;

/// The storage the mirror needs, and nothing more.
///
/// An interface rather than Firestore directly, for the same reason
/// `AccountService` is: the sync rules are the part worth testing, and they
/// should be testable without a project, a network or a platform channel.
abstract interface class CloudMirror {
  /// Writes or replaces one document.
  Future<void> put({
    required String userId,
    required String collection,
    required String id,
    required MirrorDocument data,
  });

  /// Writes many documents, atomically where the backend allows it.
  Future<void> putAll({
    required String userId,
    required String collection,
    required Map<String, MirrorDocument> documents,
  });

  /// Everything in one collection. Used only on restore.
  Future<List<MirrorDocument>> readAll({
    required String userId,
    required String collection,
  });

  /// Removes everything under this user. Withdrawing from the mirror has to
  /// actually remove the copy, or the consent meant nothing.
  Future<void> deleteEverything(String userId);
}

class MirrorException implements Exception {
  const MirrorException(this.reason);
  final String reason;

  @override
  String toString() => reason;
}

/// What a sync attempt did, in terms a surface can report honestly.
class SyncOutcome {
  const SyncOutcome({
    this.uploaded = 0,
    this.restored = 0,
    this.skipped = const {},
    this.failure,
  });

  /// Documents written to the mirror.
  final int uploaded;

  /// Rows written back into the local store from the mirror.
  final int restored;

  /// Collections deliberately not sent, and why — so the Sanctum can say
  /// "your journal stayed here" rather than implying everything went.
  final Map<String, String> skipped;

  /// Set when the attempt failed. A failed sync is never a lost record: the
  /// local rows keep their null `syncedAt` and go again next time.
  final String? failure;

  bool get didNothing => uploaded == 0 && restored == 0;
}
