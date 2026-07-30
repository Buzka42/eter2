import '../db/app_database.dart';
import 'record_error.dart';

class ManualWeightService {
  ManualWeightService(this.db);

  final AppDatabase db;

  Future<int> record({
    required double kg,
    DateTime? recordedAt,
  }) {
    if (!kg.isFinite || kg < 20 || kg > 500) {
      throw const ManualWeightException(BodyRecordError.weightRange);
    }
    return db.addManualWeight(kg: kg, recordedAt: recordedAt);
  }
}

/// A weight outside the range the store will accept.
///
/// This used to be a bare `FormatException`, which meant the one caller that
/// reports it — the journal's body commit — could not tell a rejected weight
/// from a malformed JSON payload, and caught both with the same clause.
class ManualWeightException implements Exception {
  const ManualWeightException(this.error);

  final BodyRecordError error;

  @override
  String toString() => 'ManualWeightException(${error.name})';
}
