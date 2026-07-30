import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/health/sleep_totals.dart';
import 'package:flutter_test/flutter_test.dart';

/// One answer to "how long did they sleep", pinned.
///
/// There were three, and they disagreed. The Week in View excluded awake and let
/// one source win a night; the correlation sweep excluded awake but summed every
/// source; the guidance payload did neither — so the figure Aether was *told* was
/// the least correct of the three, and a night reported by two sources arrived
/// close to double with time awake counted as sleep on top.
void main() {
  SleepSegmentRow segment({
    required String night,
    required String stage,
    required int minutes,
    String source = 'healthConnect:garmin',
    int priority = 3,
    int startHour = 1,
  }) =>
      SleepSegmentRow(
        id: 0,
        nightOf: night,
        stage: stage,
        startUtc: DateTime.utc(2026, 7, 29, startHour),
        endUtc: DateTime.utc(2026, 7, 29, startHour)
            .add(Duration(minutes: minutes)),
        source: source,
        priority: priority,
        externalId: null,
      );

  test('awake is not asleep', () {
    // The real night: Garmin said 8h21m, Eter said 8h25m, and the difference was
    // exactly the four minutes the watch recorded as awake.
    final totals = SleepTotals.byNight([
      segment(night: '2026-07-29', stage: 'light', minutes: 296),
      segment(night: '2026-07-29', stage: 'rem', minutes: 165),
      segment(night: '2026-07-29', stage: 'deep', minutes: 40),
      segment(night: '2026-07-29', stage: 'awake', minutes: 4),
    ]);

    expect(totals['2026-07-29'], 501);
  });

  test('one source wins a night rather than every source adding to it', () {
    // A phone whose watch app and whose ring both write to Health Connect holds
    // two complete accounts of the same night. Summing them describes a night
    // nobody had — sixteen hours of sleep out of eight.
    final totals = SleepTotals.byNight([
      segment(night: '2026-07-29', stage: 'light', minutes: 480, priority: 3),
      segment(
        night: '2026-07-29',
        stage: 'light',
        minutes: 465,
        source: 'healthConnect:ring',
        priority: 5,
      ),
    ]);

    expect(totals['2026-07-29'], 480, reason: 'the better source, not the sum');
  });

  test('the lowest priority wins, whatever order the rows arrive in', () {
    for (final reversed in [false, true]) {
      final rows = [
        segment(night: '2026-07-29', stage: 'light', minutes: 400, priority: 7),
        segment(
          night: '2026-07-29',
          stage: 'light',
          minutes: 470,
          source: 'appleHealth',
          priority: 1,
        ),
      ];
      final totals =
          SleepTotals.byNight(reversed ? rows.reversed.toList() : rows);
      expect(totals['2026-07-29'], 470);
    }
  });

  test('a night nobody recorded is absent, never zero', () {
    // The distinction the whole file exists to protect. A caller that cannot tell
    // "no record" from "no sleep" will average one into the other, and every
    // downstream mean drops.
    final totals = SleepTotals.byNight([
      segment(night: '2026-07-29', stage: 'light', minutes: 400),
    ]);

    expect(totals.containsKey('2026-07-28'), isFalse);
    expect(totals['2026-07-28'], isNull);
  });

  test('a night of only awake segments is absent too', () {
    expect(
      SleepTotals.byNight([
        segment(night: '2026-07-29', stage: 'awake', minutes: 40),
      ]),
      isEmpty,
    );
  });

  test('seconds accumulate, so a long night does not lose minutes', () {
    // Twelve segments of 30s90 each. Rounded per segment this loses six minutes
    // across the night; accumulated in seconds it does not.
    final rows = [
      for (var i = 0; i < 12; i++)
        SleepSegmentRow(
          id: i,
          nightOf: '2026-07-29',
          stage: 'light',
          startUtc: DateTime.utc(2026, 7, 29, 1).add(Duration(minutes: i * 31)),
          endUtc: DateTime.utc(2026, 7, 29, 1)
              .add(Duration(minutes: i * 31, seconds: 1830)),
          source: 'healthConnect:garmin',
          priority: 3,
          externalId: null,
        ),
    ];

    expect(SleepTotals.byNight(rows)['2026-07-29'], closeTo(366, 0.01));
  });

  test('nights are kept apart', () {
    final totals = SleepTotals.byNight([
      segment(night: '2026-07-28', stage: 'light', minutes: 400),
      segment(night: '2026-07-29', stage: 'light', minutes: 470),
    ]);

    expect(totals['2026-07-28'], 400);
    expect(totals['2026-07-29'], 470);
  });
}
