import 'dart:convert';

import '../arcana/major_arcana.dart';
import '../arcana/zodiac.dart';
import '../clock.dart';
import '../db/app_database.dart';
import '../patterns/local_pattern_discovery.dart';
import '../symbolic/natal_chart.dart';
import '../symbolic/numerology.dart';
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
      database.loadDayStoryRange(fromDate, toDate),
      // Findings, not history: what four weeks of records said about this
      // person that seven days of them cannot show.
      //
      // Reviewed here rather than only when the Sanctum is opened. Discovery
      // was reachable from one screen most people never visit, so guidance
      // could only ever have seen a pattern belonging to someone who had gone
      // looking for it. It is local arithmetic over rows already loaded —
      // nothing leaves, and nothing waits on a network.
      LocalPatternDiscovery(database)
          .review(now: now)
          .then((_) => database.loadActivePatterns()),
    ]);
    final summaries = results[0] as List<DaySummaryRow>;
    final vitals = results[1] as List<DailyVitalsRow>;
    final sleep = results[2] as List<SleepSegmentRow>;
    final journal = results[3] as List<JournalEntryRow>;
    final stories = results[4] as List<JournalDayStoryRow>;
    final patterns = results[5] as List<PatternCandidateRow>;

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

    // Days already reduced to a digest do not also travel as prose: the digest
    // is what the prose was compressed into, and sending both would defeat the
    // point of compressing it.
    final digestedDates = stories.map((row) => row.date).toSet();
    final digests = <AetherJournalDigest>[];
    for (final row in stories) {
      final points = _decodePoints(row.digestJson);
      if (points.isEmpty) continue;
      digests.add(AetherJournalDigest(localDate: row.date, points: points));
    }

    return requestBuilder.build(
      aiConsented: profile.aiConsentAt != null,
      journalConsented: profile.journalAiConsentAt != null,
      ageYears: _ageAt(profile.dob, localNow),
      mode: _mode(profile.guidanceMode),
      health: health,
      patterns: [for (final row in patterns) row.summary],
      bodyFatPercent: profile.bodyFatPercent,
      symbolic: await _symbolic(profile, localNow),
      digests: digests,
      journal: [
        for (final row in journal)
          if (!digestedDates.contains(eterIsoDate(row.createdAt.toLocal())))
            AetherJournalContext(
              createdAt: row.createdAt,
              text: row.entryText,
              excludedFromAi: row.excludedFromAi,
            ),
      ],
    );
  }

  /// The chart, reduced to what guidance may carry.
  ///
  /// Returns null when the chart cannot be computed — guidance then composes
  /// from the measured half alone rather than inventing placements, and the
  /// prompt is told the symbolic context is absent.
  Future<AetherSymbolicContext?> _symbolic(
    ProfileRow profile,
    DateTime localNow,
  ) async {
    try {
      final knowsTime = profile.birthTimeMinutes != null &&
          profile.birthUtcOffsetMinutes != null;
      final knowsPlace =
          profile.birthLatitude != null && profile.birthLongitude != null;
      final minutes = profile.birthTimeMinutes ?? 12 * 60;
      final chart = NatalChartEngine().calculate(NatalInput(
        localDateTime: DateTime(
          profile.dob.year,
          profile.dob.month,
          profile.dob.day,
          minutes ~/ 60,
          minutes % 60,
        ),
        utcOffsetMinutes: profile.birthUtcOffsetMinutes ?? 0,
        latitude: profile.birthLatitude ?? 0,
        longitude: profile.birthLongitude ?? 0,
      ));
      final lifePath = calculateLifePath(profile.dob);
      final today = eterIsoDate(localNow);
      // The Sun's Arcana: the one card that is permanently this person's,
      // rather than a daily draw. See _SunCard in the Vessel.
      final sunSign = Zodiac.values.firstWhere(
        (value) => value.label == chart.sun.sign,
      );
      final transit = await database.loadTransitReading(
        date: today,
        inputHash: _inputHash(profile),
      );
      return AetherSymbolicContext(
        sunSign: chart.sun.sign,
        moonSign: chart.moon.sign,
        // A noon-guessed ascendant is provisional; guidance would read it as
        // fact, so it is simply withheld rather than qualified.
        ascendantSign:
            knowsTime && knowsPlace ? chart.ascendant.sign : null,
        lifePath: lifePath,
        personalYear: calculatePersonalYear(profile.dob, localNow),
        sunCard: MajorArcana.forZodiac(sunSign).title,
        positionsNote: transit == null ? null : _guidanceNote(transit.passage),
      );
    } catch (_) {
      return null;
    }
  }

  String _inputHash(ProfileRow profile) => [
        profile.dob.toIso8601String(),
        profile.birthTimeMinutes ?? 'unknown-time',
        profile.birthUtcOffsetMinutes ?? 'unknown-offset',
        profile.birthLatitude ?? 'unknown-latitude',
        profile.birthLongitude ?? 'unknown-longitude',
      ].join('|');

  /// The stored transit row keeps the passage and its one-sentence note
  /// together; only the note may reach guidance.
  String? _guidanceNote(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['guidanceNote'] is String) {
        return (decoded['guidanceNote'] as String).trim();
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Map<String, Object?> _decodePoints(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      return const {};
    }
    return const {};
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
