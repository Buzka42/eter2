import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'controls.dart';
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

    // Column and footed base.
    final baseY = size.height * 0.92;
    canvas.drawLine(
        Offset(g.pivot.dx, g.pivotY), Offset(g.pivot.dx, baseY), thin);
    final footWidth = size.width * 0.13;
    canvas.drawLine(Offset(g.pivot.dx - footWidth, baseY),
        Offset(g.pivot.dx + footWidth, baseY), thin);
    canvas.drawLine(Offset(g.pivot.dx - footWidth * 0.55, baseY - 7),
        Offset(g.pivot.dx - footWidth, baseY), thin);
    canvas.drawLine(Offset(g.pivot.dx + footWidth * 0.55, baseY - 7),
        Offset(g.pivot.dx + footWidth, baseY), thin);

    // The beam, and the pivot jewel it turns on.
    canvas.drawLine(g.leftEnd, g.rightEnd, strong);
    canvas.drawCircle(g.pivot, 4.5, thin);
    canvas.drawCircle(g.pivot, 1.6, Paint()..color = lineStrong);

    // Hangers and pans. The pan is an arc with a rim, not a filled shape.
    //
    // The pans hang plumb: the hanger drops vertically from the beam end and
    // the bowl stays level however far the beam tilts, because that is what
    // gravity does to a suspended pan. Rotating the pans with the beam — which
    // is what a naive transform gives you — is the single thing that makes a
    // drawn balance look like a diagram instead of an object.
    for (final end in [g.leftEnd, g.rightEnd]) {
      final pan = end + Offset(0, g.hangerLength);
      canvas.drawLine(end, Offset(pan.dx - g.panRadius * 0.8, pan.dy), thin);
      canvas.drawLine(end, Offset(pan.dx + g.panRadius * 0.8, pan.dy), thin);
      final rect = Rect.fromCenter(
        center: pan,
        width: g.panRadius * 2,
        height: g.panRadius * 0.9,
      );
      canvas.drawArc(rect, 0, math.pi, false, strong);
      canvas.drawLine(Offset(pan.dx - g.panRadius, pan.dy),
          Offset(pan.dx + g.panRadius, pan.dy), strong);
    }

    // A level mark above the pivot: the eye needs a reference to read tilt
    // against, or a tilted beam just looks like a crooked line.
    final markTop = g.pivotY - size.height * 0.11;
    canvas.drawLine(
        Offset(g.pivot.dx, markTop), Offset(g.pivot.dx, markTop + 8), thin);
    for (final direction in [-1, 1]) {
      final angle = -math.pi / 2 + direction * 0.42;
      final radius = size.height * 0.10;
      canvas.drawCircle(
        g.pivot + Offset(radius * math.cos(angle), radius * math.sin(angle)),
        1.1,
        Paint()..color = line,
      );
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
  });

  final double tiltDegrees;
  final double intake;
  final double burn;
  final TextTheme style;

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
            figure(g.leftPan, 'Eaten', intake),
            figure(g.rightPan, 'Burned', burn),
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
    return Semantics(
      container: true,
      label: '$label, ${values.length} readings. Latest '
          '${_figure(latest)} $unit. Range ${_figure(low)} to '
          '${_figure(high)} $unit.',
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
                  '${values.length} DAYS',
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
    final summary = minutesByStage.entries
        .map((entry) => '${entry.key} ${entry.value} minutes')
        .join(', ');
    return Semantics(
      container: true,
      label: 'Sleep stages. $summary.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 30,
              child: Row(
                children: [
                  for (final entry in minutesByStage.entries)
                    Expanded(
                      flex: entry.value,
                      child: Container(
                        height: entry.key == 'awake' ? 6 : 1.5,
                        color: entry.key == 'deep' ? ink.lineStrong : ink.line,
                      ),
                    ),
                ],
              ),
            ),
            Wrap(
              spacing: EterSpace.s16,
              children: [
                for (final entry in minutesByStage.entries)
                  Text(
                    '${entry.key.toUpperCase()} ${entry.value}m',
                    style: text.labelSmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
    final totals = [
      for (final night in nights)
        night.values.fold<int>(0, (sum, minutes) => sum + minutes),
    ];
    final average = totals.fold<int>(0, (a, b) => a + b) / totals.length;
    final summary = nights.indexed.map((entry) {
      final stages = entry.$2.entries
          .map((stage) => '${stage.key} ${stage.value} minutes')
          .join(', ');
      return 'Night ${entry.$1 + 1}: $stages';
    }).join('. ');
    return Semantics(
      container: true,
      label: '$windowDays day sleep history, ${nights.length} nights. '
          'Average ${(average / 60).toStringAsFixed(1)} hours. $summary.',
      child: ExcludeSemantics(
        child: SizedBox(
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
                '${(average / 60).toStringAsFixed(1)} h AVG',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
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
          .map((night) => night.values.fold<int>(0, (a, b) => a + b))
          .reduce(math.max),
    );
    final axis = Paint()
      ..color = line
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), axis);
    final slot = size.width / nights.length;
    final barWidth = math.min(12.0, slot * .42);
    const order = ['awake', 'rem', 'light', 'deep', 'unknown'];
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
    final total = kcalByHour.fold<double>(0, (a, b) => a + b);
    final active = [
      for (var hour = 0; hour < 24; hour++)
        if (kcalByHour[hour] > 0)
          '${hour.toString().padLeft(2, '0')}:00 '
              '${kcalByHour[hour].round()} kilocalories',
    ].join(', ');
    return Semantics(
      container: true,
      label: 'Activity by time of day. Total ${total.round()} '
          'kilocalories. $active.',
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
