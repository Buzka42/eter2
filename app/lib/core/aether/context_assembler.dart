import '../clock.dart';
import '../db/app_database.dart';
import 'guidance_mode.dart';
import 'request_contract.dart';

class AetherContextAssembler {
  const AetherContextAssembler({
    required this.database,
    this.requestBuilder = const AetherRequestBuilder(),
    this.windowDays = 7,
  });

  final AppDatabase database;
  final AetherRequestBuilder requestBuilder;
  final int windowDays;

  /// Builds a bounded provider payload from canonical local records.
  ///
  /// The profile is used only to derive age, register and current consent.
  /// Names, exact birth data, coordinates, account IDs and source identifiers
  /// never enter [AetherRequest].
  Future<AetherRequest> assemble({required DateTime now}) async {
    final profile = await database.loadProfile();
    if (profile == null) {
      throw const AetherConsentException('A local profile is required');
    }

    final localNow = now.toLocal();
    final firstDay = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
    ).subtract(Duration(days: windowDays - 1));
    final afterWindow = DateTime(
      localNow.year,
      localNow.month,
      localNow.day + 1,
    );
    final fromDate = eterIsoDate(firstDay);
    final toDate = eterIsoDate(localNow);

    final results = await Future.wait<Object>([
      database.loadDaySummaryRange(fromDate, toDate),
      database.loadVitalsRange(fromDate, toDate),
      database.loadSleepForNights(fromDate, toDate),
      database.loadJournalForRange(
        firstDay.toUtc(),
        afterWindow.toUtc(),
        aiEligibleOnly: true,
      ),
    ]);
    final summaries = results[0] as List<DaySummaryRow>;
    final vitals = results[1] as List<DailyVitalsRow>;
    final sleep = results[2] as List<SleepSegmentRow>;
    final journal = results[3] as List<JournalEntryRow>;

    final summariesByDate = {for (final row in summaries) row.date: row};
    final vitalsByDate = {for (final row in vitals) row.date: row};
    final sleepMinutes = <String, int>{};
    for (final segment in sleep) {
      final minutes = segment.endUtc.difference(segment.startUtc).inMinutes;
      if (minutes > 0) {
        sleepMinutes.update(
          segment.nightOf,
          (value) => value + minutes,
          ifAbsent: () => minutes,
        );
      }
    }

    final health = <AetherHealthContext>[];
    for (var day = firstDay;
        !day.isAfter(localNow);
        day = day.add(const Duration(days: 1))) {
      final date = eterIsoDate(day);
      final summary = summariesByDate[date];
      final vital = vitalsByDate[date];
      final slept = sleepMinutes[date];
      if (summary == null && vital == null && slept == null) continue;
      health.add(AetherHealthContext(
        localDate: date,
        steps: summary?.steps,
        activeKcal: summary?.activeKcal,
        sleepMinutes: slept,
        restingHeartRate: vital?.restingHr,
        hrvMs: vital?.hrvMs,
      ));
    }

    return requestBuilder.build(
      aiConsented: profile.aiConsentAt != null,
      journalConsented: profile.journalAiConsentAt != null,
      ageYears: _ageAt(profile.dob, localNow),
      mode: _mode(profile.guidanceMode),
      health: health,
      journal: [
        for (final row in journal)
          AetherJournalContext(
            createdAt: row.createdAt,
            text: row.entryText,
            excludedFromAi: row.excludedFromAi,
          ),
      ],
    );
  }

  int _ageAt(DateTime dob, DateTime on) {
    var age = on.year - dob.year;
    if (on.month < dob.month || (on.month == dob.month && on.day < dob.day)) {
      age -= 1;
    }
    return age;
  }

  GuidanceMode _mode(String raw) => switch (raw) {
        'grounded' => GuidanceMode.grounded,
        'immersive' => GuidanceMode.immersive,
        _ => GuidanceMode.balanced,
      };
}
