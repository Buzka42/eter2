import 'package:flutter/material.dart';

import 'controls.dart';

/// Eter's quiet "there is depth beyond this line" mark.
///
/// A bead on a continuing thread belongs to the same engraved language as
/// the instruments and header. The parent control owns semantics; this mark
/// is decorative.
class EterDisclosureMark extends StatelessWidget {
  const EterDisclosureMark({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _DisclosurePainter(EterInk.of(context).labelMuted),
          ),
        ),
      );
}

class _DisclosurePainter extends CustomPainter {
  const _DisclosurePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 18;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(Offset(2.75 * scale, center.dy), 1.1 * scale, paint);
    canvas.drawLine(
      Offset(4.1 * scale, center.dy),
      Offset(14 * scale, center.dy),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(10 * scale, 5 * scale)
        ..lineTo(14 * scale, center.dy)
        ..lineTo(10 * scale, 13 * scale),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DisclosurePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The dictation mark: a struck capsule on a stem, over a listening arc.
///
/// Drawn rather than imported. Material's `mic` is the most recognisable glyph
/// in the tray and would be the only Material icon left on a production
/// surface; this keeps the one gesture that needs a symbol inside the same
/// engraved language as everything else.
///
/// [active] fills the head, which is the whole state change — no colour shift,
/// no pulse, no ring. The parent control owns semantics.
class EterMicMark extends StatelessWidget {
  const EterMicMark({super.key, this.size = 16, this.active = false, this.color});

  final double size;
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _MicPainter(
              color ?? EterInk.of(context).labelMuted,
              active: active,
            ),
          ),
        ),
      );
}

class _MicPainter extends CustomPainter {
  const _MicPainter(this.color, {required this.active});

  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    // A voice mark, not a microphone.
    //
    // The literal capsule-and-arc drawn here before was the one glyph in the
    // app borrowed from everyone else's toolbar: correct, legible, and from a
    // different product. This is the same idea in the shell's own language —
    // the plumb line of the colophon, with the graduated arcs of the header
    // engraving opening from it. Sound leaving a still point.
    final scale = size.shortestSide / 16;
    final centreX = size.width / 2;
    final centreY = size.height / 2;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * scale
      ..strokeCap = StrokeCap.round;

    // The stem: a plumb line, the same device the colophon uses.
    canvas.drawLine(
      Offset(centreX, centreY - 5.4 * scale),
      Offset(centreX, centreY + 5.4 * scale),
      stroke,
    );

    // The still point it hangs from. Filled while listening, so the state
    // reads at a glance without the glyph changing shape.
    canvas.drawCircle(
      Offset(centreX, centreY - 5.4 * scale),
      1.5 * scale,
      active
          ? (Paint()..color = color)
          : (Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1 * scale),
    );

    // Three graduated arcs to each side, widening outward. While listening
    // they are all present; at rest the outermost fades, so the mark is
    // quieter until it is doing something.
    const arcCount = 3;
    for (var i = 1; i <= arcCount; i++) {
      final radius = (1.9 * i + 1.4) * scale;
      final alpha = active
          ? 1.0
          : switch (i) {
              1 => 0.9,
              2 => 0.55,
              _ => 0.25,
            };
      final arc = Paint()
        ..color = color.withValues(alpha: color.a * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCenter(
        center: Offset(centreX, centreY),
        width: radius * 2,
        height: radius * 2,
      );
      // Opening left and right of the stem, a third of a turn each.
      canvas.drawArc(rect, -0.55, 1.1, false, arc);
      canvas.drawArc(rect, 3.14159 - 0.55, 1.1, false, arc);
    }
  }

  @override
  bool shouldRepaint(_MicPainter old) =>
      old.color != color || old.active != active;
}
