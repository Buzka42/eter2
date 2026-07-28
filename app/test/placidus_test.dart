import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:flutter_test/flutter_test.dart';

/// Off until the implementation lands; see the note on main().
const _skip = 'Placidus is not implemented yet — see the note above main().';

/// Houses, and the honesty about where they stop working.
///
/// Placidus is easy to get plausibly wrong: a bad solution still produces
/// twelve numbers in ascending order, and nothing about the chart looks
/// broken. So these check the properties the system must have rather than the
/// numbers it happens to produce.
// SKIPPED until Placidus is implemented correctly, and deliberately kept:
// these are the acceptance criteria, written before the implementation and
// already useful — they rejected a first attempt that produced twelve
// plausible-looking numbers with a 207-degree house in them.
//
// They also surfaced something larger. At 52N on 14 March 1990, 09:20 local,
// the engine reports an ascendant of 262 degrees (Sagittarius) against a
// midheaven of 315 (Aquarius). A morning ascendant that far behind the MC is
// not geometrically possible; 262 - 180 = 82 (Gemini) is the value the sky
// actually had. The ascendant may be half a turn out, which would affect the
// Ascendant reading and every house derived from it. Verify that before
// building houses on top of it.
void main() {
  final engine = NatalChartEngine();

  NatalChart chartAt({
    required double latitude,
    required double longitude,
    int hour = 9,
    int minute = 20,
  }) =>
      engine.calculate(NatalInput(
        localDateTime: DateTime(1990, 3, 14, hour, minute),
        utcOffsetMinutes: 60,
        latitude: latitude,
        longitude: longitude,
      ));

  group('at ordinary latitudes', skip: _skip, () {
    final chart = chartAt(latitude: 52.23, longitude: 21.01);

    test('Placidus is used, and says so', () {
      expect(chart.houseSystem, 'placidus');
      expect(chart.houseCusps, hasLength(12));
    });

    test('the angles are the first, fourth, seventh and tenth cusps', () {
      // This is what makes a quadrant system a quadrant system. Equal houses
      // satisfy the first only.
      expect(chart.houseCusps[0], closeTo(chart.ascendant.longitude, 1e-6));
      expect(chart.houseCusps[9], closeTo(chart.positions.firstWhere((p) => p.name == 'Midheaven').longitude, 1e-6));
      expect(
        chart.houseCusps[3],
        closeTo((chart.positions.firstWhere((p) => p.name == 'Midheaven').longitude + 180) % 360, 1e-6),
      );
      expect(
        chart.houseCusps[6],
        closeTo((chart.ascendant.longitude + 180) % 360, 1e-6),
      );
    });

    test('opposite cusps are exactly opposed', () {
      for (var house = 0; house < 6; house++) {
        final difference =
            (chart.houseCusps[house] - chart.houseCusps[house + 6]).abs();
        expect(difference, closeTo(180, 1e-6), reason: 'house ${house + 1}');
      }
    });

    test('the cusps advance in order around the wheel', () {
      var total = 0.0;
      for (var house = 0; house < 12; house++) {
        final span = ((chart.houseCusps[(house + 1) % 12] -
                    chart.houseCusps[house]) %
                360 +
            360) %
            360;
        expect(span, greaterThan(0), reason: 'house ${house + 1} is empty');
        expect(span, lessThan(180), reason: 'house ${house + 1} is impossible');
        total += span;
      }
      expect(total, closeTo(360, 1e-6));
    });

    test('houses are unequal, which is the whole point of the system', () {
      final spans = [
        for (var house = 0; house < 12; house++)
          ((chart.houseCusps[(house + 1) % 12] - chart.houseCusps[house]) %
                      360 +
                  360) %
              360,
      ];
      // At 52°N the quadrants are visibly distorted; if every span were 30°
      // the solver has quietly fallen back to equal houses.
      expect(
        spans.any((span) => (span - 30).abs() > 2),
        isTrue,
        reason: 'every house is 30 degrees, so this is not Placidus',
      );
    });
  });

  group('near the equator', skip: _skip, () {
    test('the distortion nearly vanishes, as it should', () {
      final chart = chartAt(latitude: 0.5, longitude: 32.6);
      final spans = [
        for (var house = 0; house < 12; house++)
          ((chart.houseCusps[(house + 1) % 12] - chart.houseCusps[house]) %
                      360 +
                  360) %
              360,
      ];
      // At the equator every semi-arc is a quarter turn, so Placidus and equal
      // houses converge. A solver that disagrees here is wrong.
      for (final span in spans) {
        expect(span, closeTo(30, 1.5));
      }
    });
  });

  group('inside the polar circles', skip: _skip, () {
    test('it refuses rather than inventing a cusp', () {
      // Tromsø. A degree of the ecliptic may never rise here, so there is no
      // semi-arc to divide — not a hard problem, an absent one.
      final chart = chartAt(latitude: 69.65, longitude: 18.96);
      expect(chart.houseSystem, 'equal');
      expect(chart.houseCusps, hasLength(12));
      for (var house = 0; house < 12; house++) {
        expect(
          chart.houseCusps[house],
          closeTo((chart.ascendant.longitude + house * 30) % 360, 1e-6),
        );
      }
    });

    test('the southern circle refuses too', () {
      final chart = chartAt(latitude: -70.1, longitude: 2.5);
      expect(chart.houseSystem, 'equal');
    });
  });

  test('a chart always carries the system it actually used', skip: _skip, () {
    // The label is not decoration: a reading that says "your Mars is in the
    // eighth" means something different under each system, and a surface can
    // only be honest about that if the chart tells it which was used.
    for (final latitude in [0.0, 25.0, 52.23, 60.0, 69.65, -45.0]) {
      final chart = chartAt(latitude: latitude, longitude: 10);
      expect(['placidus', 'equal'], contains(chart.houseSystem));
      expect(chart.toJson()['houseSystem'], chart.houseSystem);
    }
  });
}
