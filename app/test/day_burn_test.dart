import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/energy/energy.dart' as energy;
import 'package:eter/core/health/daily_activity_summary.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a day's "burned" is made of when the source counts steps and reports
/// no calories.
///
/// Found on a phone: 22,720 steps across three days, zero active kilocalories,
/// and a burn figure that was resting alone.
void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime(1993, 7, 25),
        sex: 'male',
        weightKg: 88,
        units: 'metric',
        heightCm: const Value(180),
        bodyFatPercent: const Value(10),
      ),
    );
  });
  tearDown(() => database.close());

  /// One minute of the day, as the pipeline stores it.
  Future<void> minute(
    DateTime at, {
    double activeKcal = 0,
    int? steps,
  }) =>
      database.ingestRawBuckets([
        energy.MinuteBucket(
          minuteUtc: at.toUtc(),
          activeKcal: activeKcal,
          steps: steps,
          sourceId: 'test',
          priority: energy.SourcePriority.hub,
        ),
      ]).then((_) => database.recomputeMinuteWinners(
            at.toUtc(),
            at.toUtc().add(const Duration(minutes: 1)),
          ));

  Future<DaySummaryRow> summarise(DateTime day) async {
    await DailyActivitySummaryService(database).refresh(
      DateTime(day.year, day.month, day.day),
      DateTime(day.year, day.month, day.day, 23, 59),
    );
    return (database.select(database.daySummaries)
          ..where((row) => row.date.equals(
              '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}')))
        .getSingle();
  }

  test('steps with no energy still cost something', () async {
    final day = DateTime(2026, 8, 4);
    for (var i = 0; i < 10; i++) {
      await minute(day.add(Duration(hours: 9, minutes: i)), steps: 973);
    }
    final summary = await summarise(day);

    expect(summary.steps, 9730);
    // Not zero, which is what it was.
    expect(summary.activeKcal, greaterThan(250));
    expect(summary.activeKcal, lessThan(400));
    expect(summary.basalKcal, greaterThan(0));
  });

  test('a source that reports energy is never second-guessed', () async {
    // A watch that gives both. Its own number stands, and no estimate is
    // added on top of the minutes it already accounted for.
    final day = DateTime(2026, 8, 5);
    for (var i = 0; i < 10; i++) {
      await minute(
        day.add(Duration(hours: 9, minutes: i)),
        activeKcal: 12,
        steps: 973,
      );
    }
    final summary = await summarise(day);
    expect(summary.activeKcal, closeTo(120, 0.01));
  });

  test('a training session does not cost the day its walking', () async {
    // The reason this is per minute rather than per day. A session logged
    // through the Journal writes real energy into the minutes it covers; the
    // rest of the day is still ordinary walking with no energy on it, and a
    // day-level rule would have thrown all of it away.
    final day = DateTime(2026, 8, 6);
    for (var i = 0; i < 30; i++) {
      await minute(
        day.add(Duration(hours: 18, minutes: i)),
        activeKcal: 9,
        steps: 60,
      );
    }
    for (var i = 0; i < 10; i++) {
      await minute(day.add(Duration(hours: 9, minutes: i)), steps: 900);
    }
    final summary = await summarise(day);

    // The session's own 270, plus an estimate for the 9,000 walked steps that
    // nothing measured — and nothing for the 1,800 steps inside the session.
    expect(summary.activeKcal, greaterThan(270));
    expect(summary.activeKcal, closeTo(270 + 295, 40));
  });

  test('a day with no steps and no energy stays at nothing', () async {
    final day = DateTime(2026, 8, 7);
    await minute(day.add(const Duration(hours: 9)), steps: 0);
    final summary = await summarise(day);
    expect(summary.activeKcal, 0);
  });
}
