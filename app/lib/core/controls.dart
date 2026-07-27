import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'register.dart';
import 'tokens.dart';

/// The line palette every Eter control draws with.
///
/// Controls used to be Material's defaults with a colour override here and
/// there, which is why a sky-blue filled stadium button sat inside an engraved
/// gold system. The whole set is now hairline-drawn, and every control resolves
/// its colours through this one type: gold line-work in the mystical register,
/// plain ink in grounded, and the same again against night.
@immutable
class EterInk {
  const EterInk._({
    required this.line,
    required this.lineStrong,
    required this.label,
    required this.labelMuted,
    required this.wash,
  });

  /// Hairlines at rest — rails, tracks, unselected outlines.
  final Color line;

  /// Hairlines that carry meaning — selection, focus, the filled part of a rail.
  final Color lineStrong;
  final Color label;
  final Color labelMuted;

  /// The barely-there fill behind a selected control. Never a solid colour:
  /// solid fills are what made the old buttons shout.
  final Color wash;

  factory EterInk.of(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    // C10: gold is granted by the register and requested by the surface. A
    // "Add to today" button in the Log stays plain ink even in immersive.
    final ornament = showsOrnamentHere(context);
    if (ornament) {
      return EterInk._(
        line: EterColors.aura500.withValues(alpha: night ? 0.38 : 0.34),
        lineStrong: night ? EterColors.aura300 : EterColors.aura700,
        label: night ? EterColors.nightText : EterColors.ink900,
        labelMuted: night ? EterColors.nightText2 : EterColors.ink600,
        wash: EterColors.aura500.withValues(alpha: night ? 0.12 : 0.10),
      );
    }
    return EterInk._(
      line: (night ? EterColors.nightText3 : EterColors.ink400)
          .withValues(alpha: night ? 0.55 : 0.5),
      lineStrong: night ? EterColors.nightText : EterColors.ink900,
      label: night ? EterColors.nightText : EterColors.ink900,
      labelMuted: night ? EterColors.nightText2 : EterColors.ink600,
      wash: (night ? EterColors.nightText : EterColors.ink900)
          .withValues(alpha: night ? 0.10 : 0.06),
    );
  }
}

/// Emphasis of an [EterAction]. There is deliberately no filled or capsuled
/// variant: a solid button is the loudest object a screen can hold, and the
/// stadium capsule is the most recognisable tell of generated interface.
/// Every Eter action is letterspaced caps above a hairline rule; emphasis
/// changes the rule, never the shape.
enum EterActionEmphasis {
  /// The screen's committing action. A doubled rule at the full label width —
  /// the engraving device that stands where the fill and capsule used to.
  primary,

  /// An alternative or secondary route. A single short rule that grows on
  /// press.
  secondary,

  /// A quiet inline route. Caps only; the rule appears on press or focus.
  quiet,
}

/// Eter's action control — caps and rule, drawn with [EterInk]. The rule is
/// gold in the ornament registers and plain ink in grounded, by [EterInk.of].
class EterAction extends StatefulWidget {
  const EterAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.emphasis = EterActionEmphasis.secondary,
    this.icon,
    this.busy = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final EterActionEmphasis emphasis;
  final IconData? icon;

  /// Replaces the leading glyph with a hairline progress ring and blocks input.
  final bool busy;

  /// Stretch to the available width, rule included. Off by default — the rule
  /// spans the label and no more.
  final bool expand;

  @override
  State<EterAction> createState() => _EterActionState();
}

class _EterActionState extends State<EterAction> {
  bool _down = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    final enabled = widget.onPressed != null && !widget.busy;
    final quiet = widget.emphasis == EterActionEmphasis.quiet;
    final primary = widget.emphasis == EterActionEmphasis.primary;

    final color =
        enabled ? ink.lineStrong : ink.labelMuted.withValues(alpha: .5);
    final label = Text(
      widget.label.toUpperCase(),
      style: text.labelLarge?.copyWith(
        color: color,
        letterSpacing: primary ? 1.8 : 1.4,
        fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
      ),
    );

