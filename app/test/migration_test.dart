import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Migrations have to survive being re-run.
///
/// A real device proved why. One upgrade added a column, something after it
/// threw, and the stored schema version never advanced — so every launch
/// afterwards replayed `ALTER TABLE ... ADD COLUMN` against a column that was
/// already there, failed, and left the app on its splash screen with no way
/// forward. The database could not open, so nothing could.
///
/// A migration keyed on `from` assumes the previous run finished. These tests
/// assume it did not.
void main() {
  /// A database in the exact state the phone was in: every table present,
  /// `journal_cloud_sync_consent_at` already added by a run that then failed,
  /// and a recorded version that does not know it.
  ///
  /// Built from a real database rather than a hand-written one, so the fixture
  /// cannot drift away from the schema it is meant to represent.
  Future<Database> halfMigratedFile() async {
    final memory = sqlite3.openInMemory();
    final fresh = AppDatabase(
      NativeDatabase.opened(memory, closeUnderlyingOnClose: false),
    );
    await fresh.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 3, 14),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
      birthTimeMinutes: const Value(405),
    ));
    await fresh.close();

    // Wind back to the broken state: the two later columns were never added,
    // and the version never advanced past the run that added the first one.
    memory.execute('ALTER TABLE profiles DROP COLUMN crash_report_consent_at');
    memory.execute('ALTER TABLE profiles DROP COLUMN birth_time_precision');
    memory.execute('PRAGMA user_version = 2');
    return memory;
  }

  Future<AppDatabase> halfMigrated() async =>
      AppDatabase(NativeDatabase.opened(await halfMigratedFile()));

  test('a half-applied migration repairs itself instead of bricking the app',
      () async {
    final database = await halfMigrated();
    addTearDown(database.close);

    // Opening is the whole test: before the fix this threw
    // "duplicate column name: journal_cloud_sync_consent_at" and the app
    // could never start again.
    final profile = await database.loadProfile();

    expect(profile, isNotNull);
    expect(profile!.weightKg, 70);
    // The record survives the repair. A migration that fixed itself by
    // dropping the table would be worse than the bug.
    expect(profile.birthTimeMinutes, 405);
  });

  test('the columns the interrupted run never reached are added', () async {
    final database = await halfMigrated();
    addTearDown(database.close);

    final profile = (await database.loadProfile())!;
    // Present and null: added by the repair, and carrying no consent nobody
    // gave.
    expect(profile.crashReportConsentAt, isNull);
    // Backfilled once, on the run that added it: this install held a time, so
    // it held it to the minute.
    expect(profile.birthTimePrecision, 'exact');
  });

  test('an install with no birth time is not told it knew one', () async {
    final memory = sqlite3.openInMemory();
    final fresh = AppDatabase(
      NativeDatabase.opened(memory, closeUnderlyingOnClose: false),
    );
    await fresh.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 3, 14),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
    ));
    await fresh.close();
    memory.execute('ALTER TABLE profiles DROP COLUMN birth_time_precision');
    memory.execute('PRAGMA user_version = 4');

    final database = AppDatabase(NativeDatabase.opened(memory));
    addTearDown(database.close);
    expect((await database.loadProfile())!.birthTimePrecision, 'unknown');
  });

  test('replaying the upgrade a second time is a no-op', () async {
    // The property that was missing. Whatever state a device is in, running
    // the migration again must cost nothing rather than fail.
    final database = await halfMigrated();
    addTearDown(database.close);
    await database.loadProfile();

    // Wind the recorded version back and open again: exactly what the phone
    // did on every launch.
    await database.customStatement('PRAGMA user_version = 2');
    await expectLater(database.loadProfile(), completes);
  });

  test('a fresh database still creates cleanly', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 3, 14),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
    ));
    final profile = (await database.loadProfile())!;
    expect(profile.birthTimePrecision, 'unknown');
    expect(profile.crashReportConsentAt, isNull);
    expect(profile.journalCloudSyncConsentAt, isNull);
  });

  test('a night stored twice is repaired when the database opens', () async {
    // The state a real phone was left in: nights written before the import
    // learned to prefer stages carry both the stages and the session that
    // contains them, and are never rewritten, because nobody re-syncs a
    // fortnight ago. Every average built on those nights stayed doubled.
    final memory = sqlite3.openInMemory();
    final first = AppDatabase(
      NativeDatabase.opened(memory, closeUnderlyingOnClose: false),
    );
    await first.replaceSleepForNight(
      nightOf: '2026-07-27',
      source: 'healthConnect:garmin',
      segments: [
        SleepSegmentsCompanion.insert(
          nightOf: '2026-07-27',
          stage: 'light',
          startUtc: DateTime.utc(2026, 7, 27, 1),
          endUtc: DateTime.utc(2026, 7, 27, 6),
          source: 'healthConnect:garmin',
          priority: 3,
        ),
        SleepSegmentsCompanion.insert(
          nightOf: '2026-07-27',
          stage: 'unknown',
          startUtc: DateTime.utc(2026, 7, 27, 1),
          endUtc: DateTime.utc(2026, 7, 27, 6),
          source: 'healthConnect:garmin',
          priority: 3,
        ),
      ],
    );
    // A source that only ever reports a session keeps its single row: that
    // row is the whole of what is known about that night.
    await first.replaceSleepForNight(
      nightOf: '2026-07-26',
      source: 'healthConnect:other',
      segments: [
        SleepSegmentsCompanion.insert(
          nightOf: '2026-07-26',
          stage: 'unknown',
          startUtc: DateTime.utc(2026, 7, 26, 1),
          endUtc: DateTime.utc(2026, 7, 26, 7),
          source: 'healthConnect:other',
          priority: 3,
        ),
      ],
    );
    await first.close();
    memory.execute('PRAGMA user_version = 5');

    final reopened = AppDatabase(NativeDatabase.opened(memory));
    addTearDown(reopened.close);
    final repaired =
        await reopened.loadSleepForNights('2026-07-26', '2026-07-27');

    final staged = repaired.where((row) => row.nightOf == '2026-07-27');
    expect(
      staged.map((row) => row.stage),
      ['light'],
      reason: 'the session beside its own stages must be gone',
    );
    final sessionOnly = repaired.where((row) => row.nightOf == '2026-07-26');
    expect(
      sessionOnly.map((row) => row.stage),
      ['unknown'],
      reason: 'a night known only as a session must survive',
    );
  });
}
