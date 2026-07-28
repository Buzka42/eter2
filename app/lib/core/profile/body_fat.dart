import 'package:flutter/material.dart';

import '../controls.dart';
import '../tokens.dart';

/// Optional body composition, on the scale people actually estimate in.
///
/// Kept out of the required intake on purpose. Most people do not know this
/// number, several of the ways to find it are wrong, and asking for it as a
/// required field would either produce a guess or stop the intake. Absent is
/// the honest default and the common case.
///
/// When it *is* given it earns its place twice: resting burn can be derived
/// from lean mass rather than body mass, and guidance can speak about
/// composition instead of a single number on a scale.
abstract final class EterBodyFat {
  static const double min = 5;
  static const double max = 40;
  static const double step = 2.5;

  static int get divisions => ((max - min) / step).round();

  /// Snaps to the nearest allowed mark and refuses anything outside the range,
  /// so a stored value always matches something the control can show.
  static double? normalize(double? value) {
    if (value == null || !value.isFinite) return null;
    if (value < min - step / 2 || value > max + step / 2) return null;
    final snapped = ((value - min) / step).round() * step + min;
    return snapped.clamp(min, max);
  }

  static String format(double value) {
    final rounded = value.roundToDouble() == value;
    return rounded
        ? '${value.toStringAsFixed(0)}%'
        : '${value.toStringAsFixed(1)}%';
  }
}

/// One quiet line that stays a line until it is wanted.
///
/// At rest: `BODY FAT — optional` and either the value or an em dash. Tapping
/// opens the rail; `Not given` returns it to absent, because a control that
/// can only ever be set is a trap.
class BodyFatField extends StatefulWidget {
  const BodyFatField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  State<BodyFatField> createState() => _BodyFatFieldState();
}

class _BodyFatFieldState extends State<BodyFatField> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final value = EterBodyFat.normalize(widget.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          label: value == null
              ? 'Body fat, optional, not given'
              : 'Body fat ${EterBodyFat.format(value)}',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    // Sentence case, like the fields it sits among. In caps it
                    // read as a section heading for whatever followed it.
                    child: Text(
                      'Body fat — optional',
                      style: text.bodyMedium?.copyWith(color: ink.label),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: EterSpace.s8),
                  Text(
                    value == null ? '—' : EterBodyFat.format(value),
                    style: text.bodyMedium?.copyWith(
                      color: value == null ? ink.labelMuted : ink.label,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open) ...[
          EterSlider(
            value: value ?? 20,
            min: EterBodyFat.min,
            max: EterBodyFat.max,
            divisions: EterBodyFat.divisions,
            semanticFormatter: EterBodyFat.format,
            onChanged: (next) =>
                widget.onChanged(EterBodyFat.normalize(next)),
          ),
          const SizedBox(height: EterSpace.s4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Only if you know it. Eter never estimates this from your '
                  'weight, and leaves it out of every calculation when it is '
                  'absent.',
                  style: text.bodySmall,
                ),
              ),
              if (value != null)
                EterAction(
                  label: 'Not given',
                  emphasis: EterActionEmphasis.quiet,
                  onPressed: () => widget.onChanged(null),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
