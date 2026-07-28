import 'dart:convert';
import 'dart:math' as math;

import '../db/app_database.dart';

/// Rebuilds conservative, inspectable correlations from canonical local data.
///
/// This deliberately discovers only patterns whose inputs and arithmetic can
/// be shown to the user. It does not send source data to a model, and it never
/// describes a correlation as a cause.
class LocalPatternDiscovery {
  LocalPatternDiscovery(this.database);

  final AppDatabase database;

  static const sleepAfterLateActivityKey = 'sleep-after-late-activity-v1';
  static const _windowDays = 28;
  static const _minimumGroupSize = 3;
  static const _minimumEffectMinutes = 30.0;

  Future<PatternDiscoveryResult> review({required DateTime now}) async {
    final localEnd =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final localStart = localEnd.subtract(
      const Duration(days: _windowDays),
    );
    final from = _isoDate(localStart);
    final to = _isoDate(localEnd.subtract(const Duration(days: 1)));

    final sleep = await database.loadSleepForNights(from, to);
    final sessions = await database.loadSessions(
      localStart.subtract(const Duration(days: 1)),
      localEnd,
    );
    final candidate = _sleepAfterLateActivity(
      sleep: sleep,
      sessions: sessions,
      from: from,
      to: to,
      computedAt: now.toUtc(),
    );

    if (candidate == null) {
      await database.removeActivePattern(sleepAfterLateActivityKey);
      return const PatternDiscoveryResult(
        observations: 0,
        activePatterns: 0,
      );
    }

    final active = await database.saveDiscoveredPattern(candidate.companion);
    return PatternDiscoveryResult(
      observations: candidate.observations,
      activePatterns: active ? 1 : 0,
    );
  }

  _DiscoveredPattern? _sleepAfterLateActivity({
    required List<SleepSegmentRow> sleep,
    required List<ActivitySessionRow> sessions,
    required String from,
    required String to,
    required DateTime computedAt,
  }) {
    final byNightAndSource = <String, Map<String, _SleepSourceTotal>>{};
    for (final entry in sleep) {
      if (entry.stage == 'awake') continue;
      final minutes = entry.endUtc.difference(entry.startUtc).inSeconds / 60;
      if (minutes <= 0) continue;
      final sources = byNightAndSource.putIfAbsent(entry.nightOf, () => {});
      final total = sources.putIfAbsent(
        entry.source,
        () => _SleepSourceTotal(priority: entry.priority),
      );
      total.minutes += minutes;
      total.priority = math.min(total.priority, entry.priority);
    }
    final sleepingMinutes = {
      for (final night in byNightAndSource.entries)
        night.key: (night.value.values.toList()
              ..sort((a, b) => a.priority.compareTo(b.priority)))
            .first
            .minutes,
    };

    final lateActivityDays = <String>{};
    for (final session in sessions) {
      final localStart = session.startUtc.toLocal();
      final localEnd = session.endUtc.toLocal();
      if (localStart.hour >= 19 || localEnd.hour >= 20) {
        lateActivityDays.add(_isoDate(localStart));
      }
    }

    final late = <double>[];
    final other = <double>[];
    for (final entry in sleepingMinutes.entries) {
      // Ignore naps and fragmentary imports.
      if (entry.value < 180 || entry.value > 720) continue;
      final morning = DateTime.parse(entry.key);
      final priorDay = _isoDate(morning.subtract(const Duration(days: 1)));
      (lateActivityDays.contains(priorDay) ? late : other).add(entry.value);
    }
    if (late.length < _minimumGroupSize || other.length < _minimumGroupSize) {
      return null;
    }

    final lateAverage = _average(late);
    final otherAverage = _average(other);
    final difference = lateAverage - otherAverage;
    if (difference.abs() < _minimumEffectMinutes) return null;

    final observations = late.length + other.length;
    final confidence = math.min(
      .9,
      .5 +
          math.min(difference.abs(), 180) / 180 * .2 +
          math.min(observations, _windowDays) / _windowDays * .2,
    );
    final direction = difference < 0 ? 'shorter' : 'longer';
    final summary = 'Sleep tended to be $direction after late activity.';
    final evidence = jsonEncode({
      'n': observations,
      'window': '$from to $to',
      'coefficient': double.parse(difference.toStringAsFixed(1)),
      'lateActivityN': late.length,
      'otherN': other.length,
      'lateActivityAverageMinutes': lateAverage.round(),
      'otherAverageMinutes': otherAverage.round(),
      'caveat': 'correlation, not cause',
    });
    return _DiscoveredPattern(
      key: sleepAfterLateActivityKey,
      computedAt: computedAt,
      summary: summary,
      evidenceJson: evidence,
      confidence: confidence,
      observations: observations,
    );
  }

  static double _average(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  static String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class PatternDiscoveryResult {
  const PatternDiscoveryResult({
    required this.observations,
    required this.activePatterns,
  });

  final int observations;
  final int activePatterns;
}

class _DiscoveredPattern {
  const _DiscoveredPattern({
    required this.key,
    required this.computedAt,
    required this.summary,
    required this.evidenceJson,
    required this.confidence,
    required this.observations,
  });

  final String key;
  final DateTime computedAt;
  final String summary;
  final String evidenceJson;
  final double confidence;
  final int observations;

  PatternCandidatesCompanion get companion => PatternCandidatesCompanion.insert(
        key: key,
        computedAt: computedAt,
        summary: summary,
        evidenceJson: evidenceJson,
        confidence: confidence,
      );
}

class _SleepSourceTotal {
  _SleepSourceTotal({required this.priority});

  int priority;
  double minutes = 0;
}
