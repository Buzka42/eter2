import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controls.dart';
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
/// * **No glyph font.** Planetary and zodiac glyphs are not in Cormorant or
///   Inter, and importing a symbol face to render eleven characters would put
///   an unrelated typographic voice on the most symbolic surface in the app.
///   Bodies are beads with letterspaced caps labels, which is what an engraved
///   chart does anyway.
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
            line: ink.line,
            lineStrong: ink.lineStrong,
            label: ink.labelMuted,
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
  });

  final NatalChart chart;
  final Color line;
  final Color lineStrong;
  final Color label;
  final bool drawHouses;
  final TextDirection textDirection;

  /// Two letters each, because the ring has room for two letters.
  static const _abbreviations = {
    'Sun': 'SU',
    'Moon': 'MO',
    'Mercury': 'ME',
    'Venus': 'VE',
    'Mars': 'MA',
    'Jupiter': 'JU',
    'Saturn': 'SA',
    'Uranus': 'UR',
    'Neptune': 'NE',
  };

  static const _signInitials = [
    'AR', 'TA', 'GE', 'CN', 'LE', 'VI',
    'LI', 'SC', 'SG', 'CP', 'AQ', 'PI',
  ];

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
      _label(
        canvas,
        centre,
        start + 15,
        (outer + ringInner) / 2,
        anchor,
        _signInitials[i],
        10,
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
      final abbreviation = _abbreviations[position.name];
      if (abbreviation == null) continue;
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
      _label(
        canvas,
        centre,
        position.longitude,
        radius,
        anchor,
        abbreviation,
        9,
      );
    }

    // --- The Ascendant and Midheaven, named where they fall.
    if (drawHouses) {
      for (final point in ['Ascendant', 'Midheaven']) {
        final position = _positionOf(point);
        if (position == null) continue;
        _label(
          canvas,
          centre,
          position.longitude,
          outer * 0.995,
          anchor,
          point == 'Ascendant' ? 'ASC' : 'MC',
          9,
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

  void _label(
    Canvas canvas,
    Offset centre,
    double longitude,
    double radius,
    double anchor,
    String text,
    double fontSize,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: label,
        ),
      ),
      textDirection: textDirection,
    )..layout();
    final at = _point(centre, longitude, radius, anchor);
    painter.paint(
      canvas,
      at - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ChartWheelPainter old) =>
      old.chart != chart ||
      old.line != line ||
      old.lineStrong != lineStrong ||
      old.drawHouses != drawHouses;
}
