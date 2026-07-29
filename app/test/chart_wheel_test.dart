import 'dart:math' as math;

import 'package:eter/core/symbolic/astro_glyphs.dart';
import 'package:eter/core/symbolic/chart_wheel.dart';
import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The wheel's geometry, against real charts.
///
/// Written after a chart came back with "lines criss-crossing". Both causes
/// were geometric and invisible in a review of the paint calls: the angles were
/// drawn from the centre, laying two diameters across the aspect figure, and a
/// crowded glyph stepped inward until it left the annulus and landed among the
/// chords. A golden would have caught neither at 300 dp — the second only fires
/// on a chart with a tight pair in it, and the first looked deliberate.
///
/// So these assert the rule instead: **nothing but an aspect chord enters the
/// aspect disc**, and no two glyphs overlap.
void main() {
  final engine = NatalChartEngine();

  NatalChart chartFor({
    required DateTime local,
    required int offsetMinutes,
    required double latitude,
    required double longitude,
  }) =>
      engine.calculate(NatalInput(
        localDateTime: local,
        utcOffsetMinutes: offsetMinutes,
        latitude: latitude,
        longitude: longitude,
      ));

  /// The chart that reported the fault. Uranus 19.7 Capricorn, Neptune 19.4 —
  /// three tenths of a degree apart, which is what pushed a glyph inward.
  final warsaw = chartFor(
    local: DateTime(1993, 7, 25, 12, 30),
    offsetMinutes: 120,
    latitude: 52.2297,
    longitude: 21.0122,
  );

  final charts = <String, NatalChart>{
    'Warsaw 1993': warsaw,
    'London 2000': chartFor(
      local: DateTime(2000, 1, 1, 0, 0),
      offsetMinutes: 0,
      latitude: 51.5074,
      longitude: -0.1278,
    ),
    'Quito 1985': chartFor(
      local: DateTime(1985, 6, 15, 18, 0),
      offsetMinutes: -300,
      latitude: -0.1807,
      longitude: -78.4678,
    ),
    'Sydney 1978': chartFor(
      local: DateTime(1978, 3, 3, 6, 45),
      offsetMinutes: 660,
      latitude: -33.8688,
      longitude: 151.2093,
    ),
    'Tromso 1990': chartFor(
      local: DateTime(1990, 3, 14, 9, 20),
      offsetMinutes: 60,
      latitude: 69.65,
      longitude: 18.96,
    ),
  };

  // The sizes the Vessel actually asks for, plus the widget default.
  const sizes = [240.0, 300.0, 340.0];

  group('the aspect disc belongs to the aspects', () {
    test('no body glyph or its leader line enters it', () {
      for (final entry in charts.entries) {
        for (final size in sizes) {
          final outer = size / 2 - 1;
          final layout = NatalChartWheelLayout(
            chart: entry.value,
            outer: outer,
            drawHouses: true,
          );

          for (final body in layout.bodies) {
            // The glyph box, at its innermost.
            final innerEdge = layout.labelRadius - layout.bodyGlyphSize / 2;
            expect(
              innerEdge,
              greaterThan(layout.aspectRadius),
              reason: '${entry.key} at $size: ${body.name} glyph overlaps the '
                  'aspect circle',
            );
            // And its outermost, which must stay off the sign ring.
            expect(
              layout.labelRadius + layout.bodyGlyphSize / 2,
              lessThanOrEqualTo(layout.ringInner + 0.001),
              reason: '${entry.key} at $size: ${body.name} glyph reaches the '
                  'sign ring',
            );
          }
        }
      }
    });

    test('a glyph never steps inward, however tight the pair', () {
      // Uranus and Neptune are 0.29 degrees apart in this chart. Under the old
      // radius-stepping they dropped 15 px each collision, up to 60 px, which
      // put them well inside a 92 px aspect circle.
      final layout = NatalChartWheelLayout(
        chart: warsaw,
        outer: 149,
        drawHouses: true,
      );
      final uranus =
          layout.bodies.firstWhere((body) => body.name == 'Uranus');
      final neptune =
          layout.bodies.firstWhere((body) => body.name == 'Neptune');

      // Both sit on the same circle. Only the angle differs.
      expect(layout.labelRadius, greaterThan(layout.aspectRadius));
      expect(uranus.nudge + neptune.nudge, greaterThan(0));
      expect(
        NatalChartWheelLayout.forwardGap(
          neptune.labelLongitude,
          uranus.labelLongitude,
        ),
        closeTo(layout.minLabelSeparation, 0.01),
      );
    });
  });

  group('glyphs do not overlap', () {
    test('every pair keeps its separation, in every chart and size', () {
      for (final entry in charts.entries) {
        for (final size in sizes) {
          final layout = NatalChartWheelLayout(
            chart: entry.value,
            outer: size / 2 - 1,
            drawHouses: true,
          );
          final labels = [
            for (final body in layout.bodies) body.labelLongitude,
          ]..sort();

          for (var i = 0; i < labels.length; i++) {
            final gap = NatalChartWheelLayout.forwardGap(
              labels[i],
              labels[(i + 1) % labels.length],
            );
            expect(
              gap,
              greaterThanOrEqualTo(layout.minLabelSeparation - 0.01),
              reason: '${entry.key} at $size: two glyphs overlap',
            );
          }
        }
      }
    });

    test('a body is never moved further than it has to be', () {
      // Spreading is a repair, not a layout: a chart with nothing crowded must
      // come out untouched, or every glyph would be lying about its degree by
      // a little.
      final spread = NatalChartWheelLayout(
        chart: charts['Quito 1985']!,
        outer: 170,
        drawHouses: true,
      );
      for (final body in spread.bodies) {
        expect(
          body.nudge,
          lessThan(spread.minLabelSeparation),
          reason: '${body.name} moved more than one glyph width',
        );
      }
    });

    test('the bead stays exactly on the degree, whatever the glyph did', () {
      // This is what makes the nudge honest.
      final layout = NatalChartWheelLayout(
        chart: warsaw,
        outer: 149,
        drawHouses: true,
      );
      for (final body in layout.bodies) {
        final position = warsaw.positions
            .firstWhere((candidate) => candidate.name == body.name);
        expect(body.longitude, position.longitude);
      }
    });
  });

  group('orientation', () {
    test('the Ascendant is on the left and the tenth cusp near the top', () {
      final layout = NatalChartWheelLayout(
        chart: warsaw,
        outer: 100,
        drawHouses: true,
      );
      const centre = Offset(0, 0);

      final ascendant =
          layout.point(centre, warsaw.ascendant.longitude, 100);
      expect(ascendant.dx, closeTo(-100, 0.001));
      expect(ascendant.dy, closeTo(0, 0.001));

      // Canvas y runs down, so the tenth cusp being up means a negative dy.
      final tenth = layout.point(centre, warsaw.houseCusps[9], 100);
      expect(tenth.dy, lessThan(-80));

      // And the first house falls below the Ascendant, as in every chart drawn
      // since the seventeenth century.
      final firstHouseMiddle = layout.point(
        centre,
        warsaw.ascendant.longitude + 15,
        100,
      );
      expect(firstHouseMiddle.dy, greaterThan(0));
    });

    test('without a reliable birth time Aries takes the left', () {
      final layout = NatalChartWheelLayout(
        chart: warsaw,
        outer: 100,
        drawHouses: false,
      );
      expect(layout.anchor, 0);
      final aries = layout.point(const Offset(0, 0), 0, 100);
      expect(aries.dx, closeTo(-100, 0.001));
    });
  });

  group('every drawable body is drawn', () {
    test('the ten bodies and the node, and neither angle', () {
      final layout = NatalChartWheelLayout(
        chart: warsaw,
        outer: 149,
        drawHouses: true,
      );
      final names = layout.bodies.map((body) => body.name).toSet();

      expect(names, contains('Sun'));
      expect(names, contains('Pluto'));
      expect(names, hasLength(10));
      // The angles are labelled with letters, not glyphs.
      expect(names, isNot(contains('Ascendant')));
      expect(names, isNot(contains('Midheaven')));
      // The engine computes the mean North Node and `EterAstro.ttf` has no
      // codepoint for it, so the wheel silently omits it. Documented here
      // rather than left as a surprise: the node is in the chart, in the
      // readings, and in the export, and only the wheel cannot show it.
      expect(
        warsaw.positions.any((body) => body.name == 'North Node'),
        isTrue,
      );
      expect(names, isNot(contains('North Node')));
      for (final name in names) {
        expect(AstroGlyph.forBody(name), isNotNull);
      }
    });
  });

  group('it renders', () {
    testWidgets('at every size, in both registers, without an exception',
        (tester) async {
      for (final entry in charts.entries) {
        for (final size in sizes) {
          for (final brightness in Brightness.values) {
            await tester.pumpWidget(MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: Center(
                child: NatalChartWheel(chart: entry.value, size: size),
              ),
            ));
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} at $size ${brightness.name}',
            );
          }
        }
      }
    });
  });

  group('the spread is sound in the abstract', () {
    test('a full stellium of twelve at one degree still fits', () {
      // Not a real chart. It is the case the relaxation must not spin on.
      final layout = NatalChartWheelLayout(
        chart: NatalChart(
          calculatedAtUtc: DateTime.utc(2026, 7, 29),
          houseCusps: List<double>.generate(12, (index) => index * 30.0),
          aspects: const [],
          houseSystem: 'equal',
          engine: 'test',
          positions: const [
            ZodiacPosition(name: 'Sun', longitude: 100),
            ZodiacPosition(name: 'Moon', longitude: 100.1),
            ZodiacPosition(name: 'Mercury', longitude: 100.2),
            ZodiacPosition(name: 'Venus', longitude: 100.3),
            ZodiacPosition(name: 'Mars', longitude: 100.4),
            ZodiacPosition(name: 'Jupiter', longitude: 100.5),
            ZodiacPosition(name: 'Saturn', longitude: 100.6),
            ZodiacPosition(name: 'Uranus', longitude: 100.7),
            ZodiacPosition(name: 'Neptune', longitude: 100.8),
            ZodiacPosition(name: 'Pluto', longitude: 100.9),
            ZodiacPosition(name: 'North Node', longitude: 101),
            ZodiacPosition(name: 'Ascendant', longitude: 0),
          ],
        ),
        outer: 120,
        drawHouses: false,
      );

      final labels = [for (final body in layout.bodies) body.labelLongitude]
        ..sort();
      // Ten, not eleven: the node has no glyph.
      expect(labels, hasLength(10));
      for (var i = 0; i < labels.length; i++) {
        expect(
          NatalChartWheelLayout.forwardGap(
            labels[i],
            labels[(i + 1) % labels.length],
          ),
          greaterThanOrEqualTo(layout.minLabelSeparation - 0.01),
        );
      }
      // And they stay a cluster rather than being flung around the wheel: the
      // whole group spans a little over ten glyph widths, centred where it was.
      final span = NatalChartWheelLayout.forwardGap(labels.first, labels.last);
      expect(span, lessThan(layout.minLabelSeparation * 10));
      expect(span / 2 + labels.first, closeTo(100.45, 1.5));
    });

    test('a glyph subtends the same angle at every size', () {
      // Derived from arc length, and every radius here is a fraction of the
      // same `outer`, so the angle comes out scale-invariant. That is the
      // property worth having: one chart is crowded in exactly the same places
      // on a 240 dp wheel as on a 340 dp one, so the drawing does not
      // rearrange itself as the pane resizes.
      double separationAt(double size) => NatalChartWheelLayout(
            chart: warsaw,
            outer: size / 2 - 1,
            drawHouses: true,
          ).minLabelSeparation;

      expect(separationAt(340), closeTo(separationAt(240), 1e-9));
      // Sanity: a glyph is about ten degrees of the wheel, not one and not
      // ninety. If this moves a long way the band or the glyph size changed.
      expect(separationAt(300), inInclusiveRange(6.0, 16.0));
    });
  });

  test('the aspect chords are the only thing crossing the middle', () {
    // The rule this file exists for, stated once as arithmetic: every radius
    // the wheel draws at, other than a chord endpoint, is outside the aspect
    // circle.
    final layout = NatalChartWheelLayout(
      chart: warsaw,
      outer: 149,
      drawHouses: true,
    );

    // House cusps: from the aspect circle outward. Under the fault the angular
    // four started at zero.
    expect(layout.aspectRadius, greaterThan(0));
    expect(layout.aspectRadius, lessThan(layout.ringInner));

    // Glyph band, with clearance at both edges.
    expect(
      layout.labelRadius - layout.bodyGlyphSize / 2,
      greaterThan(layout.aspectRadius),
    );

    // A leader line runs from the ring inward to the glyph edge and no
    // further, so its innermost point is the glyph's outer clearance.
    for (final body in layout.bodies) {
      final bead = layout.point(Offset.zero, body.longitude, layout.ringInner);
      final at = layout.point(
        Offset.zero,
        body.labelLongitude,
        layout.labelRadius,
      );
      final clearance = layout.bodyGlyphSize * 0.62;
      final delta = at - bead;
      final stop = delta.distance > clearance
          ? bead + delta * (1 - clearance / delta.distance)
          : bead;
      expect(
        math.sqrt(stop.dx * stop.dx + stop.dy * stop.dy),
        greaterThan(layout.aspectRadius),
        reason: '${body.name} leader line crosses the aspect circle',
      );
    }
  });
}
