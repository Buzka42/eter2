import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../energy/energy.dart' as energy;
import 'daily_activity_summary.dart';

class ManualActivityException implements Exception {
  const ManualActivityException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ManualActivityResult {
  const ManualActivityResult({
    required this.sessionId,
    required this.activeKcal,
    required this.durationMinutes,
  });

  final String sessionId;
  final double activeKcal;
  final int durationMinutes;
}

/// Writes an explicit user-provided session through Eter's deduplication path.
class ManualActivityService {
  const ManualActivityService(this.database);

  final AppDatabase database;

  Future<ManualActivityResult> record({
    required String activity,
    required int durationMinutes,
    required double activeKcal,
    DateTime? endedAt,
  }) async {
    final name = activity.trim();
    if (name.isEmpty || name.length > 80) {
      throw const ManualActivityException(
        'Name the activity in 1–80 characters.',
      );
    }
    if (durationMinutes < 1 || durationMinutes > 1440) {
      throw const ManualActivityException(
        'Enter a duration between 1 and 1,440 minutes.',
      );
    }
    if (!activeKcal.isFinite || activeKcal <= 0 || activeKcal > 10000) {
      throw const ManualActivityException(
        'Enter active energy between 1 and 10,000 kcal.',
      );
    }

    final suppliedEnd = (endedAt ?? DateTime.now()).toUtc();
    final end = DateTime.utc(
      suppliedEnd.year,
      suppliedEnd.month,
      suppliedEnd.day,
      suppliedEnd.hour,
      suppliedEnd.minute,
    );
    final start = end.subtract(Duration(minutes: durationMinutes));
    // The session's logical end can be minute-rounded (and tests deliberately
    // pin it), so include the write instant to keep two entries in one minute
    // distinct.
    final id =
        'manual-${end.microsecondsSinceEpoch}-${DateTime.now().microsecondsSinceEpoch}';
    final perMinute = activeKcal / durationMinutes;

    await database.transaction(() async {
      await database.upsertActivitySession(
        ActivitySessionsCompanion.insert(
          id: id,
          sport: Value(name),
          startUtc: start,
          endUtc: end,
          activeKcal: Value(activeKcal),
          source: 'manual',
          priority: energy.SourcePriority.manualStrength.index,
        ),
      );
      await database.ingestRawBuckets([
        for (var minute = start;
            minute.isBefore(end);
            minute = minute.add(const Duration(minutes: 1)))
          energy.MinuteBucket(
            minuteUtc: minute,
            activeKcal: perMinute,
            sourceId: id,
            priority: energy.SourcePriority.manualStrength,
          ),
      ]);
      await database.recomputeMinuteWinners(start, end);
    });
    await DailyActivitySummaryService(database).refresh(start, end);

    return ManualActivityResult(
      sessionId: id,
      activeKcal: activeKcal,
      durationMinutes: durationMinutes,
    );
  }
}
