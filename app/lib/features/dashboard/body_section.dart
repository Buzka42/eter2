import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/clock.dart';
import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/icons.dart';
import '../../core/health/manual_activity.dart';
import '../../core/health/manual_weight.dart';
import '../../core/instruments.dart';
import '../../core/energy/energy.dart' show SetTechnique;
import '../../core/nutrition/manual_meal.dart';
import '../../core/strength/strength_workout.dart';
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
        const SizedBox(height: EterSpace.s24),
        _ManualActivityEntry(db: db, now: now),
        const SizedBox(height: EterSpace.s24),
        _StrengthEntry(db: db, now: now),
        const SizedBox(height: EterSpace.s24),
        _ManualMealEntry(db: db, now: now),
        const SizedBox(height: EterSpace.s24),
        _HistoricalSignals(db: db, now: now, today: today),
        const SizedBox(height: EterSpace.s24),
        _ManualWeightEntry(db: db, now: now),
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

/// Strength, at the same line rhythm as `FOOD / ADD MEAL` and
/// `WEIGHT / RECORD` — because the expanded Body's density is settled and new
/// matter reuses it rather than inventing another.
///
/// At rest this is one line and one short fact about the last session. The
/// complete tracker — exercises, sets, reps, load, technique and history —
/// exists behind `Record` and nowhere else. That is the whole point of the
/// decision: full functionality, zero resting cost.
class _StrengthEntry extends StatefulWidget {
  const _StrengthEntry({required this.db, required this.now});

  final AppDatabase db;
  final DateTime now;

  @override
  State<_StrengthEntry> createState() => _StrengthEntryState();
}

class _StrengthEntryState extends State<_StrengthEntry> {
  final _exercises = <_ExerciseDraft>[];
  bool _open = false;
  bool _saving = false;
  String? _message;
  Stream<List<StrengthWorkoutRow>>? _history;

  static final _historyDate = DateFormat('d MMM');

