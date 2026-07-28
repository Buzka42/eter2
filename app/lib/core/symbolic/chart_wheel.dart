import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controls.dart';
import '../tokens.dart';
import 'astro_glyphs.dart';
import 'natal_chart.dart';

/// The chart itself, drawn as an instrument.
///
/// Every other symbolic surface in Eter is prose about a chart nobody can see.
/// This is the chart: the twelve signs, the house cusps, the bodies on the
/// ring at their real longitudes, and the aspects between them drawn as chords
/// across the middle.
///
/// Code-native and one colour, like every other instrument here, so it holds in
/// both registers by construction and stays sharp at any size. Two deliberate
/// refusals:
///
/// * **No glyph font.** The real symbols are drawn as paths
///   (`astro_glyphs.dart`) rather than set in a symbol face, because the
///   Unicode astrological block is in neither Cormorant nor Inter and
///   importing a third face would put an unrelated typographic voice on the
///   most symbolic surface in the app. Paths also hold a 1 px hairline at
///   11 px, which no text face will do.
/// * **No fill, no colour coding.** Aspect type is carried by line weight —
///   the hard aspects struck firmly, the soft ones faint — rather than by a
///   red/blue convention the rest of the product has no vocabulary for.
class NatalChartWheel extends StatelessWidget {
  const NatalChartWheel({
    super.key,
    required this.chart,
    this.size = 300,
    this.ascendantReliable = true,
  });

  final NatalChart chart;
  final double size;

  /// When the birth time is a guess, the houses and the Ascendant are a guess
  /// with it. The wheel then draws the sign ring and the bodies, and omits the
  /// house structure rather than drawing twelve confident lines through it.
  final bool ascendantReliable;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final night = Theme.of(context).brightness == Brightness.dark;
    final positions = chart.positions
        .where((position) =>
            position.name != 'Ascendant' && position.name != 'Midheaven')
        .toList();
    final summary = positions
        .map((position) =>
            '${position.name} in ${position.sign} at '
            '${position.degreeInSign.toStringAsFixed(0)} degrees')
        .join(', ');

