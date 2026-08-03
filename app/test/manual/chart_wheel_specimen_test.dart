import 'dart:io';
import 'dart:ui' as ui;

import 'package:eter/core/symbolic/chart_wheel.dart';
import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:eter/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prototype_harness.dart';

/// Draws the wheel for a spread of real births and writes them out to look at.
///
/// A specimen sheet, not an assertion: the wheel's faults have all been
/// geometric and none of them were visible in a reading of the paint calls.
/// Every chart it draws is arithmetically fine; what goes wrong is where
/// things land.
///
/// Run it, then open the directory:
///
///   flutter test test/manual/chart_wheel_specimen_test.dart \
///     --dart-define=ETER_WHEEL_SPECIMEN=/tmp/wheels
///
/// Skipped by default because it writes files and proves nothing on its own.
/// The assertions that *do* hold the wheel honest are in
/// `test/chart_wheel_test.dart`.
const _outputDirectory = String.fromEnvironment('ETER_WHEEL_SPECIMEN');

/// The births. Chosen so each one puts the geometry under a different strain
/// rather than to be representative of anybody.
const specimens = <({
  String name,
  int year,
  int month,
  int day,
  int hour,
  int minute,
  int offsetMinutes,
  double latitude,
  double longitude,
})>[
  // The owner's own reported chart.
  (
    name: 'reported-1993-07-25',
    year: 1993, month: 7, day: 25, hour: 12, minute: 30,
    offsetMinutes: 120, latitude: 52.2297, longitude: 21.0122,
  ),
  // Uranus within a degree of Neptune — the crowding that broke the labels
  // once already. Everyone born in the early nineties has it.
  (
    name: '1991-conjunction-warsaw',
    year: 1991, month: 2, day: 14, hour: 3, minute: 20,
    offsetMinutes: 60, latitude: 52.23, longitude: 21.01,
  ),
  // Four bodies inside a few degrees.
  (
    name: '1962-stellium-aquarius',
    year: 1962, month: 2, day: 5, hour: 12, minute: 0,
    offsetMinutes: 0, latitude: 51.51, longitude: -0.13,
  ),
  // Inside the Arctic circle: Placidus has no answer, so equal houses and no
  // house structure drawn.
  (
    name: '1980-tromso-polar',
    year: 1980, month: 6, day: 21, hour: 0, minute: 30,
    offsetMinutes: 120, latitude: 69.65, longitude: 18.96,
  ),
  // Southern hemisphere, where the semi-arcs change sign.
  (
    name: '1975-sydney-south',
    year: 1975, month: 11, day: 3, hour: 18, minute: 45,
    offsetMinutes: 660, latitude: -33.87, longitude: 151.21,
  ),
  // On the equator: tan(phi) is zero and every semi-arc is ninety degrees.
  (
    name: '2001-quito-equator',
    year: 2001, month: 9, day: 9, hour: 6, minute: 15,
    offsetMinutes: -300, latitude: -0.18, longitude: -78.47,
  ),
  // High but not polar — Placidus is defined and the quadrants are very
  // uneven, which is where cusps crowd.
  (
    name: '1968-reykjavik-high',
    year: 1968, month: 12, day: 22, hour: 9, minute: 5,
    offsetMinutes: 0, latitude: 64.15, longitude: -21.94,
  ),
  // The same day and place at four hours, so the whole wheel rotates and the
  // angles sweep every quadrant.
  (
    name: '1988-midnight',
    year: 1988, month: 7, day: 7, hour: 0, minute: 0,
    offsetMinutes: 120, latitude: 50.06, longitude: 19.94,
  ),
  (
    name: '1988-dawn',
    year: 1988, month: 7, day: 7, hour: 6, minute: 0,
    offsetMinutes: 120, latitude: 50.06, longitude: 19.94,
  ),
  (
    name: '1988-noon',
    year: 1988, month: 7, day: 7, hour: 12, minute: 0,
    offsetMinutes: 120, latitude: 50.06, longitude: 19.94,
  ),
  (
    name: '1988-dusk',
    year: 1988, month: 7, day: 7, hour: 18, minute: 0,
    offsetMinutes: 120, latitude: 50.06, longitude: 19.94,
  ),
  // Recent, and old enough to be outside the ephemeris' comfortable middle.
  (
    name: '2010-modern',
    year: 2010, month: 3, day: 30, hour: 21, minute: 40,
    offsetMinutes: 120, latitude: 52.23, longitude: 21.01,
  ),
  (
    name: '1948-old',
    year: 1948, month: 1, day: 18, hour: 4, minute: 55,
    offsetMinutes: 60, latitude: 48.86, longitude: 2.35,
  ),
];

NatalChart chartFor(dynamic specimen) => NatalChartEngine().calculate(
      NatalInput(
        localDateTime: DateTime(
          specimen.year as int,
          specimen.month as int,
          specimen.day as int,
          specimen.hour as int,
          specimen.minute as int,
        ),
        utcOffsetMinutes: specimen.offsetMinutes as int,
        latitude: specimen.latitude as double,
        longitude: specimen.longitude as double,
      ),
    );

void main() {
  testWidgets('writes a wheel per specimen, day and night', (tester) async {
    await loadEterFonts();
    final directory = Directory(_outputDirectory)..createSync(recursive: true);

    for (final specimen in specimens) {
      final chart = chartFor(specimen);
      for (final night in const [false, true]) {
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: night ? EterTheme.night() : EterTheme.day(),
            home: Scaffold(
              backgroundColor: night
                  ? const Color(0xFF0B1020)
                  : const Color(0xFFF4F1EC),
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  // The ground has to be *inside* the boundary. Outside it the
                  // capture is transparent behind the wheel, and night's
                  // backdrop disc then reads as a grey blob on white — a fault
                  // in the sheet rather than in the wheel.
                  child: ColoredBox(
                    color: night
                        ? const Color(0xFF0B1020)
                        : const Color(0xFFF4F1EC),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: NatalChartWheel(
                        chart: chart,
                        size: 340,
                        ascendantReliable: chart.houseSystem == 'placidus',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final sky = night ? 'night' : 'day';
          File('${directory.path}/${specimen.name}-$sky.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
        });
      }
    }
  },
      skip: _outputDirectory.isEmpty);
}
