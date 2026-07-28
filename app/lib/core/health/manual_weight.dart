import '../db/app_database.dart';

class ManualWeightService {
  ManualWeightService(this.db);

  final AppDatabase db;

  Future<int> record({
    required double kg,
    DateTime? recordedAt,
  }) {
    if (!kg.isFinite || kg < 20 || kg > 500) {
      throw const FormatException('Weight must be between 20 and 500 kg.');
    }
    return db.addManualWeight(kg: kg, recordedAt: recordedAt);
  }
}
