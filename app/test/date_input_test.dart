import 'package:eter/core/profile/date_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Typing a date without typing its punctuation.
///
/// The onboarding field asked for `YYYY-MM-DD` and meant it literally — a date
/// typed without hyphens failed validation, which made the format the question
/// rather than the date.
void main() {
  TextEditingValue typing(String previous, String next) =>
      const BirthDateInputFormatter().formatEditUpdate(
        TextEditingValue(
          text: previous,
          selection: TextSelection.collapsed(offset: previous.length),
        ),
        TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        ),
      );

  /// What the field holds after somebody types [keys] one character at a time.
  String typed(String keys) {
    var value = '';
    for (final key in keys.split('')) {
      value = typing(value, '$value$key').text;
    }
    return value;
  }

  group('the hyphens appear on their own', () {
    test('eight digits become a date', () {
      expect(typed('19930725'), '1993-07-25');
    });

    test('and the field is sane at every keystroke along the way', () {
      expect(typed('1'), '1');
      expect(typed('1993'), '1993');
      expect(typed('19930'), '1993-0');
      expect(typed('199307'), '1993-07');
      expect(typed('1993072'), '1993-07-2');
    });

    test('typing the hyphens as well still works', () {
      // Somebody who does type them must not end up with `1993--07`.
      expect(typed('1993-07-25'), '1993-07-25');
    });

    test('anything past the eighth digit is dropped', () {
      expect(typed('199307251234'), '1993-07-25');
    });
  });

  test('deleting is left alone', () {
    // Reformatting a shrinking string moves the caret under the finger and
    // makes backspace feel broken.
    expect(typing('1993-07-25', '1993-07-2').text, '1993-07-2');
    expect(typing('1993-07', '1993-0').text, '1993-0');
    expect(typing('1993-', '1993').text, '1993');
  });

  test('the result is what DateTime.parse wants', () {
    // The whole point: the string the field produces has to be the string the
    // validator already accepts, with nothing typed but digits.
    expect(DateTime.tryParse(typed('19930725')), DateTime(1993, 7, 25));
  });

  group('the clock does the same for HH:MM', () {
    String clock(String keys) {
      var value = '';
      for (final key in keys.split('')) {
        value = const ClockInputFormatter()
            .formatEditUpdate(
              TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              ),
              TextEditingValue(
                text: '$value$key',
                selection: TextSelection.collapsed(offset: value.length + 1),
              ),
            )
            .text;
      }
      return value;
    }

    test('four digits become a time', () => expect(clock('0742'), '07:42'));
    test('partway through it is still sane', () {
      expect(clock('0'), '0');
      expect(clock('07'), '07');
      expect(clock('074'), '07:4');
    });
    test('extra digits are dropped', () => expect(clock('074233'), '07:42'));
  });
}
