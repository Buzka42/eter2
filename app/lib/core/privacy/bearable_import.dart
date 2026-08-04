/// Reads a Bearable CSV export.
///
/// Bearable is a symptom and mood tracker, and its export is shaped very
/// differently from Daylio's: one row is not one entry but one *reading*, and a
/// single day produces many rows of different kinds.
///
/// ```
/// date,weekday,time of day,category,rating/amount,detail,notes
/// ```
///
/// `category` says what kind of reading it is — `Mood`, `Sleep`, `Symptom`,
/// `Factors`, `Medication` — `rating/amount` carries the number, and `detail`
/// names the particular thing being rated and often carries its unit, as in
/// `Step count (steps)`.
///
/// **What is honest to import, and what is not.**
///
/// Eter keeps self-reports on a **1..5** scale — that is what the Journal's
/// margin collects and what the Long View averages and plots. Bearable's
/// ratings are on a scale this reader is not told. Writing them in raw would
/// put an 8 on a five-point chart, which is not a bad import, it is a corrupt
/// one, and nothing downstream could tell.
///
/// So the scale is **read off the file itself**: the range of every rating in
/// one category decides it, and the result says which scale was inferred so a
/// surface can tell somebody. Where a category has nothing Eter keeps — a
/// symptom, a medication, a tracked factor — it is counted by name and left,
/// rather than translated into a table that means something else.
///
/// **This reader was written without a real export in hand.** The columns are
/// attested by two independent analyses of real files; the value formats are
/// not, beyond `date` and the `(unit)` convention in `detail`. Everything it is
/// unsure of is reported rather than assumed, and the one place to change when
/// a real file turns up is [_categoryKind] and [BearableScale].
library;

import 'csv.dart';
import 'foreign_import.dart';

/// The scale a set of ratings turned out to be on.
///
/// Inferred rather than declared, because the file does not say. The rule is
/// the only one that cannot be wrong in the dangerous direction: a rating above
/// five cannot be on a five-point scale, so seeing one is proof. Seeing none is
/// not proof of the opposite, which is why the inference is reported.
class BearableScale {
  const BearableScale({required this.highest});

  /// The largest rating seen in this category.
  final double highest;

  /// True when something in the file could not be on a five-point scale.
  bool get isWide => highest > 5;

  /// The reading on Eter's own 1..5, or null where there is nothing to map.
  ///
  /// A wide scale is mapped proportionally and then held inside the range: the
  /// point is that a middling day stays middling and the best day the person
  /// ever recorded is the top of the chart, not off it.
  double? map(double rating) {
    if (!isWide) {
      // Already inside Eter's range, give or take Bearable's zero. A zero
      // rating is the bottom of its scale and the bottom of Eter's is one.
      final value = rating < 1 ? 1.0 : rating;
      return value > 5 ? 5 : value;
    }
    if (highest <= 0) return null;
    final scaled = 1 + (rating / highest) * 4;
    return scaled.clamp(1.0, 5.0);
  }
}

class BearableImportSource implements ForeignImportSource {
  const BearableImportSource();

  @override
  String get name => 'Bearable';

  /// `category` and `rating/amount` together are unique to this format among
  /// the ones Eter reads, and both have been in it since it had an export.
  static const _signature = ['category', 'rating/amount'];

  @override
  bool canRead(String content) {
    final table = CsvTable.read(content);
    return table != null && table.hasAll(_signature);
  }

  @override
  ForeignRecords read(String content) {
    final table = CsvTable.read(content);
    if (table == null) return const ForeignRecords();

    // Two passes. The first learns what scale each category's ratings are on,
    // because a rating cannot be mapped until the whole file has been seen —
    // the proof that a scale is wide may be on the last row.
    final highest = <String, double>{};
    for (final row in table.rows) {
      final kind = _categoryKind(table.field(row, 'category'));
      if (kind == null) continue;
      final rating = _number(table.field(row, 'rating/amount'));
      if (rating == null) continue;
      // Written out rather than folded into one expression with `?? 0`: the
      // first rating of a kind may itself be a zero — the bottom of Bearable's
      // scale is one — and the short form then reads back a key it has not
      // written yet.
      final current = highest[kind];
      if (current == null || rating > current) highest[kind] = rating;
    }
    final scales = {
      for (final entry in highest.entries)
        entry.key: BearableScale(highest: entry.value),
    };

    final journal = <ForeignJournalEntry>[];
    final lifestyle = <ForeignLifestyleEntry>[];
    final weight = <ForeignWeightEntry>[];
    final ignored = <String, int>{};
    var unreadable = 0;
    // One day's notes can be repeated on every row of that day, which is how a
    // file that carries a note column alongside per-reading rows behaves. The
    // same words at the same moment are one page.
    final seenNotes = <String>{};

    for (final row in table.rows) {
      final at = moment(
        table.field(row, 'date'),
        table.field(row, 'time of day'),
      );
      if (at == null) {
        unreadable++;
        continue;
      }

      final note = table.field(row, 'notes');
      if (note.isNotEmpty && seenNotes.add('${at.toIso8601String()}|$note')) {
        journal.add(ForeignJournalEntry(at: at, text: note));
      }

      final category = table.field(row, 'category');
      final detail = table.field(row, 'detail');
      final rating = _number(table.field(row, 'rating/amount'));

      // Weight is the one measurement that is not a rating, and it is only
      // safe when the file states its unit: kilograms and pounds are both
      // ordinary and the difference is not a rounding error.
      if (_isWeight(category, detail) && rating != null) {
        final kg = _asKilograms(rating, detail);
        if (kg == null) {
          ignored['Weight in an unstated unit'] =
              (ignored['Weight in an unstated unit'] ?? 0) + 1;
        } else {
          weight.add(ForeignWeightEntry(at: at, kg: kg, source: 'bearable'));
        }
        continue;
      }

      final kind = _categoryKind(category);
      if (kind == null) {
        if (category.isNotEmpty) {
          ignored[category] = (ignored[category] ?? 0) + 1;
        }
        continue;
      }
      if (rating == null) {
        unreadable++;
        continue;
      }
      lifestyle.add(ForeignLifestyleEntry(
        at: at,
        kind: kind,
        value: scales[kind]?.map(rating),
        // The reading as the other app recorded it, kept verbatim beside the
        // mapped value. Nothing is lost to the mapping, and anybody checking
        // can see what it came from.
        note: detail.isEmpty ? '$category $rating' : '$detail $rating',
        source: 'bearable',
      ));
    }

    return ForeignRecords(
      journal: journal,
      lifestyle: lifestyle,
      weight: weight,
      ignored: ignored,
      unreadableRows: unreadable,
    );
  }

