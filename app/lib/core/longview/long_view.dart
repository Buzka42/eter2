/// A year you can scroll: the Journal's date axis pulled back.
///
/// Not a new destination. The Journal already turns pages a day at a time; this is
/// what the same axis says when you stop asking about a day. Day, week, month,
/// year — one zoom, four scales, no navigation added. See `docs/DECISIONS.md`.
///
/// **No model call.** Every number here is arithmetic over records already on the
/// device, which is what makes it free to run, instant, and available offline to
/// somebody whose trial has ended. It is the one large feature that costs nothing
/// per user, ever.
///
/// The rule that governs all of it: **a period nobody recorded is absent, not
/// zero.** Eter has made this mistake before — v1 showed "−828 kcal · a lighter
/// balance today" to somebody who simply had not logged food, which in a calorie
/// app is an endorsement. A year view is where that error compounds: eleven
/// recorded months and one empty one, averaged as though the empty one were a
/// month of no sleep, drags the whole year down and invents a decline.
library;

import '../db/app_database.dart';
import '../health/sleep_totals.dart';

enum LongViewSpan {
  /// Seven cells, one per day.
  week,

  /// One cell per day of the month.
  month,

  /// Twelve cells, one per month.
  year,
}

/// What scale the axis is on, given how far back it has been turned.
///
/// The Long View has no zoom control: turning back *is* the zoom. This is that
/// rule, kept here rather than in the widget because it is a statement about
/// when a day stops being the interesting unit, not about a sheet.
///
/// Null means the day itself — the History sheet's original behaviour, which is
/// what the first fortnight still gets. Nobody reads yesterday as part of a
/// trend, and nobody reads a Tuesday last March as a day.
LongViewSpan? longViewSpanFor(int daysBack) => switch (daysBack) {
      < 14 => null,
      < 60 => LongViewSpan.week,
      <= 365 => LongViewSpan.month,
      _ => LongViewSpan.year,
    };

/// One period on the axis, and what is known about it.
///
/// Every measure is nullable and null means *not recorded*. A cell can be
/// entirely empty and still exist, because the gap is part of the shape of a year
/// and hiding it would make the axis lie about time.
class LongViewCell {
  const LongViewCell({
    required this.key,
    required this.label,
    this.sleepHours,
    this.mood,
    this.steps,
    this.journalEntries = 0,
    this.note,
    this.recordedDays = 0,
    this.spanDays = 1,
  });

  /// ISO date for a day cell, `YYYY-MM` for a month cell.
  final String key;

  /// What the axis calls it — a day number, a month name. Composed by the
  /// surface, which knows the language; this carries the canonical key.
  final String label;

  /// Mean hours asleep across the days that recorded any. Null when none did.
  final double? sleepHours;

  /// Mean self-reported mood, 0–10, across the days that reported one.
  final double? mood;

  /// Mean steps across recorded days.
  final double? steps;

  /// How many pages were written in this period. Zero is a real answer here —
  /// unlike a measurement, "you wrote nothing" is something Eter knows for
  /// certain.
  final int journalEntries;

  /// Aether's own telegraphic note for the period, when there is exactly one to
  /// show. Marginalia, never a claim: these are the model's words about what it
  /// had already said, and `AI_FLOW.md` §1a forbids treating them as evidence.
  final String? note;

  /// Days in this period that recorded anything at all, and how many the period
  /// contains. The surface says "4 of 7" rather than implying a full week.
  final int recordedDays;
  final int spanDays;

  bool get isEmpty =>
      sleepHours == null && mood == null && steps == null && journalEntries == 0;
}

class LongView {
  const LongView({
    required this.span,
    required this.cells,
    required this.from,
    required this.to,
  });

  final LongViewSpan span;
  final List<LongViewCell> cells;
  final DateTime from;
  final DateTime to;

  /// Cells carrying anything. The surface leads with this: "nine of twelve
  /// months have records" is the honest headline for a year half-lived with Eter.
  int get recordedCells => cells.where((cell) => !cell.isEmpty).length;

  bool get isEmpty => recordedCells == 0;

