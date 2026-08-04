import 'package:eter/core/i18n/strings.dart';
import 'package:eter/core/instruments.dart';
import 'package:eter/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prototype_harness.dart';

/// The Long View's own drawing, which no capture in the suite reaches.
///
/// The panel is fourteen taps of a bead down a sheet the shell's capture
/// harness does not drive, so the shape of it has never been photographed. That
/// matters most for the one rule in the painter that must not be "simplified":
/// **an unrecorded period is an open tick below the baseline, not a bar of no
/// height.** The two are a few pixels apart and mean opposite things — nothing
/// measured, against measured and zero — and only a picture shows the
/// difference.
///
/// Pages is the exception and draws a real zero: Eter knows for certain that
/// nothing was written. It has its own capture for that reason.
///
/// Two widths, because the History sheet widens as you turn back and the
/// crowded end is where labels collide.
void main() {
  Future<void> capture(
    WidgetTester tester, {
    required String name,
    required LongViewMeasure measure,
    required List<double?> values,
    required List<String> labels,
    required String Function(double) format,
    required bool night,
    required double width,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: night ? EterTheme.night() : EterTheme.day(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              // Bounded, so the capture is the drawing and not a screenful of
              // background around it. A golden mostly made of empty pixels
              // fails to notice the change that matters.
              height: 160,
              child: RepaintBoundary(
                child: EngravedLongView(
                  measure: measure,
                  values: values,
                  labels: labels,
                  format: format,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(EngravedLongView),
      matchesGoldenFile(name),
    );
  }

  setUp(loadEterFonts);

  testWidgets('a week with two nights nobody recorded', (tester) async {
    // The middle of the week is absent, not zero. Those two cells must read as
    // open ticks below the line while the others stand on it.
    for (final night in const [false, true]) {
      await capture(
        tester,
        name: 'long-view-week-${night ? 'night' : 'day'}-320.png',
        measure: LongViewMeasure.sleep,
        values: const [7.2, 6.4, null, null, 8.1, 7.7, 6.9],
        labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        format: (value) => '${value.toStringAsFixed(1)} h',
        night: night,
        width: 320,
      );
    }
  });

  testWidgets('a year, which is the crowded end of the axis', (tester) async {
    // Twelve cells at the narrow width is where labels run into each other,
    // and the axis stops at the date of birth so the early months of a first
    // year are genuinely empty rather than merely unrecorded.
    await capture(
      tester,
      name: 'long-view-year-day-320.png',
      measure: LongViewMeasure.steps,
      values: const [
        null, null, null, 6200, 7100, 8300,
        9100, 8800, 7400, 6900, 7200, 8100,
      ],
      labels: const [
        'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan',
        'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul',
      ],
      format: (value) => '${value.round()}',
      night: false,
      width: 320,
    );
  });

  testWidgets('the same year on a sheet that has widened', (tester) async {
    // The History sheet grows as you turn back. Nothing else in the suite
    // draws the Long View at the width it reaches.
    await capture(
      tester,
      name: 'long-view-year-day-600.png',
      measure: LongViewMeasure.steps,
      values: const [
        null, null, null, 6200, 7100, 8300,
        9100, 8800, 7400, 6900, 7200, 8100,
      ],
      labels: const [
        'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan',
        'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul',
      ],
      format: (value) => '${value.round()}',
      night: false,
      width: 600,
    );
  });

  testWidgets('pages, where a zero is a fact and draws nothing', (tester) async {
    // The one measure with a real zero. A week nobody wrote in once drew seven
    // one-pixel stubs a hair away from the open ticks that mean something
    // else; a zero draws nothing now, and this is the picture of it.
    await capture(
      tester,
      name: 'long-view-pages-day-320.png',
      measure: LongViewMeasure.pages,
      values: const [2, 0, 0, 1, 0, 3, 0],
      labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      format: (value) => '${value.round()}',
      night: false,
      width: 320,
    );
  });
}
