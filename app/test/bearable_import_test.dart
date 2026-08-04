import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/lifestyle/daily_check_in.dart';
import 'package:eter/core/privacy/bearable_import.dart';
import 'package:eter/core/privacy/daylio_import.dart';
import 'package:eter/core/privacy/foreign_import.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading a Bearable export.
///
/// One row is one *reading*, not one entry, so a single day produces many rows
/// of different kinds — and the scale those readings are on is not stated
/// anywhere in the file.
void main() {
  const bearable = BearableImportSource();

  String csv(List<String> rows) => [
        'date,weekday,time of day,category,rating/amount,detail,notes',
        ...rows,
      ].join('\n');

  group('recognising the file', () {
    test('a Bearable export is recognised by its own columns', () {
      expect(bearable.canRead(csv([])), isTrue);
    });

    test('a Daylio export is not, and neither reader claims both', () {
      const daylioFile =
          'full_date,date,weekday,time,mood,activities,note_title,note';
      expect(bearable.canRead(daylioFile), isFalse);
      expect(const DaylioImportSource().canRead(csv([])), isFalse);
    });
  });

  group('the date, which is the awkward part', () {
    test('an ordinal suffix and an abbreviated month', () {
      // Nothing that reads ISO dates will read a single date in this file.
      expect(
        BearableImportSource.moment('22nd Jan 2022', ''),
        DateTime(2022, 1, 22),
      );
      expect(
        BearableImportSource.moment('1st March 2024', '09:30'),
        DateTime(2024, 3, 1, 9, 30),
      );
      expect(
        BearableImportSource.moment('3rd Sep 2023', '10:15 PM'),
        DateTime(2023, 9, 3, 22, 15),
      );
    });

    test('a reading with no clock still belongs to its own day', () {
      // Midnight local, so the Long View buckets it on the right date rather
      // than the day before.
      expect(
        BearableImportSource.moment('22nd Jan 2022', ''),
        DateTime(2022, 1, 22, 0, 0),
      );
    });

    test('a time of day written as a word does not lose the reading', () {
      // Some versions bucket readings into parts of the day rather than
      // writing a clock. The reading still belongs to its date.
      expect(
        BearableImportSource.moment('22nd Jan 2022', 'morning'),
        DateTime(2022, 1, 22),
      );
    });

    test('a date that is not a date is refused', () {
      expect(BearableImportSource.moment('2022-01-22', ''), isNull);
      expect(BearableImportSource.moment('31st Feb 2022', ''), isNull);
      expect(BearableImportSource.moment('', ''), isNull);
    });
  });

  group('the scale, which the file does not state', () {
    test('a rating above five proves the scale is not five', () {
      const wide = BearableScale(highest: 10);
      expect(wide.isWide, isTrue);
      // The best day recorded is the top of Eter's chart, not off it.
      expect(wide.map(10), 5);
      expect(wide.map(0), 1);
      expect(wide.map(5), closeTo(3, 0.001));
    });

    test('a file already inside the range is left alone', () {
      const narrow = BearableScale(highest: 5);
      expect(narrow.isWide, isFalse);
      expect(narrow.map(4), 4);
      // Bearable's bottom is zero and Eter's is one.
      expect(narrow.map(0), 1);
    });

    test('a wide file is mapped onto the scale Eter actually plots', () {
      // The Long View averages `value` across a day and draws it on a
      // five-point axis. An 8 written in raw is not a bad import, it is a
      // corrupt one, and nothing downstream could tell.
      final records = bearable.read(csv([
        '22nd Jan 2022,Sat,09:00,Mood,9,Mood,',
        '23rd Jan 2022,Sun,09:00,Mood,2,Mood,',
      ]));
      for (final entry in records.lifestyle) {
        expect(entry.value, inInclusiveRange(1, 5));
      }
      expect(records.lifestyle.first.value, 5);
    });

    test('every imported value fits the scale the margin collects', () {
      // Tied to the product's own definition rather than to the number five,
      // so a change to one is a failure in the other rather than a silent
      // disagreement.
      final records = bearable.read(csv([
        for (var rating = 0; rating <= 10; rating++)
          '${rating + 1}st Jan 2022,Sat,09:00,Mood,$rating,Mood,',
      ]));
      for (final entry in records.lifestyle) {
        expect(entry.value, isNotNull);
        expect(entry.value! >= 1, isTrue);
        expect(
          entry.value! <= LifestyleReading.marks.length,
          isTrue,
          reason: '${entry.value}',
        );
      }
    });

    test('the reading is kept verbatim beside the mapped value', () {
      // Nothing is lost to the mapping, and anybody checking can see what it
      // came from.
      final entry = bearable
          .read(csv(['22nd Jan 2022,Sat,09:00,Mood,9,Mood,']))
          .lifestyle
          .single;
      expect(entry.note, contains('9'));
    });
  });

  group('what is imported and what is only counted', () {
    test('mood and sleep are kept; a symptom is not translated', () {
      // A symptom is not a mood, and mapping it would put a number in a
      // column that means something else — which the Long View would then
      // average into somebody's mood.
      final records = bearable.read(csv([
        '22nd Jan 2022,Sat,09:00,Mood,4,Mood,',
        '22nd Jan 2022,Sat,09:00,Sleep,3,Sleep quality,',
        '22nd Jan 2022,Sat,09:00,Symptom,2,Headache,',
        '22nd Jan 2022,Sat,09:00,Medication,1,Ibuprofen,',
      ]));
      expect(
        records.lifestyle.map((entry) => entry.kind).toSet(),
        {'mood', 'sleep'},
      );
      // Named rather than counted in one lump: somebody deciding whether to
      // keep the other app installed needs to know what did not come across.
      expect(records.ignored['Symptom'], 1);
      expect(records.ignored['Medication'], 1);
    });

    test('notes become pages, and a note repeated on every row is one page',
        () {
      final records = bearable.read(csv([
        '22nd Jan 2022,Sat,09:00,Mood,4,Mood,"A hard morning."',
        '22nd Jan 2022,Sat,09:00,Sleep,3,Sleep quality,"A hard morning."',
      ]));
      expect(records.journal, hasLength(1));
      expect(records.journal.single.text, 'A hard morning.');
    });
  });

  group('weight, where the unit decides everything', () {
    test('kilograms and pounds both come across correctly', () {
      final kg = bearable
          .read(csv(['22nd Jan 2022,Sat,09:00,Measurement,70,Weight (kg),']))
          .weight
          .single;
      expect(kg.kg, closeTo(70, 0.001));

      final pounds = bearable
          .read(csv(['22nd Jan 2022,Sat,09:00,Measurement,154,Weight (lbs),']))
          .weight
          .single;
      expect(pounds.kg, closeTo(69.85, 0.01));
    });

    test('an unstated unit is refused rather than assumed', () {
      // A reader that picks one halves or doubles somebody's body.
      final records = bearable
          .read(csv(['22nd Jan 2022,Sat,09:00,Measurement,70,Weight,']));
      expect(records.weight, isEmpty);
      expect(records.ignored['Weight in an unstated unit'], 1);
    });
  });

  test('it writes into the record and does not double-write', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final content = csv([
      '22nd Jan 2022,Sat,09:00,Mood,4,Mood,"A hard morning."',
      '23rd Jan 2022,Sun,09:00,Mood,5,Mood,',
    ]);

    final first = await ForeignImporter(database).importContent(
      content,
      sources: const [DaylioImportSource(), BearableImportSource()],
    );
    expect(first!.source, 'Bearable');
    expect(first.journalWritten, 1);
    expect(first.lifestyleWritten, 2);

    final second = await ForeignImporter(database).importContent(
      content,
      sources: const [DaylioImportSource(), BearableImportSource()],
    );
    expect(second!.written, 0);
    expect(second.duplicatesSkipped, 3);
  });
}
