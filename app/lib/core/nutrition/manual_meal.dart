import 'package:drift/drift.dart';

import '../db/app_database.dart';

class ManualMealService {
  const ManualMealService(this.database);

  final AppDatabase database;

  Future<int> record({
    required String meal,
    required double kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    required DateTime recordedAt,
  }) async {
    final name = meal.trim();
    if (name.isEmpty) {
      throw const ManualMealException('Name the meal or food first.');
    }
    if (!kcal.isFinite || kcal <= 0 || kcal > 10000) {
      throw const ManualMealException(
        'Energy must be between 1 and 10,000 kcal.',
      );
    }
    for (final macro in [proteinG, carbsG, fatG]) {
      if (macro != null && (!macro.isFinite || macro < 0 || macro > 1000)) {
        throw const ManualMealException(
          'Each optional macro must be between 0 and 1,000 grams.',
        );
      }
    }
    return database.addConfirmedNutritionEntry(
      NutritionEntriesCompanion.insert(
        recordedAt: recordedAt.toUtc(),
        kcal: kcal,
        proteinG: Value(proteinG),
        carbsG: Value(carbsG),
        fatG: Value(fatG),
        meal: name,
        source: const Value('manual'),
        confirmed: const Value(true),
      ),
    );
  }
}

class ManualMealException implements Exception {
  const ManualMealException(this.message);

  final String message;

  @override
  String toString() => message;
}
