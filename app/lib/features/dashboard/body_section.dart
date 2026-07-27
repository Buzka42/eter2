import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/clock.dart';
import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/instruments.dart';
import '../../core/tokens.dart';
import '../../main.dart';
import '../prototype/fixtures.dart';

/// The Body disclosure and its in-place expansion.
///
/// Collapsed, it is one quiet line: the word `Body`, at most one short
/// textual fact, and a conventional chevron — no metric strip, no sparkline.
/// Expanded, it begins with its conclusion in words, then shows one
/// instrument — the engraved intake/burn balance — and offers an explicit
/// close. It never leads with a chart, and it says what it cannot see: an
/// unlogged day is stated as an absence, never rendered as a zero.
class BodySection extends ConsumerStatefulWidget {
  const BodySection({
    super.key,
    required this.expanded,
    required this.onToggle,
  });

  final bool expanded;
  final ValueChanged<bool> onToggle;

  @override
  ConsumerState<BodySection> createState() => _BodySectionState();
}

class _BodySectionState extends ConsumerState<BodySection> {
  static final _numbers = NumberFormat('#,##0');

  Stream<DaySummaryRow?>? _summaryStream;
  Stream<DailyVitalsRow?>? _vitalsStream;
  Stream<List<NutritionEntryRow>>? _nutritionStream;
  String? _streamedDay;

  /// Cached streams: a fresh watch*() per build would resubscribe all three
  /// StreamBuilders on every animation frame.
  void _ensureStreams(AppDatabase db, String today, DateTime now) {
    if (_streamedDay == today && _summaryStream != null) return;
    _streamedDay = today;
    final (dayStart, dayEnd) = eterDayBounds(now);
    _summaryStream = db.watchDaySummary(today);
    _vitalsStream = db.watchVitals(today);
    _nutritionStream = db.watchNutritionForRange(dayStart, dayEnd);
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final now = ref.watch(nowProvider)();
    final today = eterIsoDate(now);
    _ensureStreams(db, today, now);
    final ink = EterInk.of(context);

    return StreamBuilder<DaySummaryRow?>(
      stream: _summaryStream,
      builder: (context, summarySnap) {
        return StreamBuilder<DailyVitalsRow?>(
          stream: _vitalsStream,
          builder: (context, vitalsSnap) {
            return StreamBuilder<List<NutritionEntryRow>>(
              stream: _nutritionStream,
              builder: (context, nutritionSnap) {
                final summary = summarySnap.data;
                final vitals = vitalsSnap.data;
                final meals = nutritionSnap.data ?? const <NutritionEntryRow>[];
                final confirmed = meals.where((m) => m.confirmed).toList();
                final intake = confirmed.isEmpty
                    ? null
                    : confirmed.fold<double>(0, (sum, m) => sum + m.kcal);
                final burn = summary == null
                    ? null
                    : summary.activeKcal + summary.basalKcal;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 1, color: ink.line),
                    if (!widget.expanded)
                      _DisclosureLine(
                        fact: _fact(vitals, summary),
                        onTap: () => widget.onToggle(true),
                      )
                    else
                      _ExpandedHeader(onClose: () => widget.onToggle(false)),
                    AnimatedSize(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? EterMotion.durMicro
                          : EterMotion.durEmphasis,
                      curve: EterMotion.easeAir,
                      alignment: Alignment.topCenter,
                      child: widget.expanded
                          ? _ExpandedBody(
                              db: db,
                              conclusion:
                                  _conclusion(intake: intake, burn: burn),
                              vitals: vitals,
                              meals: meals,
                              intake: intake,
                              burn: burn,
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// One short textual fact beside the word `Body` — never a metric row.
  String? _fact(DailyVitalsRow? vitals, DaySummaryRow? summary) {
    final resting = vitals?.restingHr;
    if (resting != null) return '${resting.round()} bpm resting';
    final steps = summary?.steps ?? 0;
    if (steps > 0) return '${_numbers.format(steps)} steps';
    return null;
  }

  /// The section opens with its conclusion, in words, before any instrument.
  String _conclusion({required double? intake, required double? burn}) {
    if (intake == null && (burn == null || burn <= 0)) {
      return 'No activity or food has been recorded yet today.';
    }
    if (intake == null) {
      return 'Nothing has been logged to eat yet today.';
    }
    if (burn == null || burn <= 0) {
      return '${_numbers.format(intake)} kcal logged; '
          'activity has not been recorded yet.';
    }
    final eaten = _numbers.format(intake);
    final burned = _numbers.format(burn);
    final difference = intake - burn;
    if (difference.abs() < 150) {
      return 'Intake and burn sit close to level — '
          '$eaten kcal eaten against $burned kcal burned.';
    }
    return difference > 0
        ? 'A little over today — $eaten kcal eaten against $burned kcal burned.'
        : 'A little under today — $eaten kcal eaten against $burned kcal burned.';
  }
}

class _DisclosureLine extends StatelessWidget {
  const _DisclosureLine({required this.fact, required this.onTap});

  final String? fact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      expanded: false,
      label: 'The Body',
      hint: 'expands health details',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Text('THE BODY',
                  style: text.labelSmall?.copyWith(color: ink.label)),
              if (fact != null) ...[
                const SizedBox(width: EterSpace.s8),
                Expanded(
                  child: Text(
                    fact!,
                    maxLines: 2,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: ink.labelMuted),
                  ),
                ),
              ] else
                const Spacer(),
              const SizedBox(width: EterSpace.s8),
              Icon(Icons.chevron_right, size: 18, color: ink.labelMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedHeader extends StatelessWidget {
  const _ExpandedHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Text('THE BODY', style: text.labelSmall?.copyWith(color: ink.label)),
        const Spacer(),
        EterAction(
          label: 'Close',
          emphasis: EterActionEmphasis.quiet,
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.db,
    required this.conclusion,
    required this.vitals,
    required this.meals,
    required this.intake,
    required this.burn,
  });

  final AppDatabase db;
  final String conclusion;
  final DailyVitalsRow? vitals;
  final List<NutritionEntryRow> meals;
  final double? intake;
  final double? burn;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final proseStyle = text.headlineSmall?.copyWith(
      fontSize: 18,
      height: 27 / 18,
      fontWeight: FontWeight.w400,
    );
    final showBalance = intake != null && burn != null && burn! > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: EterSpace.s4),
        Text(conclusion, style: proseStyle),
        if (meals.any((meal) => !meal.confirmed)) ...[
          const SizedBox(height: EterSpace.s8),
          Text(
            'One food estimate is waiting below. It is not included in the '
            'balance until you confirm or correct it.',
            style: text.bodySmall,
          ),
        ],
        const SizedBox(height: EterSpace.s24),
        _SignalSummary(vitals: vitals),
        if (showBalance) ...[
          const SizedBox(height: EterSpace.s16),
          EngravedBalance(
            intake: intake!,
            burn: burn!,
            tilt: ((intake! - burn!) / burn! * 12).clamp(-9.0, 9.0),
          ),
        ],
        if (meals.isNotEmpty) ...[
          const SizedBox(height: EterSpace.s24),
          Text('FOOD NOTES', style: text.labelSmall),
          const SizedBox(height: EterSpace.s8),
          for (final meal in meals)
            _NutritionLine(
              key: ValueKey('nutrition-${meal.id}'),
              db: db,
              meal: meal,
            ),
        ],
        const SizedBox(height: EterSpace.s24),
      ],
    );
  }
}

class _SignalSummary extends StatelessWidget {
  const _SignalSummary({required this.vitals});

  final DailyVitalsRow? vitals;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (vitals == null ||
        (vitals!.restingHr == null &&
            vitals!.hrvMs == null &&
            vitals!.respiratoryRate == null)) {
      return Text(
        'No wearable recovery signals are available today.',
        style: text.bodyMedium,
      );
    }
    final parts = <String>[
      if (vitals!.restingHr != null)
        '${vitals!.restingHr!.round()} bpm resting heart rate',
      if (vitals!.hrvMs != null) '${vitals!.hrvMs!.round()} ms HRV',
      if (vitals!.respiratoryRate != null)
        '${vitals!.respiratoryRate!.toStringAsFixed(1)} breaths per minute',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECOVERY SIGNALS', style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        Text(parts.join(' · '), style: text.bodyMedium),
      ],
    );
  }
}

class _NutritionLine extends StatefulWidget {
  const _NutritionLine({
    super.key,
    required this.db,
    required this.meal,
  });

  final AppDatabase db;
  final NutritionEntryRow meal;

  @override
  State<_NutritionLine> createState() => _NutritionLineState();
}

class _NutritionLineState extends State<_NutritionLine> {
  late final TextEditingController _kcal;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _kcal = TextEditingController(text: widget.meal.kcal.round().toString());
  }

  @override
  void didUpdateWidget(_NutritionLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.meal.kcal != widget.meal.kcal) {
      _kcal.text = widget.meal.kcal.round().toString();
    }
  }

