import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/patterns/pattern_sweep.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sweep against real rows.
///
/// Its job is mostly to say nothing. These tests care far more about that than
/// about finding the planted signal: an app that tells someone their mood
/// depends on their step count, on three weeks of noise, has done something
/// worse than nothing.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  final now = DateTime(2026, 7, 29);

  String isoDate(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// Writes [days] days ending yesterday, with steps and sleep supplied by the
  /// caller so a relationship can be planted or withheld.
  Future<void> seed({
    required int days,
    required double Function(int index) steps,
    required double Function(int index) sleepMinutes,
  }) async {
    for (var i = 0; i < days; i++) {
      final day = now.subtract(Duration(days: days - i));
      final date = isoDate(day);
      await database.recordDayTotal(
        date: date,
        activeKcal: 300,
        basalKcal: 1500,
        steps: steps(i).round(),
        sessionsCount: 0,
      );
      final minutes = sleepMinutes(i).round();
      await database.replaceSleepForNight(
        nightOf: date,
        source: 'test',
        segments: [
          SleepSegmentsCompanion.insert(
            nightOf: date,
            stage: 'light',
            startUtc: DateTime.utc(day.year, day.month, day.day, 1),
            endUtc: DateTime.utc(day.year, day.month, day.day, 1)
                .add(Duration(minutes: minutes)),
            source: 'test',
            priority: 3,
          ),
        ],
      );
    }
  }

  test('a new user is told nothing, however suggestive the few days look',
      () async {
    // Ten days of a planted, perfect relationship. It is still ten days.
    await seed(
      days: 10,
      steps: (i) => 4000 + i * 800.0,
      sleepMinutes: (i) => 360 + i * 12.0,
    );

    final findings = await PatternSweep(database).run(now: now);

    expect(findings, isEmpty);
    expect(await database.loadActivePatterns(), isEmpty);
  });

  test('three months of noise produces no findings', () async {
    // The test this whole feature exists to pass. Ninety days of unrelated
    // numbers, swept across every pair, must yield nothing.
    final random = math.Random(20260729);
    await seed(
      days: 90,
      steps: (i) => 3000 + random.nextDouble() * 9000,
      sleepMinutes: (i) => 300 + random.nextDouble() * 200,
    );

    final findings = await PatternSweep(database).run(now: now);

    expect(
      findings,
      isEmpty,
      reason: 'noise produced: ${findings.join(' | ')}',
    );
  });

  test('a real relationship is found once there is enough of it', () async {
    final random = math.Random(4);
    await seed(
      days: 90,
      steps: (i) => 3000 + random.nextDouble() * 8000,
      sleepMinutes: (i) => 300,
    );
    // Replace sleep with something genuinely tied to that day's steps.
    for (var i = 0; i < 90; i++) {
      final day = now.subtract(Duration(days: 90 - i));
      final date = isoDate(day);
      final summary = await database.loadDaySummary(date);
      final minutes =
          260 + (summary!.steps / 100) + random.nextDouble() * 25;
      await database.replaceSleepForNight(
        nightOf: date,
        source: 'test',
        segments: [
          SleepSegmentsCompanion.insert(
            nightOf: date,
            stage: 'light',
            startUtc: DateTime.utc(day.year, day.month, day.day, 1),
            endUtc: DateTime.utc(day.year, day.month, day.day, 1)
                .add(Duration(minutes: minutes.round())),
            source: 'test',
            priority: 3,
          ),
        ],
      );
    }

    final findings = await PatternSweep(database).run(now: now);

    expect(findings, isNotEmpty);
    expect(findings.first, contains('step count'));
    expect(findings.first, contains('days'));
  });

  test('a finding says how much it explains and over how long', () async {
    final random = math.Random(9);
    await seed(
      days: 80,
      steps: (i) => 2000 + i * 90.0 + random.nextDouble() * 400,
      sleepMinutes: (i) => 280 + i * 1.6 + random.nextDouble() * 20,
    );

    final findings = await PatternSweep(database).run(now: now);
    if (findings.isEmpty) return; // The correction is allowed to refuse.

    // Without the sample size and the share explained, a finding is a
    // horoscope with a number in it.
    expect(findings.first, matches(RegExp(r'\d+% of the variation')));
    expect(findings.first, matches(RegExp(r'across \d+ days')));
  });

  test('a finding that stops being true stops being told', () async {
    final random = math.Random(2);
    await seed(
      days: 90,
      steps: (i) => 3000 + i * 60.0,
      sleepMinutes: (i) => 280 + i * 1.2 + random.nextDouble() * 15,
    );
    await PatternSweep(database).run(now: now);
    final before = await database.loadActivePatterns();

    // Now overwrite the same window with noise and sweep again.
    await seed(
      days: 90,
      steps: (i) => 3000 + random.nextDouble() * 9000,
      sleepMinutes: (i) => 300 + random.nextDouble() * 200,
    );
    await PatternSweep(database).run(now: now);
    final after = await database.loadActivePatterns();

    expect(before, isNotEmpty);
    expect(
      after.where((row) => row.key.startsWith('sweep:')),
      isEmpty,
      reason: 'a finding true of last month must not outlive its evidence',
    );
  });

  test('an empty database sweeps without complaint', () async {
    expect(await PatternSweep(database).run(now: now), isEmpty);
  });
}
