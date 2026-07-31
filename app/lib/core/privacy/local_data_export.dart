import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart';

class LocalExportBundle {
  const LocalExportBundle({
    required this.directory,
    required this.snapshot,
    required this.csvFiles,
    this.publishedTo,
  });

  final Directory directory;
  final File snapshot;
  final List<File> csvFiles;

  /// Where the copy in the phone's Downloads folder went, if one was made.
  /// Null on a platform with no shared Downloads, which is not a failure.
  final String? publishedTo;

  /// The path worth showing somebody: the one they can navigate to.
  String get readablePath => publishedTo ?? directory.path;
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

  /// The platform side of publishing into the shared Downloads collection.
  /// See `MainActivity.kt` for why it is MediaStore rather than a file write.
  static const _downloads = MethodChannel('eter/downloads');

  /// Two copies, on purpose.
  ///
  /// The bundle is written to storage this app owns — that copy always exists,
  /// needs no permission and no platform support, and is what the tests read.
  /// It is then *published* into the phone's shared Downloads, which is the
  /// copy a person can actually reach: the documents directory is invisible to
  /// every file manager and every document picker, so an export that only
  /// lived there could not be handed to anything, including Eter's own restore.
  ///
  /// Publishing is best-effort and its failure is not the export's failure.

  Future<LocalExportBundle> export({Directory? destination}) async {
    final base = destination ?? await getApplicationDocumentsDirectory();
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

    // And a copy where a person can actually find it.
    //
    // Everything above wrote to storage this app owns, which is the copy Eter
    // itself reads and the one that is guaranteed to exist. This publishes the
    // same files into the phone's Downloads, where a file manager, a cable and
    // Eter's own restore can all reach them. Best-effort on purpose: an export
    // that succeeded and could not be published is still an export.
    final published = await _publish(directory);

    return LocalExportBundle(
      directory: directory,
      snapshot: snapshot,
      csvFiles: csvFiles,
      publishedTo: published,
    );
  }

  /// Copies [directory] into the shared Downloads folder, returning the path a
  /// person would recognise, or null where the platform has no such place.
  static Future<String?> _publish(Directory directory) async {
    final folder = p.basename(directory.path);
    String? published;
    try {
      for (final file in directory.listSync().whereType<File>()) {
        final at = await _downloads.invokeMethod<String>('publish', {
          'path': file.path,
          'folder': folder,
        });
        published ??= at == null ? null : p.dirname(at);
      }
    } catch (_) {
      // Deliberately everything. Not Android, no plugin registered, MediaStore
      // refused, a test host with no binding — the answer is the same in every
      // case and it is not an error: the bundle above is already written, and
      // this copy only ever adds discoverability. An export that succeeded
      // must not be reported as failed because a convenience did not.
    }
    return published;
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
