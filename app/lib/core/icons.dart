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
    final scale = size.shortestSide / 16;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * scale
      ..strokeCap = StrokeCap.round;
    final centreX = size.width / 2;

    // The head: a rounded capsule, which is the shape of the object rather
    // than a control — the no-capsules rule is about buttons, not about what a
    // microphone looks like.
    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centreX, 5.2 * scale),
        width: 5 * scale,
        height: 8.4 * scale,
      ),
      Radius.circular(2.5 * scale),
    );
    if (active) {
      canvas.drawRRect(head, Paint()..color = color);
    } else {
      canvas.drawRRect(head, stroke);
    }

    // The listening arc and the stem it stands on.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centreX, 8.4 * scale),
        width: 9.6 * scale,
        height: 9.6 * scale,
      ),
      0.15,
      3.14159 - 0.3,
      false,
      stroke,
    );
    canvas.drawLine(
      Offset(centreX, 13.2 * scale),
      Offset(centreX, 15 * scale),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_MicPainter old) =>
      old.color != color || old.active != active;
}
