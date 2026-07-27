import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'controls.dart';
import 'tokens.dart';

/// Engraved instruments — the widgets that render live data.
///
/// These were the weakest surfaces in the app: the balance was a single
/// rotated 3px line with a Material `Icons.balance` between two text labels,
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
