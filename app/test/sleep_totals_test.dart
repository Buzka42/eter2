import 'package:eter/core/patterns/daily_series.dart';
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Slept time excludes the minutes spent awake.
///
/// Garmin reported 8h21m for a night Eter called 8h25m, and the difference
/// was exactly the four minutes the watch recorded as awake. Every downstream
/// number inherited it — the average, the bars, and any pattern tested
/// against sleep duration.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  /// The real night, as Health Connect stored it.
  Future<void> seedTheNight() => database.replaceSleepForNight(
        nightOf: '2026-07-29',
        source: 'healthConnect:garmin',
        segments: [
          for (final stage in const [
            ('light', 296),
            ('rem', 165),
            ('deep', 40),
            ('awake', 4),
          ])
            SleepSegmentsCompanion.insert(
              nightOf: '2026-07-29',
              stage: stage.$1,
              startUtc: DateTime.utc(2026, 7, 29, 0, 44),
              endUtc: DateTime.utc(2026, 7, 29, 0, 44)
                  .add(Duration(minutes: stage.$2)),
              source: 'healthConnect:garmin',
              priority: 3,
            ),
        ],
      );

  test('the slept series matches what the watch reported', () async {
    await seedTheNight();

    final series = await DailySeriesReader(database).read(
      from: '2026-07-28',
      to: '2026-07-30',
      fromLocal: DateTime(2026, 7, 28),
      toLocal: DateTime(2026, 7, 31),
    );

    // 296 + 165 + 40 = 501 minutes = 8h21m. Not 505.
    expect(series['sleep']!['2026-07-29'], 501);
    expect(series['awake']!['2026-07-29'], 4);
  });

  test('awake remains its own series, because it is worth knowing', () async {
    await seedTheNight();
    final series = await DailySeriesReader(database).read(
      from: '2026-07-28',
      to: '2026-07-30',
      fromLocal: DateTime(2026, 7, 28),
      toLocal: DateTime(2026, 7, 31),
    );
    // Removed from the total, not from the record: broken sleep is a real
    // thing to notice, and the sweep can still test against it.
    expect(series['awake']!['2026-07-29'], isNotNull);
    expect(series['deep']!['2026-07-29'], 40);
    expect(series['rem']!['2026-07-29'], 165);
  });

  test('a night of nothing but awake counts as no sleep', () async {
    await database.replaceSleepForNight(
      nightOf: '2026-07-28',
      source: 'healthConnect:garmin',
      segments: [
        SleepSegmentsCompanion.insert(
          nightOf: '2026-07-28',
          stage: 'awake',
          startUtc: DateTime.utc(2026, 7, 28, 3),
          endUtc: DateTime.utc(2026, 7, 28, 4),
          source: 'healthConnect:garmin',
          priority: 3,
        ),
      ],
    );

    final series = await DailySeriesReader(database).read(
      from: '2026-07-27',
      to: '2026-07-29',
      fromLocal: DateTime(2026, 7, 27),
      toLocal: DateTime(2026, 7, 30),
    );

    // Absent rather than zero: an hour of lying awake is not a night of
    // sleep, and it is not a night of no sleep either — it is a night with
    // nothing to say about how long someone slept.
    expect(series['sleep']!['2026-07-28'], isNull);
    expect(series['awake']!['2026-07-28'], 60);
  });
}
