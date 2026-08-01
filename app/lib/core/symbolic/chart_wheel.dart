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
///
/// The geometry lives in [NatalChartWheelLayout] rather than in the painter,
/// because both faults this surface had were geometric.
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

/// One body's place on the wheel: a bead at the degree it actually occupies,
/// and a glyph that may have been nudged along the ring to clear its
/// neighbours.
class WheelBody {
  const WheelBody({
    required this.name,
    required this.glyph,
    required this.longitude,
    required this.labelLongitude,
  });

  final String name;
  final AstroGlyph glyph;

  /// Where the body is. The bead sits here and never moves.
  final double longitude;

  /// Where its glyph is drawn. Equal to [longitude] unless a neighbour forced
  /// it aside, in which case a leader line joins the two.
  final double labelLongitude;

  /// How far the glyph was pushed, in degrees.
  double get nudge {
    final delta = ((labelLongitude - longitude) % 360 + 360) % 360;
    return delta > 180 ? 360 - delta : delta;
  }
}

/// Every radius and angle the wheel draws at, computed apart from the painter.
///
/// Split out because both faults this surface had were geometric, and neither
/// was visible in a reading of the paint calls:
///
/// * **The angles were drawn from the centre.** Cusps 1, 4, 7 and 10 ran from
///   radius zero to the sign ring, which put two full diameters straight
///   through the aspect figure — so every chord crossed both of them and the
///   middle of the wheel read as a thicket. A chart draws its cusps in the
///   annulus between the aspect circle and the ring; the angles earn their
///   emphasis from weight, not from length.
/// * **Crowded labels stepped inward until they left the annulus.** A glyph
///   colliding with a neighbour dropped 15 px, up to four times — far enough
///   to land among the chords, dragging its stem across them. Anyone born in
///   the early nineties has Uranus within a degree of Neptune, so this fired
///   on a very large number of real charts, including the one that reported
///   it. Glyphs now move *along* the ring and keep a leader line back to their
///   own degree, which is what the bead was always for.
///
/// Everything here is pure, so a test can assert that nothing but a chord ever
/// enters the aspect disc.
class NatalChartWheelLayout {
  NatalChartWheelLayout({
    required this.chart,
    required this.outer,
    required this.drawHouses,
    this.angleLabelExtent = 0,
  });

  final NatalChart chart;

  /// Radius of the outermost circle.
  final double outer;
  final bool drawHouses;

  /// Half the diagonal of an angle letter's box — the furthest any part of it
  /// can sit from the point it is centred on, whatever direction it is placed
  /// in.
  final double angleLabelExtent;

  /// Clearance between the wheel's rim and the angle letters.
  static const angleLabelGap = 3.0;

  /// The ring outside the wheel that belongs to the angle letters.
  ///
  /// They used to be drawn at `0.995 * outer` and centred there, which put
  /// them in the sign ring's own annulus — overlapping the sign glyphs by
  /// about six pixels — and carried them roughly nine pixels past the
  /// widget's edge, where the container decided whether you saw `ASC` or
  /// `AS`. Both faults fired on every chart drawn with houses, which is every
  /// chart from somebody who told Eter their birth time.
  ///
  /// So the letters get a lane of their own and the wheel gives it up. The
  /// widget's footprint is unchanged; only the drawn circle is smaller, and
  /// it is smaller by exactly what the letters need.
  double get angleLabelLane =>
      angleLabelExtent <= 0 ? 0 : angleLabelExtent * 2 + angleLabelGap;

  /// Where an angle letter is centred: clear of the rim by [angleLabelGap],
  /// and far enough in that its outer corner lands exactly on [outer] +
  /// [angleLabelLane].
  double get angleLabelRadius => outer + angleLabelGap + angleLabelExtent;

  /// The wheel's outer radius inside a square of [shortestSide], once the
  /// angle letters have been given their lane.
  ///
  /// One definition, used by the painter and asserted by the tests, so the two
  /// cannot drift apart.
  static double outerFor(double shortestSide, double angleLabelExtent) =>
      shortestSide / 2 -
      1 -
      (angleLabelExtent <= 0 ? 0 : angleLabelExtent * 2 + angleLabelGap);

  /// Inside edge of the sign ring.
  double get ringInner => outer * 0.80;

  /// The circle the aspect chords are struck across. Nothing else may cross it.
  double get aspectRadius => outer * 0.62;

  double get bodyGlyphSize => outer * 0.125;
  double get signGlyphSize => (outer - ringInner) * 0.66;

  /// Where body glyphs sit: the middle of the band between the aspect circle
  /// and the ring, the only place they fit without invading either.
  double get labelRadius => (aspectRadius + ringInner) / 2;

  /// The chart is drawn Ascendant-left, as charts are. Without a reliable
  /// birth time there is no Ascendant to anchor to, so 0° Aries takes the left
  /// instead and the houses are left undrawn.
  double get anchor => drawHouses ? chart.ascendant.longitude : 0.0;

