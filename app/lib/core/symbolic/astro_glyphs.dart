import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The real symbols, drawn rather than typed.
///
/// Two letters on a chart ring is a compromise nobody asks for; these are the
/// actual glyphs — ten bodies, twelve signs, and the two angles. Every one is
/// a path at a common 100×100 design size, so the whole set scales together,
/// shares one stroke weight, and inherits the register's colour like any other
/// hairline in the app.
///
/// Why paths rather than a symbol font: the Unicode astrological block is
/// absent from both Cormorant and Inter, so using it would mean bundling a
/// third face whose weight, optical size and voice were designed for something
/// else — on the most symbolic surface in the product. Paths also let a glyph
/// stay a 1 px hairline at 11 px, which no text face will do.
enum AstroGlyph {
  sun,
  moon,
  mercury,
  venus,
  mars,
  jupiter,
  saturn,
  uranus,
  neptune,
  pluto,
  ascendant,
  midheaven,
  aries,
  taurus,
  gemini,
  cancer,
  leo,
  virgo,
  libra,
  scorpio,
  sagittarius,
  capricorn,
  aquarius,
  pisces;

  /// The catalogue's own names, so callers can map without a second table.
  static AstroGlyph? forBody(String name) => switch (name) {
        'Sun' => sun,
        'Moon' => moon,
        'Mercury' => mercury,
        'Venus' => venus,
        'Mars' => mars,
        'Jupiter' => jupiter,
        'Saturn' => saturn,
        'Uranus' => uranus,
        'Neptune' => neptune,
        'Pluto' => pluto,
        'Ascendant' => ascendant,
        'Midheaven' => midheaven,
        _ => null,
      };

  static AstroGlyph? forSign(String label) => switch (label) {
        'Aries' => aries,
        'Taurus' => taurus,
        'Gemini' => gemini,
        'Cancer' => cancer,
        'Leo' => leo,
        'Virgo' => virgo,
        'Libra' => libra,
        'Scorpio' => scorpio,
        'Sagittarius' => sagittarius,
        'Capricorn' => capricorn,
        'Aquarius' => aquarius,
        'Pisces' => pisces,
        _ => null,
      };

  /// Spoken form, for the semantics of anything that draws one.
  String get label => switch (this) {
        sun => 'Sun',
        moon => 'Moon',
        mercury => 'Mercury',
        venus => 'Venus',
        mars => 'Mars',
        jupiter => 'Jupiter',
        saturn => 'Saturn',
        uranus => 'Uranus',
        neptune => 'Neptune',
        pluto => 'Pluto',
        ascendant => 'Ascendant',
        midheaven => 'Midheaven',
        aries => 'Aries',
        taurus => 'Taurus',
        gemini => 'Gemini',
        cancer => 'Cancer',
        leo => 'Leo',
        virgo => 'Virgo',
        libra => 'Libra',
        scorpio => 'Scorpio',
        sagittarius => 'Sagittarius',
        capricorn => 'Capricorn',
        aquarius => 'Aquarius',
        pisces => 'Pisces',
      };
}

/// Draws one glyph in a box, at the stroke weight the surface asks for.
class AstroGlyphMark extends StatelessWidget {
  const AstroGlyphMark({
    super.key,
    required this.glyph,
    required this.color,
    this.size = 14,
    this.strokeWidth = 1,
    this.semanticLabel,
  });

  final AstroGlyph glyph;
  final Color color;
  final double size;
  final double strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: AstroGlyphPainter(
          glyph: glyph,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: mark);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: mark,
    );
  }
}

class AstroGlyphPainter extends CustomPainter {
  const AstroGlyphPainter({
    required this.glyph,
    required this.color,
    this.strokeWidth = 1,
  });

  final AstroGlyph glyph;
  final Color color;
  final double strokeWidth;

