import 'dart:math' as math;

/// What one day's food is measured against, and how it did.
class MacroDay {
  const MacroDay({
    required this.date,
    required this.proteinG,
    required this.fatG,
  });

  /// Local calendar day, ISO.
  final String date;

  /// Null means the day was never logged. **Not zero** — a day nobody wrote
  /// down is a day Eter knows nothing about, and the difference between "ate
  /// no protein" and "did not say" is the difference between a true sentence
  /// and a false one. v1 told somebody who had logged nothing that they were
  /// 828 kcal down; this is the same mistake with a different unit.
  final double? proteinG;
  final double? fatG;

  bool get recorded => proteinG != null || fatG != null;
}

/// The floors, and what the record has to say about them.
class MacroTargets {
  const MacroTargets({
    required this.proteinG,
    required this.fatG,
    required this.appliesBecauseOfStrength,
    required this.shortfallDays,
    required this.recordedDays,
  });

  /// Grams per day, computed from this person's own weight and rounded to a
  /// whole gram. A target to one decimal place implies a precision that food
  /// logging does not have.
  final int proteinG;
  final int fatG;

  /// Whether strength work is in the record at all. Without it these are not
  /// advised: the floors exist because resistance training raises the protein
  /// a body can use, and pressing them on somebody who does not lift is
  /// dietary advice nobody asked for.
  final bool appliesBecauseOfStrength;

  /// How many of the recorded days in the window came in under either floor.
  /// Counted over recorded days only.
  final int shortfallDays;

  /// How many days in the window were logged at all. Zero means the window is
  /// silent and nothing may be concluded from it.
  final int recordedDays;

  /// Whether the advice should lean — recent days fell short often enough that
  /// saying so is worth more than saying it gently.
  ///
  /// Needs at least two recorded days: one short day is a Tuesday, not a
  /// pattern, and leaning on a single observation is how a product becomes
  /// nagging.
  bool get shouldLean => recordedDays >= 2 && shortfallDays >= 2;

  /// Nothing at all is known about recent intake.
  bool get windowIsSilent => recordedDays == 0;
}

/// Grams of protein per kilogram per day, when there is strength work.
///
/// The owner's figure. It sits in the range the evidence supports for people
/// doing resistance training, and it is stated here as one constant so the
/// number a person is shown and the number the advice is built on can never
/// drift apart.
const macroProteinPerKg = 1.7;

/// Grams of fat per kilogram per day, as a floor rather than a goal. Fat below
/// roughly this is where hormonal and absorption costs start; above it is a
/// preference, not a target.
const macroFatPerKg = 0.5;

/// The day's floors for this person, and how the recent record stands to them.
///
/// [weightKg] is their own weight, so the answer is in grams they can act on
/// rather than a ratio they have to do arithmetic with.
///
/// [recentDays] is the window behind today, most recent first or last — order
/// does not matter. Days nobody logged are counted as unknown and never as
/// failures, which is the rule this file exists to hold: **a shortfall can
/// only be found on a day that was recorded.**
MacroTargets macroTargetsFor({
  required double weightKg,
  required bool hasStrengthWork,
  required List<MacroDay> recentDays,
}) {
  final protein = (weightKg * macroProteinPerKg).round();
  final fat = (weightKg * macroFatPerKg).round();

  final recorded = recentDays.where((day) => day.recorded).toList();
  var shortfall = 0;
  for (final day in recorded) {
    // A measure that was not logged cannot be short. Only what is on the
    // record is judged, and only against its own floor.
    final proteinShort = day.proteinG != null && day.proteinG! < protein;
    final fatShort = day.fatG != null && day.fatG! < fat;
    if (proteinShort || fatShort) shortfall++;
  }

  return MacroTargets(
    proteinG: math.max(protein, 0),
    fatG: math.max(fat, 0),
    appliesBecauseOfStrength: hasStrengthWork,
    shortfallDays: shortfall,
    recordedDays: recorded.length,
  );
}