  /// The gap two glyphs need at [labelRadius] to avoid touching, in degrees.
  ///
  /// Derived from arc length rather than fixed, because the same glyph subtends
  /// a different angle on a 240 dp wheel than on a 340 dp one.
  double get minLabelSeparation {
    final drawn = drawableBodies.length;
    if (drawn < 2) return 0;
    final needed = bodyGlyphSize * 1.05 / labelRadius * 180 / math.pi;
    // Twelve bodies at ten degrees is under a third of the wheel, so this
    // never binds in practice. It is here so the relaxation below cannot be
    // asked for something impossible and spin.
    final feasible = 350 / drawn;
    return needed < feasible ? needed : feasible;
  }

  /// The bodies that get a glyph. The angles are labelled with letters
  /// elsewhere, and anything without a drawn glyph is not drawn.
  List<ZodiacPosition> get drawableBodies => [
        for (final position in chart.positions)
          if (position.name != 'Ascendant' &&
              position.name != 'Midheaven' &&
              AstroGlyph.forBody(position.name) != null)
            position,
      ];

  late final List<WheelBody> bodies = _layOutBodies();

  List<WheelBody> _layOutBodies() {
    final drawn = drawableBodies;
    final labels = _spread(
      [for (final position in drawn) position.longitude],
      minLabelSeparation,
    );
    return [
      for (var i = 0; i < drawn.length; i++)
        WheelBody(
          name: drawn[i].name,
          glyph: AstroGlyph.forBody(drawn[i].name)!,
          longitude: drawn[i].longitude,
          labelLongitude: labels[i],
        ),
    ];
  }

  /// Pushes crowded longitudes apart until each has [separation] to itself,
  /// moving them as little as possible.
  ///
  /// Solved rather than relaxed. An iterative push-apart was the obvious
  /// approach and it was wrong in a way that only showed up on one chart in
  /// five: a chain of crowded bodies converges geometrically, so a sweep that
  /// stops after any fixed number of passes leaves a residual overlap. Quito
  /// came out four hundredths of a degree short and two glyphs touched.
  ///
  /// So this is exact. Cut the circle at its widest gap to get a line, then
  /// substituting `q[i] = p[i] - i * separation` turns "keep them apart and in
  /// order" into "keep q non-decreasing" — which is isotonic regression, and
  /// pool-adjacent-violators solves it in one pass with the least total
  /// movement there is. Nothing moves that does not have to, and nothing that
  /// has to move goes further than it must.
  static List<double> _spread(List<double> longitudes, double separation) {
    final count = longitudes.length;
    if (count < 2 || separation <= 0) return List.of(longitudes);

    final order = List<int>.generate(count, (index) => index)
      ..sort((a, b) => longitudes[a].compareTo(longitudes[b]));

    // Cut at the widest gap, so the one constraint a line cannot express — the
    // wrap from last back to first — is the one with the most room in it.
    var cut = 0;
    var widest = -1.0;
    for (var i = 0; i < count; i++) {
      final gap = forwardGap(
        longitudes[order[i]],
        longitudes[order[(i + 1) % count]],
      );
      if (gap > widest) {
        widest = gap;
        cut = (i + 1) % count;
      }
    }

    // Unwrapped, ascending, starting at the cut.
    final rotated = [for (var i = 0; i < count; i++) order[(cut + i) % count]];
    final start = longitudes[rotated.first];
    final x = [
      for (final index in rotated) start + forwardGap(start, longitudes[index]),
    ];

    // Pool adjacent violators on q, tracking each block's mean and weight.
    final values = <double>[];
    final weights = <int>[];
    final counts = <int>[];
    for (var i = 0; i < count; i++) {
      var value = x[i] - i * separation;
      var weight = 1;
      var size = 1;
      while (values.isNotEmpty && values.last > value) {
        final mergedWeight = weights.last + weight;
        value = (values.last * weights.last + value * weight) / mergedWeight;
        weight = mergedWeight;
        size += counts.last;
        values.removeLast();
        weights.removeLast();
        counts.removeLast();
      }
      values.add(value);
      weights.add(weight);
      counts.add(size);
    }

    final solved = <double>[];
    for (var block = 0; block < values.length; block++) {
      for (var member = 0; member < counts[block]; member++) {
        solved.add(values[block] + solved.length * separation);
      }
    }

    final result = List<double>.filled(count, 0);
    for (var i = 0; i < count; i++) {
      result[rotated[i]] = _normalize(solved[i]);
    }
    return result;
  }

  /// Degrees from [from] forward to [to], always within 0..360.
  static double forwardGap(double from, double to) =>
      ((to - from) % 360 + 360) % 360;

  static double _normalize(double value) {
    final result = value % 360;
    return result < 0 ? result + 360 : result;
  }

  /// Chart longitude to canvas angle: counter-clockwise from the left, with
  /// [anchor] on the left horizon. Canvas y runs downward, so this is the
  /// traditional wheel — the first house below the Ascendant, the tenth at the
  /// top.
  double radians(double longitude) =>
      math.pi - (longitude - anchor) * math.pi / 180;

