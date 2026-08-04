import 'package:eter/core/privacy/csv.dart';
import 'package:flutter_test/flutter_test.dart';

/// The reader that every foreign import stands on.
///
/// These files are exports from mood diaries, so the awkward cases are not
/// edge cases: a note with a comma in it is the normal case, and a note with a
/// line break in it is a Tuesday.
void main() {
  group('fields', () {
    test('plain rows split on commas', () {
      expect(
        parseCsv('a,b,c\n1,2,3'),
        [
          ['a', 'b', 'c'],
          ['1', '2', '3'],
        ],
      );
    });

    test('a quoted field keeps its commas', () {
      expect(
        parseCsv('date,note\n2026-01-01,"Rain, then sun"').last,
        ['2026-01-01', 'Rain, then sun'],
      );
    });

    test('a quoted field keeps its line breaks', () {
      // Somebody's diary entry with a paragraph in it. Splitting on newlines
      // first — which is how nearly every quick CSV reader is written — turns
      // this one entry into two rows, the second of which is not a record.
      final rows = parseCsv('date,note\n2026-01-01,"First line\nSecond line"');
      expect(rows, hasLength(2));
      expect(rows.last.last, 'First line\nSecond line');
    });

    test('a doubled quote is one quote', () {
      expect(
        parseCsv('note\n"She said ""no"" twice"').last.single,
        'She said "no" twice',
      );
    });

    test('a quote inside an unquoted field is a character', () {
      // Refusing the file over this would be refusing somebody's diary over
      // their punctuation.
      expect(parseCsv('note\n5" of snow').last.single, '5" of snow');
    });

    test('empty fields survive, including a trailing one', () {
      expect(parseCsv('a,,c').single, ['a', '', 'c']);
      expect(parseCsv('a,b,').single, ['a', 'b', '']);
    });

    test('a quoted empty last field is still a field', () {
      expect(parseCsv('a,b,""').single, ['a', 'b', '']);
    });
  });

  group('line endings', () {
    test('CRLF reads the same as LF', () {
      expect(parseCsv('a,b\r\n1,2'), parseCsv('a,b\n1,2'));
    });

    test('a final newline does not invent an empty row', () {
      expect(parseCsv('a,b\n1,2\n'), hasLength(2));
    });

    test('a last line with no terminator is still read', () {
      expect(parseCsv('a,b\n1,2').last, ['1', '2']);
    });
  });

  test('a byte-order mark is not part of the first column name', () {
    // Invisible, not a separator, and left in place it renames the first
    // column to something no lookup will ever match.
    final table = CsvTable.read('﻿full_date,mood\n2026-01-01,good')!;
    expect(table.has('full_date'), isTrue);
    expect(table.field(table.rows.single, 'full_date'), '2026-01-01');
  });

  group('the table', () {
    test('columns are found whatever their case or padding', () {
      // The same column is spelled differently between an app's own versions,
      // and it is still the same column.
      final table = CsvTable.read('Rating/Amount , Detail\n3,Mood')!;
      expect(table.has('rating/amount'), isTrue);
      expect(table.field(table.rows.single, 'DETAIL'), 'Mood');
    });

    test('a missing column and a short row both read as empty', () {
      // An exporter that omits trailing empty fields produces short rows on
      // every entry that ended without a note. That is not a broken file.
      final table = CsvTable.read('date,mood,note\n2026-01-01,good')!;
      expect(table.field(table.rows.single, 'note'), '');
      expect(table.field(table.rows.single, 'nothing'), '');
    });

    test('blank rows are dropped, wherever they are', () {
      final table = CsvTable.read('\n\ndate,mood\n2026-01-01,good\n\n')!;
      expect(table.header, ['date', 'mood']);
      expect(table.rows, hasLength(1));
    });

    test('an empty file is not a table', () {
      expect(CsvTable.read(''), isNull);
      expect(CsvTable.read('\n\n  \n'), isNull);
    });

    test('hasAll is how a format is recognised', () {
      final table = CsvTable.read('full_date,time,mood,note')!;
      expect(table.hasAll(['full_date', 'mood']), isTrue);
      expect(table.hasAll(['full_date', 'rating/amount']), isFalse);
    });
  });
}