  @override
  void dispose() {
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  Stream<List<StrengthWorkoutRow>> _historyStream() =>
      _history ??= widget.db.watchStrengthWorkouts(limit: 5);

  void _toggle() {
    setState(() {
      _open = !_open;
      _message = null;
      if (_open && _exercises.isEmpty) {
        _exercises.add(_ExerciseDraft()..sets.add(_SetDraft()));
      }
    });
  }

  void _discardDraft() {
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    _exercises.clear();
  }

  Future<void> _save() async {
    if (_saving) return;
    final composed = <StrengthExercise>[];
    for (final draft in _exercises) {
      final name = draft.name.text.trim();
      if (name.isEmpty) continue;
      final sets = <StrengthSet>[];
      for (final set in draft.sets) {
        final reps = int.tryParse(set.reps.text.trim());
        if (reps == null) continue;
        sets.add(StrengthSet(
          reps: reps,
          loadKg: double.tryParse(set.load.text.trim().replaceAll(',', '.')),
          technique: draft.technique,
        ));
      }
      if (sets.isNotEmpty) {
        composed.add(StrengthExercise(name: name, sets: sets));
      }
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final result = await StrengthWorkoutService(widget.db).record(
        exercises: composed,
        endedAt: widget.now,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _open = false;
        _discardDraft();
        _message = '${result.durationMinutes} min, '
            '${result.kcal.round()} kcal recorded.';
      });
    } on StrengthWorkoutException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = error.message;
      });
    } on ManualActivityException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // The longest label in the Body's line rhythm. At 320 dp and 200%
            // type it and its action are 0.9 px wider than the gutter allows,
            // so the eyebrow yields rather than the row overflowing.
            Flexible(
              child: Text(
                'STRENGTH',
                style: text.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: EterSpace.s8),
            const Spacer(),
            EterAction(
              label: _open ? 'Cancel' : 'Record',
              emphasis: EterActionEmphasis.quiet,
              onPressed: _saving ? null : _toggle,
            ),
          ],
        ),
        StreamBuilder<List<StrengthWorkoutRow>>(
          stream: _historyStream(),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <StrengthWorkoutRow>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rows.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: EterSpace.s4),
                    child: Text(
                      _restingFact(rows.first),
                      style: text.bodySmall,
                    ),
                  ),
                if (_open) ...[
                  const SizedBox(height: EterSpace.s16),
                  for (var index = 0; index < _exercises.length; index++)
                    _ExerciseEditor(
                      key: ObjectKey(_exercises[index]),
                      draft: _exercises[index],
                      onChanged: () => setState(() {}),
                      onRemove: _exercises.length == 1
                          ? null
                          : () => setState(() {
                                _exercises.removeAt(index).dispose();
                              }),
                    ),
                  Row(
                    children: [
                      EterAction(
                        label: 'Add exercise',
                        emphasis: EterActionEmphasis.quiet,
                        onPressed: () => setState(() {
                          _exercises.add(_ExerciseDraft()..sets.add(_SetDraft()));
                        }),
                      ),
                      const Spacer(),
                      EterAction(
                        label: _saving ? 'Keeping' : 'Keep workout',
                        emphasis: EterActionEmphasis.primary,
                        busy: _saving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                  if (rows.length > 1) ...[
                    const SizedBox(height: EterSpace.s24),
                    Text('EARLIER WORK', style: text.labelSmall),
                    const SizedBox(height: EterSpace.s4),
                    for (final row in rows.skip(1))
                      Padding(
                        padding: const EdgeInsets.only(bottom: EterSpace.s4),
                        child: Text(
                          '${_historyDate.format(row.endedAt.toLocal())}  ·  '
                          '${_shape(row)}',
                          style: text.bodySmall,
                        ),
                      ),
                  ],
                ],
              ],
            );
          },
        ),
        if (_message != null) ...[
          const SizedBox(height: EterSpace.s8),
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: text.bodySmall),
          ),
        ],
      ],
    );
  }

  String _restingFact(StrengthWorkoutRow row) {
    final local = row.endedAt.toLocal();
    final when = eterIsoDate(local) == eterIsoDate(widget.now)
        ? 'Today'
        : _historyDate.format(local);
    return '$when  ·  ${_shape(row)}';
  }

  /// One factual line — never a score, a grade or a streak.
  String _shape(StrengthWorkoutRow row) {
    final exercises = StrengthExercise.decode(row.exercisesJson);
    var sets = 0;
    var volume = 0.0;
    for (final exercise in exercises) {
      sets += exercise.sets.length;
      volume += exercise.volumeKg;
    }
    final parts = <String>[
      '${exercises.length} exercise${exercises.length == 1 ? '' : 's'}',
      '$sets set${sets == 1 ? '' : 's'}',
      if (volume > 0) '${volume.round()} kg lifted',
    ];
    return parts.join(', ');
  }
}

class _SetDraft {
  final reps = TextEditingController();
  final load = TextEditingController();

  void dispose() {
    reps.dispose();
    load.dispose();
  }
}

class _ExerciseDraft {
  final name = TextEditingController();
  final sets = <_SetDraft>[];
  SetTechnique technique = SetTechnique.normal;

