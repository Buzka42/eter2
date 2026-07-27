import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/tokens.dart';

/// The shared shell header: the ETER wordmark resting inside the one approved
/// celestial signature — a solar mark on one side, a lunar mark on the other,
/// joined by a single fine orbital arc with one eight-point star at its
/// centre. Commissioned in `docs/ASSET_MANIFEST.md` as code, not bitmap:
/// one-colour paths tinted by the register, identical geometry on the Journal
/// and the Dashboard, and excluded from semantics because it is the shell's
/// decoration, not information.
///
/// Tint is a register decision rather than a surface-intent decision: the
/// signature belongs to the shell itself, so it stays present (and quiet) on
/// the plain Journal. Day draws it in ink, night in gold — never both, never
/// brighter than this.
class EterShellHeader extends StatelessWidget {
  const EterShellHeader({super.key});

  /// A shallow mobile bookplate: live type inside code-native line work.
  static const Size compositionSize = Size(300, 72);

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    final tint = night
        ? EterColors.aura500.withValues(alpha: 0.6)
        : EterColors.ink600.withValues(alpha: 0.8);
    final text = Theme.of(context).textTheme;
    return ExcludeSemantics(
      child: SizedBox(
        width: compositionSize.width,
        height: compositionSize.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _HeaderEngravingPainter(tint)),
            ),
            // The wordmark is live typography; it is not part of the asset.
            Positioned(
              top: 22,
              // This is a decorative wordmark inside fixed engraving, not
              // reading content. Keep the lockup intact when body text grows.
              child: MediaQuery.withNoTextScaling(
                child: Text(
                  'ETER',
                  style: text.displaySmall?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 8,
                    color: night ? EterColors.nightText : EterColors.ink900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderEngravingPainter extends CustomPainter {
  _HeaderEngravingPainter(this.tint);

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = tint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final w = size.width; // 300
    // A fragment of an old star chart rises over the wordmark. The previous
    // downward arc looked like a smile and made the name feel incidental.
    final arcStart = Offset(w * 0.16, 18);
    final arcEnd = Offset(w * 0.84, 18);
    final arc = Path()
      ..moveTo(arcStart.dx, arcStart.dy)
      ..quadraticBezierTo(w / 2, -2, arcEnd.dx, arcEnd.dy);
    canvas.drawPath(arc, line);

    final sun = Offset(w * 0.12, 18);
    canvas.drawCircle(sun, 3.8, line);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        sun + Offset(math.cos(angle), math.sin(angle)) * 5.5,
        sun + Offset(math.cos(angle), math.sin(angle)) * 8,
        line,
      );
    }

    final moon = Offset(w * 0.88, 18);
    final outer = Rect.fromCircle(center: moon, radius: 4.5);
    final inner =
        Rect.fromCircle(center: moon + const Offset(2, -0.7), radius: 3.7);
    final crescent = Path()
      ..addArc(outer, math.pi * 0.62, math.pi * 0.76)
      ..arcTo(inner, math.pi * 1.38, -math.pi * 0.76, false)
      ..close();
    canvas.drawPath(crescent, line);

    // A short plumb line and restrained compass star turn the composition into
    // an instrument/bookplate rather than a decorative banner.
    canvas.drawLine(Offset(w / 2, 54), Offset(w / 2, 63), line);
    final star = Offset(w / 2, 66);
    const r = 3.2;
    for (final rotation in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final angle = rotation + i * math.pi / 2;
        final p = star + Offset(math.cos(angle), math.sin(angle)) * r;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, line);
    }
    canvas.drawCircle(star, 0.7, Paint()..color = tint);
  }

  @override
  bool shouldRepaint(_HeaderEngravingPainter old) => old.tint != tint;
}

/// The persistent Journal↔Dashboard affordance — two letterspaced caps
/// labels with a single travelling gold hairline beneath the active one.
///
/// Non-negotiable 7: nothing essential behind a gesture alone. The pager
/// swipes, but the swipe is never the only way; these two words are always on
/// screen, always tappable, with a 48 dp target. The hairline is gold and
/// decorative in the day register (~1.15:1); the active state is carried
/// accessibly by the label's weight and ink.
class DestinationSwitch extends StatelessWidget {
  const DestinationSwitch({
    super.key,
    required this.activeIndex,
    required this.onSelect,
  });

  /// 0 = Journal (left), 1 = Dashboard (right).
  final int activeIndex;
  final ValueChanged<int> onSelect;

  static const _labels = ['JOURNAL', 'DASHBOARD'];
  static const _hairlineWidths = [66.0, 84.0];

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final gold = night ? EterColors.aura500 : EterColors.aura700;
    final activeInk = night ? EterColors.nightText : EterColors.ink900;
    final quietInk = night ? EterColors.nightText3 : EterColors.ink400;

    return SizedBox(
      width: EterShellHeader.compositionSize.width,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final half = constraints.maxWidth / 2;
          final lineWidth = _hairlineWidths[activeIndex];
          final targetLeft = activeIndex == 0
              ? (half - lineWidth) / 2
              : half + (half - lineWidth) / 2;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (var i = 0; i < _labels.length; i++)
                    Expanded(
                      child: _SwitchLabel(
                        label: _labels[i],
                        active: i == activeIndex,
                        style: text.labelMedium?.copyWith(
                          color: i == activeIndex ? activeInk : quietInk,
                          fontWeight: i == activeIndex
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
              SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration:
                          reduceMotion ? Duration.zero : EterMotion.durStandard,
                      curve: EterMotion.easeAir,
                      left: targetLeft,
                      top: 1,
                      child: AnimatedContainer(
                        duration: reduceMotion
                            ? Duration.zero
                            : EterMotion.durStandard,
                        curve: EterMotion.easeAir,
                        width: lineWidth,
                        height: 1,
                        color: gold.withValues(alpha: night ? 0.8 : 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SwitchLabel extends StatelessWidget {
  const _SwitchLabel({
    required this.label,
    required this.active,
    required this.style,
    required this.onTap,
  });

  final String label;
  final bool active;
  final TextStyle? style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label.toLowerCase(),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(label, style: style),
        ),
      ),
    );
  }
}
