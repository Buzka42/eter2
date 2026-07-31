/// Reads back what [LocalDataExporter] wrote.
///
/// The export has always been a versioned snapshot of every table and nothing
/// could read one, which made "export" a promise the product only half kept:
/// you could take your record out and never put it back. This is the other
/// half, and it is deliberately small — the format is already versioned and
/// already complete, so a restore is validation plus an insert.
///
/// **It only fills an empty device.** The same promise the cloud Restore makes,
/// for the same reason: merging two records means deciding which of two
/// versions of last Tuesday is true, and there is no answer to that which is
/// not a guess. Refusing is the honest behaviour, and it is the one that cannot
/// destroy anything.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

class LocalImportException implements Exception {
  const LocalImportException(this.reason);
  final String reason;

  @override
  String toString() => reason;
}

/// What a restore actually did, in enough detail to be reported rather than
/// summarised as "done".
class LocalImportResult {
  const LocalImportResult({
    required this.rowsByTable,
    required this.unknownTables,
    required this.droppedColumns,
  });

  /// Rows written, per table. Tables that were empty in the snapshot are
  /// present with zero rather than absent, so a reader can tell "there was
  /// nothing" from "it was not in the file".
  final Map<String, int> rowsByTable;

  /// Tables in the file this build has never heard of. Kept rather than
  /// swallowed: a snapshot from a newer Eter will have some, and the person
  /// deserves to know their letters did not come back.
  final List<String> unknownTables;

  /// `table.column` pairs present in the file and absent from this schema.
  final List<String> droppedColumns;

  int get rows => rowsByTable.values.fold(0, (sum, count) => sum + count);

  /// True when something in the file could not be restored. Not a failure —
  /// the restore happened — but not a clean one either, and the difference is
  /// the person's to know.
  bool get isPartial => unknownTables.isNotEmpty || droppedColumns.isNotEmpty;
}

class LocalDataImporter {
  const LocalDataImporter(this.database);

  final AppDatabase database;

  static const format = 'eter-local-export';
  static const formatVersion = 1;

  Future<LocalImportResult> importFile(File snapshot) async {
    if (!await snapshot.exists()) {
      throw const LocalImportException('That file is not there.');
    }
    return importJson(await snapshot.readAsString());
  }

  Future<LocalImportResult> importJson(String raw) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const LocalImportException('That file is not an Eter export.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const LocalImportException('That file is not an Eter export.');
    }
    if (decoded['format'] != format) {
      throw const LocalImportException('That file is not an Eter export.');
    }
    if (decoded['formatVersion'] != formatVersion) {
      throw const LocalImportException(
        'That export was written in a format this version cannot read.',
      );
    }
    // A snapshot from a *newer* schema may carry columns whose meaning this
    // build does not know — not merely their names. Refusing is the only safe
    // answer; an older one is fine, because migrations have already run.
    final snapshotSchema = decoded['databaseSchemaVersion'];
    if (snapshotSchema is int && snapshotSchema > database.schemaVersion) {
      throw const LocalImportException(
        'That export came from a newer Eter. Update this one first.',
      );
    }
    final tables = decoded['tables'];
    if (tables is! Map<String, dynamic>) {
      throw const LocalImportException('That export has no records in it.');
    }

    if (!await _isEmpty()) {
      throw const LocalImportException(
        'This device already has history, so nothing was restored.',
      );
    }

    final known = {
      for (final table in database.allTables) table.actualTableName: table,
    };
    final unknownTables = <String>[];
    final droppedColumns = <String>{};
    final rowsByTable = <String, int>{};

    await database.transaction(() async {
      for (final entry in tables.entries) {
        final table = known[entry.key];
        if (table == null) {
          unknownTables.add(entry.key);
          continue;
        }
        final columns = {
          for (final column in table.$columns) column.name: column,
        };
        final rows = entry.value;
        if (rows is! List) continue;
        var written = 0;
        for (final row in rows) {
          if (row is! Map<String, dynamic>) continue;
          final values = <String, Expression<Object>>{};
          for (final field in row.entries) {
            final column = columns[field.key];
            if (column == null) {
              droppedColumns.add('${entry.key}.${field.key}');
              continue;
            }
            values[field.key] = Variable<Object>(field.value);
          }
          if (values.isEmpty) continue;
          // A raw insert rather than `into(table).insert`.
          //
          // Drift's typed insert runs `validateIntegrity`, which is written for
          // rows the app is composing — it insists a required column be present
          // in the insertable. A restore is not composing anything: it is
          // putting back bytes this same schema wrote, and a row that was legal
          // on the way out is legal on the way back in. Validating it again
          // rejects perfectly good history for the shape of the map it arrived
          // in.
          final names = values.keys.map((name) => '"$name"').join(', ');
          final placeholders =
              List.filled(values.length, '?').join(', ');
          await database.customInsert(
            'INSERT OR REPLACE INTO "${entry.key}" ($names) '
            'VALUES ($placeholders)',
            variables: [
              for (final value in values.values) value as Variable<Object>,
            ],
          );
          written++;
        }
        rowsByTable[entry.key] = written;
      }
    });

    return LocalImportResult(
      rowsByTable: rowsByTable,
      unknownTables: unknownTables,
      droppedColumns: droppedColumns.toList()..sort(),
    );
  }

  /// Empty means *no record*, not a pristine file.
  ///
  /// A device that has only been through onboarding has a profile row and
  /// nothing else, and refusing to restore onto it would make the feature
  /// useless in exactly the case it exists for: a new phone. So the profile is
  /// not counted, and every table that holds something the person made or
  /// measured is.
  Future<bool> _isEmpty() async {
    for (final table in database.allTables) {
      if (table.actualTableName == 'profiles') continue;
      final rows = await database
          .customSelect(
            'SELECT 1 FROM "${table.actualTableName}" LIMIT 1',
            readsFrom: {table},
          )
          .get();
      if (rows.isNotEmpty) return false;
    }
    return true;
  }
}
