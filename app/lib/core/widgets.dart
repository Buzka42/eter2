import 'dart:math' as math;

import 'package:flutter/material.dart' hide Element;

import 'arcana/zodiac.dart';
import 'controls.dart';
import 'i18n/strings.dart';
import 'tokens.dart';

/// A flat, sharp-edged plate — Eter's surface where a group must be lifted
/// from the sky for legibility. Containment comes from a hairline top rule
/// and a very low-alpha flat scrim: no blur, no surround border, no shadow,
/// no radius. Frosted translucent cards at a large radius are the tell of
/// generated interface; the engraved plate is Eter's motif, and plates have
/// edges, not rounded glass.
class EterPlate extends StatelessWidget {
  const EterPlate({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    final ink = EterInk.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(EterSpace.s16),
      decoration: BoxDecoration(
        // C8 — measured against the Day Sky photograph's realistic worst case
        // (5th-percentile-darkest pixel, RGB 115,155,217). At the old 0.30 the
        // secondary ink600 reached only 3.25:1; 0.68 lifts it to 4.83:1 and
        // ink900 to 10.7:1, both clear of WCAG AA. Darkening ink600 instead was
        // rejected: to pass on *bare* sky it had to reach #25303B, all but
        // identical to ink900, which erases the secondary tier. Night at 0.45
        // already measures 14.5:1 / 8.3:1, so it is left alone.
        color: night
            ? EterColors.night900.withValues(alpha: 0.45)
            : EterColors.mist0.withValues(alpha: 0.68),
        border: Border(top: BorderSide(color: ink.line)),
      ),
      child: child,
    );
  }
}

/// Zodiac element medallion — the commissioned gold line-work emblems
/// (STATIC_ASSET_REQUESTS.md §B). Render between 40 and 96 px.
class ElementMedallion extends StatelessWidget {
  const ElementMedallion(this.element, {super.key, this.size = 64});

  final Element element;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      element.medallionAsset,
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      semanticLabel: EterStrings.of(context).elementMedallionSemantic(element),
    );
  }
}

// `EmptyStateOrnament` was here, and nothing ever constructed it. It was the
// only consumer of empty-ledger.png, empty-timeline.png and empty-balance.png,
// so a widget with no call sites was keeping 284 KB of art alive in the asset
// manifest. Every empty state Eter actually ships says its absence in words —
// which the UI brief prefers anyway ("say what you cannot see").

/// Circular progress ring, sky→gold sweep — spec 03 "AuraRing".
class AuraRing extends StatelessWidget {
  const AuraRing({
    super.key,
    required this.progress,
    required this.label,
    required this.value,
    this.size = 72,
  });
  final double progress; // 0..1+
  final String label;
  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress.clamp(0.0, 1.0)),
            duration: EterMotion.durEmphasis,
            curve: EterMotion.easeAir,
            builder: (context, p, _) => CustomPaint(
              painter: _AuraRingPainter(p),
              child: Center(
                child: Text(value,
                    style:
                        text.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
        const SizedBox(height: EterSpace.s8),
        Text(label.toUpperCase(), style: text.labelSmall),
      ],
    );
  }
}

class _AuraRingPainter extends CustomPainter {
  _AuraRingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = EterColors.sky200;
    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
        colors: [EterColors.sky400, EterColors.aura500],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, sweep, false, fill);
  }

  @override
  bool shouldRepaint(_AuraRingPainter old) => old.progress != progress;
}

/// Animated kcal numeral — digits count up, tabular figures (spec 03/04).
class CountUpText extends StatelessWidget {
  const CountUpText(this.value, {super.key, this.style});
  final double value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: EterMotion.durEmphasis,
      curve: EterMotion.easeAir,
      builder: (context, v, _) => Text('${v.floor()}', style: style),
    );
  }
}

/// Eight-pointed star ornament — Eter's mystical signature mark.
/// Drawn as fine gold line-work, never filled, always quiet.
class StarOrnament extends StatelessWidget {
  const StarOrnament({super.key, this.size = 14, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? EterColors.aura500;
    return CustomPaint(
      size: Size.square(size),
      painter: _StarOrnamentPainter(resolved),
    );
  }
}

class _StarOrnamentPainter extends CustomPainter {
  _StarOrnamentPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.07
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // Two overlaid squares, one rotated 45°, form the eight-pointed star.
    for (final rotation in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final angle = rotation + i * math.pi / 2;
        final p = c + Offset(math.cos(angle), math.sin(angle)) * r * 0.72;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(c, size.width * 0.06, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_StarOrnamentPainter old) => old.color != color;
}

/// Gold hairline flanking a star ornament — the section divider of the
/// mystical register. Grounded mode replaces it with a plain divider.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, this.width = 180});

  final double width;

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    // Day's mystical vocabulary is light, not pigment. A solid gold rule reads
    // as luxurious against black and merely heavy against pale blue, so on day
    // the rule is a band of light that dissolves at both ends.
    final line = night
        ? EterColors.aura500.withValues(alpha: 0.5)
        : EterColors.aura700.withValues(alpha: 0.42);
    Widget rule({required bool towardCentre}) => Container(
          width: width / 2 - 16,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:
                  towardCentre ? Alignment.centerLeft : Alignment.centerRight,
              end: towardCentre ? Alignment.centerRight : Alignment.centerLeft,
              colors: [line.withValues(alpha: 0), line],
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        rule(towardCentre: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: EterSpace.s12),
          child: StarOrnament(
            size: 13,
            color: night ? EterColors.aura500 : EterColors.aura700,
          ),
        ),
        rule(towardCentre: false),
      ],
    );
  }
}
