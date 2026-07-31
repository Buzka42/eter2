import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/privacy/local_data_import.dart';
import 'package:flutter_test/flutter_test.dart';

/// Taking the record out and putting it back.
///
/// The export was already a complete versioned snapshot; nothing could read
/// one, so "export" was a promise the product kept by half. The test that
/// matters most is the round trip — write, read, and find the same records —
/// because a restore that runs without error and quietly drops a table is
/// worse than one that refuses.
void main() {
  late AppDatabase source;
  late AppDatabase destination;

  setUp(() {
    source = AppDatabase(NativeDatabase.memory());
    destination = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await source.close();
    await destination.close();
  });

  Future<String> snapshotOf(AppDatabase db) async => jsonEncode({
        'format': LocalDataImporter.format,
        'formatVersion': LocalDataImporter.formatVersion,
        'databaseSchemaVersion': db.schemaVersion,
        'exportedAtUtc': DateTime.utc(2026, 7, 31).toIso8601String(),
        'scope': 'device-local',
        'tables': await db.exportLocalSnapshot(),
      });

  Future<void> aRecord(AppDatabase db) async {
    await db.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 1, 1),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
      firstName: const Value('A name'),
    ));
    await db.addJournalEntry(JournalEntriesCompanion.insert(
      entryText: 'A page, written before the phone was lost.',
      createdAt: DateTime.utc(2026, 7, 20, 21, 14),
    ));
    await db.addJournalEntry(JournalEntriesCompanion.insert(
      entryText: 'Another one.',
      createdAt: DateTime.utc(2026, 7, 21, 8, 2),
    ));
    await db.upsertLetter(LettersCompanion.insert(
      month: '2026-06',
      composedAt: DateTime.utc(2026, 7, 1),
      body: 'The month, as it looked.',
    ));
  }

  test('a record survives the round trip intact', () async {
    await aRecord(source);
    final result =
        await LocalDataImporter(destination).importJson(await snapshotOf(source));

    expect(result.isPartial, isFalse);
    expect(result.rowsByTable['journal_entries'], 2);

    final pages = await destination.loadJournalForRange(
      DateTime.utc(2026, 7, 1),
      DateTime.utc(2026, 8, 1),
    );
    expect(
      pages.map((page) => page.entryText).toSet(),
      {'A page, written before the phone was lost.', 'Another one.'},
    );
    // Timestamps are the thing most likely to be quietly wrong, because the
    // whole database stores them as text precisely so an offset survives.
    expect(
      pages.map((page) => page.createdAt.toUtc()),
      contains(DateTime.utc(2026, 7, 20, 21, 14)),
    );

    final letter = await destination.loadLetter('2026-06');
    expect(letter?.body, 'The month, as it looked.');
  });

  test('a device that has been through onboarding is still empty enough',
      () async {
    // The case the feature exists for is a new phone, and a new phone has a
    // profile row by the time anybody reaches the Sanctum. Counting it as
    // history would make the restore refuse in exactly that case.
    await destination.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 1, 1),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
    ));
    await aRecord(source);
    final result =
        await LocalDataImporter(destination).importJson(await snapshotOf(source));
    expect(result.rows, greaterThan(0));
  });

  test('it never overwrites a device that already has a record', () async {
    await aRecord(source);
    await destination.addJournalEntry(JournalEntriesCompanion.insert(
      entryText: 'Something written here first.',
      createdAt: DateTime.utc(2026, 7, 30),
    ));

    await expectLater(
      LocalDataImporter(destination).importJson(await snapshotOf(source)),
      throwsA(isA<LocalImportException>()),
    );
    final pages = await destination.loadJournalForRange(
      DateTime.utc(2026, 7, 1),
      DateTime.utc(2026, 8, 1),
    );
    // Merging means deciding which of two versions of last Tuesday is true.
    expect(pages, hasLength(1));
    expect(pages.single.entryText, 'Something written here first.');
  });

  group('what it refuses', () {
    test('anything that is not an Eter export', () async {
      final importer = LocalDataImporter(destination);
      await expectLater(
        importer.importJson('not json'),
        throwsA(isA<LocalImportException>()),
      );
      await expectLater(
        importer.importJson(jsonEncode({'format': 'something-else'})),
        throwsA(isA<LocalImportException>()),
      );
    });

    test('a format version it has never seen', () async {
      await expectLater(
        LocalDataImporter(destination).importJson(jsonEncode({
          'format': LocalDataImporter.format,
          'formatVersion': 99,
          'tables': <String, Object?>{},
        })),
        throwsA(isA<LocalImportException>()),
      );
    });

    test('a snapshot from a newer Eter', () async {
      // Not stubbornness: a newer schema carries columns whose *meaning* this
      // build does not know, and guessing is how a restore corrupts a record.
      await expectLater(
        LocalDataImporter(destination).importJson(jsonEncode({
          'format': LocalDataImporter.format,
          'formatVersion': LocalDataImporter.formatVersion,
          'databaseSchemaVersion': destination.schemaVersion + 1,
          'tables': <String, Object?>{},
        })),
        throwsA(isA<LocalImportException>()),
      );
    });
  });

  test('what could not be restored is reported, not swallowed', () async {
    final result = await LocalDataImporter(destination).importJson(jsonEncode({
      'format': LocalDataImporter.format,
      'formatVersion': LocalDataImporter.formatVersion,
      'databaseSchemaVersion': destination.schemaVersion,
      'tables': {
        'a_table_from_the_future': [
          {'id': 1},
        ],
        'journal_entries': [
          {
            'id': 1,
            // The column is named `text` on disk, not `entryText`.
            'text': 'A page.',
            'created_at': '2026-07-20T21:14:00.000Z',
            'a_column_from_the_future': 'lost',
          },
        ],
      },
    }));

    expect(result.isPartial, isTrue);
    expect(result.unknownTables, ['a_table_from_the_future']);
    expect(result.droppedColumns, ['journal_entries.a_column_from_the_future']);
    // The page itself still came back. A restore that refuses everything
    // because of one unknown column would be worse than one that says so.
    expect(result.rowsByTable['journal_entries'], 1);
  });
}
