import 'dart:convert';

// Drift exports its own isNull/isNotNull column predicates, which collide with
// matcher's. The test wants the matchers.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/energy/energy.dart' as energy;
import 'package:flutter_test/flutter_test.dart';

AppDatabase _memoryDatabase() => AppDatabase(NativeDatabase.memory());

energy.MinuteBucket _bucket({
  required DateTime minute,
  required double kcal,
  required String source,
  required energy.SourcePriority priority,
  int hrSamples = 0,
}) =>
    energy.MinuteBucket(
      minuteUtc: minute,
      activeKcal: kcal,
      sourceId: source,
      priority: priority,
      hrSampleCount: hrSamples,
    );

void main() {
  late AppDatabase db;

  setUp(() => db = _memoryDatabase());
  tearDown(() => db.close());

  group('timestamps', () {
    test('a UTC timestamp survives the round trip as UTC', () async {
      // Drift's default DateTime storage is a unix integer handed back as a
      // *local* DateTime, so 08:00Z reads back as 10:00 unmarked in UTC+2.
      // This app decides which local day a minute belongs to, which night a
      // sleep segment ends on, and when the register turns at sunset -- all
      // wrong by an offset the moment the flag is lost. Hence text storage.
      final written = DateTime.utc(2026, 7, 27, 8);
      await db.recordIntegrationSync(
        vendor: 'healthConnect',
        status: 'connected',
        recordsToday: 1,
        syncedAt: written,
      );
      final row = await db.loadIntegration('healthConnect');
      expect(row!.lastSync!.isUtc, isTrue);
      expect(row.lastSync, written);
    });

    test('minute buckets keep their UTC instant', () async {
      final minute = DateTime.utc(2026, 7, 27, 23, 30);
      await db.ingestRawBuckets([
        _bucket(
          minute: minute,
          kcal: 3,
          source: 'hub',
          priority: energy.SourcePriority.hub,
        ),
      ]);
      await db.recomputeMinuteWinners(
        minute,
        minute.add(const Duration(minutes: 1)),
      );
      final rows = await db.loadMinuteBuckets(
        minute,
        minute.add(const Duration(minutes: 1)),
      );
      // A late-evening minute misfiled by an offset lands on the wrong day,
      // which is how a day total quietly gains or loses an hour of activity.
      expect(rows.single.minuteUtc.isUtc, isTrue);
      expect(rows.single.minuteUtc, minute);
    });
  });

  group('ingest and deduplication', () {
    test('replaying the same records does not change the total', () async {
      final minute = DateTime.utc(2026, 7, 27, 12);
      final buckets = [
        _bucket(
          minute: minute,
          kcal: 8,
          source: 'hub',
          priority: energy.SourcePriority.hub,
        ),
      ];

      await db.ingestRawBuckets(buckets);
      final first = await db.recomputeMinuteWinners(
        minute,
        minute.add(const Duration(minutes: 1)),
      );

      await db.ingestRawBuckets(buckets);
      await db.ingestRawBuckets(buckets);
      final third = await db.recomputeMinuteWinners(
        minute,
        minute.add(const Duration(minutes: 1)),
      );

      expect(first, 8);
      expect(third, first);
    });

    test('a vendor-direct source outranks the hub for the same minute',
        () async {
      final minute = DateTime.utc(2026, 7, 27, 12);
      await db.ingestRawBuckets([
        _bucket(
          minute: minute,
          kcal: 20,
          source: 'hub',
          priority: energy.SourcePriority.hub,
        ),
        _bucket(
          minute: minute,
          kcal: 12,
          source: 'oura',
          priority: energy.SourcePriority.vendorDirect,
        ),
      ]);

      final total = await db.recomputeMinuteWinners(
        minute,
        minute.add(const Duration(minutes: 1)),
      );

      // 12, not 20 and not 32. The higher number does not win; the better
      // source does.
      expect(total, 12);
      final winners = await db.loadMinuteBuckets(
        minute,
        minute.add(const Duration(minutes: 1)),
      );
      expect(winners.single.winningSource, 'oura');
    });

    test('the spec 11 worked example: manual strength beats the hub', () async {
      // Hub says 300 kcal for 18:00-19:00; the user also logged strength over
      // the same hour at 260. The day gets 260, not 560 and not 300.
      final start = DateTime.utc(2026, 7, 27, 18);
      final end = start.add(const Duration(hours: 1));
      final buckets = <energy.MinuteBucket>[];
      for (var i = 0; i < 60; i++) {
        final minute = start.add(Duration(minutes: i));
        buckets
          ..add(_bucket(
            minute: minute,
            kcal: 300 / 60,
            source: 'hub',
            priority: energy.SourcePriority.hub,
          ))
          ..add(_bucket(
            minute: minute,
            kcal: 260 / 60,
            source: 'strength',
            priority: energy.SourcePriority.manualStrength,
          ));
      }

      await db.ingestRawBuckets(buckets);
      final total = await db.recomputeMinuteWinners(start, end);
      expect(total, closeTo(260, 0.001));
    });

    test('recomputation is scoped to its range', () async {
      final monday = DateTime.utc(2026, 7, 27, 12);
      final tuesday = DateTime.utc(2026, 7, 28, 12);
      await db.ingestRawBuckets([
        _bucket(
          minute: monday,
          kcal: 5,
          source: 'hub',
          priority: energy.SourcePriority.hub,
        ),
        _bucket(
          minute: tuesday,
          kcal: 7,
          source: 'hub',
          priority: energy.SourcePriority.hub,
        ),
      ]);

      await db.recomputeMinuteWinners(
          monday, monday.add(const Duration(minutes: 1)));
      await db.recomputeMinuteWinners(
          tuesday, tuesday.add(const Duration(minutes: 1)));

      final all = await db.loadMinuteBuckets(
        DateTime.utc(2026, 7, 27),
        DateTime.utc(2026, 7, 29),
      );
      expect(all, hasLength(2));
    });
  });

  group('day summaries', () {
    test('a shrinking total is flagged as recalibrated', () async {
      final first = await db.recordDayTotal(
        date: '2026-07-27',
        activeKcal: 500,
        basalKcal: 1600,
        steps: 8000,
        sessionsCount: 1,
      );
      expect(first.recalibrated, isFalse);

      final second = await db.recordDayTotal(
        date: '2026-07-27',
        activeKcal: 320,
        basalKcal: 1600,
        steps: 8000,
        sessionsCount: 1,
      );
      expect(second.recalibrated, isTrue);
      expect(second.row.activeKcal, 320);
    });

    test('a growing total is not flagged', () async {
      await db.recordDayTotal(
        date: '2026-07-27',
        activeKcal: 320,
        basalKcal: 1600,
        steps: 100,
        sessionsCount: 0,
      );
      final grown = await db.recordDayTotal(
        date: '2026-07-27',
        activeKcal: 500,
        basalKcal: 1600,
        steps: 200,
        sessionsCount: 0,
      );
      expect(grown.recalibrated, isFalse);
    });

    test('recording the day total preserves logged intake', () async {
      await db.addNutritionEntry(
        NutritionEntriesCompanion.insert(
          recordedAt: DateTime.utc(2026, 7, 27, 8),
          kcal: 420,
          meal: 'breakfast',
        ),
      );
      await db.recordDayTotal(
        date: '2026-07-27',
        activeKcal: 100,
        basalKcal: 1600,
        steps: 0,
        sessionsCount: 0,
      );
      final row = await db.loadDaySummary('2026-07-27');
      expect(row, isNotNull);
      // Intake lives in its own table; the summary must not have clobbered it.
      final intake = await db.intakeKcalForRange(
        DateTime.utc(2026, 7, 27),
        DateTime.utc(2026, 7, 28),
      );
      expect(intake, 420);
    });
  });

  group('nutrition confirmation', () {
    test('unconfirmed estimates do not count toward intake', () async {
      await db.addNutritionEntry(
        NutritionEntriesCompanion.insert(
          recordedAt: DateTime.utc(2026, 7, 27, 8),
          kcal: 400,
          meal: 'breakfast',
        ),
      );
      await db.addNutritionEntry(
        NutritionEntriesCompanion.insert(
          recordedAt: DateTime.utc(2026, 7, 27, 13),
          kcal: 900,
          meal: 'lunch',
          confirmed: const Value(false),
        ),
      );

      final intake = await db.intakeKcalForRange(
        DateTime.utc(2026, 7, 27),
        DateTime.utc(2026, 7, 28),
      );
      // The brief requires estimates be confirmed before they are saved as
      // fact. A total is exactly where that promise is kept or broken.
      expect(intake, 400);
    });

    test('confirming an estimate makes it count', () async {
      final id = await db.addNutritionEntry(
        NutritionEntriesCompanion.insert(
          recordedAt: DateTime.utc(2026, 7, 27, 13),
          kcal: 900,
          meal: 'lunch',
          confirmed: const Value(false),
        ),
      );
      await db.updateNutritionEntry(
        id,
        const NutritionEntriesCompanion(confirmed: Value(true)),
      );
      final intake = await db.intakeKcalForRange(
        DateTime.utc(2026, 7, 27),
        DateTime.utc(2026, 7, 28),
      );
      expect(intake, 900);
    });
  });

  group('journal', () {
    Future<int> writeEntry({bool excluded = false}) => db.addJournalEntry(
          JournalEntriesCompanion.insert(
            createdAt: DateTime.utc(2026, 7, 27, 9),
            entryText: 'Slept badly, ran anyway.',
            excludedFromAi: Value(excluded),
          ),
        );

    test('an excluded entry is withheld from AI-eligible reads', () async {
      await writeEntry();
      await writeEntry(excluded: true);

      final all = await db.loadJournalForRange(
        DateTime.utc(2026, 7, 27),
        DateTime.utc(2026, 7, 28),
      );
      final eligible = await db.loadJournalForRange(
        DateTime.utc(2026, 7, 27),
        DateTime.utc(2026, 7, 28),
        aiEligibleOnly: true,
      );

      expect(all, hasLength(2));
      // The brief requires the user be able to exclude journal content. This
      // is the query that has to honour it.
      expect(eligible, hasLength(1));
      expect(eligible.single.excludedFromAi, isFalse);
    });

    test('exclusion can be toggled back', () async {
      final id = await writeEntry();
      await db.setJournalExcludedFromAi(id, true);
      var eligible = await db.loadJournalForRange(
        DateTime.utc(2026, 7, 27),
        DateTime.utc(2026, 7, 28),
        aiEligibleOnly: true,
      );
      expect(eligible, isEmpty);

      await db.setJournalExcludedFromAi(id, false);
      eligible = await db.loadJournalForRange(
        DateTime.utc(2026, 7, 27),
        DateTime.utc(2026, 7, 28),
        aiEligibleOnly: true,
      );
      expect(eligible, hasLength(1));
    });

    test('undo removes the rows an entry produced', () async {
      final id = await writeEntry();
      await db.addNutritionEntry(
        NutritionEntriesCompanion.insert(
          recordedAt: DateTime.utc(2026, 7, 27, 9),
          kcal: 300,
          meal: 'breakfast',
          metadataJson: Value(jsonEncode({'journalEntryId': id})),
        ),
      );
      await db.addNutritionEntry(
        NutritionEntriesCompanion.insert(
          recordedAt: DateTime.utc(2026, 7, 27, 13),
          kcal: 500,
          meal: 'lunch',
        ),
      );
      await db.markJournalClassified(
        id: id,
        status: 'classified',
        extractionJson: '{}',
        model: 'test',
        appliedAt: DateTime.utc(2026, 7, 27, 9, 1),
      );

      await db.revertJournalEntryRows(id);

      final intake = await db.intakeKcalForRange(
        DateTime.utc(2026, 7, 27),
        DateTime.utc(2026, 7, 28),
      );
      // Only the manually logged lunch survives.
      expect(intake, 500);

      final entries = await db.loadJournalForRange(
        DateTime.utc(2026, 7, 27),
        DateTime.utc(2026, 7, 28),
      );
      expect(entries.single.status, 'pending');
      expect(entries.single.appliedAt, isNull);
      // The prose is untouched -- undoing a reading is not deleting what was
      // written.
      expect(entries.single.entryText, 'Slept badly, ran anyway.');
    });

    test('pruning drops prose but keeps derived facts', () async {
      final id = await writeEntry();
      await db.addNutritionEntry(
        NutritionEntriesCompanion.insert(
          recordedAt: DateTime.utc(2026, 7, 27, 9),
          kcal: 300,
          meal: 'breakfast',
          metadataJson: Value(jsonEncode({'journalEntryId': id})),
        ),
      );

      await db.pruneJournalProse(DateTime.utc(2026, 7, 28));

      final intake = await db.intakeKcalForRange(
        DateTime.utc(2026, 7, 27),
        DateTime.utc(2026, 7, 28),
      );
      // Deleting what you wrote must not silently delete what you ate.
      expect(intake, 300);
    });
  });

  group('vessel readings', () {
    test('a reading is composed once per position per chart', () async {
      await db.saveVesselReading(
        VesselReadingsCompanion.insert(
          inputHash: 'abc',
          positionKey: 'lifePath',
          createdAt: DateTime.utc(2026, 7, 27),
          contentJson: '{"reading":"first"}',
          model: 'test',
        ),
      );
      final loaded = await db.loadVesselReading(
        inputHash: 'abc',
        positionKey: 'lifePath',
      );
      expect(loaded, isNotNull);

      // A different position on the same chart is a separate composition.
      expect(
        await db.loadVesselReading(inputHash: 'abc', positionKey: 'sun'),
        isNull,
      );
    });

    test('correcting birth inputs discards readings about the old chart',
        () async {
      for (final hash in ['old', 'new']) {
        await db.saveVesselReading(
          VesselReadingsCompanion.insert(
            inputHash: hash,
            positionKey: 'lifePath',
            createdAt: DateTime.utc(2026, 7, 27),
            contentJson: '{}',
            model: 'test',
          ),
        );
      }

      await db.clearVesselReadingsExcept('new');

      expect(
        await db.loadVesselReading(inputHash: 'old', positionKey: 'lifePath'),
        isNull,
      );
      expect(
        await db.loadVesselReading(inputHash: 'new', positionKey: 'lifePath'),
        isNotNull,
      );
    });
  });

  group('patterns', () {
    test('a dismissed pattern is withheld from the active set', () async {
      for (final key in ['sleep-after-late-workouts', 'mood-after-walking']) {
        await db.upsertPattern(
          PatternCandidatesCompanion.insert(
            key: key,
            computedAt: DateTime.utc(2026, 7, 27),
            summary: 'summary for $key',
            evidenceJson: '{"n":14}',
            confidence: 0.6,
          ),
        );
      }

      await db.dismissPattern('mood-after-walking');
      final active = await db.loadActivePatterns();

      // Dismissing a pattern has to actually stop it reaching the model, or
      // the control is decorative.
      expect(active, hasLength(1));
      expect(active.single.key, 'sleep-after-late-workouts');
    });

    test('reset removes derived memory but preserves source records', () async {
      final journalId = await db.addJournalEntry(
        JournalEntriesCompanion.insert(
          createdAt: DateTime.utc(2026, 7, 27),
          entryText: 'A source memory that must remain.',
        ),
      );
      await db.recordGuidance(
        GuidanceHistoryCompanion.insert(
          date: '2026-07-27',
          dimension: 'synthesis',
          generatedAt: DateTime.utc(2026, 7, 27),
          contentJson: '{}',
          contextFingerprint: 'reset-test',
          source: 'test',
        ),
      );
      await db.upsertPattern(
        PatternCandidatesCompanion.insert(
          key: 'test-pattern',
          computedAt: DateTime.utc(2026, 7, 27),
          summary: 'A derived pattern',
          evidenceJson: '{"n":8}',
          confidence: 0.6,
        ),
      );
      await db.saveRetrospective(
        RetrospectivesCompanion.insert(
          id: 'week-1',
          kind: 'weekly',
          periodStart: '2026-07-21',
          periodEnd: '2026-07-27',
          generatedAt: DateTime.utc(2026, 7, 27),
          contentJson: '{}',
          model: 'test',
        ),
      );

      final result = await db.resetPersonalization();

      expect(result.total, 3);
      expect(await db.loadRecentGuidance(), isEmpty);
      expect(await db.loadActivePatterns(), isEmpty);
      expect(await db.loadRetrospectives(), isEmpty);
      expect((await db.loadJournalEntry(journalId))!.entryText,
          'A source memory that must remain.');
    });
  });

  group('integrations', () {
    test('a failure preserves the previous sync marker and token', () async {
      await db.recordIntegrationSync(
        vendor: 'healthConnect',
        status: 'connected',
        recordsToday: 120,
        changesToken: 'token-1',
        syncedAt: DateTime.utc(2026, 7, 27, 8),
      );
      await db.recordIntegrationFailure(
        vendor: 'healthConnect',
        status: 'error',
        error: 'permission revoked',
      );

      final row = await db.loadIntegration('healthConnect');
      expect(row!.status, 'error');
      expect(row.lastError, 'permission revoked');
      // A failure must not look like "never synced" or throw away the
      // differential cursor.
      expect(row.lastSync, DateTime.utc(2026, 7, 27, 8));
      expect(row.changesToken, 'token-1');
    });
  });

  group('sleep', () {
    test('re-reading a night replaces its stages rather than doubling them',
        () async {
      SleepSegmentsCompanion segment(int hour, String stage) =>
          SleepSegmentsCompanion.insert(
            startUtc: DateTime.utc(2026, 7, 26, hour),
            endUtc: DateTime.utc(2026, 7, 26, hour + 1),
            stage: stage,
            source: 'oura',
            priority: energy.SourcePriority.vendorDirect.index,
            nightOf: '2026-07-27',
          );

      await db.replaceSleepForNight(
        nightOf: '2026-07-27',
        source: 'oura',
        segments: [segment(23, 'light'), segment(1, 'deep')],
      );
      await db.replaceSleepForNight(
        nightOf: '2026-07-27',
        source: 'oura',
        segments: [segment(23, 'light'), segment(1, 'deep')],
      );

      final rows = await db.loadSleepForNights('2026-07-27', '2026-07-27');
      expect(rows, hasLength(2));
    });

    test('replacing one source leaves another source intact', () async {
      await db.replaceSleepForNight(
        nightOf: '2026-07-27',
        source: 'oura',
        segments: [
          SleepSegmentsCompanion.insert(
            startUtc: DateTime.utc(2026, 7, 26, 23),
            endUtc: DateTime.utc(2026, 7, 27, 6),
            stage: 'light',
            source: 'oura',
            priority: energy.SourcePriority.vendorDirect.index,
            nightOf: '2026-07-27',
          ),
        ],
      );
      await db.replaceSleepForNight(
        nightOf: '2026-07-27',
        source: 'healthConnect',
        segments: [
          SleepSegmentsCompanion.insert(
            startUtc: DateTime.utc(2026, 7, 26, 23, 30),
            endUtc: DateTime.utc(2026, 7, 27, 6),
            stage: 'unknown',
            source: 'healthConnect',
            priority: energy.SourcePriority.hub.index,
            nightOf: '2026-07-27',
          ),
        ],
      );

      final rows = await db.loadSleepForNights('2026-07-27', '2026-07-27');
      expect(rows.map((r) => r.source).toSet(), {'oura', 'healthConnect'});
    });
  });

  group('retention', () {
    test('pruning raw buckets leaves the deduplicated winners alone', () async {
      final old = DateTime.utc(2026, 1, 1, 12);
      await db.ingestRawBuckets([
        _bucket(
          minute: old,
          kcal: 9,
          source: 'hub',
          priority: energy.SourcePriority.hub,
        ),
      ]);
      await db.recomputeMinuteWinners(old, old.add(const Duration(minutes: 1)));

      final removed = await db.pruneRawBuckets(retainDays: 30);
      expect(removed, 1);

      final winners = await db.loadMinuteBuckets(
        old,
        old.add(const Duration(minutes: 1)),
      );
      // Raw is a staging area; the winners are the history.
      expect(winners, hasLength(1));
    });

    test('old live HR series is cleared without deleting its session',
        () async {
      final ended = DateTime.now().toUtc().subtract(const Duration(days: 181));
      await db.into(db.liveSessions).insert(
            LiveSessionsCompanion.insert(
              id: 'old-session',
              startedAt: ended.subtract(const Duration(hours: 1)),
              endedAt: ended,
              sourceId: 'polar',
              hrSeriesJson: '[120,124,128]',
              finalKcal: 240,
            ),
          );

      final changed = await db.pruneLiveHeartRateSeries();
      expect(changed, 1);
      final row = await (db.select(db.liveSessions)
            ..where((session) => session.id.equals('old-session')))
          .getSingle();
      expect(row.hrSeriesJson, '[]');
      expect(row.finalKcal, 240);
      expect(row.sourceId, 'polar');
    });
  });

  group('intake answers', () {
    test('answers are keyed and re-answerable', () async {
      await db.saveIntakeAnswer(
        key: 'lifeSeason',
        value: 'transition',
        tier: 'valuable',
      );
      await db.saveIntakeAnswer(
        key: 'lifeSeason',
        value: 'settled',
        tier: 'valuable',
      );

      final answers = await db.loadIntakeAnswers();
      expect(answers, hasLength(1));
      expect(answers['lifeSeason']!.value, 'settled');
      expect(answers['lifeSeason']!.tier, 'valuable');
    });
  });

  group('profile consent', () {
    test('AI revocation also revokes journal prose but not cloud', () async {
      await db.saveProfile(
        ProfilesCompanion.insert(
          dob: DateTime(1990, 1, 1),
          sex: 'other',
          weightKg: 70,
          units: 'metric',
        ),
      );
      await db.updateProfileConsents(
        journalAiAllowed: true,
        cloudSyncAllowed: true,
      );
      var profile = (await db.loadProfile())!;
      expect(profile.aiConsentAt, isNotNull);
      expect(profile.journalAiConsentAt, isNotNull);
      expect(profile.cloudSyncConsentAt, isNotNull);

      await db.updateProfileConsents(aiAllowed: false);
      profile = (await db.loadProfile())!;
      expect(profile.aiConsentAt, isNull);
      expect(profile.journalAiConsentAt, isNull);
      expect(profile.cloudSyncConsentAt, isNotNull);
      expect(profile.syncedAt, isNull);
    });
  });
}
