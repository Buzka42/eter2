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
