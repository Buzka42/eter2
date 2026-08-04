import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/privacy/daylio_import.dart';
import 'package:eter/core/privacy/foreign_import.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading somebody's Daylio diary into Eter.
///
/// The export is eight columns and has been for years:
/// `full_date,date,weekday,time,mood,activities,note_title,note`.
void main() {
  const daylio = DaylioImportSource();

  String csv(List<String> rows) => [
        'full_date,date,weekday,time,mood,activities,note_title,note',
        ...rows,
      ].join('\n');

  group('recognising the file', () {
    test('a Daylio export is recognised by its own columns', () {
      expect(daylio.canRead(csv([])), isTrue);
    });

    test('somebody else\'s CSV is not', () {
      expect(
        daylio.canRead('date,weekday,time of day,rating/amount,detail'),
        isFalse,
      );
      expect(daylio.canRead('not a csv at all'), isFalse);
      expect(daylio.canRead(''), isFalse);
    });
  });

  group('the moment an entry was made', () {
    ForeignRecords readOne(String date, String time) =>
        daylio.read(csv(['$date,x,x,$time,good,,,"A note"']));

    test('a 24-hour clock', () {
      expect(
        readOne('2026-01-31', '22:30').journal.single.at,
        DateTime(2026, 1, 31, 22, 30),
      );
    });

    test('a 12-hour clock, which is what most phones export', () {
      // A reader that assumes 24-hour files every afternoon entry twelve
      // hours early, silently, on every row.
      expect(
        readOne('2026-01-31', '10:30 PM').journal.single.at,
        DateTime(2026, 1, 31, 22, 30),
      );
      expect(
        readOne('2026-01-31', '10:30 AM').journal.single.at,
        DateTime(2026, 1, 31, 10, 30),
      );
    });

    test('noon and midnight, which naive arithmetic gets backwards', () {
      expect(
        readOne('2026-01-31', '12:00 AM').journal.single.at,
        DateTime(2026, 1, 31, 0, 0),
      );
      expect(
        readOne('2026-01-31', '12:15 PM').journal.single.at,
        DateTime(2026, 1, 31, 12, 15),
      );
    });

    test('a date nobody has is unreadable, not filed in March', () {
      // `DateTime` rolls 31 February over rather than refusing it, so a row
      // like this would otherwise be imported against a day that never
      // happened for this person.
      final records = readOne('2026-02-31', '10:00');
      expect(records.journal, isEmpty);
      expect(records.unreadableRows, 1);
    });

    test('an unreadable row is reported, never filed at midnight', () {
      final records = daylio.read(csv([',x,x,,good,,,"A note"']));
      expect(records.isEmpty, isTrue);
      expect(records.unreadableRows, 1);
    });
  });

  group('what becomes a page', () {
    test('the note is the page, and the tags follow it', () {
      final entry = daylio
          .read(csv([
            '2026-01-31,x,x,08:00,good,'
                '"gym | coffee",'
                '"Morning","Slept well, ran early."',
          ]))
          .journal
          .single;
      expect(entry.text, contains('Morning'));
      expect(entry.text, contains('Slept well, ran early.'));
      // The person's own vocabulary, kept with the page rather than filed
      // into a schema invented for it.
      expect(entry.text, contains('gym, coffee'));
    });

    test('tags with no prose are not a page', () {
      // Nobody wrote "gym | coffee". The mood row already holds that moment,
      // and an empty page in the Journal is worse than no page.
      final records =
          daylio.read(csv(['2026-01-31,x,x,08:00,good,"gym | coffee",,']));
      expect(records.journal, isEmpty);
      expect(records.lifestyle, hasLength(1));
    });

    test('a note with commas and line breaks survives whole', () {
      final entry = daylio
          .read(csv([
            '2026-01-31,x,x,08:00,good,,,"First, with a comma.\nSecond line."',
          ]))
          .journal
          .single;
      expect(entry.text, 'First, with a comma.\nSecond line.');
    });
  });

  group('moods', () {
    test('the five shipped moods rank one to five', () {
      const expected = {
        'awful': 1.0,
        'bad': 2.0,
        'meh': 3.0,
        'good': 4.0,
        'rad': 5.0,
      };
      expected.forEach((mood, value) {
        expect(DaylioImportSource.moodValue(mood), value, reason: mood);
      });
    });

    test('a Polish diary exports Polish mood names', () {
      // The export is written in the app's own language. A reader that knows
      // only the English five would import a decade of feelings as unranked
      // words.
      expect(DaylioImportSource.moodValue('wspaniale'), 5);
      expect(DaylioImportSource.moodValue('dobrze'), 4);
      expect(DaylioImportSource.moodValue('tak sobie'), 3);
      expect(DaylioImportSource.moodValue('źle'), 2);
      expect(DaylioImportSource.moodValue('okropnie'), 1);
    });

    test('a mood somebody invented keeps its name and takes no number', () {
      // Ranking it in the middle would be a measurement nobody made.
      final records =
          daylio.read(csv(['2026-01-31,x,x,08:00,"blegh",,,']));
      final mood = records.lifestyle.single;
      expect(mood.kind, 'mood');
      expect(mood.value, isNull);
      expect(mood.note, 'blegh');
      expect(records.ignored['Custom mood: blegh'], 1);
    });
  });

  group('writing it into the record', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    Future<ForeignImportResult> import(String content) async =>
        (await ForeignImporter(database).importContent(
          content,
          sources: const [DaylioImportSource()],
        ))!;

    test('pages and moods both land, and the span is reported', () async {
      final result = await import(csv([
        '2024-03-01,x,x,08:00,good,,,"The first day."',
        '2026-01-31,x,x,21:00,meh,,,"The last one."',
      ]));

      expect(result.source, 'Daylio');
      expect(result.journalWritten, 2);
      expect(result.lifestyleWritten, 2);
      expect(result.earliest, DateTime(2024, 3, 1, 8));
      expect(result.latest, DateTime(2026, 1, 31, 21));
    });

    test('an imported page is not queued to be read by a model', () async {
      // A person pressing import has not asked to pay for a decade of their
      // own notes to be interpreted, and the queue would happily do it.
      await import(csv(['2026-01-31,x,x,08:00,good,,,"A note."']));
      final page = await database.select(database.journalEntries).getSingle();
      expect(page.status, foreignImportStatus);
      expect(page.status, isNot('pending'));
      expect(page.appliedAt, isNull);
    });

    test('importing the same file twice adds nothing the second time',
        () async {
      // The reason this does not need an empty device. Somebody importing
      // three years of Daylio has usually been using Eter for a fortnight
      // first, and may well press the button twice.
      final content = csv([
        '2026-01-30,x,x,08:00,good,,,"One."',
        '2026-01-31,x,x,08:00,bad,,,"Two."',
      ]);
      final first = await import(content);
      expect(first.written, 4);
      expect(first.duplicatesSkipped, 0);

      final second = await import(content);
      expect(second.written, 0);
      expect(second.duplicatesSkipped, 4);
      expect(
        await database.select(database.journalEntries).get(),
        hasLength(2),
      );
    });

    test('an overlapping export adds only what is new', () async {
      await import(csv(['2026-01-30,x,x,08:00,good,,,"One."']));
      final second = await import(csv([
        '2026-01-30,x,x,08:00,good,,,"One."',
        '2026-01-31,x,x,08:00,bad,,,"Two."',
      ]));
      expect(second.journalWritten, 1);
      expect(second.duplicatesSkipped, 2);
    });

    test('it does not need an empty device', () async {
      // The opposite rule to Eter's own restore, and deliberately so.
      await database.into(database.journalEntries).insert(
            JournalEntriesCompanion.insert(
              createdAt: DateTime(2026, 2, 1, 9),
              entryText: 'Something written in Eter itself.',
            ),
          );
      final result = await import(csv([
        '2026-01-31,x,x,08:00,good,,,"An older page from elsewhere."',
      ]));
      expect(result.journalWritten, 1);
      expect(
        await database.select(database.journalEntries).get(),
        hasLength(2),
      );
    });

    test('two people writing at the same minute are two pages', () async {
      // The natural key is the moment *and* the words: somebody who genuinely
      // wrote twice in one minute wrote two different things.
      final result = await import(csv([
        '2026-01-31,x,x,08:00,good,,,"One."',
        '2026-01-31,x,x,08:00,good,,,"Another."',
      ]));
      expect(result.journalWritten, 2);
      // But only one mood: one reading of one kind at one moment.
      expect(result.lifestyleWritten, 1);
      expect(result.duplicatesSkipped, 1);
    });

    test('an imported page is one the Journal will actually show', () async {
      // The difference between an import and a no-op. Pages reach the Journal
      // through `loadJournalForRange`, which filters by status — so a status
      // chosen to keep the interpretation queue away could just as easily have
      // hidden the pages from the person who imported them.
      await import(csv(['2026-01-31,x,x,08:00,good,,,"A note."']));
      final visible = await database.loadJournalForRange(
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 1),
      );
      expect(visible, hasLength(1));
      expect(visible.single.entryText, 'A note.');
    });

    test('a file nobody can read is not an error', () async {
      // Being handed a PDF is a mistake, not a failure.
      final result = await ForeignImporter(database).importContent(
        'this is not anybody\'s export',
        sources: const [DaylioImportSource()],
      );
      expect(result, isNull);
    });
  });
}
