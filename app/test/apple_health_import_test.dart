import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/energy/energy.dart' show SourcePriority;
import 'package:eter/core/privacy/apple_health_import.dart';
import 'package:eter/core/privacy/foreign_import.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading an Apple Health export.
///
/// The import that arrives when somebody changes phone rather than changes
/// app. It takes the long history — weight, sleep, resting heart rate, HRV —
/// and deliberately leaves everything the live pipeline already owns.
void main() {
  const apple = AppleHealthImportSource();

  Future<ForeignRecords> read(String xml) =>
      apple.read(Stream.value('<HealthData>$xml</HealthData>'));

  String record(String type, Map<String, String> attributes) {
    final pairs =
        attributes.entries.map((e) => '${e.key}="${e.value}"').join(' ');
    return '<Record type="$type" $pairs/>';
  }

  test('an export is recognised from its first characters alone', () {
    // Given the head of the file, because the whole point of this reader is
    // never to hold the whole of it.
    expect(
      AppleHealthImportSource.looksLikeExport(
        '<?xml version="1.0"?><!DOCTYPE HealthData><HealthData locale="en_GB">',
      ),
      isTrue,
    );
    expect(AppleHealthImportSource.looksLikeExport('full_date,mood'), isFalse);
  });

  group('weight', () {
    test('comes across in whichever unit the phone was set to', () async {
      final records = await read([
        record('HKQuantityTypeIdentifierBodyMass', {
          'unit': 'kg',
          'startDate': '2024-03-01 08:00:00 +0000',
          'value': '70.5',
        }),
        record('HKQuantityTypeIdentifierBodyMass', {
          'unit': 'lb',
          'startDate': '2024-03-02 08:00:00 +0000',
          'value': '154',
        }),
      ].join());
      expect(records.weight, hasLength(2));
      expect(records.weight.first.kg, closeTo(70.5, 0.001));
      expect(records.weight.last.kg, closeTo(69.85, 0.01));
    });

    test('an unstated unit is not kilograms by default', () async {
      // Guessing halves or doubles somebody's body.
      final records = await read(record(
        'HKQuantityTypeIdentifierBodyMass',
        {'startDate': '2024-03-01 08:00:00 +0000', 'value': '70.5'},
      ));
      expect(records.weight, isEmpty);
      expect(records.unreadableRows, 1);
    });
  });

  group('sleep', () {
    String asleep(String value, String from, String to) => record(
          'HKCategoryTypeIdentifierSleepAnalysis',
          {
            'value': value,
            'startDate': '2024-03-01 $from:00 +0000',
            'endDate': '2024-03-01 $to:00 +0000',
          },
        );

    test('the stages Apple has written across its versions', () async {
      // An export spanning watchOS 9 carries both shapes: staged nights after
      // it, one undifferentiated block before.
      final records = await read([
        asleep('HKCategoryValueSleepAnalysisAsleepDeep', '01:00', '02:00'),
        asleep('HKCategoryValueSleepAnalysisAsleepREM', '02:00', '03:00'),
        asleep('HKCategoryValueSleepAnalysisAsleepCore', '03:00', '04:00'),
        asleep('HKCategoryValueSleepAnalysisAwake', '04:00', '04:10'),
        asleep('HKCategoryValueSleepAnalysisInBed', '00:30', '05:00'),
      ].join());
      expect(
        records.sleep.map((one) => one.stage).toList(),
        ['deep', 'rem', 'light', 'awake', 'unknown'],
      );
    });

    test('a segment that ends before it starts is not a stretch of sleep',
        () async {
      // They turn up in real exports around daylight-saving changes.
      final records =
          await read(asleep('HKCategoryValueSleepAnalysisAsleep', '03:00', '02:00'));
      expect(records.sleep, isEmpty);
      expect(records.unreadableRows, 1);
    });

    test('a night belongs to the date it ended on', () {
      // Sleep crosses midnight, so the date it started on is the wrong answer
      // for almost every night there is.
      final segment = ForeignSleepSegment(
        start: DateTime(2024, 3, 1, 23, 30).toUtc(),
        end: DateTime(2024, 3, 2, 7, 15).toUtc(),
        stage: 'light',
        source: 'x',
      );
      expect(segment.nightOf, '2024-03-02');
    });
  });

  group('vitals', () {
    test('many samples a day become one row a day', () async {
      final records = await read([
        record('HKQuantityTypeIdentifierRestingHeartRate', {
          'unit': 'count/min',
          'startDate': '2024-03-01 08:00:00 +0000',
          'value': '50',
        }),
        record('HKQuantityTypeIdentifierRestingHeartRate', {
          'unit': 'count/min',
          'startDate': '2024-03-01 20:00:00 +0000',
          'value': '60',
        }),
        record('HKQuantityTypeIdentifierHeartRateVariabilitySDNN', {
          'unit': 'ms',
          'startDate': '2024-03-01 08:00:00 +0000',
          'value': '62',
        }),
      ].join());
      final day = records.vitals.single;
      expect(day.date, '2024-03-01');
      expect(day.restingHr, 55);
      expect(day.hrvMs, 62);
    });

    test('variability in a unit that is not milliseconds is left alone',
        () async {
      // Not a conversion problem — a different measurement.
      final records = await read(record(
        'HKQuantityTypeIdentifierHeartRateVariabilitySDNN',
        {
          'unit': 's',
          'startDate': '2024-03-01 08:00:00 +0000',
          'value': '0.062',
        },
      ));
      expect(records.vitals, isEmpty);
      expect(records.ignored.keys.single, contains('variability'));
    });
  });

  test('what it does not take is named rather than lumped', () async {
    // Somebody deciding whether to keep the old phone needs to know what did
    // not come across, and "Step count" is what they would call it.
    final records = await read([
      record('HKQuantityTypeIdentifierStepCount', {
        'unit': 'count',
        'startDate': '2024-03-01 08:00:00 +0000',
        'value': '400',
      }),
      record('HKQuantityTypeIdentifierActiveEnergyBurned', {
        'unit': 'kcal',
        'startDate': '2024-03-01 08:00:00 +0000',
        'value': '12',
      }),
    ].join());
    expect(records.ignored['Step count'], 1);
    expect(records.ignored['Active energy burned'], 1);
    // Steps and energy belong to the live pipeline. A file carries no notion
    // of which device measured what, so importing them would double the days
    // a connected source is already reporting.
    expect(records.isEmpty, isTrue);
  });

  test('it reads across chunk boundaries, which is how the file arrives',
      () async {
    final xml = List.generate(
      20,
      (i) => record('HKQuantityTypeIdentifierBodyMass', {
        'unit': 'kg',
        'startDate': '2024-03-${(i + 1).toString().padLeft(2, '0')} '
            '08:00:00 +0000',
        'value': '${70 + i}',
      }),
    ).join();
    final records = await apple.read(
      Stream.fromIterable([
        for (var at = 0; at < xml.length; at += 13)
          xml.substring(at, at + 13 > xml.length ? xml.length : at + 13),
      ]),
    );
    expect(records.weight, hasLength(20));
  });

  group('writing it into the record', () {
    late AppDatabase database;
    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    String night(String value, String from, String to) => record(
          'HKCategoryTypeIdentifierSleepAnalysis',
          {
            'value': value,
            'startDate': '2024-03-01 $from:00 +0000',
            'endDate': '2024-03-0${to.startsWith('0') ? '2' : '1'} $to:00 '
                '+0000',
          },
        );

    Future<ForeignImportResult> import(String xml) async =>
        ForeignImporter(database).write(
          apple.name,
          await read(xml),
        );

    test('sleep is written last in priority, behind everything live',
        () async {
      // A file is a snapshot of what another phone thought. Where it and a
      // live source disagree about a night, the live one was measured here.
      await import(
        night('HKCategoryValueSleepAnalysisAsleepDeep', '01:00', '02:00'),
      );
      final segment =
          await database.select(database.sleepSegments).getSingle();
      expect(segment.priority, SourcePriority.importedFile.index);
      expect(segment.source, AppleHealthImportSource.sourceId);
    });

    test('a whole-night block is dropped where real stages exist', () async {
      // The same rule the hub follows: keeping both puts an "unknown" beside a
      // breakdown of the same minutes and doubles every total built on it.
      await import([
        night('HKCategoryValueSleepAnalysisInBed', '00:30', '05:00'),
        night('HKCategoryValueSleepAnalysisAsleepDeep', '01:00', '02:00'),
        night('HKCategoryValueSleepAnalysisAsleepREM', '02:00', '03:00'),
      ].join());
      final stages = await database.select(database.sleepSegments).get();
      expect(stages.map((one) => one.stage).toSet(), {'deep', 'rem'});
    });

    test('importing twice leaves one night, not two overlapping copies',
        () async {
      final xml = [
        night('HKCategoryValueSleepAnalysisAsleepDeep', '01:00', '02:00'),
        night('HKCategoryValueSleepAnalysisAsleepREM', '02:00', '03:00'),
      ].join();
      await import(xml);
      await import(xml);
      expect(await database.select(database.sleepSegments).get(), hasLength(2));
    });

    test('a day the device already measured is left exactly as it was',
        () async {
      // `DailyVitals` holds one row per date whatever measured it, so a
      // snapshot from an old phone must not overwrite what this one recorded.
      await database.into(database.dailyVitals).insert(
            DailyVitalsCompanion.insert(
              date: '2024-03-01',
              restingHr: const Value(48),
              source: 'hub:watch',
            ),
          );
      final result = await import(record(
        'HKQuantityTypeIdentifierRestingHeartRate',
        {
          'unit': 'count/min',
          'startDate': '2024-03-01 08:00:00 +0000',
          'value': '60',
        },
      ));
      final row = await database.select(database.dailyVitals).getSingle();
      expect(row.restingHr, 48);
      expect(row.source, 'hub:watch');
      expect(result.vitalDaysWritten, 0);
      // Reported rather than silent: it is the answer to "why does last March
      // still look empty".
      expect(result.vitalDaysLeftAlone, 1);
    });

    test('a day nobody has measured is filled in', () async {
      final result = await import(record(
        'HKQuantityTypeIdentifierRestingHeartRate',
        {
          'unit': 'count/min',
          'startDate': '2024-03-01 08:00:00 +0000',
          'value': '60',
        },
      ));
      expect(result.vitalDaysWritten, 1);
      final row = await database.select(database.dailyVitals).getSingle();
      expect(row.restingHr, 60);
      expect(row.source, AppleHealthImportSource.sourceId);
    });

    test('weight is written once however often the file is read', () async {
      final xml = record('HKQuantityTypeIdentifierBodyMass', {
        'unit': 'kg',
        'startDate': '2024-03-01 08:00:00 +0000',
        'value': '70.5',
      });
      await import(xml);
      final second = await import(xml);
      expect(second.weightWritten, 0);
      expect(second.duplicatesSkipped, 1);
      expect(await database.select(database.weightEntries).get(), hasLength(1));
    });
  });
}
