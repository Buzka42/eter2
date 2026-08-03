/// Typing a date without typing its punctuation.
///
/// Onboarding asked for `YYYY-MM-DD` and meant it literally: the hyphens had
/// to be typed, and a date entered without them simply failed validation with
/// "Enter a valid birth date". The format is not the question being asked, and
/// making somebody type a separator to satisfy a parser is the parser's problem
/// rather than theirs.
library;

import 'package:flutter/services.dart';

/// Inserts the hyphens as somebody types digits, and lets them delete
/// backwards through the result without fighting it.
///
/// Deliberately not a date *picker*. A birth date is four digits somebody knows
/// by heart, and a picker for it means spinning back through thirty years of
/// months — every calendar widget is worse than a keyboard here.
class BirthDateInputFormatter extends TextInputFormatter {
  const BirthDateInputFormatter();

  /// `YYYY-MM-DD`.
  static const _groups = [4, 2, 2];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Deleting is left alone entirely. Reformatting a shrinking string moves
    // the caret about under the finger and makes a backspace feel broken.
    if (newValue.text.length < oldValue.text.length) return newValue;

    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final buffer = StringBuffer();
    var index = 0;
    for (var group = 0; group < _groups.length && index < digits.length;
        group++) {
      if (group > 0) buffer.write('-');
      final take = _groups[group];
      final end = index + take < digits.length ? index + take : digits.length;
      buffer.write(digits.substring(index, end));
      index = end;
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      // Always at the end: this only runs while text is being added, and the
      // one thing a formatter must never do is leave the caret behind the
      // separator it just inserted.
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// The same idea for a 24-hour clock: `HH:MM`.
class ClockInputFormatter extends TextInputFormatter {
  const ClockInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) return newValue;
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final hours = digits.substring(0, digits.length < 2 ? digits.length : 2);
    final text = digits.length <= 2
        ? hours
        : '$hours:${digits.substring(2, digits.length < 4 ? digits.length : 4)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Why a typed birth date was refused.
enum BirthDateProblem {
  /// Not eight digits, or not a date the calendar has.
  malformed,

  /// In the future, or so far back that nobody alive was born then.
  outOfRange,

  /// Under sixteen. Eter asks for an age because the model is instructed by
  /// it; see `AetherRequestBuilder`.
  tooYoung,
}

/// Checks a typed `YYYY-MM-DD` against the calendar and against being a person.
///
/// `DateTime.parse` is not a validator: it *rolls over*, so `2000-02-31` comes
/// back as 2 March and onboarding accepted it silently — a chart cast for a
/// day the person was not born on, and no way to correct it afterwards. The
/// round-trip below is what catches that.
BirthDateProblem? birthDateProblem(String raw, {required DateTime now}) {
  final trimmed = raw.trim();
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
  if (match == null) return BirthDateProblem.malformed;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return BirthDateProblem.malformed;
  }
  final parsed = DateTime(year, month, day);
  // The round trip: February the thirty-first constructs happily and comes
  // back as March.
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return BirthDateProblem.malformed;
  }
  final today = DateTime(now.year, now.month, now.day);
  if (parsed.isAfter(today)) return BirthDateProblem.outOfRange;
  // The oldest verified person reached 122. Beyond that it is a typo.
  if (today.year - parsed.year > 130) return BirthDateProblem.outOfRange;

  var age = today.year - parsed.year;
  if (today.month < parsed.month ||
      (today.month == parsed.month && today.day < parsed.day)) {
    age--;
  }
  if (age < 16) return BirthDateProblem.tooYoung;
  return null;
}