    Widget? leading;
    if (widget.busy) {
      leading = SizedBox.square(
        dimension: 15,
        child: CircularProgressIndicator(strokeWidth: 1.2, color: color),
      );
    } else if (widget.icon != null) {
      leading = Icon(widget.icon, size: 17, color: color);
    }

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: EterSpace.s12)],
        label,
      ],
    );

    // With no border left to borrow, state rides on the rule. Press thickens
    // or lengthens it; focus thickens it and adds a gold underscore, legible
    // on both skies; disabled draws no rule at all.
    final night = Theme.of(context).brightness == Brightness.dark;
    final gold = night ? EterColors.aura300 : EterColors.aura700;
    final ruleColor =
        enabled ? (primary ? ink.lineStrong : ink.line) : Colors.transparent;

    final Widget rules;
    if (primary) {
      rules = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: EterMotion.durMicro,
            curve: EterMotion.easeAir,
            height: _down || _focused ? 2 : 1.2,
            color: ruleColor,
          ),
          const SizedBox(height: 3),
          // The second hairline is the engraving device that marks the
          // committing action; under focus it turns to solid gold.
          AnimatedContainer(
            duration: EterMotion.durMicro,
            curve: EterMotion.easeAir,
            height: 1,
            color: _focused
                ? gold
                : ruleColor.withValues(alpha: _down ? 0.9 : 0.45),
          ),
        ],
      );
    } else {
      rules = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedContainer(
              duration: EterMotion.durMicro,
              curve: EterMotion.easeAir,
              width: quiet ? ((_down || _focused) ? 28 : 0) : (_down ? 44 : 28),
              height: _focused ? 2 : 1,
              color: ruleColor,
            ),
          ),
          if (_focused && !quiet) ...[
            const SizedBox(height: 3),
            Container(height: 1, color: gold),
          ],
        ],
      );
    }

    final child = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        const SizedBox(height: EterSpace.s4),
        rules,
      ],
    );

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: _Pressable(
        onPressed: enabled ? widget.onPressed : null,
        onDown: (down) => setState(() => _down = down),
        borderRadius: BorderRadius.circular(EterSpace.s8),
        // The capsule carried the hit target before; without it the padding
        // alone keeps the 52px minimum.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52, minWidth: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: EterSpace.s8, vertical: EterSpace.s12),
            child: widget.expand ? child : IntrinsicWidth(child: child),
          ),
        ),
      ),
    );
  }
}

/// Shared press handling: no Material ink splash, which is the single most
/// recognisably "Material" thing a custom control can keep by accident.
class _Pressable extends StatelessWidget {
  const _Pressable({
    required this.child,
    required this.onPressed,
    required this.onDown,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final ValueChanged<bool> onDown;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: MouseRegion(
        cursor: onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          onTapDown: onPressed == null ? null : (_) => onDown(true),
          onTapUp: onPressed == null ? null : (_) => onDown(false),
          onTapCancel: onPressed == null ? null : () => onDown(false),
          child: child,
        ),
      ),
    );
  }
}

