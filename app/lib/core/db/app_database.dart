import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../energy/energy.dart' as energy;
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Schema 1. The v1 tree reached 18; there is no migration path because
  /// there are no external users and the fitness-era shape is not what this
  /// product stores.
  @override
  int get schemaVersion => 1;

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

  Future<void> updateNutritionEntry(
    int id,
    NutritionEntriesCompanion changes,
  ) =>
      (update(nutritionEntries)..where((row) => row.id.equals(id)))
          .write(changes.copyWith(syncedAt: const Value(null)));

  Future<void> deleteNutritionEntry(int id) =>
      (delete(nutritionEntries)..where((row) => row.id.equals(id))).go();

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

  Future<int> addWeightEntry({required double kg, String source = 'manual'}) =>
      into(weightEntries).insert(
        WeightEntriesCompanion.insert(
          recordedAt: DateTime.now().toUtc(),
          kg: kg,
          source: Value(source),
        ),
      );

  Stream<List<WeightEntryRow>> watchWeightEntries({int limit = 365}) =>
      (select(weightEntries)
            ..orderBy([(row) => OrderingTerm.desc(row.recordedAt)])
            ..limit(limit))
          .watch();

  Future<int> addLifestyleEntry(LifestyleEntriesCompanion entry) =>
      into(lifestyleEntries).insert(entry);

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

  // -------------------------------------------------------------------------
  // Journal
  // -------------------------------------------------------------------------

  Future<int> addJournalEntry(JournalEntriesCompanion entry) =>
      into(journalEntries).insert(entry);

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
