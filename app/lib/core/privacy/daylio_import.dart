/// Reads a Daylio CSV export.
///
/// Daylio is a mood diary: one entry is a moment, a mood, a set of activity
/// tags and optionally a note. Its export is eight columns and has been for
/// years —
///
/// ```
/// full_date,date,weekday,time,mood,activities,note_title,note
/// ```
///
/// — of which `full_date`, `time`, `mood`, `activities`, `note_title` and
/// `note` carry anything; `date` and `weekday` are `full_date` written out for
/// a human and are ignored.
///
/// **Where it lands.** The note becomes a journal page, because it is the
/// person's own prose and that is what the Journal holds. The mood becomes a
/// `LifestyleEntries` row of kind `mood`, which is the table Eter already keeps
/// self-reports in. The activity tags travel *with the page* rather than into a
/// table of their own: they are the person's own vocabulary — "gym", "sad
/// morning", "saw M." — and inventing a schema for a tag set nobody has seen
/// would be inventing meaning.
///
/// **What is not translated.** Daylio's moods are named, ordered and editable.
/// The five it ships with map onto a one-to-five scale; a mood somebody added
/// themselves does not, and is written with its name and **no number**, because
/// a custom mood ranked in the middle by default is a measurement nobody made.
library;

import 'csv.dart';
import 'foreign_import.dart';

class DaylioImportSource implements ForeignImportSource {
  const DaylioImportSource();

  @override
  String get name => 'Daylio';

  /// The columns that make a file a Daylio export.
  ///
  /// `full_date` and `mood` together are enough to be certain: no other export
  /// this reads has either name, and Daylio has had both since it first had a
  /// CSV.
  static const _signature = ['full_date', 'mood'];

  @override
  bool canRead(String content) {
    final table = CsvTable.read(content);
    return table != null && table.hasAll(_signature);
  }

  @override
  ForeignRecords read(String content) {
    final table = CsvTable.read(content);
    if (table == null) return const ForeignRecords();

    final journal = <ForeignJournalEntry>[];
    final lifestyle = <ForeignLifestyleEntry>[];
    final ignored = <String, int>{};
    var unreadable = 0;

    for (final row in table.rows) {
      final at = _moment(
        table.field(row, 'full_date'),
        table.field(row, 'time'),
      );
      if (at == null) {
        unreadable++;
        continue;
      }

      final mood = table.field(row, 'mood');
      if (mood.isNotEmpty) {
        final value = moodValue(mood);
        if (value == null) {
          // Counted by name, so the report can say which of somebody's own
          // moods came across as a word rather than as a measurement.
          ignored['Custom mood: $mood'] = (ignored['Custom mood: $mood'] ?? 0) + 1;
        }
        lifestyle.add(ForeignLifestyleEntry(
          at: at,
          kind: 'mood',
          value: value,
          note: mood,
          source: 'daylio',
        ));
      }

      final text = _page(
        title: table.field(row, 'note_title'),
        note: table.field(row, 'note'),
        activities: table.field(row, 'activities'),
      );
      if (text != null) {
        journal.add(ForeignJournalEntry(at: at, text: text));
      }
    }

    return ForeignRecords(
      journal: journal,
      lifestyle: lifestyle,
      ignored: ignored,
      unreadableRows: unreadable,
    );
  }

  /// The page as Eter will hold it: the title, the note, and the tags on a
  /// line of their own.
  ///
  /// Returns null when there is nothing but tags and no prose at all. A page
  /// reading only "gym | coffee" is not something anybody wrote; the mood row
  /// already carries that moment, and an empty page in the Journal is worse
  /// than no page.
  static String? _page({
    required String title,
    required String note,
    required String activities,
  }) {
    final tags = _tags(activities);
    final body = [
      if (title.isNotEmpty) title,
      if (note.isNotEmpty) note,
    ].join('\n\n');
    if (body.isEmpty) return null;
    if (tags.isEmpty) return body;
    return '$body\n\n${tags.join(', ')}';
  }

  /// Daylio separates tags with a pipe, and the pipe usually has spaces around
  /// it. Empty pieces are dropped rather than becoming empty tags.
  static List<String> _tags(String activities) => [
        for (final tag in activities.split('|'))
          if (tag.trim().isNotEmpty) tag.trim(),
      ];

  /// `2026-01-31` plus `10:30 AM`, `10:30 PM` or `22:30`.
  ///
  /// Daylio writes the time in whichever clock the phone was set to, so both
  /// forms turn up in real files — and a reader that assumes 24-hour silently
  /// files every afternoon entry twelve hours early. Returns null rather than
  /// guessing at anything it cannot read: a row with no readable moment is
  /// reported as unreadable, never filed at midnight.
  static DateTime? _moment(String date, String time) {
    final day = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(date);
    if (day == null) return null;
    final year = int.parse(day.group(1)!);
    final month = int.parse(day.group(2)!);
    final dayOfMonth = int.parse(day.group(3)!);
    if (month < 1 || month > 12 || dayOfMonth < 1 || dayOfMonth > 31) {
      return null;
    }

    var hour = 0;
    var minute = 0;
    if (time.isNotEmpty) {
      final clock = RegExp(
        r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$',
      ).firstMatch(time.trim());
      if (clock == null) return null;
      hour = int.parse(clock.group(1)!);
      minute = int.parse(clock.group(2)!);
      final meridiem = clock.group(3)?.toLowerCase();
      if (meridiem != null) {
        if (hour < 1 || hour > 12) return null;
        // 12 AM is midnight and 12 PM is noon, which is the one case a naive
        // `hour + 12` gets exactly backwards at both ends of the day.
        hour = hour % 12;
        if (meridiem == 'pm') hour += 12;
      }
      if (hour > 23 || minute > 59) return null;
    }

    final at = DateTime(year, month, dayOfMonth, hour, minute);
    // `DateTime` rolls a 31st of February over into March rather than
    // refusing it, so the only way to know the date was real is to look at
    // what came back.
    if (at.month != month || at.day != dayOfMonth) return null;
    return at;
  }

  /// Daylio's five shipped moods, in the order it ranks them, in both of the
  /// languages this product speaks.
  ///
  /// A Polish phone exports Polish mood names — the export is written in the
  /// app's own language, not in English — so a reader that knows only the
  /// English five would treat every mood in a Polish diary as a custom one and
  /// import a decade of feelings as unranked words.
  ///
  /// Five points, one to five, worst to best. Anything else returns null: a
  /// mood somebody invented has no place on this scale, and putting it in the
  /// middle would be a number nobody measured.
  static double? moodValue(String mood) => switch (mood.trim().toLowerCase()) {
        'awful' || 'okropnie' || 'okropny' => 1,
        'bad' || 'źle' || 'zły' || 'zle' => 2,
        'meh' || 'tak sobie' || 'średnio' || 'srednio' => 3,
        'good' || 'dobrze' || 'dobry' => 4,
        'rad' || 'wspaniale' || 'świetnie' || 'swietnie' => 5,
        _ => null,
      };
}
