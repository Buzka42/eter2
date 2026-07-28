import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/energy/energy.dart' as energy;
import 'package:eter/core/health/daily_activity_summary.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rebuilding a day's totals from its minute winners. The arithmetic is small
/// and the refusals matter more than the sums: without a height there is no
/// honest resting estimate, and without a recorded body fat there is no
/// Katch-McArdle branch to take.
void main() {
  late AppDatabase database;
  late DailyActivitySummaryService service;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    service = DailyActivitySummaryService(database);
  });
  tearDown(() => database.close());

  Future<void> profile({
    double weightKg = 70,
    double? heightCm = 175,
    double? bodyFatPercent,
    String sex = 'female',
    DateTime? dob,
  }) =>
      database.saveProfile(ProfilesCompanion.insert(
        dob: dob ?? DateTime(1990, 6, 1),
        sex: sex,
        weightKg: weightKg,
        units: 'metric',
        heightCm: Value(heightCm),
        bodyFatPercent: Value(bodyFatPercent),
      ));

  Future<void> bucket(
    DateTime localMinute, {
    double activeKcal = 5,
    int? steps = 100,
  }) =>
      database.into(database.minuteBuckets).insert(
            MinuteBucketsCompanion.insert(
              minuteUtc: localMinute.toUtc(),
              activeKcal: activeKcal,
              winningSource: 'phone',
              provenance: 'phone',
              steps: Value(steps),
            ),
            mode: InsertMode.insertOrReplace,
          );

  Future<void> session(DateTime localStart) =>
      database.upsertActivitySession(ActivitySessionsCompanion.insert(
        id: localStart.toIso8601String(),
        startUtc: localStart.toUtc(),
        endUtc: localStart.add(const Duration(minutes: 30)).toUtc(),
        source: 'phone',
        priority: 1,
      ));

  final start = DateTime(2026, 7, 27);
  final end = DateTime(2026, 7, 28, 10, 30);

  group('refusals', () {
    test('no profile, no totals', () async {
      await bucket(DateTime(2026, 7, 28, 9));
      expect(await service.refresh(start, end), 0);
      expect(await database.loadDaySummary('2026-07-28'), isNull);
    });

    test('no height, no resting estimate and therefore no totals', () async {
      await profile(heightCm: null);
      await bucket(DateTime(2026, 7, 28, 9));
      expect(await service.refresh(start, end), 0);
      expect(await database.loadDaySummary('2026-07-28'), isNull);
    });

    test('no minutes, nothing to rebuild', () async {
      await profile();
      expect(await service.refresh(start, end), 0);
      expect(await database.loadDaySummary('2026-07-28'), isNull);
    });
  });

  group('the sums', () {
    test('active kcal and steps are the day\'s winners, added up', () async {
      await profile();
      await bucket(DateTime(2026, 7, 28, 8), activeKcal: 4, steps: 60);
      await bucket(DateTime(2026, 7, 28, 9), activeKcal: 6.5, steps: 90);
      await bucket(DateTime(2026, 7, 28, 10), activeKcal: 1.5, steps: null);

      expect(await service.refresh(start, end), 1);
      final day = await database.loadDaySummary('2026-07-28');
      expect(day!.activeKcal, closeTo(12, 1e-9));
      expect(day.steps, 150);
    });

    test('each local day is rebuilt separately', () async {
      await profile();
      await bucket(DateTime(2026, 7, 27, 20), activeKcal: 3, steps: 10);
      await bucket(DateTime(2026, 7, 28, 9), activeKcal: 7, steps: 20);

      expect(await service.refresh(start, end), 2);
      expect(
        (await database.loadDaySummary('2026-07-27'))!.activeKcal,
        closeTo(3, 1e-9),
      );
      expect(
        (await database.loadDaySummary('2026-07-28'))!.activeKcal,
        closeTo(7, 1e-9),
      );
    });

    test('sessions are counted onto the local day they started', () async {
      await profile();
      await bucket(DateTime(2026, 7, 27, 20));
      await bucket(DateTime(2026, 7, 28, 9));
      await session(DateTime(2026, 7, 28, 7));
      await session(DateTime(2026, 7, 28, 8));

      await service.refresh(start, end);
      expect((await database.loadDaySummary('2026-07-28'))!.sessionsCount, 2);
      expect((await database.loadDaySummary('2026-07-27'))!.sessionsCount, 0);
    });
  });

  group('resting burn', () {
    test('a finished day accrues a full 1440 minutes, today only so far',
        () async {
      await profile();
      await bucket(DateTime(2026, 7, 27, 20), activeKcal: 0, steps: 0);
      await bucket(DateTime(2026, 7, 28, 9), activeKcal: 0, steps: 0);

      await service.refresh(start, end);
      final yesterday = (await database.loadDaySummary('2026-07-27'))!;
      final today = (await database.loadDaySummary('2026-07-28'))!;
      final perMinute = energy.rmrPerMin(energy.restingKcalPerDay(
        sex: energy.Sex.female,
        weightKg: 70,
        heightCm: 175,
        age: 36,
      ));

      expect(yesterday.basalKcal, closeTo(perMinute * 1440, 1e-6));
      expect(today.basalKcal, closeTo(perMinute * (10 * 60 + 30), 1e-6));
    });

    test('a known body fat takes the Katch-McArdle branch', () async {
      await profile(bodyFatPercent: 22);
      await bucket(DateTime(2026, 7, 28, 9), activeKcal: 0, steps: 0);

      await service.refresh(start, end);
      final today = (await database.loadDaySummary('2026-07-28'))!;
      final leanBased = energy.rmrPerMin(energy.rmrKcalPerDayFromLeanMass(
        weightKg: 70,
        bodyFatPercent: 22,
      ));
      final massBased = energy.rmrPerMin(energy.rmrKcalPerDay(
        sex: energy.Sex.female,
        weightKg: 70,
        heightCm: 175,
        age: 36,
      ));

      expect(today.basalKcal, closeTo(leanBased * (10 * 60 + 30), 1e-6));
      expect(today.basalKcal, isNot(closeTo(massBased * (10 * 60 + 30), 1e-3)));
    });

    test('sex is read from the profile, and an unknown one is the mean',
        () async {
      await profile(sex: 'other');
      await bucket(DateTime(2026, 7, 28, 9), activeKcal: 0, steps: 0);

      await service.refresh(start, end);
      final today = (await database.loadDaySummary('2026-07-28'))!;
      final expected = energy.rmrPerMin(energy.rmrKcalPerDay(
        sex: energy.Sex.other,
        weightKg: 70,
        heightCm: 175,
        age: 36,
      ));
      expect(today.basalKcal, closeTo(expected * (10 * 60 + 30), 1e-6));
    });

    test('age is counted at the end of the window, birthday included',
        () async {
      // Born 30 July: on 28 July 2026 they are still 35, not 36.
      await profile(dob: DateTime(1990, 7, 30));
      await bucket(DateTime(2026, 7, 28, 9), activeKcal: 0, steps: 0);

      await service.refresh(start, end);
      final today = (await database.loadDaySummary('2026-07-28'))!;
      final expected = energy.rmrPerMin(energy.rmrKcalPerDay(
        sex: energy.Sex.female,
        weightKg: 70,
        heightCm: 175,
        age: 35,
      ));
      expect(today.basalKcal, closeTo(expected * (10 * 60 + 30), 1e-6));
    });
  });

  test('a rebuild that lowers the day marks it recalibrated', () async {
    await profile();
    await bucket(DateTime(2026, 7, 28, 9), activeKcal: 40, steps: 100);
    await service.refresh(start, end);
    expect((await database.loadDaySummary('2026-07-28'))!.recalibrated, isFalse);

    await bucket(DateTime(2026, 7, 28, 9), activeKcal: 5, steps: 100);
    await service.refresh(start, end);
    final day = (await database.loadDaySummary('2026-07-28'))!;
    expect(day.activeKcal, closeTo(5, 1e-9));
    expect(day.recalibrated, isTrue);
  });
}
