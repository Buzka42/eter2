import '../db/app_database.dart';
import '../health/manual_activity.dart';
import '../health/manual_weight.dart';
import '../strength/strength_workout.dart';
import 'classification_contract.dart';
import '../health/record_error.dart';

/// The route from a journal page to the body log.
///
/// Food and lifestyle have gone straight into their own tables since
/// interpretation existed. Weight, activity and strength could not, because
/// they belong to services with real arithmetic behind them — deduplication
/// into minute buckets, MET-based energy, a resting-burn rebuild — and writing
/// their rows directly from the journal would have produced totals that
/// disagreed with the same work logged by hand.
///
/// So this commits through those services rather than around them. A run
/// written in the Journal lands exactly where a run entered manually lands,
/// and the day's numbers cannot depend on which surface recorded it.
///
/// It runs after the classification transaction rather than inside it: the
/// services rebuild day summaries as they write, which is not work that
/// belongs in a transaction holding the journal row. `appliedAt` on the entry
/// is what makes that safe — an entry already applied is never re-committed.
class JournalBodyCommitter {
  const JournalBodyCommitter(this.database);

  final AppDatabase database;

  /// Commits everything [classification] produced for the body log, and
  /// reports what it wrote.
  ///
  /// Failures are collected rather than thrown: a page mentioning both a
  /// weight and a workout should not lose the weight because the workout had
  /// no body weight to estimate from. The caller decides what to say about a
  /// partial commit.
  Future<JournalBodyCommitResult> commit({
    required JournalClassification classification,
    required DateTime recordedAt,
  }) async {
    final failures = <BodyRecordError>[];
    var weights = 0;
    var activities = 0;
    var workouts = 0;

    for (final observation in classification.weight) {
      try {
        await ManualWeightService(database).record(
          kg: observation.kg,
          recordedAt: recordedAt,
        );
        weights += 1;
      } on ManualWeightException catch (error) {
        failures.add(error.error);
      }
    }

    for (final observation in classification.activity) {
      try {
        await ManualActivityService(database).record(
          activity: observation.activity,
          durationMinutes: observation.durationMinutes,
          activeKcal: observation.kcal,
          endedAt: recordedAt,
        );
        activities += 1;
      } on ManualActivityException catch (error) {
        failures.add(error.error);
      }
    }

    if (classification.strength.isNotEmpty) {
      try {
        await StrengthWorkoutService(database).record(
          exercises: [
            for (final exercise in classification.strength)
              StrengthExercise(
                name: exercise.name,
                sets: [
                  for (final set in exercise.sets)
                    StrengthSet(reps: set.reps, loadKg: set.loadKg),
                ],
              ),
          ],
          endedAt: recordedAt,
        );
        workouts = 1;
      } on StrengthWorkoutException catch (error) {
        failures.add(error.error);
      }
    }

    return JournalBodyCommitResult(
      weights: weights,
      activities: activities,
      workouts: workouts,
      failures: List.unmodifiable(failures),
    );
  }
}

class JournalBodyCommitResult {
  const JournalBodyCommitResult({
    required this.weights,
    required this.activities,
    required this.workouts,
    required this.failures,
  });

  final int weights;
  final int activities;
  final int workouts;

  /// Human-readable reasons, in the services' own words, for anything the
  /// page described that could not be committed.
  /// Bounds that were exceeded, in the order they were hit. Worded by the
  /// surface — see `EterStrings.bodyRecordError`.
  final List<BodyRecordError> failures;

  bool get wroteNothing => weights == 0 && activities == 0 && workouts == 0;
}
