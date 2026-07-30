/// Loads the rows a [LongView] is folded from, and nothing else.
///
/// Kept apart from [LongViewComposer] so the fold stays pure and testable
/// against hand-built rows. This half is the boring half: five range queries
/// against tables that already exist, and the arithmetic that turns a span and
/// an anchor day into the two dates those queries want.
library;

import '../db/app_database.dart';
import 'long_view.dart';

/// The window a span covers when it is anchored on [anchor].
///
/// A week ends on the anchor rather than starting on it, because the axis is
/// travelled backwards: you arrive at a week by turning back out of its last
/// day, and the week you meant is the one you were standing in.
class LongViewWindow {
  const LongViewWindow(this.from, this.to);

  factory LongViewWindow.of(LongViewSpan span, DateTime anchor) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (span) {
      LongViewSpan.week =>
        LongViewWindow(day.subtract(const Duration(days: 6)), day),
      LongViewSpan.month => LongViewWindow(
          DateTime(day.year, day.month),
          DateTime(day.year, day.month + 1, 0),
        ),
      // Twelve months ending with the anchor's, so a year seen in March is the
      // twelve months you have lived, not January to December of a year that
      // has barely started.
      LongViewSpan.year => LongViewWindow(
          DateTime(day.year, day.month - 11),
          DateTime(day.year, day.month + 1, 0),
        ),
    };
  }

  final DateTime from;
  final DateTime to;

  int get days => to.difference(from).inDays + 1;

  /// One step earlier on the same scale.
  DateTime earlier(LongViewSpan span) => switch (span) {
        LongViewSpan.week => from.subtract(const Duration(days: 1)),
        LongViewSpan.month => DateTime(from.year, from.month, 0),
        LongViewSpan.year => DateTime(from.year, from.month, 0),
      };

  /// One step later. May land after today; the surface clamps it.
  DateTime later(LongViewSpan span) => switch (span) {
        LongViewSpan.week => to.add(const Duration(days: 7)),
        LongViewSpan.month => DateTime(to.year, to.month + 1, 1),
        LongViewSpan.year => DateTime(to.year, to.month + 12, 1),
      };
}

abstract final class LongViewSource {
  /// Reads the window and folds it. No model call, no network — see the library
  /// comment on `long_view.dart` for why that is load-bearing rather than
  /// incidental.
  static Future<LongView> load(
    AppDatabase db, {
    required LongViewSpan span,
    required DateTime anchor,
    required bool journalAllowed,
  }) async {
    final window = LongViewWindow.of(span, anchor);
    final from = isoDate(window.from);
    final to = isoDate(window.to);

    // Lifestyle and journal are timestamped rather than dated, so their range is
    // half-open on the day after the last one.
    final endExclusive = window.to.add(const Duration(days: 1));

    final results = await Future.wait<Object>([
      db.loadDaySummaryRange(from, to),
      db.loadSleepForNights(from, to),
      db.loadLifestyleRange(window.from, endExclusive),
      db.loadJournalForRange(window.from, endExclusive),
      // Recalls are Aether's own words and only ever marginalia. Withheld
      // entirely when the journal may not be read, because a recall can quote a
      // page — `AI_FLOW.md` §1a.
      if (journalAllowed)
        db.loadGuidanceRecalls(today: to, days: window.days)
      else
        Future.value(const <GuidanceRecallRow>[]),
    ]);

    return LongViewComposer.compose(
      span: span,
      from: window.from,
      to: window.to,
      days: results[0] as List<DaySummaryRow>,
      sleep: results[1] as List<SleepSegmentRow>,
      lifestyle: results[2] as List<LifestyleEntryRow>,
      journal: results[3] as List<JournalEntryRow>,
      recalls: results[4] as List<GuidanceRecallRow>,
    );
  }

  static String isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
