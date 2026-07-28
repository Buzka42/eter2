import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Prepares a factual seven-day review entirely on device.
///
/// The result is intentionally descriptive rather than advisory. It records
/// which canonical inputs were present, never fills missing days with zero,
/// and remains useful when no model transport or AI consent exists.
class LocalWeeklyRetrospective {
  LocalWeeklyRetrospective(this.database);

  final AppDatabase database;

  Future<WeeklyRetrospectiveResult?> prepare({
    required DateTime now,
  }) async {
    final today = DateTime(now.year, now.month, now.day);
    final endExclusive = today;
    final start = endExclusive.subtract(const Duration(days: 7));
    final periodStart = _isoDate(start);
    final periodEnd = _isoDate(endExclusive.subtract(const Duration(days: 1)));

    final summaries = await database.loadDaySummaryRange(
      periodStart,
      periodEnd,
    );
    final sleep = await database.loadSleepForNights(periodStart, periodEnd);
    final journal = await database.loadJournalForRange(start, endExclusive);
    final lifestyle = await database.loadLifestyleRange(start, endExclusive);
    if (summaries.isEmpty &&
        sleep.isEmpty &&
        journal.isEmpty &&
        lifestyle.isEmpty) {
      return null;
    }

    final passages = <String>[];
    if (summaries.isNotEmpty) {
      final activeAverage =
          summaries.fold<double>(0, (sum, row) => sum + row.activeKcal) /
              summaries.length;
      // The v1 schema cannot distinguish an unavailable step count from its
      // default zero, so only positive counts are described as measured.
      final stepDays = summaries.where((row) => row.steps > 0).toList();
      final movement = StringBuffer(
        'Movement was recorded on ${summaries.length} of 7 days, averaging '
        '${activeAverage.round()} active kcal on recorded days',
      );
      if (stepDays.isNotEmpty) {
        final stepAverage =
            stepDays.fold<int>(0, (sum, row) => sum + row.steps) ~/
                stepDays.length;
        movement.write(
          ' and $stepAverage steps across ${stepDays.length} measured '
          '${stepDays.length == 1 ? 'day' : 'days'}',
        );
      }
      passages.add('$movement.');
    }

    final sleepByNight = _sleepMinutesByNight(sleep);
    if (sleepByNight.isNotEmpty) {
      final average =
          sleepByNight.values.reduce((a, b) => a + b) / sleepByNight.length;
      passages.add(
        'Sleep was available for ${sleepByNight.length} of 7 nights, '
        'averaging ${(average / 60).toStringAsFixed(1)} hours.',
      );
    }
    if (journal.isNotEmpty) {
      passages.add(
        'You made ${journal.length} journal '
        '${journal.length == 1 ? 'entry' : 'entries'} during this window.',
      );
    }
    if (lifestyle.isNotEmpty) {
      final kinds = lifestyle.map((entry) => entry.kind).toSet().toList()
        ..sort();
      passages.add(
        '${lifestyle.length} self-reported '
        '${lifestyle.length == 1 ? 'signal was' : 'signals were'} recorded '
        'across ${kinds.join(', ')}.',
      );
    }

    final content = jsonEncode({
      'schemaVersion': 1,
      'headline': summaries.length == 7
          ? 'Your seven-day view'
          : 'Your partial seven-day view',
      'passages': passages,
      'caveat': 'Missing days are omitted, not treated as zero.',
    });
    final evidence = jsonEncode({
      'window': '$periodStart to $periodEnd',
      'daySummaryN': summaries.length,
      'sleepNightN': sleepByNight.length,
      'journalEntryN': journal.length,
      'lifestyleEntryN': lifestyle.length,
    });
    final id = 'weekly-$periodEnd';
    await database.saveRetrospective(
      RetrospectivesCompanion.insert(
        id: id,
        kind: 'weekly',
        periodStart: periodStart,
        periodEnd: periodEnd,
        generatedAt: now.toUtc(),
        contentJson: content,
        evidenceJson: Value(evidence),
        model: 'local-factual-v1',
      ),
    );
    return WeeklyRetrospectiveResult(
      id: id,
      periodStart: periodStart,
      periodEnd: periodEnd,
      passages: passages,
    );
  }

  static Map<String, double> _sleepMinutesByNight(
    List<SleepSegmentRow> rows,
  ) {
    final totals = <String, Map<String, _SleepSourceTotal>>{};
    for (final row in rows) {
      if (row.stage == 'awake') continue;
      final minutes = row.endUtc.difference(row.startUtc).inSeconds / 60;
      if (minutes <= 0) continue;
      final sources = totals.putIfAbsent(row.nightOf, () => {});
      final source = sources.putIfAbsent(
        row.source,
        () => _SleepSourceTotal(priority: row.priority),
      );
      source.minutes += minutes;
      if (row.priority < source.priority) source.priority = row.priority;
    }
    return {
      for (final night in totals.entries)
        night.key: (night.value.values.toList()
              ..sort((a, b) => a.priority.compareTo(b.priority)))
            .first
            .minutes,
    };
  }

  static String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class WeeklyRetrospectiveResult {
  const WeeklyRetrospectiveResult({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.passages,
  });

  final String id;
  final String periodStart;
  final String periodEnd;
  final List<String> passages;
}

class _SleepSourceTotal {
  _SleepSourceTotal({required this.priority});

  int priority;
  double minutes = 0;
}