  /// Every path below is drawn against this square and scaled at paint time.
  static const design = 100.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / design;
    canvas.save();
    canvas.scale(scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    switch (glyph) {
      // --- Bodies -------------------------------------------------------
      case AstroGlyph.sun:
        canvas.drawCircle(const Offset(50, 50), 34, stroke);
        canvas.drawCircle(const Offset(50, 50), 7, fill);
      case AstroGlyph.moon:
        // A crescent: one disc with a second swung out of it.
        final outer = Path()
          ..addOval(Rect.fromCircle(center: const Offset(58, 50), radius: 36));
        final bite = Path()
          ..addOval(Rect.fromCircle(center: const Offset(78, 44), radius: 32));
        canvas.drawPath(
          Path.combine(PathOperation.difference, outer, bite),
          stroke,
        );
      case AstroGlyph.mercury:
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(50, 22), radius: 15),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          stroke,
        );
        canvas.drawCircle(const Offset(50, 50), 17, stroke);
        canvas.drawLine(const Offset(50, 67), const Offset(50, 90), stroke);
        canvas.drawLine(const Offset(36, 79), const Offset(64, 79), stroke);
      case AstroGlyph.venus:
        canvas.drawCircle(const Offset(50, 38), 20, stroke);
        canvas.drawLine(const Offset(50, 58), const Offset(50, 90), stroke);
        canvas.drawLine(const Offset(34, 76), const Offset(66, 76), stroke);
      case AstroGlyph.mars:
        canvas.drawCircle(const Offset(42, 62), 21, stroke);
        canvas.drawLine(const Offset(57, 47), const Offset(84, 20), stroke);
        canvas.drawLine(const Offset(64, 18), const Offset(86, 18), stroke);
        canvas.drawLine(const Offset(86, 18), const Offset(86, 40), stroke);
      case AstroGlyph.jupiter:
        // The stylised 4: a crescent stem crossed by the base line.
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(38, 34), radius: 18),
          math.pi * 0.6,
          math.pi * 1.25,
          false,
          stroke,
        );
        canvas.drawLine(const Offset(38, 16), const Offset(38, 82), stroke);
        canvas.drawLine(const Offset(24, 82), const Offset(80, 82), stroke);
      case AstroGlyph.saturn:
        // The stylised h with its cross.
        canvas.drawLine(const Offset(34, 14), const Offset(34, 60), stroke);
        canvas.drawLine(const Offset(20, 30), const Offset(50, 30), stroke);
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(52, 66), radius: 22),
          math.pi * 1.05,
          math.pi * 1.2,
          false,
          stroke,
        );
      case AstroGlyph.uranus:
        canvas.drawCircle(const Offset(50, 76), 13, stroke);
        canvas.drawLine(const Offset(50, 63), const Offset(50, 34), stroke);
        canvas.drawLine(const Offset(24, 34), const Offset(76, 34), stroke);
        canvas.drawLine(const Offset(24, 34), const Offset(24, 12), stroke);
        canvas.drawLine(const Offset(76, 34), const Offset(76, 12), stroke);
      case AstroGlyph.neptune:
        canvas.drawLine(const Offset(50, 20), const Offset(50, 88), stroke);
        canvas.drawLine(const Offset(30, 74), const Offset(70, 74), stroke);
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(50, 40), radius: 26),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawLine(const Offset(24, 40), const Offset(24, 22), stroke);
        canvas.drawLine(const Offset(76, 40), const Offset(76, 22), stroke);
      case AstroGlyph.pluto:
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(50, 34), radius: 16),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawCircle(const Offset(50, 34), 8, stroke);
        canvas.drawLine(const Offset(50, 50), const Offset(50, 88), stroke);
        canvas.drawLine(const Offset(32, 74), const Offset(68, 74), stroke);

      // --- Angles -------------------------------------------------------
      case AstroGlyph.ascendant:
        // A rising mark: the horizon and a body climbing off it.
        canvas.drawLine(const Offset(14, 74), const Offset(86, 74), stroke);
        canvas.drawCircle(const Offset(58, 44), 12, stroke);
        canvas.drawLine(const Offset(20, 66), const Offset(44, 42), stroke);
      case AstroGlyph.midheaven:
        canvas.drawLine(const Offset(20, 78), const Offset(20, 30), stroke);
        canvas.drawLine(const Offset(20, 30), const Offset(42, 56), stroke);
        canvas.drawLine(const Offset(42, 56), const Offset(64, 30), stroke);
        canvas.drawLine(const Offset(64, 30), const Offset(64, 78), stroke);
        canvas.drawCircle(const Offset(82, 34), 8, stroke);

      // --- Signs --------------------------------------------------------
      case AstroGlyph.aries:
        // The ram: a stem rising to a brow, from which both horns sweep out
        // and curl back down. Curling them inward — the first attempt — reads
        // as an M, which is Virgo's territory.
        canvas.drawPath(
          Path()
            ..moveTo(50, 88)
            ..lineTo(50, 46)
            ..cubicTo(50, 26, 34, 16, 24, 24)
            ..cubicTo(14, 32, 16, 50, 20, 60),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(50, 46)
            ..cubicTo(50, 26, 66, 16, 76, 24)
            ..cubicTo(86, 32, 84, 50, 80, 60),
          stroke,
        );
      case AstroGlyph.taurus:
        canvas.drawCircle(const Offset(50, 66), 24, stroke);
        // Horns: a wide crescent resting on the head, open upward.
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(50, 36), radius: 30),
          math.pi * 0.92,
          math.pi * 1.16,
          false,
          stroke,
        );
      case AstroGlyph.gemini:
        // The Roman two: two uprights closed by a bar at each end, the bars
        // bowed very slightly so it reads as a glyph and not as a table.
        canvas.drawLine(const Offset(32, 24), const Offset(32, 76), stroke);
        canvas.drawLine(const Offset(68, 24), const Offset(68, 76), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(20, 22)
            ..quadraticBezierTo(50, 14, 80, 22),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(20, 78)
            ..quadraticBezierTo(50, 86, 80, 78),
          stroke,
        );
      case AstroGlyph.cancer:
        canvas.drawCircle(const Offset(34, 62), 10, stroke);
        canvas.drawCircle(const Offset(66, 38), 10, stroke);
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(52, 40), radius: 26),
          math.pi * 0.9,
          math.pi * 0.9,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(48, 60), radius: 26),
          math.pi * 1.9,
          math.pi * 0.9,
          false,
          stroke,
        );
      case AstroGlyph.leo:
        canvas.drawCircle(const Offset(34, 68), 16, stroke);
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(56, 40), radius: 22),
          math.pi * 0.7,
          math.pi * 1.5,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(76, 66), radius: 14),
          math.pi * 1.2,
          math.pi * 1.1,
          false,
          stroke,
        );
      case AstroGlyph.virgo:
        for (final x in [24.0, 44.0]) {
          canvas.drawLine(Offset(x, 24), Offset(x, 78), stroke);
          canvas.drawArc(
            Rect.fromCircle(center: Offset(x + 10, 24), radius: 10),
            math.pi,
            math.pi,
            false,
            stroke,
          );
        }
        canvas.drawLine(const Offset(64, 24), const Offset(64, 66), stroke);
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(74, 24), radius: 10),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(72, 66), radius: 16),
          math.pi * 0.8,
          math.pi * 1.1,
          false,
          stroke,
        );
        canvas.drawLine(const Offset(64, 82), const Offset(90, 60), stroke);
      case AstroGlyph.libra:
        canvas.drawLine(const Offset(14, 80), const Offset(86, 80), stroke);
        canvas.drawLine(const Offset(30, 58), const Offset(70, 58), stroke);
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(50, 58), radius: 20),
          math.pi,
          math.pi,
          false,
          stroke,
        );
      case AstroGlyph.scorpio:
        for (final x in [24.0, 44.0]) {
          canvas.drawLine(Offset(x, 30), Offset(x, 78), stroke);
          canvas.drawArc(
            Rect.fromCircle(center: Offset(x + 10, 30), radius: 10),
            math.pi,
            math.pi,
            false,
            stroke,
          );
        }
        canvas.drawLine(const Offset(64, 30), const Offset(64, 74), stroke);
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(74, 30), radius: 10),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawLine(const Offset(64, 74), const Offset(88, 52), stroke);
        canvas.drawLine(const Offset(88, 52), const Offset(76, 50), stroke);
        canvas.drawLine(const Offset(88, 52), const Offset(88, 66), stroke);
      case AstroGlyph.sagittarius:
        canvas.drawLine(const Offset(20, 82), const Offset(80, 22), stroke);
        canvas.drawLine(const Offset(56, 22), const Offset(82, 22), stroke);
        canvas.drawLine(const Offset(82, 22), const Offset(82, 48), stroke);
        canvas.drawLine(const Offset(36, 46), const Offset(62, 72), stroke);
      case AstroGlyph.capricorn:
        // The goat's horn falling into the fish's tail: one stroke down and
        // across, then a loop closing back on itself.
        canvas.drawPath(
          Path()
            ..moveTo(16, 26)
            ..lineTo(30, 74)
            ..lineTo(44, 26)
            ..lineTo(58, 70),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(58, 70)
            ..cubicTo(66, 44, 90, 48, 86, 68)
            ..cubicTo(84, 82, 66, 84, 62, 74),
          stroke,
        );
      case AstroGlyph.aquarius:
        for (final y in [40.0, 66.0]) {
          final path = Path()..moveTo(16, y);
          for (var i = 0; i < 2; i++) {
            final x = 16 + i * 34.0;
            path.lineTo(x + 8.5, y - 11);
            path.lineTo(x + 17, y);
            path.lineTo(x + 25.5, y - 11);
            path.lineTo(x + 34, y);
          }
          canvas.drawPath(path, stroke);
        }
      case AstroGlyph.pisces:
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(50, 50), radius: 34),
          math.pi * 0.62,
          math.pi * 0.76,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(50, 50), radius: 34),
          math.pi * 1.62,
          math.pi * 0.76,
          false,
          stroke,
        );
        canvas.drawLine(const Offset(20, 50), const Offset(80, 50), stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(AstroGlyphPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
