import 'package:eter/core/longview/long_view.dart';
import 'package:eter/core/longview/long_view_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// The arithmetic that turns a span and a day into two dates.
///
/// Separate from `long_view_test.dart`, which pins the fold. This pins the
/// window, and the reason it is worth its own file is that every one of these
/// is an off-by-one waiting to happen at a month boundary — and a wrong window
/// does not throw. It quietly shows you the wrong eleven months.
void main() {
  group('the window a span covers', () {
    test('a week ends on the anchor and holds seven days', () {
      final window = LongViewWindow.of(LongViewSpan.week, DateTime(2026, 7, 30));
      expect(LongViewSource.isoDate(window.from), '2026-07-24');
      expect(LongViewSource.isoDate(window.to), '2026-07-30');
      expect(window.days, 7);
    });

    test('a week reaches back across the start of a month', () {
      final window = LongViewWindow.of(LongViewSpan.week, DateTime(2026, 3, 2));
      expect(LongViewSource.isoDate(window.from), '2026-02-24');
      expect(window.days, 7);
    });

    test('a month is the anchor’s own month, whole', () {
      final window =
          LongViewWindow.of(LongViewSpan.month, DateTime(2026, 2, 14));
      expect(LongViewSource.isoDate(window.from), '2026-02-01');
      expect(LongViewSource.isoDate(window.to), '2026-02-28');
      expect(window.days, 28);
    });

    test('February knows about leap years', () {
      final window =
          LongViewWindow.of(LongViewSpan.month, DateTime(2028, 2, 14));
      expect(LongViewSource.isoDate(window.to), '2028-02-29');
      expect(window.days, 29);
    });

    test('a year is the twelve months you have lived, not January onwards', () {
      // Seen in March, the year is April to March. Anchoring on 1 January would
      // show a year that is three months old and eleven months empty, which the
      // absent-not-zero rule would render honestly and uselessly.
      final window = LongViewWindow.of(LongViewSpan.year, DateTime(2026, 3, 15));
      expect(LongViewSource.isoDate(window.from), '2025-04-01');
      expect(LongViewSource.isoDate(window.to), '2026-03-31');
    });

    test('a year anchored in January reaches back into the year before', () {
      final window = LongViewWindow.of(LongViewSpan.year, DateTime(2026, 1, 6));
      expect(LongViewSource.isoDate(window.from), '2025-02-01');
      expect(LongViewSource.isoDate(window.to), '2026-01-31');
    });
  });

  group('stepping along the axis', () {
    test('earlier by a week lands on the day before the window', () {
      final window = LongViewWindow.of(LongViewSpan.week, DateTime(2026, 7, 30));
      final back = window.earlier(LongViewSpan.week);
      expect(LongViewSource.isoDate(back), '2026-07-23');
      // And the window it anchors is the seven days before, contiguous.
      final previous = LongViewWindow.of(LongViewSpan.week, back);
      expect(LongViewSource.isoDate(previous.to), '2026-07-23');
      expect(LongViewSource.isoDate(previous.from), '2026-07-17');
    });

    test('earlier by a month lands in the month before', () {
      final window = LongViewWindow.of(LongViewSpan.month, DateTime(2026, 3, 9));
      final back = window.earlier(LongViewSpan.month);
      expect(LongViewSource.isoDate(back), '2026-02-28');
    });

    test('later by a month lands in the month after', () {
      final window = LongViewWindow.of(LongViewSpan.month, DateTime(2026, 12, 9));
      final forward = window.later(LongViewSpan.month);
      expect(LongViewSource.isoDate(forward), '2027-01-01');
    });

    test('a year steps a whole year, not a month', () {
      final window = LongViewWindow.of(LongViewSpan.year, DateTime(2026, 3, 15));
      final back = window.earlier(LongViewSpan.year);
      final previous = LongViewWindow.of(LongViewSpan.year, back);
      expect(LongViewSource.isoDate(previous.to), '2025-03-31');
      expect(LongViewSource.isoDate(previous.from), '2024-04-01');
    });
  });
}
