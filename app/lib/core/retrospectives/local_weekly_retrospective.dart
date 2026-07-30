import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../i18n/language.dart';
import '../i18n/strings.dart';

/// Prepares a factual seven-day review entirely on device.
///
/// The result is intentionally descriptive rather than advisory. It records
/// which canonical inputs were present, never fills missing days with zero,
/// and remains useful when no model transport or AI consent exists.
///
/// Written in the profile's language. This is the one piece of prose in the
/// product that Eter composes itself rather than asking Aether for, so it is
/// also the one that would have stayed English in a translated build — and it is
/// stored, so it would have stayed English on screen too. The stored row is
/// discarded when the language changes; see `AppDatabase.chooseLanguage`.
class LocalWeeklyRetrospective {
  LocalWeeklyRetrospective(this.database);

  final AppDatabase database;

  Future<WeeklyRetrospectiveResult?> prepare({
    required DateTime now,
  }) async {
    final strings = EterStrings.forLanguage(
      AppLanguage.forProfile((await database.loadProfile())?.language),
    );
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
      passages.add(strings.retrospectiveMovement(
        days: summaries.length,
        averageActiveKcal: activeAverage.round(),
        averageSteps: stepDays.isEmpty
            ? null
            : stepDays.fold<int>(0, (sum, row) => sum + row.steps) ~/
                stepDays.length,
        stepDays: stepDays.isEmpty ? null : stepDays.length,
      ));
    }

    final sleepByNight = _sleepMinutesByNight(sleep);
    if (sleepByNight.isNotEmpty) {
      final average =
          sleepByNight.values.reduce((a, b) => a + b) / sleepByNight.length;
      passages.add(strings.retrospectiveSleep(
        nights: sleepByNight.length,
        averageHours: (average / 60).toStringAsFixed(1),
      ));
    }
    if (journal.isNotEmpty) {
      passages.add(strings.retrospectiveJournal(journal.length));
    }
    if (lifestyle.isNotEmpty) {
      final kinds = lifestyle.map((entry) => entry.kind).toSet().toList()
        ..sort();
      passages.add(strings.retrospectiveLifestyle(
        signals: lifestyle.length,
        kinds: kinds,
      ));
    }

    final content = jsonEncode({
      'schemaVersion': 1,
      'headline': strings.retrospectiveHeadline(complete: summaries.length == 7),
      'passages': passages,
      'caveat': strings.retrospectiveCaveat,
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
