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

  group('the angle letters keep to their own lane', () {
    // `ASC` and `MC` used to be drawn at 0.995 of the outer radius and centred
    // there, which is inside the sign ring — they overlapped the sign glyphs
    // by about six pixels — and carried them some nine pixels past the
    // widget's own edge, so whether you read `ASC` or `AS` was up to whatever
    // contained the wheel. It fired on every chart drawn with houses, which is
    // every chart from somebody who gave Eter a birth time.
    //
    // Measured here rather than looked at, because at 340 dp on a plate the
    // overlap is a few pixels and reads as kerning.

    /// What the painter measures for `ASC`: half the diagonal of its box.
    /// Inter at these sizes is about 2.2:1 for three caps, so this is a
    /// deliberate over-estimate of the real face — the lane must be at least
    /// this wide, never exactly it.
    double extentFor(double size) {
      final fontSize = (size * 0.027).clamp(7.5, 9.5);
      final width = fontSize * 2.4;
      final height = fontSize * 1.35;
      return math.sqrt(width * width + height * height) / 2;
    }

    test('a letter never leaves the widget, at any size', () {
      for (final size in sizes) {
        final extent = extentFor(size);
        final outer = NatalChartWheelLayout.outerFor(size, extent);
        final layout = NatalChartWheelLayout(
          chart: warsaw,
          outer: outer,
          drawHouses: true,
          angleLabelExtent: extent,
        );
        // The furthest corner of the box, in the worst direction.
        final furthest = layout.angleLabelRadius + extent;
        expect(
          furthest,
          lessThanOrEqualTo(size / 2),
          reason: 'an angle letter paints outside a ${size}dp wheel',
        );
      }
    });

    test('a letter never touches the sign ring', () {
      for (final size in sizes) {
        final extent = extentFor(size);
        final outer = NatalChartWheelLayout.outerFor(size, extent);
        final layout = NatalChartWheelLayout(
          chart: warsaw,
          outer: outer,
          drawHouses: true,
          angleLabelExtent: extent,
        );
        // The sign glyphs sit in the middle of the ring band; the letters must
        // clear the band entirely, not merely miss the glyphs.
        expect(
          layout.angleLabelRadius - extent,
          greaterThanOrEqualTo(outer),
          reason: 'an angle letter enters the ring on a ${size}dp wheel',
        );
      }
    });

    test('the wheel gives up exactly the lane and no more', () {
      const size = 340.0;
      final extent = extentFor(size);
      final outer = NatalChartWheelLayout.outerFor(size, extent);
      final layout = NatalChartWheelLayout(
        chart: warsaw,
        outer: outer,
        drawHouses: true,
        angleLabelExtent: extent,
      );
      // Whatever the letters cost, the rim plus the lane is the widget.
      expect(outer + layout.angleLabelLane, closeTo(size / 2 - 1, 1e-9));
      // And the cost is a lane, not a haircut: the wheel keeps most of itself.
      expect(outer, greaterThan(size / 2 * 0.82));
    });

    test('with no letters to place, the wheel keeps the whole square', () {
      // A chart without a reliable birth time draws no angles, so nothing is
      // reserved — but the Vessel asks for houses whenever it has them, and
      // the size must not depend on the chart, so the painter always reserves.
      // This pins the arithmetic of the empty case rather than the policy.
      expect(NatalChartWheelLayout.outerFor(340, 0), closeTo(169, 1e-9));
    });
  });

  test('every chart in a wide sweep of births lays out cleanly', () {
    // The five charts above were each chosen because something had gone wrong
    // on one like it. This is the other half of the argument: a few hundred
    // births across seventy years, every hour of the day, and latitudes from
    // the tropics to the edge of the Arctic circle — the range the product
    // actually has to draw.
    //
    // Pure arithmetic, so it costs nothing to be thorough. What it cannot see
    // is anything about ink; `test/manual/chart_wheel_specimen_test.dart`
    // draws the same range to look at.
    var checked = 0;
    for (final year in const [1948, 1962, 1975, 1988, 1999, 2010, 2021]) {
      for (final month in const [1, 4, 7, 10]) {
        for (final hour in const [0, 5, 11, 17, 22]) {
          for (final latitude in const [-33.9, -0.2, 40.7, 52.2, 64.1]) {
            final chart = chartFor(
              local: DateTime(year, month, 14, hour, 25),
              offsetMinutes: 60,
              latitude: latitude,
              longitude: 18.0,
            );
            final layout = NatalChartWheelLayout(
              chart: chart,
              outer: 146,
              drawHouses: chart.houseSystem == 'placidus',
            );
            final bodies = layout.bodies;
            final separation = layout.minLabelSeparation;

            for (final body in bodies) {
              // In the band, both edges clear.
              final inner = layout.labelRadius - layout.bodyGlyphSize / 2;
              final outerEdge = layout.labelRadius + layout.bodyGlyphSize / 2;
              expect(inner, greaterThan(layout.aspectRadius));
              expect(outerEdge, lessThan(layout.ringInner));
              // The bead still marks the true degree, whatever the glyph did.
              expect(body.longitude, isNot(isNaN));
              expect(body.labelLongitude, isNot(isNaN));
            }

            // No pair closer than a glyph, anywhere on the ring.
            for (var i = 0; i < bodies.length; i++) {
              for (var j = i + 1; j < bodies.length; j++) {
                final apart = NatalChartWheelLayout.forwardGap(
                  bodies[i].labelLongitude,
                  bodies[j].labelLongitude,
                );
                final gap = apart > 180 ? 360 - apart : apart;
                expect(
                  gap,
                  greaterThan(separation - 1e-6),
                  reason: '$year-$month ${hour}h at $latitude: '
                      '${bodies[i].name} and ${bodies[j].name} touch',
                );
              }
            }
            checked++;
          }
        }
      }
    }
    expect(checked, 700);
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

  test('the house band belongs to the houses alone', () {
    // The houses were illegible because they had no band of their own: the
    // cusps ran through the body glyphs, and the eight ordinary ones were
    // painted in the same weight as the sign ring's graduations. The band is
    // the fix, and it is only a fix while nothing else is in it.
    final layout = NatalChartWheelLayout(
      chart: warsaw,
      outer: 149,
      drawHouses: true,
    );

    expect(layout.aspectRadius, lessThan(layout.houseRing));
    expect(layout.houseRing, lessThan(layout.ringInner));

    // No body glyph may reach into the band. This is the collision that put a
    // cusp through Saturn on the Reykjavik specimen and through the Sun on the
    // chart that reported the fault.
    expect(
      layout.labelRadius - layout.bodyGlyphSize / 2,
      greaterThan(layout.houseRing),
      reason: 'a body glyph reaches into the house band',
    );

    // The numerals stay inside the band, both edges clear.
    expect(
      layout.houseNumberRadius - layout.houseNumberSize / 2,
      greaterThan(layout.aspectRadius),
    );
    expect(
      layout.houseNumberRadius + layout.houseNumberSize / 2,
      lessThan(layout.houseRing),
    );
  });

  test('every house is numbered, at the middle of the arc it occupies', () {
    // A division nobody can name is the unexplained symbol non-negotiable 7
    // forbids, so all twelve carry a numeral. The midpoint is of the house's
    // own arc rather than of a twelfth of the circle, because Placidus
    // quadrants are very uneven away from the equator.
    for (final latitude in const [0.0, 52.23, 64.15, -33.87]) {
      final chart = chartFor(
        local: DateTime(1988, 7, 7, 9, 12),
        offsetMinutes: 60,
        latitude: latitude,
        longitude: 18.0,
      );
      if (chart.houseSystem != 'placidus') continue;
      final layout = NatalChartWheelLayout(
        chart: chart,
        outer: 149,
        drawHouses: true,
      );
      final midpoints = layout.houseMidpoints;
      expect(midpoints, hasLength(12));

      for (var i = 0; i < 12; i++) {
        final cusp = chart.houseCusps[i];
        final next = chart.houseCusps[(i + 1) % 12];
        final span = NatalChartWheelLayout.forwardGap(cusp, next);
        // The numeral lies strictly inside its own house, never on a cusp.
        final into = NatalChartWheelLayout.forwardGap(cusp, midpoints[i]);
        expect(
          into,
          closeTo(span / 2, 1e-6),
          reason: 'house ${i + 1} at $latitude is numbered off its midpoint',
        );
        expect(into, greaterThan(0));
        expect(into, lessThan(span));
      }
    }
  });
}
