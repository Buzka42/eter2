import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/i18n/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Switching language, and what it is allowed to cost.
///
/// The switch is not a relabelling: every passage Aether has written is prose in
/// the old language, and the composers key their caches on a fingerprint of the
/// *inputs*, none of which change when the language does. Left in place, a
/// Polish Dashboard would open on an English paragraph that every composer
/// considered current and would never replace. Clearing is what makes the choice
/// take effect at all.
///
/// The other half is what must survive. Nobody switching language has agreed to
/// lose a measurement or a journal page, and this is the file that says so.
void main() {
  late AppDatabase db;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async => db.close());

  Future<void> seedProfile({String? language}) => db.saveProfile(
        ProfilesCompanion.insert(
          dob: DateTime(1990, 3, 14),
          sex: 'other',
          weightKg: 70,
          units: 'metric',
          language: Value(language),
        ),
      );

  /// One of everything the switch is supposed to discard, plus one of everything
  /// it is supposed to keep.
  Future<void> seedComposedAndMeasured() async {
    await db.recordGuidance(GuidanceHistoryCompanion.insert(
      date: '2026-07-27',
      dimension: 'synthesis',
      generatedAt: DateTime.utc(2026, 7, 27, 8),
      contentJson: '{"passage":"A quiet observation."}',
      contextFingerprint: 'fingerprint',
      source: 'provider',
    ));
    await db.saveGuidanceRecall(GuidanceRecallsCompanion.insert(
      date: '2026-07-27',
      generatedAt: DateTime.utc(2026, 7, 27, 8),
      note: 'second short night. offered a walk.',
    ));
    await db.saveVesselReading(VesselReadingsCompanion.insert(
      inputHash: 'hash',
      positionKey: 'sun',
      createdAt: DateTime.utc(2026, 7, 27, 8),
      contentJson: '{"passage":"Composed reflection for sun."}',
      model: 'provider',
    ));
    await db.saveTransitReading(TransitReadingsCompanion.insert(
      date: '2026-07-27',
      inputHash: 'hash',
      generatedAt: DateTime.utc(2026, 7, 27, 8),
      contactsJson: '[]',
      passage: 'A day that tends to reward patience.',
    ));
    await db.saveDayStory(JournalDayStoriesCompanion.insert(
      date: '2026-07-27',
      generatedAt: DateTime.utc(2026, 7, 27, 20),
      story: 'You slept badly and walked anyway.',
      digestJson: const Value('{"digest":"short night, walked"}'),
      entryCount: const Value(1),
      sourceFingerprint: 'prose-fingerprint',
    ));
    await db.saveRetrospective(RetrospectivesCompanion.insert(
      id: 'weekly-2026-07-27',
      kind: 'weekly',
      periodStart: '2026-07-21',
      periodEnd: '2026-07-27',
      generatedAt: DateTime.utc(2026, 7, 27, 21),
      contentJson: '{"headline":"Your seven-day view","passages":["x"],'
          '"caveat":"y"}',
      model: 'local-factual-v1',
    ));

    // The record. None of this is prose and none of it may move.
    await db.addJournalEntry(JournalEntriesCompanion.insert(
      entryText: 'I slept badly, but the morning walk helped.',
      createdAt: DateTime.utc(2026, 7, 27, 21, 30),
    ));
    await db.recordDayTotal(
      date: '2026-07-27',
      activeKcal: 480,
      basalKcal: 1390,
      steps: 8420,
      sessionsCount: 1,
    );
  }

  test('choosing a language records it', () async {
    await seedProfile();
    expect((await db.loadProfile())!.language, isNull);

    await db.chooseLanguage('pl');

    final profile = (await db.loadProfile())!;
    expect(profile.language, 'pl');
    expect(AppLanguage.forProfile(profile.language), AppLanguage.polish);
  });

  test('an unchosen language is null, not English', () async {
    await seedProfile();
    // The distinction the nullable column exists for. An install that has never
    // been asked follows the phone; writing `'en'` on first launch would freeze
    // every Polish-speaking install in English.
    expect((await db.loadProfile())!.language, isNull);
  });

  test('changing language discards every composed passage', () async {
    await seedProfile(language: 'en');
    await seedComposedAndMeasured();

    final cleared = await db.chooseLanguage('pl');

    // Six rows: guidance, its recall, the vessel reading, the transit reading,
    // the day story and the retrospective.
    expect(cleared, 6);
    expect(await db.loadGuidanceForDate('2026-07-27'), isEmpty);
    expect(await db.loadGuidanceRecalls(today: '2026-07-28'), isEmpty);
    expect(
      await db.loadVesselReading(inputHash: 'hash', positionKey: 'sun'),
      isNull,
    );
    expect(
      await db.loadTransitReading(inputHash: 'hash', date: '2026-07-27'),
      isNull,
    );
    expect(await db.loadDayStory('2026-07-27'), isNull);
    expect(await db.loadRetrospectives(), isEmpty);
  });

  test('changing language keeps every record', () async {
    await seedProfile(language: 'en');
    await seedComposedAndMeasured();

    await db.chooseLanguage('pl');

    // The pages and the measurements. Nobody switching language agreed to lose
    // a word they wrote or a step they took.
    final entries = await db.loadJournalForRange(
      DateTime.utc(2026, 7, 27),
      DateTime.utc(2026, 7, 28),
    );
    expect(entries, hasLength(1));
    expect(entries.single.entryText, contains('slept badly'));
    expect((await db.loadDaySummary('2026-07-27'))!.steps, 8420);
    // And the profile keeps everything except the one field that changed.
    final profile = (await db.loadProfile())!;
    expect(profile.weightKg, 70);
    expect(profile.dob, DateTime(1990, 3, 14));
  });

  test('choosing the language already in force discards nothing', () async {
    await seedProfile(language: 'pl');
    await seedComposedAndMeasured();

    // The Sanctum's choice group fires on every tap, including a tap on the
    // current value. That must not throw away a week of composition.
    final cleared = await db.chooseLanguage('pl');

    expect(cleared, 0);
    expect(await db.loadGuidanceForDate('2026-07-27'), hasLength(1));
    expect(await db.loadDayStory('2026-07-27'), isNotNull);
  });

  test('the first choice on an unchosen install still clears', () async {
    // Null is not `'pl'`, so moving from unchosen to Polish is a real change —
    // and anything composed before it was composed in whatever the phone said.
    await seedProfile();
    await seedComposedAndMeasured();

    expect(await db.chooseLanguage('pl'), 6);
  });

  test('the language column survives an upgrade from v8', () async {
    // The migration is idempotent by design; this checks it actually adds the
    // column, and that an existing install arrives unchosen rather than being
    // told it picked English.
    final memory = sqlite3.openInMemory();
    final fresh = AppDatabase(
      NativeDatabase.opened(memory, closeUnderlyingOnClose: false),
    );
    await fresh.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1985, 1, 2),
      sex: 'other',
      weightKg: 64,
      units: 'metric',
    ));
    await fresh.close();

    memory.execute('ALTER TABLE profiles DROP COLUMN language');
    memory.execute('PRAGMA user_version = 8');

    final upgraded = AppDatabase(NativeDatabase.opened(memory));
    addTearDown(upgraded.close);

    final profile = await upgraded.loadProfile();
    expect(profile, isNotNull);
    expect(profile!.language, isNull);
    expect(profile.weightKg, 64);
  });
}
