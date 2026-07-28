import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../clock.dart';
import '../energy/energy.dart' as energy;
import '../journal/classification_contract.dart';
import '../symbolic/natal_chart.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Profiles,
    DaySummaries,
    RawBuckets,
    MinuteBuckets,
    Integrations,
    SleepSegments,
    DailyVitals,
    ActivitySessions,
    StrengthWorkouts,
    WeightEntries,
    NutritionEntries,
    LiveSessions,
    RememberedSensors,
    LifestyleEntries,
    JournalEntries,
    GuidanceHistory,
    VesselReadings,
    DailyCards,
    PatternCandidates,
    Retrospectives,
    IntakeAnswers,
    JournalDayStories,
    TransitReadings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Schema 3. The v1 tree reached 18; there is no migration path because
  /// there are no external users and the fitness-era shape is not what this
  /// product stores. v2 added optional body fat, the journal's daily story and
  /// digest, and the cached transit reading. v3 added the separate consent for
  /// mirroring journal prose; v4 adds the crash-report consent.
  @override
  int get schemaVersion => 4;

  /// Timestamps are stored as ISO-8601 text, not unix seconds.
  ///
  /// Drift's default stores an integer and hands it back as a *local*
  /// DateTime, so a value written as 08:00Z reads back as 10:00 unmarked. That
  /// is invisible until it isn't: this app decides which local day a minute
  /// belongs to, which night a sleep segment ends on, and when the register
  /// turns at sunset — all of which are wrong by an offset the moment the
  /// flag is lost, and wrong twice over when the user travels.
  ///
  /// Text storage preserves the offset through the round trip. The cost is
  /// slightly larger rows and string comparison on range scans, which the
  /// indexes already cover.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            // Null, so an existing install does not silently acquire consent
            // to mirror its journal. Consent is given, never inherited.
            await m.addColumn(profiles, profiles.journalCloudSyncConsentAt);
          }
          if (from < 4) {
            await m.addColumn(profiles, profiles.crashReportConsentAt);
          }
          await _createIndexes();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createIndexes() async {
    // Every one of these backs a query the surfaces run on every build. Range
    // scans over a year of minutes without them are the difference between a
    // dashboard that opens and one that janks.
    const statements = [
      'CREATE INDEX IF NOT EXISTS idx_raw_minute ON raw_buckets (minute_utc)',
      'CREATE INDEX IF NOT EXISTS idx_sleep_night ON sleep_segments (night_of)',
      'CREATE INDEX IF NOT EXISTS idx_sleep_start ON sleep_segments (start_utc)',
      'CREATE INDEX IF NOT EXISTS idx_sessions_start ON activity_sessions (start_utc)',
      'CREATE INDEX IF NOT EXISTS idx_nutrition_at ON nutrition_entries (recorded_at)',
      'CREATE INDEX IF NOT EXISTS idx_lifestyle_at ON lifestyle_entries (recorded_at)',
      'CREATE INDEX IF NOT EXISTS idx_weight_at ON weight_entries (recorded_at)',
      'CREATE INDEX IF NOT EXISTS idx_journal_created ON journal_entries (created_at)',
      'CREATE INDEX IF NOT EXISTS idx_guidance_date ON guidance_history (date)',
    ];
    for (final statement in statements) {
      await customStatement(statement);
    }
  }

  // -------------------------------------------------------------------------
  // Profile
  // -------------------------------------------------------------------------

  Future<ProfileRow?> loadProfile() =>
      (select(profiles)..where((row) => row.id.equals(1))).getSingleOrNull();

  Stream<ProfileRow?> watchProfile() =>
      (select(profiles)..where((row) => row.id.equals(1))).watchSingleOrNull();

  Future<void> saveProfile(ProfilesCompanion profile) =>
      into(profiles).insertOnConflictUpdate(
        profile.copyWith(id: const Value(1), syncedAt: const Value(null)),
      );

  /// Updates the chart inputs together and keeps only readings matching the
  /// new chart. Stale alternatives never accumulate.
  Future<void> updateBirthContext({
    required int? birthTimeMinutes,
    required int? birthUtcOffsetMinutes,
    required String? birthPlace,
    required double? birthLatitude,
    required double? birthLongitude,
  }) async {
    await transaction(() async {
      final profile = await loadProfile();
      if (profile == null) return;
      await (update(profiles)..where((row) => row.id.equals(1))).write(
        ProfilesCompanion(
          birthTimeMinutes: Value(birthTimeMinutes),
          birthUtcOffsetMinutes: Value(birthUtcOffsetMinutes),
          birthPlace: Value(birthPlace),
          birthLatitude: Value(birthLatitude),
          birthLongitude: Value(birthLongitude),
          syncedAt: const Value(null),
        ),
      );
      final inputHash = natalInputHash(
        dob: profile.dob,
        birthTimeMinutes: birthTimeMinutes,
        birthUtcOffsetMinutes: birthUtcOffsetMinutes,
        birthLatitude: birthLatitude,
        birthLongitude: birthLongitude,
      );
      await (delete(vesselReadings)
            ..where((row) => row.inputHash.equals(inputHash).not()))
          .go();
      await (delete(transitReadings)
            ..where((row) => row.inputHash.equals(inputHash).not()))
          .go();
    });
  }

  /// Updates only shell-level preferences. Keeping this separate from
  /// [saveProfile] prevents a settings tap from rewriting birth or consent
  /// data that the Sanctum did not display.
  Future<int> updateProfilePreferences({
    String? guidanceMode,
    String? startSurface,
    bool? hapticsEnabled,
  }) =>
      (update(profiles)..where((row) => row.id.equals(1))).write(
        ProfilesCompanion(
          guidanceMode:
              guidanceMode == null ? const Value.absent() : Value(guidanceMode),
          startSurface:
              startSurface == null ? const Value.absent() : Value(startSurface),
          hapticsEnabled: hapticsEnabled == null
              ? const Value.absent()
              : Value(hapticsEnabled),
          syncedAt: const Value(null),
        ),
      );

  /// Changes only explicit outbound-data permissions.
  ///
  /// Revoking general AI processing also revokes journal-prose processing.
  /// Enabling journal-aware guidance implies general AI permission. Each
  /// grant receives a fresh timestamp; revocation is represented by null and
  /// therefore takes effect for the next pipeline read without a migration.
  Future<void> updateProfileConsents({
    bool? aiAllowed,
    bool? journalAiAllowed,
    bool? cloudSyncAllowed,
    bool? journalCloudSyncAllowed,
    bool? crashReportsAllowed,
  }) async {
    final current = await loadProfile();
    if (current == null) return;
    final now = DateTime.now().toUtc();
    DateTime? aiAt = current.aiConsentAt;
    DateTime? journalAt = current.journalAiConsentAt;
    DateTime? cloudAt = current.cloudSyncConsentAt;
    DateTime? journalCloudAt = current.journalCloudSyncConsentAt;
    DateTime? crashAt = current.crashReportConsentAt;

    if (aiAllowed != null) {
      aiAt = aiAllowed ? now : null;
      if (!aiAllowed) journalAt = null;
    }
    if (journalAiAllowed != null) {
      journalAt = journalAiAllowed ? now : null;
      if (journalAiAllowed) aiAt ??= now;
    }
    if (cloudSyncAllowed != null) {
      cloudAt = cloudSyncAllowed ? now : null;
      // Journal prose cannot mirror on its own: withdrawing the mirror
      // entirely must withdraw the pages with it.
      if (!cloudSyncAllowed) journalCloudAt = null;
    }
    if (crashReportsAllowed != null) {
      crashAt = crashReportsAllowed ? now : null;
    }
    if (journalCloudSyncAllowed != null) {
      journalCloudAt = journalCloudSyncAllowed ? now : null;
      if (journalCloudSyncAllowed) cloudAt ??= now;
    }

    await (update(profiles)..where((row) => row.id.equals(1))).write(
      ProfilesCompanion(
        aiConsentAt: Value(aiAt),
        journalAiConsentAt: Value(journalAt),
        cloudSyncConsentAt: Value(cloudAt),
        journalCloudSyncConsentAt: Value(journalCloudAt),
        crashReportConsentAt: Value(crashAt),
        syncedAt: const Value(null),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Health ingest. Raw in, deduplicated winners out, day total recomputed.
  // -------------------------------------------------------------------------

  /// Replay-safe: the natural `(source, minute)` key means ingesting the same
  /// record twice cannot change a total.
  Future<void> ingestRawBuckets(Iterable<energy.MinuteBucket> buckets) async {
    await batch((batch) {
      for (final bucket in buckets) {
        batch.insert(
          rawBuckets,
          RawBucketsCompanion.insert(
            minuteUtc: bucket.minuteUtc.toUtc(),
            source: bucket.sourceId,
            activeKcal: bucket.activeKcal,
            priority: bucket.priority.index,
            hrSampleCount: Value(bucket.hrSampleCount),
            steps: Value(bucket.steps),
            avgHr: Value(bucket.avgHr),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Rebuilds canonical winners for a half-open UTC range and returns the
  /// active total. Delete-then-rebuild inside one transaction, so a partial
  /// recompute can never leave two sources owning the same minute.
  Future<double> recomputeMinuteWinners(
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final raw = await (select(rawBuckets)
          ..where((row) =>
              row.minuteUtc.isBiggerOrEqualValue(startUtc.toUtc()) &
              row.minuteUtc.isSmallerThanValue(endUtc.toUtc())))
        .get();

    final winners = energy.dedupe(
      raw.map((row) => energy.MinuteBucket(
            minuteUtc: row.minuteUtc.toUtc(),
            activeKcal: row.activeKcal,
            sourceId: row.source,
            priority: energy.SourcePriority.values[row.priority],
            hrSampleCount: row.hrSampleCount,
            steps: row.steps,
            avgHr: row.avgHr,
          )),
    );

    await transaction(() async {
      await (delete(minuteBuckets)
            ..where((row) =>
                row.minuteUtc.isBiggerOrEqualValue(startUtc.toUtc()) &
                row.minuteUtc.isSmallerThanValue(endUtc.toUtc())))
          .go();
      await batch((batch) {
        for (final winner in winners.values) {
          batch.insert(
            minuteBuckets,
            MinuteBucketsCompanion.insert(
              minuteUtc: winner.minuteUtc,
              activeKcal: winner.activeKcal,
              winningSource: winner.sourceId,
              provenance: winner.sourceId,
              steps: Value(winner.steps),
              avgHr: Value(winner.avgHr),
            ),
          );
        }
      });
    });

    return energy.dailyTotalKcal(winners);
  }

  Future<List<MinuteBucketRow>> loadMinuteBuckets(
    DateTime startUtc,
    DateTime endUtc,
  ) =>
      (select(minuteBuckets)
            ..where((row) =>
                row.minuteUtc.isBiggerOrEqualValue(startUtc.toUtc()) &
                row.minuteUtc.isSmallerThanValue(endUtc.toUtc()))
            ..orderBy([(row) => OrderingTerm.asc(row.minuteUtc)]))
          .get();

  Stream<List<MinuteBucketRow>> watchMinuteBuckets(
    DateTime startUtc,
    DateTime endUtc,
  ) =>
      (select(minuteBuckets)
            ..where((row) =>
                row.minuteUtc.isBiggerOrEqualValue(startUtc.toUtc()) &
                row.minuteUtc.isSmallerThanValue(endUtc.toUtc()))
            ..orderBy([(row) => OrderingTerm.asc(row.minuteUtc)]))
          .watch();

  /// Writes the day's total and reports whether it shrank.
  ///
  /// A total that goes down is not a bug -- a higher-priority source arriving
  /// late legitimately displaces what the hub guessed -- but the surface has
  /// to be able to say so rather than silently contradicting a number the
  /// user already read.
  Future<DayTotalUpdate> recordDayTotal({
    required String date,
    required double activeKcal,
    required double basalKcal,
    required int steps,
    required int sessionsCount,
  }) async {
    return transaction(() async {
      final previous = await (select(daySummaries)
            ..where((row) => row.date.equals(date)))
          .getSingleOrNull();

      final recalibrated =
          previous != null && activeKcal < previous.activeKcal - 0.5;

      await into(daySummaries).insertOnConflictUpdate(
        DaySummariesCompanion.insert(
          date: date,
          activeKcal: Value(activeKcal),
          basalKcal: Value(basalKcal),
          steps: Value(steps),
          sessionsCount: Value(sessionsCount),
          intakeKcal: Value(previous?.intakeKcal),
          recalibrated: Value(recalibrated),
          syncedAt: const Value(null),
        ),
      );

      final row = await (select(daySummaries)
            ..where((r) => r.date.equals(date)))
          .getSingle();
      return DayTotalUpdate(row: row, recalibrated: recalibrated);
    });
  }

  Future<DaySummaryRow?> loadDaySummary(String date) =>
      (select(daySummaries)..where((row) => row.date.equals(date)))
          .getSingleOrNull();

  Stream<DaySummaryRow?> watchDaySummary(String date) =>
      (select(daySummaries)..where((row) => row.date.equals(date)))
          .watchSingleOrNull();

  Future<List<DaySummaryRow>> loadDaySummaryRange(String from, String to) =>
      (select(daySummaries)
            ..where((row) =>
                row.date.isBiggerOrEqualValue(from) &
                row.date.isSmallerOrEqualValue(to))
            ..orderBy([(row) => OrderingTerm.asc(row.date)]))
          .get();

  // -------------------------------------------------------------------------
  // Sleep, vitals, sessions
  // -------------------------------------------------------------------------

  /// Replaces a night wholesale rather than merging, so a re-read of the same
  /// night from the same source cannot double its stages.
  Future<void> replaceSleepForNight({
    required String nightOf,
    required String source,
    required Iterable<SleepSegmentsCompanion> segments,
  }) async {
    await transaction(() async {
      await (delete(sleepSegments)
            ..where((row) =>
                row.nightOf.equals(nightOf) & row.source.equals(source)))
          .go();
      await batch((batch) => batch.insertAll(sleepSegments, segments.toList()));
    });
  }

  Future<List<SleepSegmentRow>> loadSleepForNights(
    String from,
    String to,
  ) =>
      (select(sleepSegments)
            ..where((row) =>
                row.nightOf.isBiggerOrEqualValue(from) &
                row.nightOf.isSmallerOrEqualValue(to))
            ..orderBy([(row) => OrderingTerm.asc(row.startUtc)]))
          .get();

  Stream<List<SleepSegmentRow>> watchSleepForNight(String nightOf) =>
      (select(sleepSegments)
            ..where((row) => row.nightOf.equals(nightOf))
            ..orderBy([(row) => OrderingTerm.asc(row.startUtc)]))
          .watch();

  Future<void> recordDailyVitals(DailyVitalsCompanion vitals) =>
      into(dailyVitals).insertOnConflictUpdate(vitals);

  Future<List<DailyVitalsRow>> loadVitalsRange(String from, String to) =>
      (select(dailyVitals)
            ..where((row) =>
                row.date.isBiggerOrEqualValue(from) &
                row.date.isSmallerOrEqualValue(to))
            ..orderBy([(row) => OrderingTerm.asc(row.date)]))
          .get();

  Stream<DailyVitalsRow?> watchVitals(String date) =>
      (select(dailyVitals)..where((row) => row.date.equals(date)))
          .watchSingleOrNull();

  Future<void> upsertActivitySession(ActivitySessionsCompanion session) =>
      into(activitySessions).insertOnConflictUpdate(session);

  Future<List<ActivitySessionRow>> loadSessions(
    DateTime startUtc,
    DateTime endUtc,
  ) =>
      (select(activitySessions)
            ..where((row) =>
                row.startUtc.isBiggerOrEqualValue(startUtc.toUtc()) &
                row.startUtc.isSmallerThanValue(endUtc.toUtc()))
            ..orderBy([(row) => OrderingTerm.asc(row.startUtc)]))
          .get();

  // -------------------------------------------------------------------------
  // Nutrition, weight, lifestyle
  // -------------------------------------------------------------------------

  /// Unconfirmed estimates are excluded. The brief requires AI food estimates
  /// to be confirmed before they count, and a total is exactly the place that
  /// promise is kept or broken.
  Future<double> intakeKcalForRange(DateTime startUtc, DateTime endUtc) async {
    final rows = await (select(nutritionEntries)
          ..where((row) =>
              row.recordedAt.isBiggerOrEqualValue(startUtc.toUtc()) &
              row.recordedAt.isSmallerThanValue(endUtc.toUtc()) &
              row.confirmed.equals(true)))
        .get();
    return rows.fold<double>(0, (sum, row) => sum + row.kcal);
  }

  Future<int> addNutritionEntry(NutritionEntriesCompanion entry) =>
      into(nutritionEntries).insert(entry);

  Future<int> addConfirmedNutritionEntry(
    NutritionEntriesCompanion entry,
  ) =>
      transaction(() async {
        final id = await into(nutritionEntries).insert(entry);
        await _refreshDayIntake(entry.recordedAt.value);
        return id;
      });

  Future<void> updateNutritionEntry(
    int id,
    NutritionEntriesCompanion changes,
  ) async {
    await transaction(() async {
      final existing = await (select(nutritionEntries)
            ..where((row) => row.id.equals(id)))
          .getSingleOrNull();
      if (existing == null) return;
      await (update(nutritionEntries)..where((row) => row.id.equals(id)))
          .write(changes.copyWith(syncedAt: const Value(null)));
      await _refreshDayIntake(existing.recordedAt);
    });
  }

  Future<void> deleteNutritionEntry(int id) async {
    await transaction(() async {
      final existing = await (select(nutritionEntries)
            ..where((row) => row.id.equals(id)))
          .getSingleOrNull();
      if (existing == null) return;
      await (delete(nutritionEntries)..where((row) => row.id.equals(id))).go();
      await _refreshDayIntake(existing.recordedAt);
    });
  }

  Future<void> _refreshDayIntake(DateTime recordedAt) async {
    final local = recordedAt.toLocal();
    final (start, end) = eterDayBounds(local);
    final rows = await (select(nutritionEntries)
          ..where((row) =>
              row.recordedAt.isBiggerOrEqualValue(start.toUtc()) &
              row.recordedAt.isSmallerThanValue(end.toUtc()) &
              row.confirmed.equals(true)))
        .get();
    final total = rows.fold<double>(0, (sum, row) => sum + row.kcal);
    await (update(daySummaries)
          ..where((row) => row.date.equals(eterIsoDate(local))))
        .write(
      DaySummariesCompanion(
        intakeKcal: Value(rows.isEmpty ? null : total),
        syncedAt: const Value(null),
      ),
    );
  }

  Stream<List<NutritionEntryRow>> watchNutritionForRange(
    DateTime startUtc,
    DateTime endUtc,
  ) =>
      (select(nutritionEntries)
            ..where((row) =>
                row.recordedAt.isBiggerOrEqualValue(startUtc.toUtc()) &
                row.recordedAt.isSmallerThanValue(endUtc.toUtc()))
            ..orderBy([(row) => OrderingTerm.asc(row.recordedAt)]))
          .watch();

  Future<int> addWeightEntry({
    required double kg,
    String source = 'manual',
    DateTime? recordedAt,
  }) =>
      into(weightEntries).insert(
        WeightEntriesCompanion.insert(
          recordedAt: (recordedAt ?? DateTime.now()).toUtc(),
          kg: kg,
          source: Value(source),
        ),
      );

  /// Records a user-entered weight and makes it the current calculation input.
  Future<int> addManualWeight({
    required double kg,
    DateTime? recordedAt,
  }) =>
      transaction(() async {
        final id = await addWeightEntry(
          kg: kg,
          source: 'manual',
          recordedAt: recordedAt,
        );
        await (update(profiles)..where((row) => row.id.equals(1))).write(
          ProfilesCompanion(
            weightKg: Value(kg),
            syncedAt: const Value(null),
          ),
        );
        return id;
      });

  Stream<List<WeightEntryRow>> watchWeightEntries({int limit = 365}) =>
      (select(weightEntries)
            ..orderBy([(row) => OrderingTerm.desc(row.recordedAt)])
            ..limit(limit))
          .watch();

  Future<int> addLifestyleEntry(LifestyleEntriesCompanion entry) =>
      into(lifestyleEntries).insert(entry);

  Stream<List<LifestyleEntryRow>> watchLifestyleForRange(
    DateTime startUtc,
    DateTime endUtc,
  ) =>
      (select(lifestyleEntries)
            ..where((row) =>
                row.recordedAt.isBiggerOrEqualValue(startUtc.toUtc()) &
                row.recordedAt.isSmallerThanValue(endUtc.toUtc()))
            ..orderBy([(row) => OrderingTerm.asc(row.recordedAt)]))
          .watch();

  /// A self-reported reading is the day's answer, not a log line: recording
  /// mood again replaces the day's mood instead of stacking a second opinion
  /// beside it. Practice sessions ([addLifestyleEntry]) accumulate; readings
  /// do not. Replacement is transactional so a day never holds two answers.
  Future<int> recordLifestyleReading({
    required String kind,
    required double value,
    required DateTime recordedAt,
    required DateTime dayStartUtc,
    required DateTime dayEndUtc,
  }) =>
      transaction(() async {
        await (delete(lifestyleEntries)
              ..where((row) =>
                  row.kind.equals(kind) &
                  row.source.equals('self-report') &
                  row.recordedAt.isBiggerOrEqualValue(dayStartUtc.toUtc()) &
                  row.recordedAt.isSmallerThanValue(dayEndUtc.toUtc())))
            .go();
        return into(lifestyleEntries).insert(
          LifestyleEntriesCompanion.insert(
            recordedAt: recordedAt.toUtc(),
            kind: kind,
            value: Value(value),
          ),
        );
      });

  Future<void> deleteLifestyleEntry(int id) =>
      (delete(lifestyleEntries)..where((row) => row.id.equals(id))).go();

  Future<List<LifestyleEntryRow>> loadLifestyleRange(
    DateTime startUtc,
    DateTime endUtc,
  ) =>
      (select(lifestyleEntries)
            ..where((row) =>
                row.recordedAt.isBiggerOrEqualValue(startUtc.toUtc()) &
                row.recordedAt.isSmallerThanValue(endUtc.toUtc()))
            ..orderBy([(row) => OrderingTerm.asc(row.recordedAt)]))
          .get();

  Future<void> upsertStrengthWorkout(StrengthWorkoutsCompanion workout) =>
      into(strengthWorkouts).insertOnConflictUpdate(workout);

  Stream<List<StrengthWorkoutRow>> watchStrengthWorkouts({int limit = 30}) =>
      (select(strengthWorkouts)
            ..orderBy([(row) => OrderingTerm.desc(row.endedAt)])
            ..limit(limit))
          .watch();

  // -------------------------------------------------------------------------
  // The day's story, and the digest guidance reads instead of raw prose
  // -------------------------------------------------------------------------

  Stream<JournalDayStoryRow?> watchDayStory(String date) =>
      (select(journalDayStories)..where((row) => row.date.equals(date)))
          .watchSingleOrNull();

  Future<JournalDayStoryRow?> loadDayStory(String date) =>
      (select(journalDayStories)..where((row) => row.date.equals(date)))
          .getSingleOrNull();

  Future<void> saveDayStory(JournalDayStoriesCompanion story) =>
      into(journalDayStories).insertOnConflictUpdate(story);

  /// The digests guidance sends in place of prose, oldest first.
  Future<List<JournalDayStoryRow>> loadDayStoryRange(
    String fromDate,
    String toDate,
  ) =>
      (select(journalDayStories)
            ..where((row) =>
                row.date.isBiggerOrEqualValue(fromDate) &
                row.date.isSmallerOrEqualValue(toDate))
            ..orderBy([(row) => OrderingTerm.asc(row.date)]))
          .get();

  // -------------------------------------------------------------------------
  // Transits
  // -------------------------------------------------------------------------

  Future<TransitReadingRow?> loadTransitReading({
    required String date,
    required String inputHash,
  }) =>
      (select(transitReadings)
            ..where((row) =>
                row.date.equals(date) & row.inputHash.equals(inputHash)))
          .getSingleOrNull();

  Future<void> saveTransitReading(TransitReadingsCompanion reading) =>
      into(transitReadings).insertOnConflictUpdate(reading);

  /// Readings for charts other than the current one are meaningless; birth
  /// context changes therefore retire them, as they do vessel readings.
  Future<void> retireTransitReadingsExcept(String inputHash) =>
      (delete(transitReadings)
            ..where((row) => row.inputHash.equals(inputHash).not()))
          .go();

  // -------------------------------------------------------------------------
  // Journal
  // -------------------------------------------------------------------------

  Future<int> addJournalEntry(JournalEntriesCompanion entry) =>
      into(journalEntries).insert(entry);

  Future<JournalEntryRow?> loadJournalEntry(int id) =>
      (select(journalEntries)..where((row) => row.id.equals(id)))
          .getSingleOrNull();

  Stream<List<JournalEntryRow>> watchJournalForRange(
    DateTime startUtc,
    DateTime endUtc,
  ) =>
      (select(journalEntries)
            ..where((row) =>
                row.createdAt.isBiggerOrEqualValue(startUtc.toUtc()) &
                row.createdAt.isSmallerThanValue(endUtc.toUtc()) &
                row.status.equals('discarded').not())
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
          .watch();

  Future<List<JournalEntryRow>> loadJournalForRange(
    DateTime startUtc,
    DateTime endUtc, {
    bool aiEligibleOnly = false,
  }) =>
      (select(journalEntries)
            ..where((row) {
              var predicate =
                  row.createdAt.isBiggerOrEqualValue(startUtc.toUtc()) &
                      row.createdAt.isSmallerThanValue(endUtc.toUtc()) &
                      row.status.equals('discarded').not();
              if (aiEligibleOnly) {
                predicate = predicate & row.excludedFromAi.equals(false);
              }
              return predicate;
            })
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
          .get();

  Future<void> setJournalExcludedFromAi(int id, bool excluded) =>
      (update(journalEntries)..where((row) => row.id.equals(id))).write(
        JournalEntriesCompanion(
          excludedFromAi: Value(excluded),
          syncedAt: const Value(null),
        ),
      );

  Future<void> markJournalClassified({
    required int id,
    required String status,
    required String extractionJson,
    required String model,
    DateTime? appliedAt,
  }) =>
      (update(journalEntries)..where((row) => row.id.equals(id))).write(
        JournalEntriesCompanion(
          status: Value(status),
          extractionJson: Value(extractionJson),
          model: Value(model),
          appliedAt: Value(appliedAt),
          syncedAt: const Value(null),
        ),
      );

  /// Applies a validated interpretation exactly once.
  ///
  /// Food remains unconfirmed and therefore excluded from totals until the
  /// user reviews it. The entry status and every derived record commit in one
  /// transaction so provider retries cannot leave partial state.
  Future<void> applyJournalClassification({
    required JournalEntryRow entry,
    required String status,
    required String extractionJson,
    required String model,
    required List<FoodEstimate> food,
    required List<LifestyleEstimate> lifestyle,
  }) async {
    await transaction(() async {
      final current = await loadJournalEntry(entry.id);
      if (current == null || current.appliedAt != null) return;
      final appliedAt = status == 'classified' ? DateTime.now().toUtc() : null;
      for (final item in food) {
        await into(nutritionEntries).insert(
          NutritionEntriesCompanion.insert(
            recordedAt: entry.createdAt,
            kcal: item.kcal,
            proteinG: Value(item.proteinG),
            carbsG: Value(item.carbsG),
            fatG: Value(item.fatG),
            meal: item.meal,
            source: const Value('aether-estimate'),
            metadataJson: Value(jsonEncode({
              'journalEntryId': entry.id,
              'confidence': item.confidence,
              'assumptions': item.assumptions,
            })),
            confirmed: const Value(false),
          ),
        );
      }
      for (final item in lifestyle) {
        await into(lifestyleEntries).insert(
          LifestyleEntriesCompanion.insert(
            recordedAt: entry.createdAt,
            kind: item.kind,
            value: Value(item.value),
            durationMinutes: Value(item.durationMinutes),
            note: Value(item.note),
            source: Value('journal:${entry.id}'),
          ),
        );
      }
      await markJournalClassified(
        id: entry.id,
        status: status,
        extractionJson: extractionJson,
        model: model,
        appliedAt: appliedAt,
      );
    });
  }

  /// Undo: remove every row this entry produced, then mark it unapplied.
  ///
  /// Derived rows carry `journalEntryId` in their metadata, which is what
  /// makes a reading revocable rather than merely regrettable.
  Future<void> revertJournalEntryRows(int journalEntryId) async {
    await transaction(() async {
      final nutrition = await select(nutritionEntries).get();
      for (final row in nutrition) {
        final metadata = _decodeMetadata(row.metadataJson);
        if (metadata['journalEntryId'] == journalEntryId) {
          await (delete(nutritionEntries)..where((r) => r.id.equals(row.id)))
              .go();
        }
      }

      await (delete(rawBuckets)
            ..where((row) => row.externalId.equals('journal:$journalEntryId')))
          .go();

      await (delete(lifestyleEntries)
            ..where((row) => row.source.equals('journal:$journalEntryId')))
          .go();

      await (update(journalEntries)
            ..where((row) => row.id.equals(journalEntryId)))
          .write(
        const JournalEntriesCompanion(
          status: Value('pending'),
          appliedAt: Value(null),
          syncedAt: Value(null),
        ),
      );
    });
  }

  /// Retention. Drops the prose while keeping the derived facts, so deleting
  /// what you wrote does not silently delete what you ate.
  ///
  /// v1 implemented this and never called it from anywhere; the Sanctum must
  /// expose it.
  Future<int> pruneJournalProse(DateTime olderThanUtc) =>
      (update(journalEntries)
            ..where((row) => row.createdAt.isSmallerThanValue(olderThanUtc)))
          .write(
        const JournalEntriesCompanion(
          entryText: Value(''),
          status: Value('discarded'),
          syncedAt: Value(null),
        ),
      );

  // -------------------------------------------------------------------------
  // Guidance, memory, symbolic
  // -------------------------------------------------------------------------

  Future<int> recordGuidance(GuidanceHistoryCompanion guidance) =>
      into(guidanceHistory).insert(guidance);

  Future<List<GuidanceHistoryRow>> loadGuidanceByFingerprint(
    String fingerprint,
  ) =>
      (select(guidanceHistory)
            ..where((row) => row.contextFingerprint.equals(fingerprint))
            ..orderBy([(row) => OrderingTerm.asc(row.id)]))
          .get();

  /// A composition is useful only as a complete four-dimension set.
  Future<void> recordGuidanceSet(
    List<GuidanceHistoryCompanion> guidance,
  ) =>
      transaction(() async {
        for (final item in guidance) {
          await into(guidanceHistory).insert(item);
        }
      });

  Future<List<GuidanceHistoryRow>> loadGuidanceForDate(String date) =>
      (select(guidanceHistory)
            ..where((row) => row.date.equals(date))
            ..orderBy([(row) => OrderingTerm.desc(row.generatedAt)]))
          .get();

  /// The memory window. Bounded on purpose: the brief warns against sending
  /// unlimited raw history to the model.
  Future<List<GuidanceHistoryRow>> loadRecentGuidance({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final from = _isoDate(cutoff);
    return (select(guidanceHistory)
          ..where((row) => row.date.isBiggerOrEqualValue(from))
          ..orderBy([(row) => OrderingTerm.desc(row.generatedAt)]))
        .get();
  }

  Stream<List<GuidanceHistoryRow>> watchGuidanceForDate(String date) =>
      (select(guidanceHistory)
            ..where((row) => row.date.equals(date))
            ..orderBy([(row) => OrderingTerm.desc(row.generatedAt)]))
          .watch();

  Future<VesselReadingRow?> loadVesselReading({
    required String inputHash,
    required String positionKey,
  }) =>
      (select(vesselReadings)
            ..where((row) =>
                row.inputHash.equals(inputHash) &
                row.positionKey.equals(positionKey)))
          .getSingleOrNull();

  Future<void> saveVesselReading(VesselReadingsCompanion reading) =>
      into(vesselReadings).insertOnConflictUpdate(reading);

  Future<void> saveVesselReadingSet(
    List<VesselReadingsCompanion> readings,
  ) =>
      transaction(() async {
        for (final reading in readings) {
          await into(vesselReadings).insert(reading);
        }
      });

  /// Birth inputs changed, so every composed reading is now about a chart that
  /// is no longer theirs.
  Future<int> clearVesselReadingsExcept(String inputHash) =>
      (delete(vesselReadings)
            ..where((row) => row.inputHash.equals(inputHash).not()))
          .go();

  Future<void> recordDailyCard(DailyCardsCompanion card) =>
      into(dailyCards).insertOnConflictUpdate(card);

  Future<DailyCardRow?> loadDailyCard(String date) =>
      (select(dailyCards)..where((row) => row.date.equals(date)))
          .getSingleOrNull();

  Future<List<DailyCardRow>> loadRecentCards({int limit = 30}) =>
      (select(dailyCards)
            ..orderBy([(row) => OrderingTerm.desc(row.date)])
            ..limit(limit))
          .get();

  Future<void> upsertPattern(PatternCandidatesCompanion pattern) =>
      into(patternCandidates).insertOnConflictUpdate(pattern);

  /// Refreshes discovery evidence without reviving a pattern the user
  /// dismissed. User agency wins over later recomputation.
  Future<bool> saveDiscoveredPattern(
    PatternCandidatesCompanion companion,
  ) async {
    return transaction(() async {
      final key = companion.key.value;
      final existing = await (select(patternCandidates)
            ..where((row) => row.key.equals(key)))
          .getSingleOrNull();
      if (existing?.status == 'dismissed') return false;
      await into(patternCandidates).insertOnConflictUpdate(companion);
      return true;
    });
  }

  Future<void> removeActivePattern(String key) => (delete(patternCandidates)
        ..where(
          (row) => row.key.equals(key) & row.status.equals('active'),
        ))
      .go();

  /// Dismissed patterns are excluded. A pattern the user rejected must not
  /// reach the model, or dismissing it means nothing.
  Future<List<PatternCandidateRow>> loadActivePatterns() =>
      (select(patternCandidates)
            ..where((row) => row.status.equals('active'))
            ..orderBy([(row) => OrderingTerm.desc(row.confidence)]))
          .get();

  Future<void> dismissPattern(String key) =>
      (update(patternCandidates)..where((row) => row.key.equals(key)))
          .write(const PatternCandidatesCompanion(status: Value('dismissed')));

  Future<void> saveRetrospective(RetrospectivesCompanion retrospective) =>
      into(retrospectives).insertOnConflictUpdate(retrospective);

  Future<List<RetrospectiveRow>> loadRetrospectives({int limit = 24}) =>
      (select(retrospectives)
            ..orderBy([(row) => OrderingTerm.desc(row.generatedAt)])
            ..limit(limit))
          .get();

  /// Clears derived Aether memory without touching source health, journal,
  /// profile, consent, nutrition, or deterministic symbolic calculations.
  Future<PersonalizationResetResult> resetPersonalization() async {
    return transaction(() async {
      final guidanceCount = await delete(guidanceHistory).go();
      final patternCount = await delete(patternCandidates).go();
      final retrospectiveCount = await delete(retrospectives).go();
      return PersonalizationResetResult(
        guidance: guidanceCount,
        patterns: patternCount,
        retrospectives: retrospectiveCount,
      );
    });
  }

  // -------------------------------------------------------------------------
  // Intake
  // -------------------------------------------------------------------------

  Future<void> saveIntakeAnswer({
    required String key,
    required String value,
    required String tier,
  }) =>
      into(intakeAnswers).insertOnConflictUpdate(
        IntakeAnswersCompanion.insert(
          key: key,
          value: value,
          tier: Value(tier),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

  Future<Map<String, IntakeAnswerRow>> loadIntakeAnswers() async {
    final rows = await select(intakeAnswers).get();
    return {for (final row in rows) row.key: row};
  }

  Future<void> clearIntakeAnswers() => delete(intakeAnswers).go();

  // -------------------------------------------------------------------------
  // Integrations
  // -------------------------------------------------------------------------

  Future<void> recordIntegrationSync({
    required String vendor,
    required String status,
    required int recordsToday,
    String? changesToken,
    DateTime? syncedAt,
    Map<String, Object?> diagnostics = const {},
    String? error,
  }) =>
      into(integrations).insertOnConflictUpdate(
        IntegrationsCompanion.insert(
          vendor: vendor,
          status: status,
          lastAttempt: Value(DateTime.now().toUtc()),
          lastSync: Value(syncedAt?.toUtc() ?? DateTime.now().toUtc()),
          changesToken: Value(changesToken),
          recordsToday: Value(recordsToday),
          diagnosticsJson: Value(jsonEncode(diagnostics)),
          lastError: Value(error),
        ),
      );

  /// Preserves the previous sync marker and token. A failure must not look
  /// like "never synced" or discard the differential cursor.
  Future<void> recordIntegrationFailure({
    required String vendor,
    required String status,
    required String error,
  }) async {
    final previous = await (select(integrations)
          ..where((row) => row.vendor.equals(vendor)))
        .getSingleOrNull();
    await into(integrations).insertOnConflictUpdate(
      IntegrationsCompanion.insert(
        vendor: vendor,
        status: status,
        lastAttempt: Value(DateTime.now().toUtc()),
        lastSync: Value(previous?.lastSync),
        changesToken: Value(previous?.changesToken),
        recordsToday: Value(previous?.recordsToday ?? 0),
        diagnosticsJson: Value(previous?.diagnosticsJson ?? '{}'),
        lastError: Value(error),
      ),
    );
  }

  Future<IntegrationRow?> loadIntegration(String vendor) =>
      (select(integrations)..where((row) => row.vendor.equals(vendor)))
          .getSingleOrNull();

  Stream<List<IntegrationRow>> watchIntegrations() =>
      select(integrations).watch();

  Future<void> forgetIntegration(String vendor) =>
      (delete(integrations)..where((row) => row.vendor.equals(vendor))).go();

  // -------------------------------------------------------------------------
  // Retention and deletion
  // -------------------------------------------------------------------------

  /// Nightly prune. Raw buckets are an ingest staging area, not history --
  /// the deduplicated winners and day summaries are what survives.
  Future<int> pruneRawBuckets({int retainDays = 90}) {
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: retainDays));
    return (delete(rawBuckets)
          ..where((row) => row.minuteUtc.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Removes raw heart-rate series after 180 days while preserving the
  /// session aggregate the user expects to keep.
  Future<int> pruneLiveHeartRateSeries({int retainDays = 180}) {
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: retainDays));
    return (update(liveSessions)
          ..where((row) =>
              row.endedAt.isSmallerThanValue(cutoff) &
              row.hrSeriesJson.equals('[]').not()))
        .write(const LiveSessionsCompanion(hrSeriesJson: Value('[]')));
  }

  Future<({int rawBuckets, int heartRateSeries})> runLocalRetention() async {
    final raw = await pruneRawBuckets();
    final heartRate = await pruneLiveHeartRateSeries();
    return (rawBuckets: raw, heartRateSeries: heartRate);
  }

  /// Complete, inspectable local snapshot for the Art. 15 export surface.
  ///
  /// `actualTableName` comes from generated Drift metadata, never user input.
  /// Dates are already stored as ISO text by [options], so every value remains
  /// JSON-safe and round-trippable.
  Future<Map<String, List<Map<String, Object?>>>> exportLocalSnapshot() async {
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in allTables) {
      final name = table.actualTableName;
      final rows = await customSelect(
        'SELECT * FROM "$name"',
        readsFrom: {table},
      ).get();
      result[name] = [
        for (final row in rows) Map<String, Object?>.from(row.data),
      ];
    }
    return result;
  }

  /// Local delete-everything. Distinct from account deletion, which also has
  /// to clear the Firestore mirror -- the Sanctum must present them as two
  /// separately confirmed actions with two different consequences.
  Future<void> deleteAllLocalData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

class DayTotalUpdate {
  const DayTotalUpdate({required this.row, required this.recalibrated});
  final DaySummaryRow row;

  /// The recomputed total came out lower than what was stored.
  final bool recalibrated;
}

class PersonalizationResetResult {
  const PersonalizationResetResult({
    required this.guidance,
    required this.patterns,
    required this.retrospectives,
  });

  final int guidance;
  final int patterns;
  final int retrospectives;
  int get total => guidance + patterns + retrospectives;
}

Map<String, Object?> _decodeMetadata(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, Object?> ? decoded : const {};
  } on FormatException {
    return const {};
  }
}

String _isoDate(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

LazyDatabase _openConnection() => LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(p.join(directory.path, 'eter.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
