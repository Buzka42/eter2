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
