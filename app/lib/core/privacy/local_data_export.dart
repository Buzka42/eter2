import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart';

class LocalExportBundle {
  const LocalExportBundle({
    required this.directory,
    required this.snapshot,
    required this.csvFiles,
  });

  final Directory directory;
  final File snapshot;
  final List<File> csvFiles;
}

/// Writes a user-readable local export without involving an account or
/// network service.
///
/// The JSON snapshot contains every Drift table. The CSV companions keep the
/// high-volume movement/session records practical to inspect in a spreadsheet.
/// A cloud export remains a separate authenticated Function because it has a
/// different source and deletion boundary.
class LocalDataExporter {
  const LocalDataExporter(this.database);

  final AppDatabase database;

  /// Where an export lands, in order of preference.
  ///
  /// The Downloads directory, because the old destination was the application
  /// documents directory — app-private, invisible to every file manager, and
  /// unreachable by the document picker, so you could export a record and then
  /// not be able to hand it to anything, including Eter's own restore.
  ///
  /// This is Android's **app-specific** Downloads
  /// (`Android/data/<package>/files/Download`), not the shared one. Writing to
  /// the shared folder needs `MANAGE_EXTERNAL_STORAGE`, which is a permission
  /// to read every file on the phone, and a product whose whole argument is
  /// that your record stays yours does not get to ask for that in order to
  /// save a JSON file. The app-specific folder is on external storage: the
  /// picker can see it, USB can see it, and it survives uninstall no better or
  /// worse than the documents directory did.
  ///
  /// Falls back to documents when the platform has no Downloads to offer.
  static Future<Directory> defaultDestination() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        await downloads.create(recursive: true);
        return downloads;
      }
    } on MissingPluginException {
      // Desktop test hosts and anything without the plugin registered.
    } on UnsupportedError {
      // A platform path_provider has no Downloads for.
    }
    return getApplicationDocumentsDirectory();
  }

  Future<LocalExportBundle> export({Directory? destination}) async {
    final base = destination ?? await defaultDestination();
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final directory = Directory(p.join(base.path, 'Eter export $stamp'));
    await directory.create(recursive: true);

    final tables = await database.exportLocalSnapshot();
    final snapshot = File(p.join(directory.path, 'eter-local-data.json'));
    await snapshot.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'format': 'eter-local-export',
        'formatVersion': 1,
        'databaseSchemaVersion': database.schemaVersion,
        'exportedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'scope': 'device-local',
        'tables': tables,
      }),
      flush: true,
    );

    final csvFiles = <File>[];
    for (final tableName in const [
      'raw_buckets',
      'minute_buckets',
      'activity_sessions',
      'live_sessions',
    ]) {
      final rows = tables[tableName] ?? const <Map<String, Object?>>[];
      final file = File(p.join(directory.path, '$tableName.csv'));
      await file.writeAsString(_toCsv(rows), flush: true);
      csvFiles.add(file);
    }

    final readme = File(p.join(directory.path, 'README.txt'));
    await readme.writeAsString(
      'This folder was created by Eter on this device.\n'
      'eter-local-data.json contains the complete local database snapshot.\n'
      'The CSV files contain raw/deduplicated movement and session records.\n'
      'No cloud account data is included in this local export.\n',
      flush: true,
    );

    return LocalExportBundle(
      directory: directory,
      snapshot: snapshot,
      csvFiles: csvFiles,
    );
  }

  static String _toCsv(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return '';
    final headers = <String>{
      for (final row in rows) ...row.keys,
    }.toList()
      ..sort();
    final buffer = StringBuffer()..writeln(headers.map(_escapeCsv).join(','));
    for (final row in rows) {
      buffer.writeln(
        headers.map((header) => _escapeCsv(row[header])).join(','),
      );
    }
    return buffer.toString();
  }

  static String _escapeCsv(Object? value) {
    final text = switch (value) {
      null => '',
      DateTime date => date.toUtc().toIso8601String(),
      _ => value.toString(),
    };
    if (!text.contains(RegExp('[",\\r\\n]'))) return text;
    return '"${text.replaceAll('"', '""')}"';
  }
}
