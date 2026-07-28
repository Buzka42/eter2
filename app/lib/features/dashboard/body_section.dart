import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/clock.dart';
import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/icons.dart';
import '../../core/instruments.dart';
import '../../core/tokens.dart';
import '../../main.dart';

/// The Body disclosure and its in-place expansion.
///
/// Collapsed, it is one quiet line: the word `Body`, at most one short
/// textual fact, and Eter's thread disclosure mark — no metric strip or
/// sparkline.
/// Expanded, it begins with its conclusion in words, then shows one
/// instrument — the engraved intake/burn balance — and offers an explicit
/// close. It never leads with a chart, and it says what it cannot see: an
/// unlogged day is stated as an absence, never rendered as a zero.
///
/// **The Dashboard reads; the Journal writes** (product rule, 28 July 2026).
/// Every capture control this section used to carry — add activity, add meal,
/// record strength, record weight — has been removed. Recording happens by
/// writing a page and letting interpretation derive from it, or in the Sanctum
/// for settings. The write services behind those controls are untouched and
/// still tested: what moved is the surface, not the capability.
///
/// The one interaction that remains is correcting a *derived* food estimate,
/// which is review of something the Journal produced rather than new input,
/// and which the brief requires before an estimate may count.
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
                              now: now,
                              today: today,
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
              const EterDisclosureMark(),
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
    required this.now,
    required this.today,
    required this.conclusion,
    required this.vitals,
    required this.meals,
    required this.intake,
    required this.burn,
  });

  final AppDatabase db;
  final DateTime now;
  final String today;
  final String conclusion;
  final DailyVitalsRow? vitals;
  final List<NutritionEntryRow> meals;
  final double? intake;
  final double? burn;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final proseStyle = EterProse.of(context);
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
        // One reading order, and it is a reading order: conclusion, then
        // today's instruments, then history. Capture used to be interleaved
        // here — activity, strength and food above the trends, weight below
        // them — which is why the section shuffled between telling you
        // something and asking you for something. Nothing on this surface
        // asks any more (see the class comment).
        const SizedBox(height: EterSpace.s24),
        _HistoricalSignals(db: db, now: now, today: today),
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

class _HistoricalSignals extends StatefulWidget {
  const _HistoricalSignals({
    required this.db,
    required this.now,
    required this.today,
  });

  final AppDatabase db;
  final DateTime now;
  final String today;

  @override
  State<_HistoricalSignals> createState() => _HistoricalSignalsState();
}

