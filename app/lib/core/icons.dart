import 'package:flutter/material.dart';

import 'controls.dart';
import 'tokens.dart';

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

/// The three depths behind the Dashboard's threshold, each as a drawn mark.
///
/// Placeholders in the shell's own engraved language — a hairline, a point, an
/// arc — so the row reads as one instrument rather than three borrowed icons.
/// The label stays beside each mark: non-negotiable 7 forbids an unexplained
/// symbol, and these are new enough that nothing has taught them yet. If
/// generated artwork replaces them later, only the painters change.
enum EterSectionGlyph { guidance, body, vessel }

class EterSectionMark extends StatelessWidget {
  const EterSectionMark({
    super.key,
    required this.glyph,
    this.size = 18,
    this.color,
  });

  final EterSectionGlyph glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _SectionPainter(
              glyph,
              color ?? EterInk.of(context).labelMuted,
            ),
          ),
        ),
      );
}

class _SectionPainter extends CustomPainter {
  const _SectionPainter(this.glyph, this.color);

  final EterSectionGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 18;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * scale
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;
    final cx = size.width / 2;
    switch (glyph) {
      case EterSectionGlyph.guidance:
        // A point risen above the horizon: the day's word arriving.
        canvas.drawLine(
          Offset(2 * scale, 13 * scale),
          Offset(16 * scale, 13 * scale),
          stroke,
        );
        canvas.drawCircle(Offset(cx, 6.5 * scale), 2.4 * scale, stroke);
        canvas.drawCircle(Offset(cx, 6.5 * scale), 0.9 * scale, fill);
      case EterSectionGlyph.body:
        // A graduated rule: measure, the recorded body.
        canvas.drawLine(
          Offset(cx, 3 * scale),
          Offset(cx, 15 * scale),
          stroke,
        );
        for (final (dy, reach) in [(5.0, 3.4), (9.0, 2.2), (13.0, 3.4)]) {
          canvas.drawLine(
            Offset(cx, dy * scale),
            Offset(cx + reach * scale, dy * scale),
            stroke,
          );
        }
      case EterSectionGlyph.vessel:
        // An open bowl on its foot: the vessel, holding what it is given.
        final rect = Rect.fromCircle(
          center: Offset(cx, 7.5 * scale),
          radius: 5.2 * scale,
        );
        canvas.drawArc(rect, 0, 3.14159, false, stroke);
        canvas.drawLine(
          Offset(cx, 12.7 * scale),
          Offset(cx, 15 * scale),
          stroke,
        );
        canvas.drawLine(
          Offset(cx - 2.6 * scale, 15 * scale),
          Offset(cx + 2.6 * scale, 15 * scale),
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(_SectionPainter old) =>
      old.color != color || old.glyph != glyph;
}

/// The way into the Sanctum: an astrolabe's mater, seen face on.
///
/// Two concentric rings, a centre point, and one short index line at the upper
/// right — the instrument reduced to the least that still reads as an instrument.
///
/// Deliberately *not* the eight-pointed [StarOrnament], which is Eter's signature
/// mark and already appears as ornament in five places; a control that shares its
/// glyph with decoration teaches nobody anything. Deliberately not a cog either:
/// the whole point of drawing these is that Material's tray would be the only
/// imported vocabulary left on a production surface.
///
/// The parent control owns semantics and the 48 dp target; this is 22 dp of ink.
class EterSanctumMark extends StatelessWidget {
  const EterSanctumMark({
    super.key,
    this.size = 22,
    this.color,
    this.glow = false,
  });

  final double size;
  final Color? color;

  /// A soft aura behind the ink, to say the mark is a control rather than
  /// ornament.
  ///
  /// Static. Not a pulse: a breathing control on a contemplative surface is the
  /// kind of motion `PRODUCT.md` calls excessive, and it would need a
  /// reduced-motion branch to earn nothing. Two stops at low alpha, no ring, no
  /// bloom — the point is that the eye registers something behind the line, not
  /// that it sees a light.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? EterColors.aura500;
    final mark = CustomPaint(
      size: Size.square(size),
      painter: _SanctumPainter(resolved),
    );
    if (!glow) return mark;
    return SizedBox(
      width: size * 2.1,
      height: size * 2.1,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                resolved.withValues(alpha: 0.20),
                resolved.withValues(alpha: 0.06),
                resolved.withValues(alpha: 0),
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
          child: SizedBox(
            width: size * 2.1,
            height: size * 2.1,
            child: Center(child: mark),
          ),
        ),
      ),
    );
  }
}

class _SanctumPainter extends CustomPainter {
  const _SanctumPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2 - 0.75;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      // One hairline at every size: the engraved language is a drawn line, not a
      // scaled shape, and a thickening ring would read as a filled disc.
      ..strokeWidth = 1
      ..isAntiAlias = true;

    canvas.drawCircle(centre, outer, stroke);
    canvas.drawCircle(centre, outer * 0.52, stroke);
    // The index, at the ascending angle the header's own arc rises through.
    canvas.drawLine(
      centre + Offset(outer * 0.37, -outer * 0.37),
      centre + Offset(outer * 0.86, -outer * 0.86),
      stroke,
    );
    canvas.drawCircle(centre, 1, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SanctumPainter old) => old.color != color;
}
