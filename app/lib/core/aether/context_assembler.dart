import 'dart:convert';

import '../arcana/major_arcana.dart';
import '../arcana/zodiac.dart';
import '../clock.dart';
import '../db/app_database.dart';
import '../health/sleep_totals.dart';
import '../patterns/local_pattern_discovery.dart';
import '../patterns/pattern_sweep.dart';
import '../register.dart';
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
  /// [register] decides how loud the sky is allowed to be. The caller resolves
  /// it — it needs a horizon and a clock, which this class has no business
  /// holding — and passes it in.
  Future<AetherRequest> assemble({
    required DateTime now,
    EterRegister register = EterRegister.day,
  }) async {
    final profile = await database.loadProfile();
    if (profile == null) {
      throw const AetherConsentException('A local profile is required');
    }

    // Immersive always leans on the sky; balanced does once the sun is down.
    // Grounded never does — that register exists to be plain.
    final mode = _mode(profile.guidanceMode);
    final leansSymbolic = mode == GuidanceMode.immersive ||
        (mode == GuidanceMode.balanced && register == EterRegister.night);
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
      Future(() async {
        await LocalPatternDiscovery(database).review(now: now);
        await PatternSweep(database).run(now: now);
        return database.loadActivePatterns();
      }),
      // What the person said about the inside of the week — the margin's
      // check-in and whatever their pages reported. Guidance reasoned from
      // sensors and prose and never saw these at all, so a day someone marked
      // as heavy read exactly like a day they had not answered.
      database.loadLifestyleRange(firstDay.toUtc(), afterWindow.toUtc()),
      // A fortnight of what Aether itself said, so today is not composed as
      // though nothing was ever said to this person. Journal consent is read
      // here rather than trusted from when the note was written: a note that
      // saw a page must stop travelling if that permission is withdrawn.
      database.loadGuidanceRecalls(
        today: toDate,
        journalAllowed: profile.journalAiConsentAt != null,
      ),
    ]);
    final summaries = results[0] as List<DaySummaryRow>;
    final vitals = results[1] as List<DailyVitalsRow>;
    final sleep = results[2] as List<SleepSegmentRow>;
    final journal = results[3] as List<JournalEntryRow>;
    final stories = results[4] as List<JournalDayStoryRow>;
    final patterns = results[5] as List<PatternCandidateRow>;
    final lifestyle = results[6] as List<LifestyleEntryRow>;
    final recalled = results[7] as List<GuidanceRecallRow>;

    final summariesByDate = {for (final row in summaries) row.date: row};
    final vitalsByDate = {for (final row in vitals) row.date: row};
    // Was summed here, inline, over every segment of every source including the
    // ones marked awake -- so the figure Aether was told about a two-source night
    // was close to double, with time awake counted as sleep on top. One answer
    // now, shared with the Week in View and the correlation sweep.
    final sleepMinutes = SleepTotals.byNight(sleep);

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
        // Rounded only at the boundary. The contract sends whole minutes — a
        // model has no use for a fractional one — but the total is accumulated in
        // seconds so a night of a dozen segments does not lose a minute to
        // rounding each one.
        sleepMinutes: slept?.round(),
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
      leansSymbolic: leansSymbolic,
      health: health,
      patterns: [for (final row in patterns) _pattern(row)],
      lifestyle: [
        for (final row in lifestyle)
          AetherLifestyleContext(
            localDate: eterIsoDate(row.recordedAt.toLocal()),
            kind: row.kind,
            value: row.value,
            durationMinutes: row.durationMinutes,
            note: row.note,
            // `journal:<id>` is what `applyJournalClassification` writes.
            fromJournal: row.source.startsWith('journal:'),
          ),
      ],
      recalled: [
        for (final row in recalled)
          AetherRecallContext(
            localDate: row.date,
            note: row.note,
            action: row.action,
          ),
      ],
      bodyFatPercent: profile.bodyFatPercent,
      symbolic: await _symbolic(profile, localNow, leansSymbolic),
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

  /// A finding with the strength of the finding attached.
  ///
  /// `evidenceJson` is written by `LocalPatternDiscovery` and carries `n` and
  /// the window it compared. Both are optional here: a malformed or older row
  /// still travels as a summary and a confidence, which is what it always did.
  AetherPatternContext _pattern(PatternCandidateRow row) {
    int? observations;
    String? window;
    try {
      final decoded = jsonDecode(row.evidenceJson);
      if (decoded is Map<String, dynamic>) {
        if (decoded['n'] case final num count) observations = count.round();
        if (decoded['window'] case final String span) window = span;
      }
    } on FormatException {
      // The summary and the confidence are enough.
    }
    return AetherPatternContext(
      summary: row.summary,
      confidence: row.confidence,
      observations: observations,
      window: window,
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
    bool leansSymbolic,
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
        // The whole passage, but only where the sky is the louder half. One
        // sentence was all guidance ever received about the day's transits,
        // which is why it read as health reporting whatever the stated
        // proportions said.
        positionsPassage: leansSymbolic && transit != null
            ? _passage(transit.passage)
            : null,
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
  /// The Positions passage itself, already written and already validated.
  String? _passage(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['passage'] is String) {
        return (decoded['passage'] as String).trim();
      }
    } on FormatException {
      return null;
    }
    return null;
  }

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
