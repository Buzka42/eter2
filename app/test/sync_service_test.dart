import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/account/account.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/sync/cloud_mirror.dart';
import 'package:eter/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The mirror's rules, tested against a fake so they hold without a project.
///
/// Three properties matter more than the copying itself: consent decides what
/// travels, a failure loses nothing, and a restore can never overwrite a
/// record this device already has.
void main() {
  late AppDatabase database;
  late _FakeMirror mirror;
  late SyncService sync;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    mirror = _FakeMirror();
    sync = SyncService(database: database, mirror: mirror);
  });
  tearDown(() => database.close());

  const confirmed = EterAccount(
    id: 'uid-1',
    email: 'someone@example.com',
    emailVerified: true,
    provider: 'password',
  );
  const unconfirmed = EterAccount(
    id: 'uid-1',
    email: 'someone@example.com',
    emailVerified: false,
    provider: 'password',
  );

  Future<void> profile({
    bool cloud = true,
    bool journalCloud = false,
  }) async {
    await database.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 1, 1),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
      firstName: const Value('Mara'),
      heightCm: const Value(170),
    ));
    await database.updateProfileConsents(
      cloudSyncAllowed: cloud,
      journalCloudSyncAllowed: journalCloud ? true : null,
    );
  }

  Future<void> someRecords() async {
    await database.addManualWeight(kg: 84.2, recordedAt: DateTime(2026, 7, 28));
    await database.into(database.lifestyleEntries).insert(
          LifestyleEntriesCompanion.insert(
            recordedAt: DateTime(2026, 7, 28, 9),
            kind: 'mood',
            value: const Value(7),
          ),
        );
    await database.addJournalEntry(JournalEntriesCompanion.insert(
      createdAt: DateTime(2026, 7, 28, 10),
      entryText: 'A private page.',
    ));
  }

  group('consent decides what travels', () {
    test('cloud continuity off sends nothing at all', () async {
      await profile(cloud: false);
      await someRecords();

      final outcome = await sync.push(confirmed);

      expect(outcome.uploaded, 0);
      expect(outcome.refusal, SyncRefusal.cloudContinuityOff);
      expect(mirror.writes, isEmpty);
    });

    test('the journal stays behind unless it is separately allowed', () async {
      await profile(journalCloud: false);
      await someRecords();

      final outcome = await sync.push(confirmed);

      expect(outcome.uploaded, greaterThan(0));
      expect(mirror.collections, contains('weights'));
      expect(mirror.collections, isNot(contains('journal')));
      expect(
          outcome.skipped['journalEntries'], contains('stay on this device'));
    });

    test('allowing the journal separately sends the pages', () async {
      await profile(journalCloud: true);
      await someRecords();

      await sync.push(confirmed);

      expect(mirror.collections, contains('journal'));
      expect(
          mirror.writes['journal']!.values.single['text'], 'A private page.');
    });

    test('withdrawing cloud continuity withdraws the journal with it',
        () async {
      await profile(journalCloud: true);
      await database.updateProfileConsents(cloudSyncAllowed: false);

      final saved = await database.loadProfile();
      expect(saved!.cloudSyncConsentAt, isNull);
      expect(saved.journalCloudSyncConsentAt, isNull);
    });

    test('an unconfirmed account copies nothing anywhere', () async {
      await profile();
      await someRecords();

      final outcome = await sync.push(unconfirmed);

      expect(outcome.uploaded, 0);
      expect(mirror.writes, isEmpty);
      expect(outcome.refusal, SyncRefusal.confirmEmailBeforeCopying);
    });
  });

  group('what is deliberately withheld', () {
    test('every withheld collection carries a reason', () {
      expect(SyncService.withheld, isNotEmpty);
      for (final entry in SyncService.withheld.entries) {
        expect(entry.value, isNotEmpty, reason: entry.key);
        expect(entry.value.trim().endsWith('.'), isTrue, reason: entry.key);
      }
    });

    test('the minute buckets are named, not silently missing', () async {
      await profile();
      await someRecords();
      final outcome = await sync.push(confirmed);
      expect(outcome.skipped, contains('minuteBuckets'));
    });
  });

  group('a failure loses nothing', () {
    test('rows keep their unsynced mark and go again', () async {
      await profile();
      await someRecords();
      mirror.failOn = 'weights';

      final first = await sync.push(confirmed);
      expect(first.failure, isNotNull);

      final unsynced = await (database.select(database.weightEntries)
            ..where((row) => row.syncedAt.isNull()))
          .get();
      expect(unsynced, hasLength(1));

      mirror.failOn = null;
      final second = await sync.push(confirmed);
      expect(second.failure, isNull);
      expect(mirror.writes['weights'], hasLength(1));
    });

    test('a second push sends nothing already sent', () async {
      await profile();
      await someRecords();

      await sync.push(confirmed);
      final writesAfterFirst = mirror.writeCount;
      final second = await sync.push(confirmed);

      expect(second.uploaded, 0);
      expect(mirror.writeCount, writesAfterFirst);
    });

    test('a new record after a sync is picked up by the next one', () async {
      await profile();
      await someRecords();
      await sync.push(confirmed);

      await database.addManualWeight(
        kg: 83.9,
        recordedAt: DateTime(2026, 7, 29),
      );
      final outcome = await sync.push(confirmed);

      // Two documents: the weight itself, and the profile — recording a
      // weight also updates the current one, which is a real change and
      // should travel.
      expect(outcome.uploaded, 2);
      expect(mirror.writes['weights'], hasLength(2));
    });
  });

  group('restore', () {
    test('refuses on a device that already has history', () async {
      await profile();
      await someRecords();

      final outcome = await sync.restore(confirmed);

      expect(outcome.restored, 0);
      expect(outcome.refusal, SyncRefusal.deviceAlreadyHasHistory);
    });

    test('brings the record onto an empty device', () async {
      // One device fills the mirror.
      await profile();
      await someRecords();
      await sync.push(confirmed);

      // Another opens it.
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final restored =
          await SyncService(database: fresh, mirror: mirror).restore(confirmed);

      expect(restored.failure, isNull);
      expect(restored.restored, greaterThan(0));
      final weights = await fresh.watchWeightEntries().first;
      expect(weights.single.kg, 84.2);
      final profileRow = await fresh.loadProfile();
      expect(profileRow!.firstName, 'Mara');
      // 84.2 rather than the 70 the profile started at: logging a weight
      // updates the current one, and it is that later value the mirror holds.
      expect(profileRow.weightKg, 84.2);
    });

    test('a restored device does not inherit the AI permissions', () async {
      await profile();
      await database.updateProfileConsents(aiAllowed: true);
      await someRecords();
      await sync.push(confirmed);

      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      await SyncService(database: fresh, mirror: mirror).restore(confirmed);

      // Consent is given on a device, by a person. A new phone asks again.
      final profileRow = await fresh.loadProfile();
      expect(profileRow!.aiConsentAt, isNull);
      expect(profileRow.journalAiConsentAt, isNull);
    });

    test('an unconfirmed account restores nothing', () async {
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final outcome = await SyncService(database: fresh, mirror: mirror)
          .restore(unconfirmed);
      expect(outcome.restored, 0);
      expect(outcome.refusal, SyncRefusal.confirmEmailFirst);
    });

    test('restored rows are already marked synced, not re-uploaded', () async {
      await profile();
      await someRecords();
      await sync.push(confirmed);
      final afterFirstDevice = mirror.writeCount;

      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final second = SyncService(database: fresh, mirror: mirror);
      await second.restore(confirmed);
      await fresh.updateProfileConsents(cloudSyncAllowed: true);
      await second.push(confirmed);

      // The restore must not bounce the whole record back up again. The one
      // extra write is the profile, and it is the `updateProfileConsents` call
      // above that earns it — a real local change on this device. The restore
      // itself grants nothing.
      expect(mirror.writeCount, afterFirstDevice + 1);
    });

    test('a restored device does not inherit cloud continuity', () async {
      await profile();
      await someRecords();
      await sync.push(confirmed);

      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      await SyncService(database: fresh, mirror: mirror).restore(confirmed);

      // Consent is given on a device, by a person. A restore that switched
      // copying on would start mirroring a record to the cloud without anyone
      // on this phone having agreed to it — and the code did exactly that,
      // immediately beneath a comment promising it did not.
      expect((await fresh.loadProfile())?.cloudSyncConsentAt, isNull);
    });

    test('a restore sends nothing back on its own', () async {
      await profile();
      await someRecords();
      await sync.push(confirmed);
      final afterFirstDevice = mirror.writeCount;

      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final second = SyncService(database: fresh, mirror: mirror);
      await second.restore(confirmed);
      // No consent was granted by the restore, so this refuses rather than
      // pushing — which is the same fact as the test above, seen from the
      // outside.
      final outcome = await second.push(confirmed);

      expect(outcome.refusal, SyncRefusal.cloudContinuityOff);
      expect(mirror.writeCount, afterFirstDevice);
    });
  });

  test('forgetting removes the copy', () async {
    await profile();
    await someRecords();
    await sync.push(confirmed);
    expect(mirror.writes, isNotEmpty);

    await sync.forget(confirmed.id);
    expect(mirror.writes, isEmpty);
  });

  test('nothing is sent for a device with no profile', () async {
    final outcome = await sync.push(confirmed);
    expect(outcome.uploaded, 0);
    expect(outcome.refusal, SyncRefusal.nothingToSync);
    expect(mirror.writes, isEmpty);
  });

  /// Withdrawing: the copy, then the account, and never the other way round.
  ///
  /// The order is the only thing these tests are really about. Deleting the
  /// account first would leave the mirror standing under a uid nobody can ever
  /// present again — `firestore.rules` authorises every delete by
  /// `request.auth.uid` — so the copy would be permanently unreachable and
  /// permanently undeleted. That is the worst outcome the deletion path has,
  /// and nothing about it is visible from the outside, so it is asserted here.
  group('withdraw', () {
    test('clears the copy before deleting the account', () async {
      await profile();
      await someRecords();
      await sync.push(confirmed);
      expect(mirror.writes, isNotEmpty);

      // Fails the test from inside the account service if the copy is still
      // there when the account is deleted. Asserting afterwards could not tell
      // the two orderings apart: both end with an empty mirror and no account.
      final accounts = _FakeAccounts(
        onDelete: () => expect(
          mirror.writes,
          isEmpty,
          reason: 'the mirror must be cleared while the credential still works',
        ),
      );

      await sync.withdraw(account: confirmed, service: accounts);
      expect(accounts.deleted, isTrue);
      expect(mirror.writes, isEmpty);
    });

    test('a mirror that will not clear leaves the account alone', () async {
      await profile();
      await someRecords();
      await sync.push(confirmed);

      mirror.failOnDelete = true;
      final accounts = _FakeAccounts();

      await expectLater(
        sync.withdraw(account: confirmed, service: accounts),
        throwsA(isA<MirrorException>()),
      );
      // Still deletable. Had the account gone first, the retry would have no
      // authority left to clear the copy with.
      expect(accounts.deleted, isFalse);
      expect(mirror.writes, isNotEmpty);
    });

    test('local records survive a withdrawal', () async {
      await profile();
      await someRecords();
      await sync.push(confirmed);

      await sync.withdraw(account: confirmed, service: _FakeAccounts());

      // Withdrawing from the mirror is not asking Eter to forget you. Erasing
      // the local record is the Sanctum's other, separately confirmed action.
      expect(await database.loadProfile(), isNotNull);
      expect(await sync.isEmpty(), isFalse);
    });
  });
}