  @override
  void dispose() {
    _kcal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_kcal.text.trim());
    if (value == null || value <= 0 || _saving) return;
    setState(() => _saving = true);
    await widget.db.updateNutritionEntry(
      widget.meal.id,
      NutritionEntriesCompanion(
        kcal: Value(value),
        confirmed: const Value(true),
      ),
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _editing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ink.line, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: EterSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.meal.meal, style: text.bodyMedium),
                    const SizedBox(height: EterSpace.s4),
                    Text(
                      widget.meal.confirmed
                          ? '${widget.meal.kcal.round()} kcal'
                          : 'ESTIMATE · ${widget.meal.kcal.round()} KCAL · '
                              'NOT COUNTED',
                      style: text.labelSmall?.copyWith(
                        color: widget.meal.confirmed
                            ? ink.labelMuted
                            : ink.lineStrong,
                      ),
                    ),
                  ],
                ),
              ),
              EterAction(
                label: _editing
                    ? (_saving ? 'Saving' : 'Confirm')
                    : (widget.meal.confirmed ? 'Edit' : 'Review'),
                emphasis: EterActionEmphasis.quiet,
                busy: _saving,
                onPressed:
                    _editing ? _save : () => setState(() => _editing = true),
              ),
            ],
          ),
          if (_editing) ...[
            const SizedBox(height: EterSpace.s8),
            Row(
              children: [
                SizedBox(
                  width: 88,
                  child: TextField(
                    key: ValueKey('nutrition-kcal-${widget.meal.id}'),
                    controller: _kcal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'kcal',
                    ),
                  ),
                ),
                const SizedBox(width: EterSpace.s12),
                Expanded(
                  child: Text(
                    'Correct the estimate before it enters today’s total.',
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
