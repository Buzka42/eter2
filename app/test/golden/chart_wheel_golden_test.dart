import 'package:eter/core/symbolic/chart_wheel.dart';
import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:eter/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prototype_harness.dart';

/// The wheel with its houses drawn, which nothing else captures.
///
/// The Vessel's own goldens go through the prototype fixture, and that profile
/// has no birth time — so `ascendantReliable` is false there, no cusps are
/// drawn and neither angle is named. Every shell capture in the suite shows the
/// half of this surface that has no angles in it.
///
/// That is the gap the `ASC` fault lived in: the letters overlapped the sign
/// glyphs and ran past the widget's edge on every chart from somebody who had
/// given Eter their birth time, and not one golden drew them. These two
/// captures are the other half.
void main() {
  testWidgets('a chart with houses, in both skies', (tester) async {
    await loadEterFonts();
    // A real birth, and a crowded one: the Aquarius stellium puts eight bodies
    // in a third of the wheel and drives the Midheaven's letters into the
    // sign ring if anything about the lane is wrong.
    final chart = NatalChartEngine().calculate(NatalInput(
      localDateTime: DateTime(1962, 2, 5, 12, 0),
      utcOffsetMinutes: 0,
      latitude: 51.51,
      longitude: -0.13,
    ));
    expect(chart.houseSystem, 'placidus', reason: 'the houses must be drawn');

    for (final night in const [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: night ? EterTheme.night() : EterTheme.day(),
          home: ColoredBox(
            color: night ? const Color(0xFF0B1020) : const Color(0xFFF4F1EC),
            child: Center(
              child: RepaintBoundary(
                child: NatalChartWheel(chart: chart, size: 340),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(NatalChartWheel),
        matchesGoldenFile(
          'chart-wheel-houses-${night ? 'night' : 'day'}-340.png',
        ),
      );
    }
  });
}
