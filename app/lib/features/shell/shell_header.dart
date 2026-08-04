import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/tokens.dart';

/// The shared shell header: the ETER wordmark inside the shell's celestial
/// signature. Commissioned in `docs/ENGINEERING.md` as code, not bitmap:
/// one-colour paths tinted by the register, identical geometry on the Journal
/// and the Dashboard, and excluded from semantics because it is the shell's
/// decoration, not information.
///
/// The signature is register-dependent (steering decision, 28 July 2026):
///
/// * **Day** is the sparse register — the wordmark and the lower
///   plumb-and-star colophon, and nothing above the name. Daylight already
///   carries the sky; the name should be the only event.
/// * **Night** is the elaborate register — the astrolabe reading: a graduated
///   arc with its tick ring, solar and lunar marks, an inner declination arc,
///   and one very slow drift of the graduation. Reduced motion renders it
///   settled on frame one.
///
/// Composition size, lockup geometry and hit region are identical across both
/// registers; only the drawn matter changes. Tint is a register decision
/// rather than a surface-intent decision, so the signature stays present (and
/// quiet) on the plain Journal. Day draws it in ink, night in gold — never
/// both, never brighter than this.
class EterShellHeader extends StatefulWidget {
  const EterShellHeader({super.key, this.onOpenSanctum});

  final VoidCallback? onOpenSanctum;

  /// A shallow mobile bookplate: live type inside code-native line work.
  static const Size compositionSize = Size(300, 72);

  /// One full revolution of the night graduation. Slower than the sky drift on
  /// purpose: the movement should never be catchable, only noticed.
  static const Duration nightDrift = Duration(minutes: 6);

  @override
  State<EterShellHeader> createState() => _EterShellHeaderState();
}

class _EterShellHeaderState extends State<EterShellHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: EterShellHeader.nightDrift,
  );

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  /// The ticker runs only where the drawing uses it: the night register, with
  /// motion allowed. Anywhere else it is stopped, so the day header and every
  /// reduced-motion surface stay genuinely still.
  void _syncDrift({required bool night, required bool reduceMotion}) {
    final shouldRun = night && !reduceMotion;
    if (shouldRun && !_drift.isAnimating) {
      _drift.repeat();
    } else if (!shouldRun && _drift.isAnimating) {
      _drift.stop();
      _drift.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncDrift(night: night, reduceMotion: reduceMotion);
    final tint = night
        ? EterColors.aura500.withValues(alpha: 0.6)
        : EterColors.ink600.withValues(alpha: 0.8);
    final text = Theme.of(context).textTheme;
    // The mark stays tappable and is *silent* to assistive technology.
    //
    // It used to carry the `Open Sanctum` label, which was right while it was the
    // only way in. It is not any more: the glyph on the destination row is the
    // named, explained affordance, and leaving the label here announced the same
    // door twice on every screen — the golden harness found two widgets and could
    // not decide which to tap, which is the machine noticing what a screen-reader
    // user would have had to sit through.
    //
    // Kept tappable rather than made inert, for the people who learned it before
    // the glyph existed.
    return Semantics(
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpenSanctum,
        child: SizedBox(
          width: EterShellHeader.compositionSize.width,
          height: EterShellHeader.compositionSize.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _drift,
                    builder: (context, _) => CustomPaint(
                      painter: _HeaderEngravingPainter(
                        tint: tint,
                        elaborate: night,
                        phase: _drift.value,
                      ),
                    ),
                  ),
                ),
              ),
              // The wordmark is live typography; it is not part of the asset.
              Positioned(
                top: 22,
                // This is a decorative wordmark inside fixed engraving, not
                // reading content. Keep the lockup intact when body text grows.
                child: MediaQuery.withNoTextScaling(
                  child: Text(
                    EterStrings.of(context).wordmark,
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
      ),
    );
  }
}

class _HeaderEngravingPainter extends CustomPainter {
  _HeaderEngravingPainter({
    required this.tint,
    required this.elaborate,
    required this.phase,
  });

  final Color tint;

  /// Night draws the complete astrolabe; day draws the colophon alone.
  final bool elaborate;