    return Semantics(
      label: 'Natal chart. $summary.',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _ChartWheelPainter(
            chart: chart,
            // Night draws the chart in gold on its own ground rather than in
            // the shell's hairline ink. Against a star field an ink hairline
            // competes with the stars and loses: the wheel was legible in day
            // and nearly gone at night.
            line: night
                ? EterColors.aura500.withValues(alpha: 0.85)
                : ink.line,
            lineStrong: night ? EterColors.gild : ink.lineStrong,
            label: night
                ? EterColors.aura300.withValues(alpha: 0.9)
                : ink.labelMuted,
            ground: night
                ? EterColors.night900.withValues(alpha: 0.55)
                : null,
            drawHouses: ascendantReliable,
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _ChartWheelPainter extends CustomPainter {
  _ChartWheelPainter({
    required this.chart,
    required this.line,
    required this.lineStrong,
    required this.label,
    required this.drawHouses,
    required this.textDirection,
    this.ground,
  });

  final NatalChart chart;
  final Color line;
  final Color lineStrong;
  final Color label;

  /// A disc laid under the wheel so the sky behind it stops competing with the
  /// line-work. Null in day, where the plate is already calm.
  final Color? ground;
  final bool drawHouses;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - 1;
    final ringInner = outer * 0.80;
    final aspectRadius = outer * 0.62;

    final thin = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final strong = Paint()
      ..color = lineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final faint = Paint()
      ..color = line.withValues(alpha: line.a * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;

    final ground = this.ground;
    if (ground != null) {
      canvas.drawCircle(
        centre,
        outer,
        Paint()
          ..shader = RadialGradient(
            colors: [ground, ground.withValues(alpha: 0)],
            stops: const [0.72, 1],
          ).createShader(Rect.fromCircle(center: centre, radius: outer)),
      );
    }
    canvas.drawCircle(centre, outer, thin);
    canvas.drawCircle(centre, ringInner, thin);
    canvas.drawCircle(centre, aspectRadius, faint);

    // The chart is drawn Ascendant-left, as charts are. Without a reliable
    // birth time there is no Ascendant to anchor to, so 0° Aries takes the
    // left instead and the houses are left undrawn.
    final anchor = drawHouses ? chart.ascendant.longitude : 0.0;

    // --- The twelve signs, and a graduation every 10°.
    for (var i = 0; i < 12; i++) {
      final start = i * 30.0;
      _spoke(canvas, centre, start, ringInner, outer, anchor, thin);
      _glyph(
        canvas,
        centre,
        start + 15,
        (outer + ringInner) / 2,
        anchor,
        AstroGlyph.signs[i],
        (outer - ringInner) * 0.66,
      );
      for (var tick = 10; tick < 30; tick += 10) {
        _spoke(
          canvas,
          centre,
          start + tick,
          ringInner,
          ringInner + (outer - ringInner) * 0.28,
          anchor,
          faint,
        );
      }
    }

    // --- Houses, when the birth time supports them.
    if (drawHouses) {
      for (var i = 0; i < chart.houseCusps.length; i++) {
        final angular = i % 3 == 0; // 1, 4, 7, 10
        _spoke(
          canvas,
          centre,
          chart.houseCusps[i],
          angular ? 0 : aspectRadius,
          ringInner,
          anchor,
          angular ? strong : faint,
        );
      }
    }

    // --- Aspects, as chords across the middle. Hard aspects carry weight;
    // soft ones stay faint. Nothing is coloured.
    // The tightest few only. A complete aspect grid on a 300 dp wheel is a
    // ball of thread, and the loose ones are the least worth drawing.
    for (final aspect in chart.aspects.take(8)) {
      final first = _positionOf(aspect.first);
      final second = _positionOf(aspect.second);
      if (first == null || second == null) continue;
      final hard = aspect.type == 'square' ||
          aspect.type == 'opposition' ||
          aspect.type == 'conjunction';
      canvas.drawLine(
        _point(centre, first.longitude, aspectRadius, anchor),
        _point(centre, second.longitude, aspectRadius, anchor),
        hard ? thin : faint,
      );
    }

    // --- The bodies: a bead on the ring, a stem to the aspect circle, and a
    // label inside it.
    //
    // Bodies cluster — a stellium puts four of them inside eight degrees — so
    // labels step inward when they would otherwise be struck through by their
    // neighbour. Stepping the radius rather than the angle keeps every label
    // pointing at the degree it belongs to.
    final placed = <({double longitude, double radius})>[];
    for (final position in chart.positions) {
      final glyph = AstroGlyph.forBody(position.name);
      if (glyph == null || position.name == 'Ascendant' ||
          position.name == 'Midheaven') {
        continue;
      }
      var radius = ringInner * 0.87;
      var guard = 0;
      while (guard < 4 &&
          placed.any((other) =>
              (other.radius - radius).abs() < 12 &&
              _arcDistance(other.longitude, position.longitude) < 11)) {
        radius -= 15;
        guard += 1;
      }
      placed.add((longitude: position.longitude, radius: radius));

      final bead = _point(centre, position.longitude, ringInner, anchor);
      canvas.drawLine(
        bead,
        _point(centre, position.longitude, radius - 7, anchor),
        faint,
      );
      canvas.drawCircle(bead, 2.4, strong);
      _glyph(
        canvas,
        centre,
        position.longitude,
        radius,
        anchor,
        glyph,
        outer * 0.125,
      );
    }

    // --- The Ascendant and Midheaven, named where they fall.
    if (drawHouses) {
      for (final point in ['Ascendant', 'Midheaven']) {
        final position = _positionOf(point);
        if (position == null) continue;
        _angleLabel(
          canvas,
          centre,
          position.longitude,
          outer * 0.995,
          anchor,
          point == 'Ascendant' ? 'ASC' : 'MC',
        );
      }
    }
  }

  /// Degrees between two longitudes, the short way round.
  double _arcDistance(double first, double second) {
    final delta = ((first - second) % 360 + 360) % 360;
    return delta > 180 ? 360 - delta : delta;
  }

  ZodiacPosition? _positionOf(String name) {
    for (final position in chart.positions) {
      if (position.name == name) return position;
    }
    return null;
  }

  /// Chart longitude to canvas angle: counter-clockwise from the left, with
  /// [anchor] placed on the left horizon.
  double _radians(double longitude, double anchor) =>
      math.pi - (longitude - anchor) * math.pi / 180;

  Offset _point(Offset centre, double longitude, double radius, double anchor) {
    final angle = _radians(longitude, anchor);
    return centre + Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  void _spoke(
    Canvas canvas,
    Offset centre,
    double longitude,
    double from,
    double to,
    double anchor,
    Paint paint,
  ) {
    canvas.drawLine(
      _point(centre, longitude, from, anchor),
      _point(centre, longitude, to, anchor),
      paint,
    );
  }

  /// Paints one glyph centred on a chart longitude.
  void _glyph(
    Canvas canvas,
    Offset centre,
    double longitude,
    double radius,
    double anchor,
    AstroGlyph glyph,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: glyph.character,
        style: TextStyle(
          fontFamily: AstroGlyph.fontFamily,
          fontSize: size,
          color: label,
        ),
      ),
      textDirection: textDirection,
    )..layout();
    final at = _point(centre, longitude, radius, anchor);
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  /// The angles have no glyph in Unicode, so they keep their letters.
  void _angleLabel(
    Canvas canvas,
    Offset centre,
    double longitude,
    double radius,
    double anchor,
    String text,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: label,
        ),
      ),
      textDirection: textDirection,
    )..layout();
    final at = _point(centre, longitude, radius, anchor);
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_ChartWheelPainter old) =>
      old.chart != chart ||
      old.line != line ||
      old.lineStrong != lineStrong ||
      old.ground != ground ||
      old.drawHouses != drawHouses;
}