/// Just enough account service to observe when deletion happens.
class _FakeAccounts implements AccountService {
  _FakeAccounts({this.onDelete});

  /// Run inside [deleteAccount], so a test can assert the state of the world at
  /// the exact moment the account goes.
  final void Function()? onDelete;

  bool deleted = false;

  @override
  Future<void> deleteAccount() async {
    onDelete?.call();
    deleted = true;
  }

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('withdraw must not reach ${invocation.memberName}');
}

/// A complete in-memory mirror. Its existence is the proof that nothing in
/// SyncService depends on Firestore.
class _FakeMirror implements CloudMirror {
  final Map<String, Map<String, MirrorDocument>> writes = {};
  String? failOn;
  bool failOnDelete = false;
  int writeCount = 0;

  Iterable<String> get collections => writes.keys;

  void _maybeFail(String collection) {
    if (failOn == collection) {
      throw const MirrorException('The mirror could not be reached.');
    }
  }

  @override
  Future<void> put({
    required String userId,
    required String collection,
    required String id,
    required MirrorDocument data,
  }) async {
    _maybeFail(collection);
    writes.putIfAbsent(collection, () => {})[id] = data;
    writeCount += 1;
  }

  @override
  Future<void> putAll({
    required String userId,
    required String collection,
    required Map<String, MirrorDocument> documents,
  }) async {
    _maybeFail(collection);
    writes.putIfAbsent(collection, () => {}).addAll(documents);
    writeCount += documents.length;
  }

  @override
  Future<List<MirrorDocument>> readAll({
    required String userId,
    required String collection,
  }) async =>
      writes[collection]?.values.toList() ?? const [];

  @override
  Future<void> deleteEverything(String userId) async {
    if (failOnDelete) {
      throw const MirrorException('The mirror could not be reached.');
    }
    writes.clear();
  }
}
