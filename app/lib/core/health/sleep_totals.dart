import '../db/app_database.dart';

/// How long somebody slept, answered once.
///
/// This existed three times, and the three did not agree:
///
/// | | excluded `awake` | one source per night |
/// |---|---|---|
/// | `local_weekly_retrospective` | yes | yes |
/// | `patterns/daily_series` | yes | **no** |
/// | `aether/context_assembler` | **no** | **no** |
///
/// So the Week in View, the correlation sweep and the number Aether was *told*
/// could each report a different night, and the one guidance received was the
/// least correct of the three — a night with two contributing sources came out
/// close to double, with the minutes spent awake counted as sleep on top.
///
/// Two rules, both learned from real data:
///
/// **Awake is not asleep.** Garmin reported 8h21m for a night Eter called 8h25m,
/// and the difference was exactly the four minutes the watch recorded as awake.
/// Every downstream number inherited it. See `test/sleep_totals_test.dart`.
///
/// **One source wins a night, rather than every source adding to it.**
/// `replaceSleepForNight` is keyed on `(night, source)`, so a phone whose watch
/// app and whose ring both write to Health Connect legitimately holds two full
/// accounts of the same night. Summing them describes a night nobody had. The
/// lowest `priority` wins, which is the same precedence the minute pipeline uses,
/// so sleep and movement agree about which source is authoritative.
abstract final class SleepTotals {
  /// Minutes asleep per `nightOf`, keyed by the morning the night ended.
  ///
  /// Nights with no sleep at all are simply absent. They are never zero: a night
  /// nobody recorded and a night with no sleep are different facts, and a caller
  /// that cannot tell them apart will average one into the other.
  static Map<String, double> byNight(Iterable<SleepSegmentRow> rows) {
    final perSource = <String, Map<String, _SourceTotal>>{};
    for (final row in rows) {
      if (row.stage == 'awake') continue;
      // Seconds rather than whole minutes: a night is a dozen or more segments,
      // and rounding each one down loses several minutes across the night.
      final minutes = row.endUtc.difference(row.startUtc).inSeconds / 60;
      if (minutes <= 0) continue;
      final sources = perSource.putIfAbsent(row.nightOf, () => {});
      final total = sources.putIfAbsent(
        row.source,
        () => _SourceTotal(priority: row.priority),
      );
      total.minutes += minutes;
      if (row.priority < total.priority) total.priority = row.priority;
    }
    return {
      for (final night in perSource.entries)
        night.key: (night.value.values.toList()
              ..sort((a, b) => a.priority.compareTo(b.priority)))
            .first
            .minutes,
    };
  }
}

class _SourceTotal {
  _SourceTotal({required this.priority});
  double minutes = 0;
  int priority;
}