  void dispose() {
    name.dispose();
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _ExerciseEditor extends StatelessWidget {
  const _ExerciseEditor({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final _ExerciseDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: EterSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Exercise',
                    hintText: 'Back squat',
                  ),
                ),
              ),
              if (onRemove != null)
                EterAction(
                  label: 'Remove',
                  emphasis: EterActionEmphasis.quiet,
                  onPressed: onRemove,
                ),
            ],
          ),
          for (var index = 0; index < draft.sets.length; index++)
            Padding(
              padding: const EdgeInsets.only(top: EterSpace.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 28,
                    // The set number is a margin annotation; sit it on the
                    // field's own baseline rather than the row's floor.
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: EterSpace.s12),
                      child: Text('${index + 1}', style: text.labelSmall),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: draft.sets[index].reps,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps'),
                    ),
                  ),
                  const SizedBox(width: EterSpace.s8),
                  Expanded(
                    child: TextField(
                      controller: draft.sets[index].load,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Load kg'),
                    ),
                  ),
                  if (draft.sets.length > 1)
                    EterAction(
                      label: 'Drop',
                      emphasis: EterActionEmphasis.quiet,
                      onPressed: () {
                        draft.sets.removeAt(index).dispose();
                        onChanged();
                      },
                    ),
                ],
              ),
            ),
          Row(
            children: [
              EterAction(
                label: 'Add set',
                emphasis: EterActionEmphasis.quiet,
                onPressed: () {
                  draft.sets.add(_SetDraft());
                  onChanged();
                },
              ),
              const Spacer(),
              // Technique changes the energy estimate, so it is recorded — but
              // it stays one quiet cycling word, not a control cluster.
              EterAction(
                label: _techniqueLabel(draft.technique),
                emphasis: EterActionEmphasis.quiet,
                onPressed: () {
                  const values = SetTechnique.values;
                  draft.technique = values[
                      (values.indexOf(draft.technique) + 1) % values.length];
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _techniqueLabel(SetTechnique technique) => switch (technique) {
        SetTechnique.normal => 'Straight sets',
        SetTechnique.superset => 'Supersets',
        SetTechnique.dropSet => 'Drop sets',
        SetTechnique.restPause => 'Rest-pause',
        SetTechnique.eccentric => 'Eccentric',
      };
}

class _ManualWeightEntry extends StatefulWidget {
  const _ManualWeightEntry({required this.db, required this.now});

  final AppDatabase db;
  final DateTime now;

  @override
  State<_ManualWeightEntry> createState() => _ManualWeightEntryState();
}

class _ManualWeightEntryState extends State<_ManualWeightEntry> {
  final _weight = TextEditingController();
  bool _open = false;
  bool _saving = false;
  String? _message;

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final kg = double.tryParse(_weight.text.trim());
    if (kg == null) {
      setState(() => _message = 'Enter weight in kilograms.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await ManualWeightService(widget.db).record(
        kg: kg,
        recordedAt: widget.now,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _open = false;
        _message = '${kg.toStringAsFixed(1)} kg recorded.';
        _weight.clear();
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = error.message.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('WEIGHT', style: text.labelSmall),
            const Spacer(),
            EterAction(
              label: _open ? 'Cancel' : 'Record',
              emphasis: EterActionEmphasis.quiet,
              onPressed: _saving
                  ? null
                  : () => setState(() {
                        _open = !_open;
                        _message = null;
                      }),
            ),
          ],
        ),
        if (_open) ...[
          const SizedBox(height: EterSpace.s8),
          TextField(
            key: const Key('manual-weight-kg'),
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              labelText: 'Weight in kilograms',
              hintText: '70.0',
            ),
          ),
          const SizedBox(height: EterSpace.s8),
          Align(
            alignment: Alignment.centerRight,
            child: EterAction(
              label: _saving ? 'Recording' : 'Record',
              emphasis: EterActionEmphasis.primary,
              busy: _saving,
              onPressed: _save,
            ),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: EterSpace.s8),
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: text.bodySmall),
          ),
        ],
      ],
    );
  }
}

class _ManualMealEntry extends StatefulWidget {
  const _ManualMealEntry({required this.db, required this.now});

  final AppDatabase db;
  final DateTime now;

  @override
  State<_ManualMealEntry> createState() => _ManualMealEntryState();
}

class _ManualMealEntryState extends State<_ManualMealEntry> {
  final _meal = TextEditingController();
  final _energy = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  bool _open = false;
  bool _saving = false;
  String? _message;

