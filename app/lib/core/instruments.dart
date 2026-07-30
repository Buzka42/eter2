import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'controls.dart';
import 'i18n/strings.dart';
import 'tokens.dart';

/// Engraved instruments — the widgets that render live data.
///
/// These were the weakest surfaces in the app: the balance was a single
/// rotated 3px line with a bespoke fulcrum between two text labels,
/// and the progress rings were 6px strokes with a sky-to-gold sweep. In both
/// cases the illustrated *empty state* sitting directly beneath was more
/// carefully drawn than the live widget above it. They are redrawn here as
/// fine line-work, to the standard of the commissioned engravings.

/// A beam balance: column, pivot, tilting beam, two pans on hangers.
/// The tilt is the datum — intake against expenditure.
class EngravedBalance extends StatelessWidget {
  const EngravedBalance({
    super.key,
    required this.intake,
    required this.burn,
    required this.tilt,
    this.height = 190,
  });

  final double intake;
  final double burn;

  /// Degrees, negative tips toward burn, positive toward intake.
  final double tilt;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    // A real beam does not ease into place and stop dead — it overshoots and
    // rings down. The elastic curve is what separates an instrument from a
    // diagram, and it costs one line.
    final settle = MediaQuery.disableAnimationsOf(context)
        ? Curves.linear
        : Curves.elasticOut;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: tilt),
      duration: MediaQuery.disableAnimationsOf(context)
          ? EterMotion.durMicro
          : const Duration(milliseconds: 1400),
      curve: settle,
      builder: (context, value, _) => SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BalancePainter(
                  tiltDegrees: value,
                  line: ink.line,
                  lineStrong: ink.lineStrong,
                ),
              ),
            ),
            // Figures ride the pans, so the numbers themselves are what the
            // beam is weighing rather than a caption underneath it.
            Positioned.fill(
              child: _PanLabels(
                tiltDegrees: value,
                intake: intake,
                burn: burn,
                style: text,
                strings: EterStrings.of(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Geometry shared by the painter and the labels so the figures sit exactly on
/// the pans as the beam tilts.
class _BalanceGeometry {
  _BalanceGeometry(this.size, double tiltDegrees)
      : radians = tiltDegrees * math.pi / 180;

  final Size size;
  final double radians;

  double get pivotY => size.height * 0.22;
  double get halfBeam => size.width * 0.34;
  Offset get pivot => Offset(size.width / 2, pivotY);

  // A positive tilt means the left pan is the heavier one, so the left end
  // travels *down*. Deriving both ends from +sin on the left was drawing every
  // balance upside down: the pan holding the larger figure rose.
  Offset get leftEnd => Offset(
        pivot.dx - halfBeam * math.cos(radians),
        pivot.dy + halfBeam * math.sin(radians),
      );
  Offset get rightEnd => Offset(
        pivot.dx + halfBeam * math.cos(radians),
        pivot.dy - halfBeam * math.sin(radians),
      );

  double get hangerLength => size.height * 0.30;
  Offset get leftPan => leftEnd + Offset(0, hangerLength);
  Offset get rightPan => rightEnd + Offset(0, hangerLength);
  double get panRadius => size.width * 0.13;
}

class _BalancePainter extends CustomPainter {
  _BalancePainter({
    required this.tiltDegrees,
    required this.line,
    required this.lineStrong,
  });

  final double tiltDegrees;
  final Color line;
  final Color lineStrong;

  @override
  void paint(Canvas canvas, Size size) {
    final g = _BalanceGeometry(size, tiltDegrees);
    final thin = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final strong = Paint()
      ..color = lineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final faint = Paint()
      ..color = line.withValues(alpha: line.a * 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;

    // --- The pillar: a tapered column on a stepped plinth, not a stick on a
    // triangle. The taper is two lines that meet the cap moulding; the plinth
    // is three narrowing courses. This is where most of the object's weight
    // comes from, and it costs nothing at any size.
    final baseY = size.height * 0.92;
    final capY = g.pivotY + 6;
    final halfCap = size.width * 0.011;
    final halfFoot = size.width * 0.022;
    canvas.drawLine(
      Offset(g.pivot.dx - halfCap, capY),
      Offset(g.pivot.dx - halfFoot, baseY - 10),
      thin,
    );
    canvas.drawLine(
      Offset(g.pivot.dx + halfCap, capY),
      Offset(g.pivot.dx + halfFoot, baseY - 10),
      thin,
    );
    canvas.drawLine(
      Offset(g.pivot.dx - halfCap * 1.6, capY),
      Offset(g.pivot.dx + halfCap * 1.6, capY),
      thin,
    );
    for (final (index, course) in [(0, 0.62), (1, 0.82), (2, 1.0)].indexed) {
      final width = size.width * 0.070 * course.$2;
      final y = baseY - 10 + index * 5;
      canvas.drawLine(
        Offset(g.pivot.dx - width, y),
        Offset(g.pivot.dx + width, y),
        index == 2 ? strong : thin,
      );
    }

    // --- The graduated scale, and the pointer that reads against it. Both sit
    // *below* the pivot, in front of the column, where a beam balance actually
    // carries them — above the pivot the arc had nothing to hang on and ran
    // straight out of the frame.
    final arcRadius = size.height * 0.235;
    final arcRect = Rect.fromCircle(center: g.pivot, radius: arcRadius);
    canvas.drawArc(arcRect, math.pi * 0.36, math.pi * 0.28, false, faint);
    for (var i = -3; i <= 3; i++) {
      final angle = math.pi / 2 + i * 0.075;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final long = i == 0;
      canvas.drawLine(
        g.pivot + direction * arcRadius,
        g.pivot + direction * (arcRadius + (long ? 6 : 3)),
        long ? thin : faint,
      );
    }

    // The pointer swings with the beam: a level beam reads dead centre.
    final needle = math.pi / 2 - g.radians;
    canvas.drawLine(
      g.pivot,
      g.pivot + Offset(math.cos(needle), math.sin(needle)) * (arcRadius - 3),
      thin,
    );

    // --- The beam: a tapered bar with an eye at each end, and the pivot jewel
    // it turns on.
    canvas.drawLine(g.leftEnd, g.rightEnd, strong);
    for (final end in [g.leftEnd, g.rightEnd]) {
      canvas.drawCircle(end, 2.2, thin);
    }
    canvas.drawCircle(g.pivot, 5.5, thin);
    canvas.drawCircle(g.pivot, 3.2, faint);
    canvas.drawCircle(g.pivot, 1.6, Paint()..color = lineStrong);

    // --- Chains and pans.
    //
    // The pans hang plumb: the chain drops vertically from the beam end and
    // the bowl stays level however far the beam tilts, because that is what
    // gravity does to a suspended pan. Rotating the pans with the beam — which
    // is what a naive transform gives you — is the single thing that makes a
    // drawn balance look like a diagram instead of an object.
    for (final end in [g.leftEnd, g.rightEnd]) {
      final pan = end + Offset(0, g.hangerLength);
      for (final side in [-1.0, 1.0]) {
        final foot = Offset(pan.dx + g.panRadius * 0.8 * side, pan.dy);
        canvas.drawLine(end, foot, faint);
        // Three links, struck along the run: enough to read as chain.
        for (final t in [0.32, 0.55, 0.78]) {
          final at = Offset.lerp(end, foot, t)!;
          canvas.drawCircle(at, 1.1, faint);
        }
      }
      // A bowl with depth: rim, body, and a second arc for thickness.
      final rim = Rect.fromCenter(
        center: pan,
        width: g.panRadius * 2,
        height: g.panRadius * 0.55,
      );
      final body = Rect.fromCenter(
        center: pan,
        width: g.panRadius * 2,
        height: g.panRadius * 1.15,
      );
      canvas.drawArc(body, 0, math.pi, false, strong);
      canvas.drawArc(
        body.deflate(2.5),
        0.25,
        math.pi - 0.5,
        false,
        faint,
      );
      canvas.drawArc(rim, 0, math.pi, false, faint);
      canvas.drawLine(Offset(pan.dx - g.panRadius, pan.dy),
          Offset(pan.dx + g.panRadius, pan.dy), strong);
    }
  }

  @override
  bool shouldRepaint(_BalancePainter old) =>
      old.tiltDegrees != tiltDegrees ||
      old.line != line ||
      old.lineStrong != lineStrong;
}

class _PanLabels extends StatelessWidget {
  const _PanLabels({
    required this.tiltDegrees,
    required this.intake,
    required this.burn,
    required this.style,
    required this.strings,
  });

  final double tiltDegrees;
  final double intake;
  final double burn;
  final TextTheme style;
  final EterStrings strings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final g = _BalanceGeometry(constraints.biggest, tiltDegrees);
        // Clear of the pan bowl, which hangs half a pan-radius below the rim —
        // at a flat +6 the figures were struck through by their own pan.
        Widget figure(Offset pan, String label, double value) => Positioned(
              left: pan.dx - g.panRadius,
              top: pan.dy + g.panRadius * 0.5 + 10,
              width: g.panRadius * 2,
              child: Column(
                children: [
                  Text('${value.round()}',
                      style: style.titleMedium, textAlign: TextAlign.center),
                  Text(label.toUpperCase(),
                      style: style.labelSmall, textAlign: TextAlign.center),
                ],
              ),
            );
        return Stack(
          children: [
            figure(g.leftPan, strings.balanceEaten, intake),
            figure(g.rightPan, strings.balanceBurned, burn),
          ],
        );
      },
    );
  }
}

/// A restrained historical line instrument. The graphic is decorative; the
/// complete first/latest/range summary is exposed as one semantic sentence.
class EngravedTrend extends StatelessWidget {
  const EngravedTrend({
    super.key,
    required this.values,
    required this.label,
    required this.unit,
    this.height = 120,
  });

  final List<double> values;
  final String label;
  final String unit;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final latest = values.last;
    final strings = EterStrings.of(context);
    return Semantics(
      container: true,
      label: strings.trendSemantic(
        label: label,
        readings: values.length,
        latest: _figure(latest),
        unit: unit,
        low: _figure(low),
        high: _figure(high),
      ),
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrendPainter(
                    values: values,
                    line: ink.line,
                    lineStrong: ink.lineStrong,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Text(
                  '${_figure(latest)} $unit',
                  style: text.labelSmall,
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: Text(
                  strings.trendDayCount(values.length),
                  style: text.labelSmall?.copyWith(color: ink.labelMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _figure(double value) =>
      value % 1 == 0 ? value.round().toString() : value.toStringAsFixed(1);
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.line,
    required this.lineStrong,
  });

  final List<double> values;
  final Color line;
  final Color lineStrong;

  @override
  void paint(Canvas canvas, Size size) {
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final span = math.max(1.0, high - low);
    const top = 25.0;
    final bottom = size.height - 25;
    final plotHeight = bottom - top;
    final faint = Paint()
      ..color = line
      ..strokeWidth = 1;
    final strong = Paint()
      ..color = lineStrong
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), faint);
    for (var i = 0; i < 5; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, bottom - 3), Offset(x, bottom + 3), faint);
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final y = bottom - ((values[i] - low) / span) * plotHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, strong);
    final lastY = bottom - ((values.last - low) / span) * plotHeight;
    canvas.drawCircle(
      Offset(size.width, lastY),
      2.5,
      Paint()..color = lineStrong,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.line != line || old.lineStrong != lineStrong;
}

/// A single night's stage proportions, drawn as one measured rail rather than
/// a colourful stacked dashboard bar.
class EngravedSleepStages extends StatelessWidget {
  const EngravedSleepStages({super.key, required this.minutesByStage});

  final Map<String, int> minutesByStage;

  @override
  Widget build(BuildContext context) {
    final total = minutesByStage.values.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return const SizedBox.shrink();
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
    final summary = minutesByStage.entries
        .map((entry) => strings.sleepStageSemanticEntry(entry.key, entry.value))
        .join(', ');
    return Semantics(
      container: true,
      label: strings.sleepStagesSemantic(summary),
      // The rail carries the proportions; the legend beneath carries the
      // values, and each legend entry is struck in its own stage's weight so
      // the two read as one instrument. Positional alignment was tried first
      // and cannot work: a ratio as small as awake-against-a-whole-night gives
      // a column too narrow to hold the word AWAKE.
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (final entry in minutesByStage.entries)
                    Expanded(
                      flex: entry.value,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Container(
                          height: _stageWeight(entry.key),
                          color: entry.key == 'deep' ? ink.lineStrong : ink.line,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: EterSpace.s8),
            Wrap(
              spacing: EterSpace.s16,
              runSpacing: EterSpace.s4,
              children: [
                for (final entry in minutesByStage.entries)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: _stageWeight(entry.key),
                        color: entry.key == 'deep' ? ink.lineStrong : ink.line,
                      ),
                      const SizedBox(width: EterSpace.s8),
                      Text(
                        strings.sleepStageMinutes(entry.key, entry.value),
                        style: text.labelSmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Awake is drawn heavier than sleep: it is the interruption, and the eye
  /// should find it without a colour.
  static double _stageWeight(String stage) => stage == 'awake' ? 5 : 1.5;
}

/// Several nights of stage totals. Each night is a narrow measured column,
/// preserving the stage composition without importing a dashboard chart
/// language. Unknown sleep remains a visible stage rather than being divided
/// into invented light/deep/REM values.
class EngravedSleepHistory extends StatelessWidget {
  const EngravedSleepHistory({
    super.key,
    required this.nights,
    required this.windowDays,
  });

  final List<Map<String, int>> nights;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    if (nights.isEmpty) return const SizedBox.shrink();
    final ink = EterInk.of(context);
    // Asleep, not in bed: the average and the bars both exclude the awake
    // minutes, so the figure here agrees with the watch that produced it.
    final totals = [
      for (final night in nights)
        night.entries
            .where((stage) => stage.key != 'awake')
            .fold<int>(0, (sum, stage) => sum + stage.value),
    ];
    final strings = EterStrings.of(context);
    final average = totals.fold<int>(0, (a, b) => a + b) / totals.length;
    final summary = nights.indexed.map((entry) {
      final stages = entry.$2.entries
          .map((stage) =>
              strings.sleepStageSemanticEntry(stage.key, stage.value))
          .join(', ');
      return strings.sleepNightSemantic(entry.$1 + 1, stages);
    }).join('. ');
    return Semantics(
      container: true,
      label: strings.sleepHistorySemantic(
        windowDays: windowDays,
        nights: nights.length,
        averageHours: (average / 60).toStringAsFixed(1),
        nightSummary: summary,
      ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        SizedBox(
          height: 132,
          child: CustomPaint(
            painter: _SleepHistoryPainter(
              nights: nights,
              line: ink.line,
              strong: ink.lineStrong,
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                strings.averageHoursMark((average / 60).toStringAsFixed(1)),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ),
            const SizedBox(height: EterSpace.s8),
            // A key for the bars.
            //
            // The stacked segments were unlabelled, so the only way to know
            // which band was deep sleep was to already know. It reads bottom
            // upward, in the order the painter stacks them, and carries no
            // numbers: the values belong to the night above, not to a
            // seven-night chart.
            Wrap(
              spacing: EterSpace.s12,
              runSpacing: EterSpace.s4,
              children: [
                for (final stage in const ['deep', 'light', 'rem'])
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 6,
                        color: switch (stage) {
                          'deep' => ink.lineStrong,
                          'rem' => ink.lineStrong.withValues(alpha: .65),
                          _ => ink.line,
                        },
                      ),
                      const SizedBox(width: EterSpace.s4),
                      Text(
                        strings.sleepStageName(stage),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepHistoryPainter extends CustomPainter {
  const _SleepHistoryPainter({
    required this.nights,
    required this.line,
    required this.strong,
  });

  final List<Map<String, int>> nights;
  final Color line;
  final Color strong;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 26.0;
    final bottom = size.height - 18;
    final height = bottom - top;
    final maxMinutes = math.max(
      480,
      nights
          .map(
            (night) => night.entries
                .where((stage) => stage.key != 'awake')
                .fold<int>(0, (a, b) => a + b.value),
          )
          .reduce(math.max),
    );
    final axis = Paint()
      ..color = line
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), axis);
    final slot = size.width / nights.length;
    final barWidth = math.min(12.0, slot * .42);
    // Awake is not drawn: a bar whose height is slept time cannot also stack
    // a band that is not slept time.
    const order = ['rem', 'light', 'deep', 'unknown'];
    for (var i = 0; i < nights.length; i++) {
      var y = bottom;
      for (final stage in order) {
        final minutes = nights[i][stage] ?? 0;
        if (minutes == 0) continue;
        final segment = height * minutes / maxMinutes;
        final paint = Paint()
          ..color = switch (stage) {
            'deep' => strong,
            'rem' => strong.withValues(alpha: .65),
            'unknown' => line.withValues(alpha: .45),
            _ => line,
          };
        canvas.drawRect(
          Rect.fromLTWH(
            slot * i + (slot - barWidth) / 2,
            y - segment,
            barWidth,
            math.max(1, segment - 1),
          ),
          paint,
        );
        y -= segment;
      }
    }
  }

  @override
  bool shouldRepaint(_SleepHistoryPainter old) =>
      old.nights != nights || old.line != line || old.strong != strong;
}

/// Active energy by local hour. The complete 24-value sequence is exposed to
/// assistive technology; the bars are only its engraved visual equivalent.
class EngravedActivityDay extends StatelessWidget {
  const EngravedActivityDay({super.key, required this.kcalByHour});

  final List<double> kcalByHour;

  @override
  Widget build(BuildContext context) {
    if (kcalByHour.length != 24) return const SizedBox.shrink();
    final ink = EterInk.of(context);
    final strings = EterStrings.of(context);
    final total = kcalByHour.fold<double>(0, (a, b) => a + b);
    final active = [
      for (var hour = 0; hour < 24; hour++)
        if (kcalByHour[hour] > 0)
          strings.activityHourSemantic(
            clock: '${hour.toString().padLeft(2, '0')}:00',
            kcal: kcalByHour[hour].round(),
          ),
    ].join(', ');
    return Semantics(
      container: true,
      label: strings.activityDaySemantic(
        totalKilocalories: '${total.round()}',
        detail: active,
      ),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 112,
          child: CustomPaint(
            painter: _ActivityDayPainter(
              values: kcalByHour,
              line: ink.line,
              strong: ink.lineStrong,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final label in const ['00', '06', '12', '18', '24'])
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityDayPainter extends CustomPainter {
  const _ActivityDayPainter({
    required this.values,
    required this.line,
    required this.strong,
  });
  final List<double> values;
  final Color line;
  final Color strong;

  @override
  void paint(Canvas canvas, Size size) {
    final bottom = size.height - 22;
    const top = 8.0;
    final maxValue = math.max(1.0, values.reduce(math.max));
    final slot = size.width / values.length;
    final axis = Paint()
      ..color = line
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), axis);
    for (var i = 0; i < values.length; i++) {
      final barHeight = (bottom - top) * values[i] / maxValue;
      canvas.drawLine(
        Offset(slot * (i + .5), bottom),
        Offset(slot * (i + .5), bottom - barHeight),
        Paint()
          ..color = values[i] == maxValue ? strong : line
          ..strokeWidth = math.max(1.4, slot * .32),
      );
    }
  }

  @override
  bool shouldRepaint(_ActivityDayPainter old) =>
      old.values != values || old.line != line || old.strong != strong;
}

/// One measure across a Long View window, drawn on the same axis as every other
/// instrument here: a hairline baseline, one mark per period, nothing filled.
///
/// The rule this widget exists to keep is that **a period nobody recorded is
/// absent, not zero**. A bar of height zero and a bar that was never measured
/// look identical, and on a year axis that difference is the whole reading —
/// eleven recorded months beside one empty one, drawn as twelve bars, invents a
/// collapse that did not happen. An unrecorded period is therefore drawn as an
/// open tick *below* the baseline: present on the axis, visibly not a value.
///
/// [values] is one entry per cell, null where nothing was recorded. [labels] is
/// the same length and carries what the axis calls each cell; only the first,
/// middle and last are drawn, because twelve month names do not fit at 320 dp.
class EngravedLongView extends StatelessWidget {
  const EngravedLongView({
    super.key,
    required this.measure,
    required this.values,
    required this.labels,
    required this.format,
    this.height = 108,
  });

  final LongViewMeasure measure;
  final List<double?> values;
  final List<String> labels;

  /// How a value is said, in the caller's units. Passed in rather than switched
  /// on [measure], because hours, a 0–10 mood and a step count round nothing
  /// like each other and the surface already knows which it asked for.
  final String Function(double) format;

  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || values.length != labels.length) {
      return const SizedBox.shrink();
    }
    final ink = EterInk.of(context);
    final strings = EterStrings.of(context);
    final text = Theme.of(context).textTheme;
    final name = strings.longViewMeasure(measure);

    final spoken = <String>[];
    var absent = 0;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) {
        absent++;
        continue;
      }
      spoken.add(
        strings.longViewCellSemantic(label: labels[i], value: format(value)),
      );
    }

    return Semantics(
      container: true,
      label: strings.longViewSeriesSemantic(
        measure: name,
        cells: spoken.join(', '),
        absent: absent,
      ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: text.labelSmall),
            const SizedBox(height: EterSpace.s4),
            SizedBox(
              height: height,
              child: CustomPaint(
                painter: _LongViewPainter(
                  values: values,
                  line: ink.line,
                  strong: ink.lineStrong,
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final index in _axisLabelIndices(labels.length))
                        Text(labels[index], style: text.labelSmall),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// First, middle and last. Three is what fits at 320 dp with 200% text, and
  /// the middle one is what stops a twelve-month axis reading as seven days.
  static List<int> _axisLabelIndices(int count) {
    if (count <= 1) return const [0];
    if (count == 2) return const [0, 1];
    return [0, count ~/ 2, count - 1];
  }
}

class _LongViewPainter extends CustomPainter {
  const _LongViewPainter({
    required this.values,
    required this.line,
    required this.strong,
  });

  final List<double?> values;
  final Color line;
  final Color strong;

  @override
  void paint(Canvas canvas, Size size) {
    final bottom = size.height - 22;
    const top = 6.0;
    final recorded = [
      for (final value in values)
        if (value != null) value,
    ];
    if (recorded.isEmpty) {
      // The baseline still gets drawn. A window with nothing in it is a period
      // of time that happened, and erasing the axis would deny that.
      canvas.drawLine(
        Offset(0, bottom),
        Offset(size.width, bottom),
        Paint()
          ..color = line
          ..strokeWidth = 1,
      );
      return;
    }
    final peak = recorded.reduce(math.max);
    // A flat series still has to be drawn at some height, and drawing it at the
    // top would say "peak" about a week where nothing moved.
    final scale = peak <= 0 ? 1.0 : peak;
    final slot = size.width / values.length;
    final stroke = math.max(1.4, math.min(12.0, slot * .34));

    canvas.drawLine(
      Offset(0, bottom),
      Offset(size.width, bottom),
      Paint()
        ..color = line
        ..strokeWidth = 1,
    );

    for (var i = 0; i < values.length; i++) {
      final x = slot * (i + .5);
      final value = values[i];
      if (value == null) {
        // Absent: a short open tick under the axis. Below it, so it can never
        // be misread as a small value above it.
        canvas.drawLine(
          Offset(x, bottom + 2),
          Offset(x, bottom + 6),
          Paint()
            ..color = line
            ..strokeWidth = 1,
        );
        continue;
      }
      final barHeight = (bottom - top) * (value / scale);
      canvas.drawLine(
        Offset(x, bottom),
        Offset(x, bottom - math.max(1, barHeight)),
        Paint()
          ..color = value == peak ? strong : line
          ..strokeWidth = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_LongViewPainter old) =>
      !listEquals(old.values, values) ||
      old.line != line ||
      old.strong != strong;
}