/// Eter's selection chip — a hairline outline with an engraved marker when
/// chosen, replacing Material's `ChoiceChip` and its emoji labels.
class EterOptionChip extends StatelessWidget {
  const EterOptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelected,
        child: AnimatedContainer(
          duration: EterMotion.durMicro,
          curve: EterMotion.easeAir,
          padding: const EdgeInsets.symmetric(
              horizontal: EterSpace.s16, vertical: EterSpace.s12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EterSpace.rChip),
            color: selected ? ink.wash : Colors.transparent,
            border: Border.all(
              color: selected ? ink.lineStrong.withValues(alpha: .6) : ink.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16,
                    color: selected ? ink.lineStrong : ink.labelMuted),
                const SizedBox(width: EterSpace.s8),
              ],
              Text(
                label,
                style: text.titleSmall?.copyWith(
                  color: selected ? ink.label : ink.labelMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eter's switch — a hairline track with a travelling ring. Material's switch
/// is a filled pill with a shadowed thumb; nothing about it belongs here.
class EterToggle extends StatelessWidget {
  const EterToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: SizedBox(
          width: 52,
          height: 44, // keeps the 44pt touch target the visual track loses
          child: Center(
            child: AnimatedContainer(
              duration: EterMotion.durStandard,
              curve: EterMotion.easeAir,
              width: 48,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: value ? ink.wash : Colors.transparent,
                border: Border.all(
                    color: value
                        ? ink.lineStrong.withValues(alpha: .55)
                        : ink.line),
              ),
              child: AnimatedAlign(
                duration: EterMotion.durStandard,
                curve: EterMotion.easeAir,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value ? ink.lineStrong : Colors.transparent,
                      border: Border.all(
                        color: value ? ink.lineStrong : ink.line,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Eter's slider — an engraved rail with measure ticks and a ringed knob,
/// reading as an instrument scale rather than a Material track.
class EterSlider extends StatelessWidget {
  const EterSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.semanticFormatter,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String Function(double)? semanticFormatter;

  /// Half the knob ring, kept clear at both ends so the knob is not clipped
  /// when the value sits at min or max.
  static const double _inset = 10;

  double get _fraction => ((value - min) / (max - min)).clamp(0.0, 1.0);

  void _emit(double dx, double width) {
    final span = (width - _inset * 2).clamp(1.0, double.infinity);
    final raw = min + ((dx - _inset) / span).clamp(0.0, 1.0) * (max - min);
    final divisions = this.divisions;
    if (divisions == null) {
      onChanged(raw);
      return;
    }
    final step = (max - min) / divisions;
    onChanged((((raw - min) / step).round() * step + min).clamp(min, max));
  }

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    return Semantics(
      slider: true,
      value: semanticFormatter?.call(value) ?? value.round().toString(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _emit(details.localPosition.dx, width),
            onHorizontalDragUpdate: (details) =>
                _emit(details.localPosition.dx, width),
            // CustomPaint sizes to its child, and with no child it falls back
            // to `size`, which defaults to zero — the rail and ticks vanish and
            // only the knob lands, at the origin. The size has to be explicit.
            child: CustomPaint(
              size: Size(width, 44),
              painter: _EterSliderPainter(
                fraction: _fraction,
                divisions: divisions,
                line: ink.line,
                lineStrong: ink.lineStrong,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EterSliderPainter extends CustomPainter {
  _EterSliderPainter({
    required this.fraction,
    required this.divisions,
    required this.line,
    required this.lineStrong,
  });

  final double fraction;
  final int? divisions;
  final Color line;
  final Color lineStrong;

  static const double _inset = EterSlider._inset;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    const left = _inset;
    final right = size.width - _inset;
    final span = right - left;
    if (span <= 0) return;
    final rail = Paint()
      ..color = line
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, y), Offset(right, y), rail);

    // Measure ticks: taller at the ends and at the midpoint, the way an
    // engraved scale is marked.
    final count = divisions ?? 0;
    if (count > 0 && count <= 60) {
      final tick = Paint()
        ..color = line
        ..strokeWidth = 1;
      for (var i = 0; i <= count; i++) {
        final x = left + (i / count) * span;
        final major = i == 0 || i == count || (count.isEven && i == count ~/ 2);
        final half = major ? 6.0 : 2.5;
        canvas.drawLine(Offset(x, y - half), Offset(x, y + half), tick);
      }
    }

    final knobX = left + fraction * span;
    final filled = Paint()
      ..color = lineStrong
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, y), Offset(knobX, y), filled);

    // The knob is a ring, not a disc: filled circles read as Material thumbs.
    final ring = Paint()
      ..color = lineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(knobX, y), 9, ring);
    canvas.drawCircle(
      Offset(knobX, y),
      2.4,
      Paint()..color = lineStrong,
    );
  }

  @override
  bool shouldRepaint(_EterSliderPainter old) =>
      old.fraction != fraction ||
      old.divisions != divisions ||
      old.line != line ||
      old.lineStrong != lineStrong;
}

/// A hairline rule with an optional label — the section divider for instrument
/// surfaces, where [OrnamentDivider]'s star would be too much.
class EterRule extends StatelessWidget {
  const EterRule({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    final label = this.label;
    return Row(
      children: [
        if (label != null) ...[
          Text(label.toUpperCase(),
              style: text.labelSmall?.copyWith(color: ink.labelMuted)),
          const SizedBox(width: EterSpace.s16),
        ],
        Expanded(child: Container(height: 1, color: ink.line)),
      ],
    );
  }
}

/// The line glyph for an activity. Outline weights only — the filled Material
/// variants sit heavier than every hairline around them.
