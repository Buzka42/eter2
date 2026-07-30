import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/account/account.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/sync/background_sync.dart';
import 'package:eter/core/sync/cloud_mirror.dart';
import 'package:eter/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pushing without being asked to.
///
/// `push` had one caller — the Sanctum's button — so the mirror held only what
/// someone had remembered to send. The point of these tests is that automating
/// it did not also make it pushy: it stays debounced, stays silent, and still
/// refuses everything `SyncService` already refused.
void main() {
  late AppDatabase database;
  late _CountingMirror mirror;
  late SyncService sync;
  late DateTime clock;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    mirror = _CountingMirror();
    sync = SyncService(database: database, mirror: mirror);
    clock = DateTime.utc(2026, 7, 30, 9);
  });
  tearDown(() => database.close());

  BackgroundSync build() =>
      BackgroundSync(sync: sync, now: () => clock);

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

  Future<void> recordsAndConsent({bool cloud = true}) async {
    await database.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 1, 1),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
    ));
    if (cloud) {
      await database.updateProfileConsents(cloudSyncAllowed: true);
    }
    await database.addManualWeight(kg: 80, recordedAt: DateTime(2026, 7, 30));
  }

  test('pushes what the Sanctum would have pushed', () async {
    await recordsAndConsent();
    final outcome = await build().pushIfDue(confirmed);

    expect(outcome?.uploaded, greaterThan(0));
    expect(mirror.writes, isNotEmpty);
  });

  test('a second attempt inside the interval does nothing', () async {
    await recordsAndConsent();
    final push = build();
    await push.pushIfDue(confirmed);
    final after = mirror.commits;

    // Same minute: opening and closing the app repeatedly must not become a
    // write loop against a metered database.
    clock = clock.add(const Duration(minutes: 2));
    expect(await push.pushIfDue(confirmed), isNull);
    expect(mirror.commits, after);
  });

  test('once the interval has passed it goes again', () async {
    await recordsAndConsent();
    final push = build();
    await push.pushIfDue(confirmed);

    await database.addManualWeight(kg: 79, recordedAt: DateTime(2026, 7, 31));
    clock = clock.add(const Duration(minutes: 6));

    expect((await push.pushIfDue(confirmed))?.uploaded, greaterThan(0));
  });

  test('nobody signed in, nothing sent', () async {
    await recordsAndConsent();
    expect(await build().pushIfDue(null), isNull);
    expect(mirror.writes, isEmpty);
  });

  test('an unconfirmed address is not a place to keep a record', () async {
    await recordsAndConsent();
    expect(await build().pushIfDue(unconfirmed), isNull);
    expect(mirror.writes, isEmpty);
  });

  test('consent is still the sync service\'s decision, not this one', () async {
    await recordsAndConsent(cloud: false);
    final outcome = await build().pushIfDue(confirmed);

    // It runs, and is refused one layer down. That is deliberate: the consent
    // rule lives in exactly one place rather than two that must agree forever.
    expect(outcome?.refusal, SyncRefusal.cloudContinuityOff);
    expect(mirror.writes, isEmpty);
  });

  test('a build with no mirror is inert rather than broken', () async {
    await recordsAndConsent();
    expect(await BackgroundSync(sync: null).pushIfDue(confirmed), isNull);
  });

  test('a mirror failure is swallowed, and loses nothing', () async {
    await recordsAndConsent();
    mirror.failEverything = true;

    final outcome = await build().pushIfDue(confirmed);

    // Reported in the return value, never thrown at somebody who was opening
    // their journal — and the rows keep their null `syncedAt`, so they go again.
    expect(outcome?.failure, isNotNull);
    final weights = await database.select(database.weightEntries).get();
    expect(weights.single.syncedAt, isNull);
  });
}

class _CountingMirror implements CloudMirror {
  final Map<String, Map<String, MirrorDocument>> writes = {};
  bool failEverything = false;
  int commits = 0;

  void _maybeFail() {
    if (failEverything) {
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
    _maybeFail();
    commits += 1;
    writes.putIfAbsent(collection, () => {})[id] = data;
  }

  @override
  Future<void> putAll({
    required String userId,
    required String collection,
    required Map<String, MirrorDocument> documents,
  }) async {
    _maybeFail();
    commits += 1;
    writes.putIfAbsent(collection, () => {}).addAll(documents);
  }

  @override
  Future<List<MirrorEntry>> readAll({
    required String userId,
    required String collection,
  }) async =>
      [
        for (final entry in writes[collection]?.entries ?? const <Never>[])
          MirrorEntry(id: entry.key, data: entry.value),
      ];

  @override
  Future<void> deleteEverything(String userId) async => writes.clear();
}
