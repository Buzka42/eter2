import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:eter/core/clock.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/energy/energy.dart' as energy;
import 'package:eter/core/strength/strength_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  final endedAt = DateTime(2026, 7, 28, 18, 30);

  Future<void> seedProfile({double? weightKg = 80}) => db.saveProfile(
        ProfilesCompanion.insert(
          dob: DateTime(1990, 1, 1),
          sex: 'other',
          weightKg: weightKg ?? 0,
          heightCm: const Value(180),
          units: 'metric',
        ),
      );

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  const squat = StrengthExercise(
    name: 'Back squat',
    sets: [
      StrengthSet(reps: 5, loadKg: 100),
      StrengthSet(reps: 5, loadKg: 100),
      StrengthSet(reps: 5, loadKg: 110),
    ],
  );

  test('a workout records its sets, load and derived energy', () async {
    await seedProfile();

    final result = await StrengthWorkoutService(db).record(
      exercises: [squat],
      endedAt: endedAt,
    );

    final rows = await db.watchStrengthWorkouts().first;
    expect(rows, hasLength(1));
    final stored = StrengthExercise.decode(rows.single.exercisesJson);
    expect(stored.single.name, 'Back squat');
    expect(stored.single.sets.map((set) => set.reps), [5, 5, 5]);
    expect(stored.single.sets.last.loadKg, 110);
    expect(rows.single.bodyWeightKgAtTime, 80);
    // Load is recorded but does not enter the MET estimate.
    expect(result.volumeKg, 5 * 100 + 5 * 100 + 5 * 110);
    expect(result.kcal, closeTo(energy.applyEpoc(rows.single.fallbackKcal), 1e-9));
    expect(rows.single.endedAt, endedAt.toUtc());
  });

  test('strength burn reaches the day through the deduplicated path',
      () async {
    await seedProfile();

    final result = await StrengthWorkoutService(db).record(
      exercises: [squat],
      endedAt: endedAt,
    );

    final sessions = await db.select(db.activitySessions).get();
    expect(sessions, hasLength(1));
    expect(sessions.single.id, result.workoutId);
    expect(sessions.single.sport, 'Strength');
    expect(
      sessions.single.priority,
      energy.SourcePriority.manualStrength.index,
    );

    final (start, end) = eterDayBounds(endedAt);
    final summary = await db.loadDaySummary(eterIsoDate(endedAt));
    expect(summary, isNotNull);
    expect(summary!.activeKcal, greaterThan(0));
    expect(start.isBefore(end), isTrue);
  });

  test('a workout without usable sets writes nothing', () async {
    await seedProfile();

    await expectLater(
      StrengthWorkoutService(db).record(
        exercises: const [StrengthExercise(name: 'Back squat', sets: [])],
        endedAt: endedAt,
      ),
      throwsA(isA<StrengthWorkoutException>()),
    );

    expect(await db.watchStrengthWorkouts().first, isEmpty);
    expect(await db.select(db.activitySessions).get(), isEmpty);
  });

  test('strength is not estimated without a recorded body weight', () async {
    await expectLater(
      StrengthWorkoutService(db).record(
        exercises: [squat],
        endedAt: endedAt,
      ),
      throwsA(isA<StrengthWorkoutException>()),
    );

    expect(await db.watchStrengthWorkouts().first, isEmpty);
  });
}
