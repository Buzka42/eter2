import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/energy/energy.dart' as energy;
import 'package:eter/core/privacy/local_data_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local export contains every table and inspectable movement CSVs',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final destination =
        await Directory.systemTemp.createTemp('eter-export-test-');
    addTearDown(() async {
      await db.close();
      if (await destination.exists()) {
        await destination.delete(recursive: true);
      }
    });

    await db.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'other',
        weightKg: 70,
        units: 'metric',
      ),
    );
    final minute = DateTime.utc(2026, 7, 27, 8);
    await db.ingestRawBuckets([
      energy.MinuteBucket(
        minuteUtc: minute,
        activeKcal: 12.5,
        sourceId: 'healthConnect',
        priority: energy.SourcePriority.hub,
        steps: 140,
      ),
    ]);
    await db.recomputeMinuteWinners(
      minute,
      minute.add(const Duration(minutes: 1)),
    );
    await db.upsertActivitySession(
      ActivitySessionsCompanion.insert(
        id: 'walk-1',
        startUtc: minute,
        endUtc: minute.add(const Duration(minutes: 30)),
        source: 'healthConnect',
        priority: energy.SourcePriority.hub.index,
        activeKcal: const Value(90),
        sport: const Value('walking'),
      ),
    );

    final bundle = await LocalDataExporter(db).export(destination: destination);
    expect(await bundle.snapshot.exists(), isTrue);
    expect(bundle.csvFiles, hasLength(4));
    expect(bundle.csvFiles.every((file) => file.existsSync()), isTrue);

    final decoded = jsonDecode(await bundle.snapshot.readAsString())
        as Map<String, Object?>;
    expect(decoded['format'], 'eter-local-export');
    expect(decoded['scope'], 'device-local');
    final tables = decoded['tables'] as Map<String, Object?>;
    expect(
        tables.keys, containsAll(db.allTables.map((t) => t.actualTableName)));
    expect((tables['profiles'] as List<Object?>), hasLength(1));
    expect((tables['minute_buckets'] as List<Object?>), hasLength(1));

    final minutesCsv = await File(
      '${bundle.directory.path}${Platform.pathSeparator}minute_buckets.csv',
    ).readAsString();
    expect(minutesCsv, contains('active_kcal'));
    expect(minutesCsv, contains('healthConnect'));
    expect(minutesCsv, contains('12.5'));
  });
}
