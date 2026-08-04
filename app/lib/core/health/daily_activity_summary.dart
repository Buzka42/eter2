import '../clock.dart';
import '../db/app_database.dart';
import '../energy/energy.dart' as energy;

/// Rebuilds reactive day totals from canonical minute winners.
///
/// Both platform imports and manual sessions pass through this service. It
/// never estimates resting burn without the complete body context required by
/// Mifflin–St Jeor.
class DailyActivitySummaryService {
  const DailyActivitySummaryService(this.database);

  final AppDatabase database;

  Future<int> refresh(DateTime start, DateTime end) async {
    final profile = await database.loadProfile();
    final height = profile?.heightCm;
    if (profile == null || height == null) return 0;

    final minutes = await database.loadMinuteBuckets(
      start.toUtc(),
      end.toUtc(),
    );
    if (minutes.isEmpty) return 0;
    final sessions = await database.loadSessions(start.toUtc(), end.toUtc());
    final byDate = <String, List<MinuteBucketRow>>{};
    for (final row in minutes) {
      byDate
          .putIfAbsent(eterIsoDate(row.minuteUtc.toLocal()), () => [])
          .add(row);
    }
    final sessionCounts = <String, int>{};
    for (final session in sessions) {
      sessionCounts.update(
        eterIsoDate(session.startUtc.toLocal()),
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final endLocal = end.toLocal();
    final endDate = eterIsoDate(endLocal);
    final restingPerMinute = energy.rmrPerMin(
      energy.restingKcalPerDay(
        sex: switch (profile.sex) {
          'female' => energy.Sex.female,
          'male' => energy.Sex.male,
          _ => energy.Sex.other,
        },
        weightKg: profile.weightKg,
        heightCm: height,
        age: _ageAt(profile.dob, endLocal),
        bodyFatPercent: profile.bodyFatPercent,
      ),
    );

    final sex = switch (profile.sex) {
      'female' => energy.Sex.female,
      'male' => energy.Sex.male,
      _ => energy.Sex.other,
    };

    for (final entry in byDate.entries) {
      final measured =
          entry.value.fold<double>(0, (sum, row) => sum + row.activeKcal);
      final steps =
          entry.value.fold<int>(0, (sum, row) => sum + (row.steps ?? 0));

      // Energy is filled in **per minute**, for the minutes that have none.
      //
      // Health Connect on a real phone gave 22,720 steps across three days and
      // zero active kilocalories: the step counter is the handset's own, and
      // nothing on it writes `ActiveCaloriesBurned`. The day's burn was
      // resting alone, so somebody who had walked ten thousand steps saw the
      // same figure as somebody who had not left a chair.
      //
      // Per minute rather than per day, and that distinction is the whole of
      // it. A training session logged through the Journal writes real energy
      // into the minutes it covers — so a day-level "estimate only when the
      // day has nothing" would have thrown away the walking on every day
      // somebody trained. This way each minute contributes exactly once:
      // measured where something measured it, estimated from its own steps
      // where nothing did, and nothing at all where there were no steps.
      //
      // It also cannot double-count a session against the steps taken during
      // it: those minutes already carry energy, so they are not estimated.
      final stepsWithoutEnergy = entry.value.fold<int>(
        0,
        (sum, row) => row.activeKcal > 0 ? sum : sum + (row.steps ?? 0),
      );
      final active = measured +
          energy.activeKcalFromSteps(
            steps: stepsWithoutEnergy,
            weightKg: profile.weightKg,
            heightCm: height,
            sex: sex,
          );
      final elapsedMinutes =
          entry.key == endDate ? endLocal.hour * 60 + endLocal.minute : 1440;
      await database.recordDayTotal(
        date: entry.key,
        activeKcal: active,
        basalKcal: restingPerMinute * elapsedMinutes,
        steps: steps,
        sessionsCount: sessionCounts[entry.key] ?? 0,
      );
    }
    return byDate.length;
  }

  int _ageAt(DateTime dob, DateTime on) {
    var age = on.year - dob.year;
    if (on.month < dob.month || (on.month == dob.month && on.day < dob.day)) {
      age -= 1;
    }
    return age;
  }
}