class _HistoricalSignalsState extends State<_HistoricalSignals> {
  late Future<List<DailyVitalsRow>> _vitals;
  late Future<List<SleepSegmentRow>> _sleepHistory;
  late Stream<List<SleepSegmentRow>> _sleep;
  late Stream<List<MinuteBucketRow>> _activity;
  late Stream<List<WeightEntryRow>> _weight;
  int _sleepWindow = 7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_HistoricalSignals oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.db != widget.db || oldWidget.today != widget.today) _load();
  }

  void _load() {
    _vitals = widget.db.loadVitalsRange(
      eterIsoDate(widget.now.subtract(const Duration(days: 29))),
      widget.today,
    );
    _sleep = widget.db.watchSleepForNight(widget.today);
    _loadSleepHistory();
    final (dayStart, dayEnd) = eterDayBounds(widget.now);
    _activity = widget.db.watchMinuteBuckets(dayStart, dayEnd);
    _weight = widget.db.watchWeightEntries(limit: 30);
  }

  void _loadSleepHistory() {
    _sleepHistory = widget.db.loadSleepForNights(
      eterIsoDate(widget.now.subtract(Duration(days: _sleepWindow - 1))),
      widget.today,
    );
  }

  void _selectSleepWindow(int days) {
    if (_sleepWindow == days) return;
    setState(() {
      _sleepWindow = days;
      _loadSleepHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<DailyVitalsRow>>(
          future: _vitals,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <DailyVitalsRow>[];
            final heartRate = [
              for (final row in rows)
                if (row.restingHr != null) row.restingHr!,
            ];
            final hrv = [
              for (final row in rows)
                if (row.hrvMs != null) row.hrvMs!,
            ];
            if (heartRate.length < 2 && hrv.length < 2) {
              return Text(
                'A historical recovery trend is not available yet.',
                style: text.bodyMedium,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heartRate.length >= 2) ...[
                  Text('RESTING HEART RATE', style: text.labelSmall),
                  EngravedTrend(
                    values: heartRate,
                    label: 'Resting heart rate trend',
                    unit: 'bpm',
                  ),
                  const SizedBox(height: EterSpace.s16),
                ],
                if (hrv.length >= 2) ...[
                  Text('HEART RATE VARIABILITY', style: text.labelSmall),
                  EngravedTrend(
                    values: hrv,
                    label: 'Heart rate variability trend',
                    unit: 'ms',
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: EterSpace.s24),
        StreamBuilder<List<SleepSegmentRow>>(
          stream: _sleep,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <SleepSegmentRow>[];
            if (rows.isEmpty) {
              return Text(
                'Sleep stages were not provided for last night.',
                // Absence is the section speaking, not a label: it takes the
                // same serif prose as the conclusion above it. Two sentences
                // of the same kind in two different faces reads as a bug,
                // because it is one.
                style: EterProse.of(context),
              );
            }
            final minutes = <String, int>{};
            for (final row in rows) {
              final duration = row.endUtc.difference(row.startUtc).inMinutes;
              minutes.update(
                row.stage,
                (value) => value + duration,
                ifAbsent: () => duration,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LAST NIGHT', style: text.labelSmall),
                const SizedBox(height: EterSpace.s8),
                EngravedSleepStages(minutesByStage: minutes),
              ],
            );
          },
        ),
        const SizedBox(height: EterSpace.s24),
        Text('SLEEP HISTORY', style: text.labelSmall),
        Row(
          children: [
            _PeriodChoice(
              label: '7 days',
              selected: _sleepWindow == 7,
              onTap: () => _selectSleepWindow(7),
            ),
            const SizedBox(width: EterSpace.s16),
            _PeriodChoice(
              label: '30 days',
              selected: _sleepWindow == 30,
              onTap: () => _selectSleepWindow(30),
            ),
          ],
        ),
        FutureBuilder<List<SleepSegmentRow>>(
          future: _sleepHistory,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <SleepSegmentRow>[];
            final byNight = <String, Map<String, int>>{};
            for (final row in rows) {
              final night =
                  byNight.putIfAbsent(row.nightOf, () => <String, int>{});
              final minutes = row.endUtc.difference(row.startUtc).inMinutes;
              night.update(
                row.stage,
                (value) => value + minutes,
                ifAbsent: () => minutes,
              );
            }
            if (byNight.length < 2) {
              return Text(
                'A sleep history needs at least two recorded nights.',
                style: text.bodyMedium,
              );
            }
            return EngravedSleepHistory(
              nights: byNight.values.toList(),
              windowDays: _sleepWindow,
            );
          },
        ),
        const SizedBox(height: EterSpace.s24),
        StreamBuilder<List<WeightEntryRow>>(
          stream: _weight,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <WeightEntryRow>[];
            if (rows.length < 2) {
              return Text(
                'A weight trend needs at least two entries.',
                style: text.bodyMedium,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WEIGHT', style: text.labelSmall),
                EngravedTrend(
                  values: rows.reversed.map((row) => row.kg).toList(),
                  label: 'Weight trend',
                  unit: 'kg',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: EterSpace.s24),
        StreamBuilder<List<MinuteBucketRow>>(
          stream: _activity,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <MinuteBucketRow>[];
            if (rows.isEmpty) {
              return Text(
                'Activity by time of day is unavailable until minute-level '
                'movement data is connected.',
                style: text.bodySmall,
              );
            }
            final hourly = List<double>.filled(24, 0);
            for (final row in rows) {
              hourly[row.minuteUtc.toLocal().hour] += row.activeKcal;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVITY BY TIME', style: text.labelSmall),
                const SizedBox(height: EterSpace.s8),
                EngravedActivityDay(kcalByHour: hourly),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PeriodChoice extends StatelessWidget {
  const _PeriodChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? ink.lineStrong : ink.labelMuted,
                    decoration: selected
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: ink.lineStrong,
                  ),
            ),
          ),
        ),
      ),
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
        style: EterProse.of(context),
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
