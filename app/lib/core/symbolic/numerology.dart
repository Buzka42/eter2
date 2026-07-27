library;

/// Deterministic numerology.
///
/// Lives here rather than in `aether/` because the steering brief is explicit:
/// "Astrology and numerology calculations should be deterministic rather than
/// calculated by the language model." The model receives the result and
/// interprets it; it never computes it.

/// Master numbers are preserved rather than reduced to a single digit.
///
/// Must stay in step with `MajorArcana.supportedLifePaths`. A test asserts it:
/// in v1 this function preserved 33 while the card lookup had no case for it,
/// and a date of birth summing to 33 threw out of the Vessel at runtime.
const masterNumbers = <int>{11, 22, 33};

int calculateLifePath(DateTime dob) {
  var value = _digitSum(
    '${dob.year}'
    '${dob.month.toString().padLeft(2, '0')}'
    '${dob.day.toString().padLeft(2, '0')}',
  );
  while (value > 9 && !masterNumbers.contains(value)) {
    value = _digitSum(value.toString());
  }
  return value;
}

/// The personal year: where the user sits in the nine-year cycle.
///
/// Feeds daily-card selection so the choice has a stated reason rather than
/// being drawn arbitrarily — the brief requires the application, not the model,
/// to control how the card is chosen.
int calculatePersonalYear(DateTime dob, DateTime now) {
  var value = _digitSum(
    '${now.year}'
    '${dob.month.toString().padLeft(2, '0')}'
    '${dob.day.toString().padLeft(2, '0')}',
  );
  while (value > 9) {
    value = _digitSum(value.toString());
  }
  return value;
}

int _digitSum(String digits) =>
    digits.split('').map(int.parse).fold<int>(0, (sum, digit) => sum + digit);
