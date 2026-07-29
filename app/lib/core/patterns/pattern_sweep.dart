/// Looking for anything, and reporting almost none of it.
///
/// The sweep tests every pair of things Eter records — same day, and yesterday
/// against today — which is a lot of questions. Asking a lot of questions is
/// how an app ends up telling someone that their mood depends on their step
/// count when nothing of the sort is true.
///
/// So the arithmetic in `statistics.dart` does the deciding, and this file
/// does the asking and the wording. The design consequence is deliberate and
/// worth stating plainly: **a new user is told nothing.** Three weeks of
/// records is the floor, and even then most pairs will not clear a
/// false-discovery correction across a sweep this wide. What survives is
/// survivable — the person's own record, over their own months, said so.
library;

import 'dart:convert';

import '../db/app_database.dart';
import 'daily_series.dart';
import 'statistics.dart';

/// A pair worth testing, and what it would mean.
class _Pairing {
  const _Pairing({
    required this.from,
    required this.to,
    required this.lagged,
  });

  final SeriesDefinition from;
  final SeriesDefinition to;

  /// True when [from] is yesterday and [to] is today. Same-day pairs say two
  /// things happened together; lagged pairs are the ones people mean when
  /// they ask whether exercise helps them sleep.
  final bool lagged;

  String get key =>
      'sweep:${from.key}${lagged ? '>' : '~'}${to.key}';
}

class PatternSweep {
  const PatternSweep(this.database, {this.windowDays = 120});

  final AppDatabase database;

  /// How far back to look. Long enough for a season to show, short enough
  /// that a habit from last year is not presented as current.
  final int windowDays;

  /// Recomputes every finding, writes the survivors, and retires the rest.
  ///
  /// Returns the surviving findings, strongest first.
  Future<List<String>> run({required DateTime now}) async {
    final toLocal = DateTime(now.year, now.month, now.day);
    final fromLocal = toLocal.subtract(Duration(days: windowDays));
    final series = await DailySeriesReader(database).read(
      from: _isoDate(fromLocal),
      to: _isoDate(toLocal),
      fromLocal: fromLocal,
      toLocal: toLocal.add(const Duration(days: 1)),
    );

    final candidates = <Candidate<_Pairing>>[];
    for (final from in dailySeriesDefinitions) {
      for (final to in dailySeriesDefinitions) {
        if (from.key == to.key) continue;
        for (final lagged in const [false, true]) {
          // Same-day pairs are symmetric, so test each unordered pair once.
          if (!lagged && from.key.compareTo(to.key) >= 0) continue;
          final pairing = _Pairing(from: from, to: to, lagged: lagged);
          final aligned = _align(
            series[from.key]!,
            series[to.key]!,
            lagged: lagged,
          );
          final correlation = correlate(aligned.$1, aligned.$2);
          if (correlation == null) continue;
          candidates.add(
            Candidate(subject: pairing, correlation: correlation),
          );
        }
      }
    }

    final findings = survivingFindings(candidates);
    final summaries = <String>[];
    for (final finding in findings) {
      final summary = _describe(finding);
      summaries.add(summary);
      await database.saveDiscoveredPattern(
        PatternCandidatesCompanion.insert(
          key: finding.subject.key,
          computedAt: now.toUtc(),
          summary: summary,
          evidenceJson: jsonEncode({
            'days': finding.correlation.n,
            'r': double.parse(finding.correlation.r.toStringAsFixed(3)),
            'p': double.parse(finding.correlation.p.toStringAsExponential(2)),
            'explains': '${(finding.correlation.explainedFraction * 100).round()}%',
            'lagged': finding.subject.lagged,
          }),
          confidence: finding.correlation.explainedFraction,
        ),
      );
    }

    // Anything the sweep no longer supports stops being told. A finding that
    // was true of three months ago and is not true now is worse than none.
    final surviving = findings.map((f) => f.subject.key).toSet();
    for (final row in await database.loadActivePatterns()) {
      if (row.key.startsWith('sweep:') && !surviving.contains(row.key)) {
        await database.removeActivePattern(row.key);
      }
    }
    return summaries;
  }

  /// Pairs the two series on the days both have a value.
  ///
  /// Absent days are dropped rather than filled: a missing value is missing,
  /// and substituting a zero or an average would invent the very relationship
  /// the sweep is trying to detect.
  (List<double>, List<double>) _align(
    Map<String, double> from,
    Map<String, double> to, {
    required bool lagged,
  }) {
    final xs = <double>[];
    final ys = <double>[];
    final days = from.keys.toList()..sort();
    for (final day in days) {
      final other = lagged ? _nextDay(day) : day;
      final y = to[other];
      if (y == null) continue;
      xs.add(from[day]!);
      ys.add(y);
    }
    return (xs, ys);
  }

  /// The sentence a person reads, and the model is given.
  ///
  /// It says what was compared, which way it went, how much it accounts for,
  /// and over how many days — because "your sleep is worse after late
  /// training" without the sample size is a horoscope.
  String _describe(Candidate<_Pairing> finding) {
    final pairing = finding.subject;
    final r = finding.correlation;
    final direction = r.isPositive ? 'more' : 'less';
    final percent = (r.explainedFraction * 100).round();
    if (pairing.lagged) {
      return 'On days after ${pairing.from.label} is higher, '
          '${pairing.to.label} tends to be $direction '
          '(about $percent% of the variation, across ${r.n} days).';
    }
    return 'When ${pairing.from.label} is higher, ${pairing.to.label} tends '
        'to be $direction that same day '
        '(about $percent% of the variation, across ${r.n} days).';
  }

  static String _nextDay(String isoDate) {
    final parsed = DateTime.parse(isoDate).add(const Duration(days: 1));
    return _isoDate(parsed);
  }

  static String _isoDate(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
