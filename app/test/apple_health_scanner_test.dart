import 'package:eter/core/privacy/apple_health_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

/// The scanner that reads `export.xml` without holding it.
///
/// A phone carried for a few years produces one in the hundreds of megabytes,
/// so every test here is really about the same thing: nothing may depend on
/// having the whole file at once.
void main() {
  List<AppleHealthRecord> scanAll(List<String> chunks) {
    final scanner = AppleHealthScanner();
    final records = <AppleHealthRecord>[];
    for (final chunk in chunks) {
      records.addAll(scanner.add(chunk));
    }
    scanner.flush();
    return records;
  }

  const weight = '<Record type="HKQuantityTypeIdentifierBodyMass" '
      'unit="kg" startDate="2024-03-01 08:15:00 +0100" '
      'endDate="2024-03-01 08:15:00 +0100" value="70.5"/>';

  group('finding records', () {
    test('a self-closing record is read', () {
      final record = scanAll([weight]).single;
      expect(record.type, 'HKQuantityTypeIdentifierBodyMass');
      expect(record.unit, 'kg');
      expect(record.value, 70.5);
    });

    test('a record written with children reads the same', () {
      // Apple writes some records with a `MetadataEntry` inside them and a
      // closing tag. The attributes are on the opening tag either way.
      final record = scanAll([
        '<Record type="HKQuantityTypeIdentifierBodyMass" unit="kg" '
            'value="70.5">'
            '<MetadataEntry key="HKWasUserEntered" value="1"/>'
            '</Record>',
      ]).single;
      expect(record.value, 70.5);
    });

    test('elements that merely start with the same letters are not records',
        () {
      expect(scanAll(['<RecordingSession id="1"/>']), isEmpty);
    });

    test('other elements are ignored entirely', () {
      final records = scanAll([
        '<HealthData locale="en_GB">'
            '<ExportDate value="2026-08-04 12:00:00 +0100"/>'
            '<Me HKCharacteristicTypeIdentifierBiologicalSex="HKBiologicalSexMale"/>'
            '$weight'
            '</HealthData>',
      ]);
      expect(records, hasLength(1));
    });
  });

  group('chunk boundaries, which is the whole point', () {
    test('a record split anywhere still arrives exactly once', () {
      // The boundary falls mid-tag on almost every chunk of a real file, so
      // this is the ordinary case rather than an edge one.
      for (var at = 1; at < weight.length; at++) {
        final records = scanAll([weight.substring(0, at), weight.substring(at)]);
        expect(records, hasLength(1), reason: 'split at $at');
        expect(records.single.value, 70.5, reason: 'split at $at');
      }
    });

    test('a record split across three chunks arrives once', () {
      const third = weight.length ~/ 3;
      final records = scanAll([
        weight.substring(0, third),
        weight.substring(third, third * 2),
        weight.substring(third * 2),
      ]);
      expect(records, hasLength(1));
    });

    test('many records across arbitrary chunks are all found, once each', () {
      final file = List.generate(
        50,
        (i) => '<Record type="HKQuantityTypeIdentifierBodyMass" unit="kg" '
            'startDate="2024-03-01 08:15:00 +0100" value="$i"/>',
      ).join();
      for (final size in [1, 7, 33, 128, 1024]) {
        final chunks = <String>[];
        for (var at = 0; at < file.length; at += size) {
          chunks.add(file.substring(
            at,
            at + size > file.length ? file.length : at + size,
          ));
        }
        final records = scanAll(chunks);
        expect(records, hasLength(50), reason: 'chunks of $size');
        expect(
          records.map((record) => record.value).toList(),
          [for (var i = 0; i < 50; i++) i.toDouble()],
          reason: 'chunks of $size',
        );
      }
    });

    test('a file cut off mid-record loses that record and nothing else', () {
      final records = scanAll([weight, '<Record type="HKQuantityType']);
      expect(records, hasLength(1));
    });
  });

  group('attributes', () {
    test('a quoted value may contain the character that ends a tag', () {
      // `sourceName="Bob's > phone"` is somebody's actual device.
      final record = scanAll([
        '<Record type="X" sourceName="Bob&apos;s &gt; phone" value="1"/>',
      ]).single;
      expect(record['sourceName'], "Bob's > phone");
      expect(record.value, 1);
    });

    test('entity references come back as their characters', () {
      final record =
          scanAll(['<Record type="X" sourceName="Tom &amp; Jerry"/>']).single;
      expect(record['sourceName'], 'Tom & Jerry');
    });

    test('an escaped ampersand is not re-read as an entity', () {
      // `&amp;lt;` is the text "&lt;", not a less-than sign. Unescaping in the
      // wrong order turns somebody's note into a tag.
      final record =
          scanAll(['<Record type="X" sourceName="a &amp;lt; b"/>']).single;
      expect(record['sourceName'], 'a &lt; b');
    });

    test('single-quoted attributes are read too', () {
      final record = scanAll(["<Record type='X' value='2'/>"]).single;
      expect(record.type, 'X');
      expect(record.value, 2);
    });
  });

  group('the date format, which is not ISO', () {
    test('a wall clock and its offset become an instant', () {
      // The space instead of a T and the space before the offset both defeat
      // `DateTime.parse`.
      expect(
        parseAppleDate('2024-03-01 08:15:00 +0100'),
        DateTime.utc(2024, 3, 1, 7, 15),
      );
      expect(
        parseAppleDate('2024-03-01 08:15:00 -0500'),
        DateTime.utc(2024, 3, 1, 13, 15),
      );
    });

    test('the offset is not decoration', () {
      // A night recorded in one country and read in another lands on the wrong
      // day without it.
      final warsaw = parseAppleDate('2024-03-01 00:30:00 +0100')!;
      expect(warsaw.toUtc().day, 29);
    });

    test('a stamp with no offset is taken as written', () {
      expect(
        parseAppleDate('2024-03-01 08:15:00'),
        DateTime.utc(2024, 3, 1, 8, 15),
      );
    });

    test('a date nobody has is refused rather than rolled forward', () {
      expect(parseAppleDate('2024-02-31 08:15:00 +0100'), isNull);
      expect(parseAppleDate('2024-13-01 08:15:00 +0100'), isNull);
      expect(parseAppleDate('not a date'), isNull);
      expect(parseAppleDate(null), isNull);
    });
  });

  test('a tag that never closes does not grow the buffer for ever', () {
    // A file that is not what it claims to be. A real record is a few hundred
    // characters.
    final scanner = AppleHealthScanner(maximumTagLength: 64);
    for (var i = 0; i < 100; i++) {
      expect(scanner.add('<Record type="${'x' * 100}'), isEmpty);
    }
    // And it still reads the next real one.
    expect(scanner.add(weight), hasLength(1));
  });
}