  Offset point(Offset centre, double longitude, double radius) {
    final angle = radians(longitude);
    return centre + Offset(math.cos(angle), math.sin(angle)) * radius;
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
    // The angle letters are measured before anything is sized, because the
    // wheel's radius is what is left once they have their lane.
    final angleStyle = _angleStyle(size.shortestSide);
    final angleExtent = _angleLabelExtent(angleStyle);
    final outer = NatalChartWheelLayout.outerFor(size.shortestSide, angleExtent);
    final layout = NatalChartWheelLayout(
      chart: chart,
      outer: outer,
      drawHouses: drawHouses,
      angleLabelExtent: angleExtent,
    );
    final ringInner = layout.ringInner;
    final aspectRadius = layout.aspectRadius;

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

    final anchor = layout.anchor;

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
        layout.signGlyphSize,
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
    //
    // Every cusp runs the same span, from the aspect circle to the ring. The
    // angles were drawn from radius zero, which laid two diameters across the
    // aspect figure and made the middle of every chart illegible; they are
    // distinguished by weight instead, which is what weight is for here.
    if (drawHouses) {
      for (var i = 0; i < chart.houseCusps.length; i++) {
        final angular = i % 3 == 0; // 1, 4, 7, 10
        _spoke(
          canvas,
          centre,
          chart.houseCusps[i],
          aspectRadius,
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

    // --- The bodies: a bead at the true degree on the ring, a glyph in the
    // band inside it, and a leader line between them when they differ.
    //
    // Bodies cluster — a stellium puts four inside eight degrees, and every
    // chart from the early nineties has Uranus on top of Neptune — so glyphs
    // are pushed apart *along* the ring. The bead never moves, so the degree a
    // body actually occupies is still marked exactly; the leader line is what
    // ties the two together.
    for (final body in layout.bodies) {
      final bead = _point(centre, body.longitude, ringInner, anchor);
      final at = _point(centre, body.labelLongitude, layout.labelRadius, anchor);

      // Stop the line short of the glyph rather than running under it.
      final delta = at - bead;
      final clearance = layout.bodyGlyphSize * 0.62;
      if (delta.distance > clearance) {
        canvas.drawLine(
          bead,
          bead + delta * (1 - clearance / delta.distance),
          faint,
        );
      }
      canvas.drawCircle(bead, 2.4, strong);
      _glyph(
        canvas,
        centre,
        body.labelLongitude,
        layout.labelRadius,
        anchor,
        body.glyph,
        layout.bodyGlyphSize,
      );
    }

    // --- The Ascendant and Midheaven, named in the lane outside the rim.
    if (drawHouses) {
      final ascendant = _positionOf('Ascendant');
      final midheaven = _positionOf('Midheaven');
      if (ascendant != null && midheaven != null) {
        // The two can close to a few degrees at high latitudes — the meridian
        // and the eastern horizon are not ninety degrees apart except on the
        // equator — and their letters would then sit on top of each other.
        // Nothing else shares this lane, so they simply give way to each other.
        final needed = angleExtent * 2 /
            layout.angleLabelRadius *
            180 /
            math.pi;
        final placed = _separate(
          ascendant.longitude,
          midheaven.longitude,
          needed,
        );
        _angleLabel(canvas, centre, placed.$1, layout.angleLabelRadius, anchor,
            'ASC', angleStyle);
        _angleLabel(canvas, centre, placed.$2, layout.angleLabelRadius, anchor,
            'MC', angleStyle);
      }
    }
  }

  /// The style the angle letters are set in, scaled to the wheel.
  ///
  /// It was a hard-coded 9 px, which is a different thing at 240 dp than at
  /// 340 dp — the wheel's smallest size carried its largest lettering.
  TextStyle _angleStyle(double shortestSide) => TextStyle(
        fontFamily: 'Inter',
        fontSize: (shortestSide * 0.027).clamp(7.5, 9.5),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: label,
      );

  /// Half the diagonal of the widest angle letter's box.
  ///
  /// The diagonal rather than the width, because the label is placed at an
  /// angle that depends on the chart: at the left horizon its width points
  /// outward, at the meridian its height does, and the diagonal bounds both.
  double _angleLabelExtent(TextStyle style) {
    final gauge = _text('ASC', style);
    return math.sqrt(gauge.width * gauge.width + gauge.height * gauge.height) /
        2;
  }

  /// Pushes two longitudes symmetrically apart until [separation] degrees sit
  /// between them, and leaves them alone if they already do.
  static (double, double) _separate(
    double first,
    double second,
    double separation,
  ) {
    final forward = NatalChartWheelLayout.forwardGap(first, second);
    final signed = forward > 180 ? forward - 360 : forward;
    if (signed.abs() >= separation) return (first, second);
    final push = (separation - signed.abs()) / 2;
    final direction = signed < 0 ? -1 : 1;
    double wrap(double value) {
      final result = value % 360;
      return result < 0 ? result + 360 : result;
    }

    return (wrap(first - direction * push), wrap(second + direction * push));
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

  TextPainter _text(String text, TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: textDirection,
      )..layout();

  /// The angles have no glyph in Unicode, so they keep their letters.
  void _angleLabel(
    Canvas canvas,
    Offset centre,
    double longitude,
    double radius,
    double anchor,
    String text,
    TextStyle style,
  ) {
    final painter = _text(text, style);
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
