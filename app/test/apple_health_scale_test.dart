import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/privacy/apple_health_import.dart';
import 'package:eter/core/privacy/foreign_import.dart';
import 'package:flutter_test/flutter_test.dart';

/// Three years of a worn watch, at the shape a real export has.
///
/// The other Apple Health tests are about meaning; this one is about the fact
/// that the file is enormous and almost entirely made of records nothing here
/// wants. Two hundred heart-rate samples a day against one night of sleep is
/// the real ratio, and it is the reason the scanner filters on the raw tag
/// before parsing anything: reading the attributes of every record and throwing
/// them away was three quarters of the time this takes.
///
/// **Nothing here asserts a duration.** A test that times an operation fails on
/// a busy machine and passes on the author's, which this repository has been
/// bitten by before. What it asserts is that the shortcut did not lose
/// anything — the same counts, and the same report of what was left behind.
void main() {
  test('a large export is read whole, and reports what it skipped', () async {
    const days = 400;
    const samplesPerDay = 200;

    final buffer = StringBuffer('<HealthData>');
    for (var i = 0; i < days; i++) {
      final at = DateTime.utc(2023, 1, 1).add(Duration(days: i));
      final date = '${at.year}-${at.month.toString().padLeft(2, '0')}'
          '-${at.day.toString().padLeft(2, '0')}';
      for (final stage in const ['AsleepDeep', 'AsleepREM', 'AsleepCore']) {
        buffer.write(
          '<Record type="HKCategoryTypeIdentifierSleepAnalysis" '
          'value="HKCategoryValueSleepAnalysis$stage" '
          'startDate="$date 01:00:00 +0000" endDate="$date 02:00:00 +0000"/>',
        );
      }
      buffer.write(
        '<Record type="HKQuantityTypeIdentifierRestingHeartRate" '
        'unit="count/min" startDate="$date 08:00:00 +0000" value="52"/>',
      );
      buffer.write(
        '<Record type="HKQuantityTypeIdentifierBodyMass" unit="kg" '
        'startDate="$date 07:00:00 +0000" value="70.5"/>',
      );
      // The bulk of any real file, and none of it is wanted.
      for (var s = 0; s < samplesPerDay; s++) {
        buffer.write(
          '<Record type="HKQuantityTypeIdentifierHeartRate" unit="count/min" '
          'startDate="$date 08:00:00 +0000" value="70"/>',
        );
      }
    }
    buffer.write('</HealthData>');
    final xml = buffer.toString();

    // Chunked as a file arrives, not handed over whole.
    final records = await const AppleHealthImportSource().read(
      Stream.fromIterable([
        for (var at = 0; at < xml.length; at += 65536)
          xml.substring(at, at + 65536 > xml.length ? xml.length : at + 65536),
      ]),
    );

    expect(records.sleep, hasLength(days * 3));
    expect(records.weight, hasLength(days));
    expect(records.vitals, hasLength(days));
    // The filter runs before the attributes are parsed, and it still counts
    // what it drops — otherwise the shortcut would have quietly cost the one
    // thing a person needs to be told.
    expect(records.ignored['Heart rate'], days * samplesPerDay);
    expect(records.unreadableRows, 0);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final result =
        await ForeignImporter(database).write('Apple Health', records);

    // One night per day, not one row per segment: a night is what a person
    // recognises, and it is also what `replaceSleepForNight` writes.
    expect(result.sleepNightsWritten, days);
    expect(result.vitalDaysWritten, days);
    expect(result.weightWritten, days);
    expect(
      await database.select(database.sleepSegments).get(),
      hasLength(days * 3),
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
