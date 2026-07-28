import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../energy/energy.dart' as energy;
import '../health/manual_activity.dart';

/// Strength, recorded in full — sets, reps and load — but never on the resting
/// screen (steering decision, 28 July 2026: complete functionality behind
/// progressive disclosure).
///
/// This module owns the record itself. Two rules make it more than a note:
///
/// * **Energy is derived, not typed.** The spec-08 MET fallback runs over the
///   real sets and reps, with EPOC applied once at workout level. The user is
///   never asked to guess a calorie figure for lifting.
/// * **Burn reaches the day through the one canonical path.** The session is
///   written by [ManualActivityService], so strength minutes deduplicate
///   against watch and phone minutes through the same priority ladder instead
///   of being added on top of them.
class StrengthSet {
  const StrengthSet({
    required this.reps,
    this.loadKg,
    this.technique = energy.SetTechnique.normal,
  });

  final int reps;

  /// Absent for bodyweight work. Load is recorded because it is the point of
  /// the log; it does not enter the energy estimate, which is MET-based.
  final double? loadKg;
  final energy.SetTechnique technique;

  Map<String, Object?> toJson() => {
        'reps': reps,
        if (loadKg != null) 'loadKg': loadKg,
        'technique': technique.name,
      };

  static StrengthSet fromJson(Map<String, Object?> json) => StrengthSet(
        reps: (json['reps'] as num).round(),
        loadKg: (json['loadKg'] as num?)?.toDouble(),
        technique: energy.SetTechnique.values.firstWhere(
          (value) => value.name == json['technique'],
          orElse: () => energy.SetTechnique.normal,
        ),
      );
}

class StrengthExercise {
  const StrengthExercise({
    required this.name,
    required this.sets,
    this.metHint = 5.0,
    this.restSecPerGap = 90,
  });

  final String name;
  final List<StrengthSet> sets;

  /// Compendium MET for the movement. 5.0 is the general resistance-training
  /// value and the honest default when the movement is unknown.
  final double metHint;
  final double restSecPerGap;

  double get volumeKg {
    var total = 0.0;
    for (final set in sets) {
      total += (set.loadKg ?? 0) * set.reps;
    }
    return total;
  }

  Map<String, Object?> toJson() => {
        'name': name,
        'metHint': metHint,
        'restSecPerGap': restSecPerGap,
        'sets': [for (final set in sets) set.toJson()],
      };

  static StrengthExercise fromJson(Map<String, Object?> json) =>
      StrengthExercise(
        name: json['name'] as String,
        metHint: (json['metHint'] as num?)?.toDouble() ?? 5.0,
        restSecPerGap: (json['restSecPerGap'] as num?)?.toDouble() ?? 90,
        sets: [
          for (final set in (json['sets'] as List<Object?>? ?? const []))
            StrengthSet.fromJson(set as Map<String, Object?>),
        ],
      );

  /// Seconds of work and counted rest, by the spec-08 shape.
  double activeSeconds() {
    if (sets.isEmpty) return 0;
    var work = 0.0;
    for (final set in sets) {
      work += set.reps * 3;
    }
    return work + (sets.length - 1) * restSecPerGap * 0.35;
  }

  double fallbackKcal(double weightKg) {
    if (sets.isEmpty) return 0;
    var reps = 0;
    for (final set in sets) {
      reps += set.reps;
    }
    // The formula takes one reps-per-set figure; the recorded sets are rarely
    // uniform, so it receives their mean and the set count they actually have.
    return energy.exerciseFallbackKcal(
      metHint: metHint,
      weightKg: weightKg,
      sets: sets.length,
      repsPerSet: (reps / sets.length).round(),
      restSecPerGap: restSecPerGap,
      technique: sets.first.technique,
    );
  }

  static List<StrengthExercise> decode(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map<String, Object?>) StrengthExercise.fromJson(item),
    ];
  }
}

class StrengthWorkoutResult {
  const StrengthWorkoutResult({
    required this.workoutId,
    required this.kcal,
    required this.durationMinutes,
    required this.volumeKg,
  });

  final String workoutId;
  final double kcal;
  final int durationMinutes;
  final double volumeKg;
}

class StrengthWorkoutException implements Exception {
  const StrengthWorkoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StrengthWorkoutService {
  const StrengthWorkoutService(this.database);

  final AppDatabase database;

  /// Commits a composed workout. [endedAt] is when the last set was finished;
  /// the session's start is derived from the work it contains rather than
  /// asked for, so recording after the fact stays a two-field job.
  Future<StrengthWorkoutResult> record({
    required List<StrengthExercise> exercises,
    required DateTime endedAt,
  }) async {
    final usable = [
      for (final exercise in exercises)
        if (exercise.name.trim().isNotEmpty && exercise.sets.isNotEmpty)
          exercise,
    ];
    if (usable.isEmpty) {
      throw const StrengthWorkoutException(
        'Add one exercise with at least one set.',
      );
    }
    for (final exercise in usable) {
      for (final set in exercise.sets) {
        if (set.reps < 1 || set.reps > 500) {
          throw const StrengthWorkoutException(
            'Each set holds between 1 and 500 reps.',
          );
        }
        final load = set.loadKg;
        if (load != null && (!load.isFinite || load < 0 || load > 1000)) {
          throw const StrengthWorkoutException(
            'Load must be between 0 and 1,000 kg.',
          );
        }
      }
    }

    final profile = await database.loadProfile();
    final weightKg = profile?.weightKg;
    if (weightKg == null || weightKg <= 0) {
      throw const StrengthWorkoutException(
        'Record a body weight first; strength energy is estimated from it.',
      );
    }

    var seconds = 0.0;
    var fallback = 0.0;
    var volume = 0.0;
    for (final exercise in usable) {
      seconds += exercise.activeSeconds();
      fallback += exercise.fallbackKcal(weightKg);
      volume += exercise.volumeKg;
    }
    final kcal = energy.applyEpoc(fallback);
    final minutes = (seconds / 60).ceil().clamp(1, 1440);

    // The canonical deduplicated write. Strength does not get a private route
    // into the day's burn.
    final session = await ManualActivityService(database).record(
      activity: 'Strength',
      durationMinutes: minutes,
      activeKcal: kcal,
      endedAt: endedAt,
    );

    await database.upsertStrengthWorkout(
      StrengthWorkoutsCompanion.insert(
        id: session.sessionId,
        startedAt:
            endedAt.toUtc().subtract(Duration(minutes: session.durationMinutes)),
        endedAt: endedAt.toUtc(),
        bodyWeightKgAtTime: weightKg,
        exercisesJson: jsonEncode([
          for (final exercise in usable) exercise.toJson(),
        ]),
        fallbackKcal: fallback,
        finalKcal: kcal,
        method: const Value('fallback'),
      ),
    );

    return StrengthWorkoutResult(
      workoutId: session.sessionId,
      kcal: kcal,
      durationMinutes: session.durationMinutes,
      volumeKg: volume,
    );
  }
}