  /// 0..1 revolution of the graduation ring. Always 0 when the day register or
  /// reduced motion is in force.
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = tint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final w = size.width; // 300
    if (elaborate) _paintAstrolabe(canvas, w, line);
    _paintColophon(canvas, w, line);
  }

  /// The night register. A fragment of an old star chart rises over the
  /// wordmark: a graduated arc between a solar and a lunar mark, one inner
  /// declination arc, and a ring of graduations that drifts through it.
  void _paintAstrolabe(Canvas canvas, double w, Paint line) {
    final arc = Path()
      ..moveTo(w * 0.16, 18)
      ..quadraticBezierTo(w / 2, -2, w * 0.84, 18);
    canvas.drawPath(arc, line);

    // The inner declination arc — shallower, fainter, the second reading of
    // the same instrument.
    final inner = Path()
      ..moveTo(w * 0.28, 20)
      ..quadraticBezierTo(w / 2, 7, w * 0.72, 20);
    canvas.drawPath(
      inner,
      Paint()
        ..color = tint.withValues(alpha: tint.a * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..strokeCap = StrokeCap.round,
    );

    // Graduations, struck on the arc's own circle. The drift turns this ring
    // and nothing else, so the fixed marks stay fixed.
    final centre = Offset(w / 2, 118);
    const radius = 108.0;
    final tick = Paint()
      ..color = tint.withValues(alpha: tint.a * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;
    const count = 24;
    for (var i = 0; i < count; i++) {
      final turn = (i / count + phase) % 1;
      final angle = -math.pi / 2 + (turn - 0.5) * math.pi * 2;
      // Only the graduations riding the visible upper arc are struck; the
      // rest of the revolution passes behind the wordmark, unseen.
      if (angle < -math.pi * 0.72 || angle > -math.pi * 0.28) continue;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final long = i % 6 == 0;
      canvas.drawLine(
        centre + direction * radius,
        centre + direction * (radius + (long ? 5 : 2.6)),
        tick,
      );
    }

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
    final outerCrescent = Rect.fromCircle(center: moon, radius: 4.5);
    final innerCrescent =
        Rect.fromCircle(center: moon + const Offset(2, -0.7), radius: 3.7);
    final crescent = Path()
      ..addArc(outerCrescent, math.pi * 0.62, math.pi * 0.76)
      ..arcTo(innerCrescent, math.pi * 1.38, -math.pi * 0.76, false)
      ..close();
    canvas.drawPath(crescent, line);
  }

  /// The colophon that both registers keep: a short plumb line and a
  /// restrained compass star, which make the composition an instrument rather
  /// than a decorative banner. In day this is the whole signature.
  void _paintColophon(Canvas canvas, double w, Paint line) {
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
  bool shouldRepaint(_HeaderEngravingPainter old) =>
      old.tint != tint || old.elaborate != elaborate || old.phase != phase;
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

  /// The rule spans the word it underlines, so its width is measured from the
  /// rendered text rather than tabulated.
  ///
  /// It used to be `[66.0, 84.0]` — the pixel widths of JOURNAL and DASHBOARD,
  /// in Inter, at one text scale. Those two numbers were three assumptions:
  /// that the words never change, that the face never changes, and that nobody
  /// enlarges their type. PULPIT is a third narrower than DASHBOARD, which under
  /// the old constants would have left the gold rule hanging past the end of the
  /// word by a visible margin. A [TextPainter] against the real style answers
  /// the question the constants were guessing at.
  static double _ruleWidth(String label, TextStyle? style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    // The trailing letterspace is added after the last glyph and is not part of
    // the word's ink; leaving it in made every rule overhang to the right.
    return painter.width - (style?.letterSpacing ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final gold = night ? EterColors.aura500 : EterColors.aura700;
    final activeInk = night ? EterColors.nightText : EterColors.ink900;
    final quietInk = night ? EterColors.nightText3 : EterColors.ink400;
    final labels = [strings.destinationJournal, strings.destinationDashboard];

    return SizedBox(
      width: EterShellHeader.compositionSize.width,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final half = constraints.maxWidth / 2;
          // Measured in the weight the active label actually renders in, which
          // is heavier than the resting one.
          final lineWidth = _ruleWidth(
            labels[activeIndex],
            text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            MediaQuery.textScalerOf(context),
          );
          final targetLeft = activeIndex == 0
              ? (half - lineWidth) / 2
              : half + (half - lineWidth) / 2;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: _SwitchLabel(
                        label: labels[i],
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
