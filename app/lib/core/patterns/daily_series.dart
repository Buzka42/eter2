/// Everything Eter records, as one value per day.
///
/// The sweep needs comparable columns, and the database stores minutes, nights,
/// sessions and entries in their own shapes. This flattens all of them onto the
/// local calendar day so any pair can be tested against any other.
///
/// Two deliberate choices. A day with no record of a variable is **absent**
/// rather than zero — a day nobody logged food is not a day of no eating, and
/// treating it as one manufactures correlations out of missing data. And sleep
/// belongs to the morning it ends, which is how a person means it when they
/// say they slept badly.
library;

import '../db/app_database.dart';
import '../health/sleep_totals.dart';

/// One measurable thing, and how to say it in a sentence.
class SeriesDefinition {
  const SeriesDefinition({
    required this.key,
    required this.label,
    required this.unit,
    this.higherIsMore = true,
  });

  final String key;

  /// How the finding names it: "deep sleep", "your step count".
  final String label;

  /// For the evidence line, never shown to the model as a bare number.
  final String unit;

  /// Whether a larger number means more of the thing the label describes.
  final bool higherIsMore;
}

/// The catalogue. Adding a row here adds it to every future sweep.
const dailySeriesDefinitions = <SeriesDefinition>[
  SeriesDefinition(key: 'steps', label: 'your step count', unit: 'steps'),
  SeriesDefinition(
    key: 'activeKcal',
    label: 'how much you moved',
    unit: 'kcal',
  ),
  // Asleep, not in bed: the awake minutes are their own series below.
  SeriesDefinition(key: 'sleep', label: 'how long you slept', unit: 'minutes'),
  SeriesDefinition(key: 'deep', label: 'deep sleep', unit: 'minutes'),
  SeriesDefinition(key: 'rem', label: 'REM sleep', unit: 'minutes'),
  SeriesDefinition(key: 'awake', label: 'time awake in the night', unit: 'minutes'),
  SeriesDefinition(
    key: 'restingHr',
    label: 'your resting heart rate',
    unit: 'bpm',
  ),
  SeriesDefinition(key: 'hrv', label: 'your heart-rate variability', unit: 'ms'),
  SeriesDefinition(key: 'intake', label: 'what you ate', unit: 'kcal'),
  SeriesDefinition(key: 'sessions', label: 'training sessions', unit: 'sessions'),
  SeriesDefinition(key: 'mood', label: 'your mood', unit: 'out of ten'),
  SeriesDefinition(key: 'stress', label: 'your stress', unit: 'out of ten'),
  SeriesDefinition(
    key: 'recovery',
    label: 'how recovered you felt',
    unit: 'out of ten',
  ),
  SeriesDefinition(
    key: 'meditation',
    label: 'time spent in meditation',
    unit: 'minutes',
  ),
  SeriesDefinition(key: 'weight', label: 'your weight', unit: 'kg'),
];

/// Reads the whole record into one value per variable per day.
class DailySeriesReader {
  const DailySeriesReader(this.database);

  final AppDatabase database;

  /// `{seriesKey: {isoDate: value}}` over [from]–[to] inclusive.
  Future<Map<String, Map<String, double>>> read({
    required String from,
    required String to,
    required DateTime fromLocal,
    required DateTime toLocal,
  }) async {
    final series = <String, Map<String, double>>{
      for (final definition in dailySeriesDefinitions) definition.key: {},
    };

    for (final row in await database.loadDaySummaryRange(from, to)) {
      if (row.steps > 0) series['steps']![row.date] = row.steps.toDouble();
      if (row.activeKcal > 0) series['activeKcal']![row.date] = row.activeKcal;
      if (row.intakeKcal != null && row.intakeKcal! > 0) {
        series['intake']![row.date] = row.intakeKcal!;
      }
      if (row.sessionsCount > 0) {
        series['sessions']![row.date] = row.sessionsCount.toDouble();
      }
    }

    for (final row in await database.loadVitalsRange(from, to)) {
      if (row.restingHr != null) series['restingHr']![row.date] = row.restingHr!;
      if (row.hrvMs != null) series['hrv']![row.date] = row.hrvMs!;
    }

    // Sleep is summed per stage and belongs to the night's own date, which is
    // the morning it ended.
    final sleepRows = await database.loadSleepForNights(from, to);
    // Total slept comes from the shared answer, which excludes awake *and* lets
    // one source win a night rather than every source adding to it. Summed here,
    // a night reported by both a watch app and a ring came out close to double.
    series['sleep']!.addAll(SleepTotals.byNight(sleepRows));
    for (final row in sleepRows) {
      final minutes =
          row.endUtc.difference(row.startUtc).inMinutes.toDouble();
      if (minutes <= 0) continue;
      // The per-stage series are left summing across sources, deliberately: a
      // correlation against deep sleep is looking for a shape over time, and no
      // source-precedence rule exists for stages that the ingest has not already
      // applied. They are named as stage totals rather than as time asleep.
      final stage = switch (row.stage) {
        'deep' => 'deep',
        'rem' => 'rem',
        'awake' => 'awake',
        _ => null,
      };
      if (stage != null) {
        series[stage]!.update(
          row.nightOf,
          (value) => value + minutes,
          ifAbsent: () => minutes,
        );
      }
    }

    // Self-reports: the average of the day's entries, because someone may
    // record a mood twice and neither is more true than the other.
    final lifestyleTotals = <String, Map<String, (double, int)>>{};
    for (final row in await database.loadLifestyleRange(
      fromLocal.toUtc(),
      toLocal.toUtc(),
    )) {
      final key = switch (row.kind) {
        'mood' => 'mood',
        'stress' => 'stress',
        'recovery' => 'recovery',
        'meditation' => 'meditation',
        _ => null,
      };
      if (key == null) continue;
      final value = key == 'meditation' ? row.durationMinutes : row.value;
      if (value == null) continue;
      final date = _isoDate(row.recordedAt.toLocal());
      final totals = lifestyleTotals.putIfAbsent(key, () => {});
      final current = totals[date] ?? (0.0, 0);
      totals[date] = (current.$1 + value, current.$2 + 1);
    }
    for (final entry in lifestyleTotals.entries) {
      for (final day in entry.value.entries) {
        series[entry.key]![day.key] = day.value.$1 / day.value.$2;
      }
    }

    for (final row in await database.loadWeightEntries()) {
      final date = _isoDate(row.recordedAt.toLocal());
      if (date.compareTo(from) >= 0 && date.compareTo(to) <= 0) {
        series['weight']![date] = row.kg;
      }
    }

    return series;
  }

  static String _isoDate(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
