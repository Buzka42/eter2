import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/longview/long_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// The year, folded.
///
/// Almost every test here is one rule seen from a different angle: **a period
/// nobody recorded is absent, not zero.** Eter has got this wrong before — v1 told
/// somebody who had not logged food that they were 828 kcal down, which in a
/// calorie app is an endorsement. A year view is where the error compounds:
/// average eleven recorded months with one empty one treated as a month of no
/// sleep and you have invented a decline that did not happen.
void main() {
  DaySummaryRow day(String date, {int steps = 0}) => DaySummaryRow(
        date: date,
        activeKcal: 0,
        basalKcal: 0,
        intakeKcal: null,
        steps: steps,
        sessionsCount: 0,
        recalibrated: false,
        syncedAt: null,
      );

  SleepSegmentRow night(String date, {required int minutes}) => SleepSegmentRow(
        id: 0,
        nightOf: date,
        stage: 'light',
        startUtc: DateTime.utc(2026, 7, 1),
        endUtc: DateTime.utc(2026, 7, 1).add(Duration(minutes: minutes)),
        source: 'healthConnect:garmin',
        priority: 3,
        externalId: null,
      );

  LifestyleEntryRow mood(DateTime at, double value) => LifestyleEntryRow(
        id: 0,
        recordedAt: at,
        kind: 'mood',
        value: value,
        durationMinutes: null,
        note: null,
        source: 'self-report',
        syncedAt: null,
        mirrorId: null,
      );

  JournalEntryRow page(DateTime at, {String status = 'kept'}) =>
      JournalEntryRow(
        id: 0,
        createdAt: at,
        entryText: 'something',
        source: 'typed',
        status: status,
        extractionJson: null,
        model: null,
        promptVersion: null,
        appliedAt: null,
        excludedFromAi: false,
        syncedAt: null,
        mirrorId: null,
      );

  LongView week({
    List<DaySummaryRow> days = const [],
    List<SleepSegmentRow> sleep = const [],
    List<LifestyleEntryRow> lifestyle = const [],
    List<JournalEntryRow> journal = const [],
    List<GuidanceRecallRow> recalls = const [],
  }) =>
      LongViewComposer.compose(
        span: LongViewSpan.week,
        from: DateTime(2026, 7, 20),
        to: DateTime(2026, 7, 26),
        days: days,
        sleep: sleep,
        lifestyle: lifestyle,
        journal: journal,
        recalls: recalls,
      );

  group('absent is not zero', () {
    test('an unrecorded day carries nulls, not zeroes', () {
      final view = week(sleep: [night('2026-07-20', minutes: 420)]);

      final recorded = view.cells.firstWhere((c) => c.key == '2026-07-20');
      final empty = view.cells.firstWhere((c) => c.key == '2026-07-21');
      expect(recorded.sleepHours, 7);
      expect(empty.sleepHours, isNull);
      expect(empty.steps, isNull);
      expect(empty.mood, isNull);
      expect(empty.isEmpty, isTrue);
    });

    test('the mean skips unrecorded days rather than averaging them in', () {
      // Two nights of seven hours across a seven-day week is a seven-hour mean,
      // not a two-hour one. This is the whole point of the file.
      final view = week(sleep: [
        night('2026-07-20', minutes: 420),
        night('2026-07-22', minutes: 420),
      ]);

      expect(view.meanOf((cell) => cell.sleepHours), 7);
    });

    test('an empty period still occupies the axis', () {
      // Absent from the averages, present on the axis. A year with a gap in it
      // has a gap in it, and collapsing the cells would make the axis lie about
      // time.
      final view = week();

      expect(view.cells, hasLength(7));
      expect(view.recordedCells, 0);
      expect(view.isEmpty, isTrue);
      expect(view.meanOf((cell) => cell.sleepHours), isNull);
    });

    test('it says how much of a period was recorded', () {
      final view = week(sleep: [
        night('2026-07-20', minutes: 400),
        night('2026-07-21', minutes: 400),
      ]);

      // Per cell here; the year fold is what makes this carry its weight.
      expect(
        view.cells.where((cell) => cell.recordedDays == 1).length,
        2,
      );
    });
  });

  group('what a day is worth', () {
    test('several moods in a day average, rather than the last one winning', () {
      // Poor at breakfast and better by evening is a middling day, not a good
      // one, and not a bad one either.
      final view = week(lifestyle: [
        mood(DateTime(2026, 7, 20, 8), 3),
        mood(DateTime(2026, 7, 20, 21), 7),
      ]);

      expect(view.cells.first.mood, 5);
    });

    test('a discarded page is not a page', () {
      // Discarding blanks the text and keeps the row, so counting rows would
      // count pages the person removed.
      final view = week(journal: [
        page(DateTime(2026, 7, 20, 9)),
        page(DateTime(2026, 7, 20, 10), status: 'discarded'),
      ]);

      expect(view.cells.first.journalEntries, 1);
    });

    test('writing nothing is a real zero, unlike a measurement', () {
      // Eter cannot know whether a body slept on a day nothing recorded, but it
      // knows perfectly well whether a page was written.
      final view = week(sleep: [night('2026-07-20', minutes: 400)]);

      expect(view.cells.first.journalEntries, 0);
      expect(view.cells.first.sleepHours, isNotNull);
    });

    test('a day is counted as recorded if anything at all touched it', () {
      final view = week(days: [day('2026-07-23', steps: 6000)]);
      final cell = view.cells.firstWhere((c) => c.key == '2026-07-23');

      expect(cell.recordedDays, 1);
      expect(cell.isEmpty, isFalse);
      expect(cell.sleepHours, isNull, reason: 'steps are not sleep');
    });
  });

  group('the year fold', () {
    LongView year(List<SleepSegmentRow> sleep) => LongViewComposer.compose(
          span: LongViewSpan.year,
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 12, 31),
          days: const [],
          sleep: sleep,
          lifestyle: const [],
          journal: const [],
          recalls: const [],
        );

    test('is twelve cells whatever was recorded', () {
      expect(year(const []).cells, hasLength(12));
    });

    test('one empty month does not drag the year down', () {
      // Eleven months at seven hours and one month with no records is a
      // seven-hour year. Treating the empty month as zero would report 6.4 and
      // invent a decline nobody lived.
      final sleep = [
        for (var month = 1; month <= 11; month++)
          night(
            '2026-${month.toString().padLeft(2, '0')}-15',
            minutes: 420,
          ),
      ];
      final view = year(sleep);

      expect(view.recordedCells, 11);
      expect(view.meanOf((cell) => cell.sleepHours), 7);
      expect(view.cells.last.sleepHours, isNull);
    });

    test('a month averages its recorded nights, not its calendar days', () {
      final view = year([
        night('2026-03-01', minutes: 480),
        night('2026-03-02', minutes: 360),
      ]);
      final march = view.cells.firstWhere((cell) => cell.key == '2026-03');

      expect(march.sleepHours, 7);
      expect(march.recordedDays, 2);
      expect(march.spanDays, 31);
    });

    test('a month shows no note rather than one of thirty', () {
      // Picking one arbitrarily would imply it summarised the month. These are
      // Aether's own words about what it had already said, and `ENGINEERING.md` §1a
      // forbids treating them as a claim about anything.
      expect(year(const []).cells.every((cell) => cell.note == null), isTrue);
    });
  });
}