  @override
  void dispose() {
    _meal.dispose();
    _energy.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  double? _optionalNumber(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : double.tryParse(value);
  }

  Future<void> _save() async {
    if (_saving) return;
    final kcal = double.tryParse(_energy.text.trim());
    final optional = [_protein, _carbs, _fat];
    if (kcal == null ||
        optional.any(
          (controller) =>
              controller.text.trim().isNotEmpty &&
              double.tryParse(controller.text.trim()) == null,
        )) {
      setState(() => _message = 'Enter energy and optional macros as numbers.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    final name = _meal.text.trim();
    try {
      await ManualMealService(widget.db).record(
        meal: name,
        kcal: kcal,
        proteinG: _optionalNumber(_protein),
        carbsG: _optionalNumber(_carbs),
        fatG: _optionalNumber(_fat),
        recordedAt: widget.now,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _open = false;
        _message = '$name added as a confirmed food record.';
        _meal.clear();
        _energy.clear();
        _protein.clear();
        _carbs.clear();
        _fat.clear();
      });
    } on ManualMealException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('FOOD', style: text.labelSmall)),
            EterAction(
              label: _open ? 'Cancel' : 'Add meal',
              emphasis: EterActionEmphasis.quiet,
              onPressed: _saving
                  ? null
                  : () => setState(() {
                        _open = !_open;
                        _message = null;
                      }),
            ),
          ],
        ),
        if (_open) ...[
          const SizedBox(height: EterSpace.s8),
          TextField(
            key: const ValueKey('manual-meal-name'),
            controller: _meal,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Meal or food'),
          ),
          const SizedBox(height: EterSpace.s8),
          TextField(
            key: const ValueKey('manual-meal-energy'),
            controller: _energy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Energy · kcal'),
          ),
          const SizedBox(height: EterSpace.s8),
          Text(
            'OPTIONAL MACROS · GRAMS',
            style: text.labelSmall,
          ),
          const SizedBox(height: EterSpace.s4),
          for (final field in [
            (_protein, 'manual-meal-protein', 'Protein'),
            (_carbs, 'manual-meal-carbs', 'Carbohydrate'),
            (_fat, 'manual-meal-fat', 'Fat'),
          ]) ...[
            TextField(
              key: ValueKey(field.$2),
              controller: field.$1,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: field.$2 == 'manual-meal-fat'
                  ? TextInputAction.done
                  : TextInputAction.next,
              onSubmitted:
                  field.$2 == 'manual-meal-fat' ? (_) => _save() : null,
              decoration: InputDecoration(labelText: field.$3),
            ),
            const SizedBox(height: EterSpace.s8),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: EterAction(
              label: _saving ? 'Adding' : 'Add',
              emphasis: EterActionEmphasis.primary,
              busy: _saving,
              onPressed: _save,
            ),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: EterSpace.s8),
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: text.bodySmall),
          ),
        ],
      ],
    );
  }
}

class _ManualActivityEntry extends StatefulWidget {
  const _ManualActivityEntry({required this.db, required this.now});

  final AppDatabase db;
  final DateTime now;

  @override
  State<_ManualActivityEntry> createState() => _ManualActivityEntryState();
}

class _ManualActivityEntryState extends State<_ManualActivityEntry> {
  final _activity = TextEditingController();
  final _duration = TextEditingController();
  final _energy = TextEditingController();
  bool _open = false;
  bool _saving = false;
  String? _message;

  @override
  void dispose() {
    _activity.dispose();
    _duration.dispose();
    _energy.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final duration = int.tryParse(_duration.text.trim());
    final kcal = double.tryParse(_energy.text.trim());
    if (duration == null || kcal == null) {
      setState(() => _message = 'Enter duration and active energy as numbers.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await ManualActivityService(widget.db).record(
        activity: _activity.text,
        durationMinutes: duration,
        activeKcal: kcal,
        endedAt: widget.now,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _open = false;
        _message = '${_activity.text.trim()} added to today.';
        _activity.clear();
        _duration.clear();
        _energy.clear();
      });
    } on ManualActivityException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('ACTIVITY', style: text.labelSmall)),
            EterAction(
              label: _open ? 'Cancel' : 'Add activity',
              emphasis: EterActionEmphasis.quiet,
              onPressed: _saving
                  ? null
                  : () => setState(() {
                        _open = !_open;
                        _message = null;
                      }),
            ),
          ],
        ),
        if (_open) ...[
          const SizedBox(height: EterSpace.s8),
          TextField(
            key: const ValueKey('manual-activity-name'),
            controller: _activity,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Activity'),
          ),
          const SizedBox(height: EterSpace.s8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('manual-activity-duration'),
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(labelText: 'Duration · minutes'),
                ),
              ),
              const SizedBox(width: EterSpace.s12),
              Expanded(
                child: TextField(
                  key: const ValueKey('manual-activity-energy'),
                  controller: _energy,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _save(),
                  decoration:
                      const InputDecoration(labelText: 'Active energy · kcal'),
                ),
              ),
            ],
          ),
          const SizedBox(height: EterSpace.s8),
          Align(
            alignment: Alignment.centerRight,
            child: EterAction(
              label: _saving ? 'Adding' : 'Add',
              emphasis: EterActionEmphasis.primary,
              busy: _saving,
              onPressed: _save,
            ),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: EterSpace.s8),
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: text.bodySmall),
          ),
        ],
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
                style: text.bodyMedium,
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
