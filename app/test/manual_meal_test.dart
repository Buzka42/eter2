import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/nutrition/manual_meal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('records a confirmed manual meal and refreshes existing day intake',
      () async {
    await database.recordDayTotal(
      date: '2026-07-28',
      activeKcal: 300,
      basalKcal: 1400,
      steps: 7000,
      sessionsCount: 1,
    );

    final id = await ManualMealService(database).record(
      meal: 'Rice and vegetables',
      kcal: 620,
      proteinG: 24,
      carbsG: 92,
      fatG: 18,
      recordedAt: DateTime(2026, 7, 28, 13),
    );

    final rows = await database
        .watchNutritionForRange(
          DateTime(2026, 7, 28),
          DateTime(2026, 7, 29),
        )
        .first;
    final summary = await database.loadDaySummary('2026-07-28');
    expect(rows.single.id, id);
    expect(rows.single.source, 'manual');
    expect(rows.single.confirmed, isTrue);
    expect(rows.single.proteinG, 24);
    expect(summary?.intakeKcal, 620);
  });

  test('correction and deletion keep the day intake mirror accurate', () async {
    await database.recordDayTotal(
      date: '2026-07-28',
      activeKcal: 300,
      basalKcal: 1400,
      steps: 7000,
      sessionsCount: 1,
    );
    final service = ManualMealService(database);
    final first = await service.record(
      meal: 'Lunch',
      kcal: 500,
      recordedAt: DateTime(2026, 7, 28, 12),
    );
    await service.record(
      meal: 'Dinner',
      kcal: 700,
      recordedAt: DateTime(2026, 7, 28, 19),
    );

    await database.updateNutritionEntry(
      first,
      const NutritionEntriesCompanion(kcal: Value(450)),
    );
    expect(
      (await database.loadDaySummary('2026-07-28'))?.intakeKcal,
      1150,
    );
    await database.deleteNutritionEntry(first);
    expect(
      (await database.loadDaySummary('2026-07-28'))?.intakeKcal,
      700,
    );
  });

  test('invalid energy or macros write nothing', () async {
    final service = ManualMealService(database);
    await expectLater(
      service.record(
        meal: '',
        kcal: 400,
        recordedAt: DateTime(2026, 7, 28),
      ),
      throwsA(isA<ManualMealException>()),
    );
    await expectLater(
      service.record(
        meal: 'Impossible meal',
        kcal: 400,
        proteinG: -2,
        recordedAt: DateTime(2026, 7, 28),
      ),
      throwsA(isA<ManualMealException>()),
    );
    expect(
      await database
          .watchNutritionForRange(
            DateTime(2026, 7, 28),
            DateTime(2026, 7, 29),
          )
          .first,
      isEmpty,
    );
  });
}