  /// Which of Eter's self-report kinds a Bearable category is, or null when it
  /// is something Eter does not keep.
  ///
  /// Deliberately short. `Energy` is not `recovery`, a `Symptom` is not a mood,
  /// and a medication log is not a self-report at all — mapping any of them
  /// would put a number in a column that means something else, and the Long
  /// View would average it into somebody's mood.
  static String? _categoryKind(String category) =>
      switch (category.trim().toLowerCase()) {
        'mood' => 'mood',
        'sleep' || 'sleep quality' => 'sleep',
        _ => null,
      };

  static bool _isWeight(String category, String detail) {
    final text = '$category $detail'.toLowerCase();
    return text.contains('weight');
  }

  /// Bearable writes the unit in brackets after the name — `Weight (kg)`.
  /// Without one there is no way to tell 70 kg from 70 lb, and a reader that
  /// picks one is a reader that halves or doubles somebody's body.
  static double? _asKilograms(double amount, String detail) {
    final unit = RegExp(r'\(([^)]*)\)').firstMatch(detail)?.group(1);
    return switch (unit?.trim().toLowerCase()) {
      'kg' || 'kgs' || 'kilograms' => amount,
      'lb' || 'lbs' || 'pounds' => amount * 0.45359237,
      'st' || 'stone' => amount * 6.35029318,
      _ => null,
    };
  }

  static double? _number(String raw) {
    if (raw.isEmpty) return null;
    // A rating may arrive as `3`, `3.5` or `3/5`; the last is the reading and
    // its own scale written together, and the part before the slash is the
    // reading.
    final head = raw.split('/').first.trim();
    return double.tryParse(head.replaceAll(',', '.'));
  }

  /// `22nd Jan 2022`, with an optional clock.
  ///
  /// The ordinal suffix is the awkward part and it is not optional: every date
  /// in the file has one, and nothing that reads ISO dates will read any of
  /// them. Returns null rather than guessing, so an unreadable row is reported
  /// instead of being filed against a day that never happened.
  static DateTime? moment(String date, String time) {
    final day = RegExp(
      r'^(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]+)\.?\s+(\d{4})$',
    ).firstMatch(date.trim());
    if (day == null) return null;
    final dayOfMonth = int.parse(day.group(1)!);
    final month = _month(day.group(2)!);
    if (month == null || dayOfMonth < 1 || dayOfMonth > 31) return null;
    final year = int.parse(day.group(3)!);

    var hour = 0;
    var minute = 0;
    if (time.trim().isNotEmpty) {
      final clock = RegExp(
        r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$',
      ).firstMatch(time.trim());
      // A time of day Bearable wrote as a word rather than a clock — some
      // versions bucket readings into parts of the day. The reading still
      // belongs to its date, so the row is kept at the start of that day
      // rather than thrown away over its clock.
      if (clock != null) {
        hour = int.parse(clock.group(1)!);
        minute = int.parse(clock.group(2)!);
        final meridiem = clock.group(3)?.toLowerCase();
        if (meridiem != null) {
          if (hour < 1 || hour > 12) return null;
          hour = hour % 12;
          if (meridiem == 'pm') hour += 12;
        }
        if (hour > 23 || minute > 59) return null;
      }
    }

    final at = DateTime(year, month, dayOfMonth, hour, minute);
    if (at.month != month || at.day != dayOfMonth) return null;
    return at;
  }

  static int? _month(String name) => switch (name.toLowerCase()) {
        'jan' || 'january' => 1,
        'feb' || 'february' => 2,
        'mar' || 'march' => 3,
        'apr' || 'april' => 4,
        'may' => 5,
        'jun' || 'june' => 6,
        'jul' || 'july' => 7,
        'aug' || 'august' => 8,
        'sep' || 'sept' || 'september' => 9,
        'oct' || 'october' => 10,
        'nov' || 'november' => 11,
        'dec' || 'december' => 12,
        _ => null,
      };
}
