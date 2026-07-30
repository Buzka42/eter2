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
      // extra write is the profile: restoring sets cloud consent on the new
      // device, which is a genuine local change and belongs in the mirror.
      expect(mirror.writeCount, afterFirstDevice + 1);
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
}

/// A complete in-memory mirror. Its existence is the proof that nothing in
/// SyncService depends on Firestore.
class _FakeMirror implements CloudMirror {
  final Map<String, Map<String, MirrorDocument>> writes = {};
  String? failOn;
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
  Future<void> deleteEverything(String userId) async => writes.clear();
}
