@Tags(['manual'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/privacy/local_data_import.dart';
import 'package:flutter_test/flutter_test.dart';

/// The restore, against a **real** export rather than a hand-built one.
///
/// `local_data_import_test.dart` pins the rules on fixtures of three rows. This
/// one runs a snapshot taken off an actual phone — sixteen thousand rows,
/// every table the app has ever written, real timestamps with real offsets,
/// and whatever the health import happens to have produced. It is the only
/// version of this test that can catch a column the fixtures never exercised.
///
/// Skipped unless the file is there, because the file is somebody's record and
/// does not belong in the repository. To run it:
///
/// ```
/// adb exec-out "run-as com.eterhealth.eter cat 'app_flutter/Eter export .../eter-local-data.json'" > /tmp/real-export.json
/// flutter test test/manual/real_export_round_trip_test.dart --tags manual \
///   --dart-define=ETER_EXPORT=/tmp/real-export.json
/// ```
void main() {
  const path = String.fromEnvironment('ETER_EXPORT');

  test('a real export restores whole', () async {
    if (path.isEmpty || !File(path).existsSync()) {
      markTestSkipped('No export at ETER_EXPORT');
      return;
    }
    final raw = await File(path).readAsString();
    final snapshot = jsonDecode(raw) as Map<String, dynamic>;
    final tables = (snapshot['tables'] as Map<String, dynamic>).map(
      (name, rows) => MapEntry(name, (rows as List).length),
    );

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final result = await LocalDataImporter(database).importJson(raw);

    // Every row in the file, in the database. Not "no exception thrown": a
    // restore that silently drops a table is the failure this exists to catch.
    for (final entry in tables.entries) {
      if (entry.value == 0) continue;
      expect(
        result.rowsByTable[entry.key],
        entry.value,
        reason: '${entry.key}: ${entry.value} in the file',
      );
    }
    expect(result.unknownTables, isEmpty);
    expect(result.droppedColumns, isEmpty);

    // And the prose came back as prose, not as a truncated or re-encoded
    // approximation of it — the journal is the part nobody would notice was
    // subtly wrong.
    final pages = await database.loadJournalForRange(
      DateTime.utc(2000),
      DateTime.utc(2100),
    );
    final original = (snapshot['tables']['journal_entries'] as List)
        .map((row) => (row as Map)['text'] as String)
        .toSet();
    expect(pages.map((page) => page.entryText).toSet(), original);
  });
}