  /// Mean across recorded cells only, or null when none recorded it.
  double? meanOf(double? Function(LongViewCell) measure) {
    final values = [
      for (final cell in cells)
        if (measure(cell) case final value?) value,
    ];
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

/// Folds records into an axis. Pure: every row is passed in.
abstract final class LongViewComposer {
  static LongView compose({
    required LongViewSpan span,
    required DateTime from,
    required DateTime to,
    required List<DaySummaryRow> days,
    required List<SleepSegmentRow> sleep,
    required List<LifestyleEntryRow> lifestyle,
    required List<JournalEntryRow> journal,
    required List<GuidanceRecallRow> recalls,
  }) {
    final sleepByNight = SleepTotals.byNight(sleep);
    final stepsByDay = {
      for (final day in days)
        if (day.steps > 0) day.date: day.steps.toDouble(),
    };

    // Mood is a self-report and there can be several in a day. The day's value is
    // their mean rather than the latest: somebody who felt poor at breakfast and
    // better by evening had a middling day, not a good one.
    final moodByDay = <String, List<double>>{};
    for (final entry in lifestyle) {
      if (entry.kind != 'mood') continue;
      if (entry.value case final value?) {
        moodByDay.putIfAbsent(_isoDate(entry.recordedAt.toLocal()), () => [])
            .add(value);
      }
    }

    final entriesByDay = <String, int>{};
    for (final page in journal) {
      // Discarded pages are blanked but keep their row, so counting rows would
      // count pages the person removed.
      if (page.status == 'discarded') continue;
      final date = _isoDate(page.createdAt.toLocal());
      entriesByDay.update(date, (value) => value + 1, ifAbsent: () => 1);
    }

    final noteByDay = {for (final recall in recalls) recall.date: recall.note};

    final cells = <LongViewCell>[];
    if (span == LongViewSpan.year) {
      for (var month = DateTime(from.year, from.month);
          !month.isAfter(DateTime(to.year, to.month));
          month = DateTime(month.year, month.month + 1)) {
        final prefix = '${month.year.toString().padLeft(4, '0')}-'
            '${month.month.toString().padLeft(2, '0')}';
        bool inMonth(String date) => date.startsWith(prefix);
        cells.add(_fold(
          key: prefix,
          label: prefix,
          spanDays: DateTime(month.year, month.month + 1, 0).day,
          matches: inMonth,
          sleep: sleepByNight,
          steps: stepsByDay,
          mood: moodByDay,
          entries: entriesByDay,
          // A month has thirty notes and no room for them. The axis shows none
          // rather than picking one arbitrarily and implying it summarised the
          // month.
          note: null,
        ));
      }
    } else {
      for (var day = from; !day.isAfter(to); day = day.add(_oneDay)) {
        final date = _isoDate(day);
        cells.add(_fold(
          key: date,
          label: date,
          spanDays: 1,
          matches: (candidate) => candidate == date,
          sleep: sleepByNight,
          steps: stepsByDay,
          mood: moodByDay,
          entries: entriesByDay,
          note: noteByDay[date],
        ));
      }
    }

    return LongView(span: span, cells: cells, from: from, to: to);
  }

  static const _oneDay = Duration(days: 1);

  static LongViewCell _fold({
    required String key,
    required String label,
    required int spanDays,
    required bool Function(String date) matches,
    required Map<String, double> sleep,
    required Map<String, double> steps,
    required Map<String, List<double>> mood,
    required Map<String, int> entries,
    required String? note,
  }) {
    double? mean(Iterable<double> values) {
      final list = values.toList();
      if (list.isEmpty) return null;
      return list.reduce((a, b) => a + b) / list.length;
    }

    final sleptMinutes = [
      for (final night in sleep.entries)
        if (matches(night.key)) night.value,
    ];
    final stepCounts = [
      for (final day in steps.entries)
        if (matches(day.key)) day.value,
    ];
    final moods = [
      for (final day in mood.entries)
        if (matches(day.key)) ...day.value,
    ];
    final pages = [
      for (final day in entries.entries)
        if (matches(day.key)) day.value,
    ];

    // Days that recorded *anything*, so the surface can say "4 of 7" instead of
    // presenting a mean of four days as a week.
    final recorded = <String>{
      for (final night in sleep.keys)
        if (matches(night)) night,
      for (final day in steps.keys)
        if (matches(day)) day,
      for (final day in mood.keys)
        if (matches(day)) day,
      for (final day in entries.keys)
        if (matches(day)) day,
    };

    return LongViewCell(
      key: key,
      label: label,
      sleepHours: mean(sleptMinutes.map((minutes) => minutes / 60)),
      mood: mean(moods),
      steps: mean(stepCounts),
      journalEntries: pages.fold(0, (sum, count) => sum + count),
      note: note,
      recordedDays: recorded.length,
      spanDays: spanDays,
    );
  }

  static String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
