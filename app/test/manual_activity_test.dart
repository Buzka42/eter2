import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/energy/energy.dart' as energy;
import 'package:eter/core/health/manual_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'female',
        weightKg: 65,
        heightCm: const Value(168),
        units: 'metric',
      ),
    );
  });
  tearDown(() => database.close());

  test('records one session and distributes explicit energy by minute',
      () async {
    final result = await ManualActivityService(database).record(
      activity: 'Evening walk',
      durationMinutes: 30,
      activeKcal: 120,
      endedAt: DateTime.utc(2026, 7, 28, 18),
    );

    final sessions = await database.loadSessions(
      DateTime.utc(2026, 7, 28),
      DateTime.utc(2026, 7, 29),
    );
    final minutes = await database.loadMinuteBuckets(
      DateTime.utc(2026, 7, 28),
      DateTime.utc(2026, 7, 29),
    );
    final summary = await database.loadDaySummary('2026-07-28');

    expect(result.durationMinutes, 30);
    expect(sessions, hasLength(1));
    expect(sessions.single.sport, 'Evening walk');
    expect(minutes, hasLength(30));
    expect(minutes.fold<double>(0, (sum, row) => sum + row.activeKcal), 120);
    expect(summary?.activeKcal, 120);
    expect(summary?.sessionsCount, 1);
  });

  test('manual session wins overlap without adding both sources', () async {
    final start = DateTime.utc(2026, 7, 28, 17, 30);
    await database.ingestRawBuckets([
      for (var i = 0; i < 30; i++)
        energy.MinuteBucket(
          minuteUtc: start.add(Duration(minutes: i)),
          activeKcal: 2,
          sourceId: 'healthConnect:watch',
          priority: energy.SourcePriority.hub,
        ),
    ]);
    await database.recomputeMinuteWinners(
      start,
      DateTime.utc(2026, 7, 28, 18),
    );

    await ManualActivityService(database).record(
      activity: 'Strength',
      durationMinutes: 30,
      activeKcal: 120,
      endedAt: DateTime.utc(2026, 7, 28, 18),
    );
    final minutes = await database.loadMinuteBuckets(
      start,
      DateTime.utc(2026, 7, 28, 18),
    );

    expect(minutes.fold<double>(0, (sum, row) => sum + row.activeKcal), 120);
    expect(minutes.every((row) => row.winningSource.startsWith('manual-')),
        isTrue);
  });

  test('two entries ending in the same minute remain distinct sessions',
      () async {
    final service = ManualActivityService(database);
    final end = DateTime.utc(2026, 7, 28, 18);

    final first = await service.record(
      activity: 'Walk',
      durationMinutes: 30,
      activeKcal: 100,
      endedAt: end,
    );
    final second = await service.record(
      activity: 'Strength',
      durationMinutes: 30,
      activeKcal: 120,
      endedAt: end,
    );
    final sessions = await database.loadSessions(
      DateTime.utc(2026, 7, 28),
      DateTime.utc(2026, 7, 29),
    );

    expect(first.sessionId, isNot(second.sessionId));
    expect(sessions, hasLength(2));
  });

  test('rejects incomplete or implausible explicit values', () async {
    final service = ManualActivityService(database);

    await expectLater(
      service.record(
        activity: '',
        durationMinutes: 30,
        activeKcal: 100,
      ),
      throwsA(isA<ManualActivityException>()),
    );
    await expectLater(
      service.record(
        activity: 'Walk',
        durationMinutes: 0,
        activeKcal: 100,
      ),
      throwsA(isA<ManualActivityException>()),
    );
    await expectLater(
      service.record(
        activity: 'Walk',
        durationMinutes: 30,
        activeKcal: double.nan,
      ),
      throwsA(isA<ManualActivityException>()),
    );
    expect(
      await database.loadSessions(
        DateTime.utc(2020),
        DateTime.utc(2030),
      ),
      isEmpty,
    );
  });
}
