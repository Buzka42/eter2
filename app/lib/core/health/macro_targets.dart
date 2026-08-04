import 'dart:math' as math;

/// What one day's food is measured against, and how it did.
class MacroDay {
  const MacroDay({
    required this.date,
    required this.proteinG,
    required this.fatG,
    this.carbsG,
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

  /// Counted, and almost never spoken about. Carbohydrate is tracked because
  /// the owner wants it tracked, and it earns no advice of its own: there is
  /// no floor for it and no target, and telling somebody to eat fewer of them
  /// is the diet talk this product does not do.
  ///
  /// The one exception is [carbHeavyWithLowProtein].
  final double? carbsG;

  bool get recorded => proteinG != null || fatG != null || carbsG != null;

  /// Energy from each macronutrient, in kcal, for the ones that were logged.
  /// Four per gram of protein and carbohydrate, nine per gram of fat.
  double get _proteinKcal => (proteinG ?? 0) * 4;
  double get _carbKcal => (carbsG ?? 0) * 4;
  double get _fatKcal => (fatG ?? 0) * 9;
  double get _totalKcal => _proteinKcal + _carbKcal + _fatKcal;

  /// A day that was very nearly all carbohydrate.
  ///
  /// Measured by share of energy rather than by grams, because a gram of fat
  /// is not a gram of anything else — by weight, a day of bread and butter
  /// looks carbohydrate-dominated when by energy it is not.
  ///
  /// Seven tenths, and every macronutrient must have been logged: a day where
  /// only carbohydrate was written down is a day nobody described, not a day
  /// of pure carbohydrate, and treating the second as the first would be the
  /// absent-not-zero mistake wearing a new hat.
  bool get carbDominant {
    if (proteinG == null || carbsG == null || fatG == null) return false;
    if (_totalKcal <= 0) return false;
    return _carbKcal / _totalKcal >= 0.7;
  }
}

/// The floors, and what the record has to say about them.
class MacroTargets {
  const MacroTargets({
    required this.proteinG,
    required this.fatG,
    required this.appliesBecauseOfStrength,
    required this.shortfallDays,
    required this.recordedDays,
    this.carbHeavyWithLowProtein = false,
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

  /// The one thing that may be said about carbohydrate.
  ///
  /// True when a recorded day was very nearly all carbohydrate *and* protein
  /// came in under its floor. Then, and only then, the advice may suggest
  /// trading some of it for protein — because the sentence is about the
  /// protein that is missing, not about the carbohydrate being wrong.
  ///
  /// Both halves are required. A carbohydrate-heavy day that still met the
  /// protein floor needs no comment; a low-protein day that was not
  /// carbohydrate-heavy is covered by [shortfallDays] and does not need a
  /// swap suggested.
  final bool carbHeavyWithLowProtein;
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
  var carbHeavyLowProtein = false;
  for (final day in recorded) {
    // A measure that was not logged cannot be short. Only what is on the
    // record is judged, and only against its own floor.
    final proteinShort = day.proteinG != null && day.proteinG! < protein;
    final fatShort = day.fatG != null && day.fatG! < fat;
    if (proteinShort || fatShort) shortfall++;
    if (proteinShort && day.carbDominant) carbHeavyLowProtein = true;
  }

  return MacroTargets(
    proteinG: math.max(protein, 0),
    fatG: math.max(fat, 0),
    appliesBecauseOfStrength: hasStrengthWork,
    shortfallDays: shortfall,
    recordedDays: recorded.length,
    carbHeavyWithLowProtein: carbHeavyLowProtein,
  );
}
