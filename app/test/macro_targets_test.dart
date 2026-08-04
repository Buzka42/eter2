import 'package:eter/core/health/macro_targets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The protein and fat floors, when there is strength work.
///
/// The rule that matters most here is the product's oldest one: a day nobody
/// logged is **absent, never zero**. A missed target can only be found on a day
/// that was recorded, or Eter ends up telling somebody they fell short on days
/// they simply did not write down.
void main() {
  MacroDay day(String date, {double? protein, double? fat}) =>
      MacroDay(date: date, proteinG: protein, fatG: fat);

  test('the floors are grams for this body, not a ratio to work out', () {
    final targets = macroTargetsFor(
      weightKg: 80,
      hasStrengthWork: true,
      recentDays: const [],
    );
    expect(targets.proteinG, 136); // 80 * 1.7
    expect(targets.fatG, 40); // 80 * 0.5
    // Whole grams. A decimal place implies a precision food logging does not
    // have.
    expect(targets.proteinG, isA<int>());
  });

  test('they scale with the person', () {
    expect(
      macroTargetsFor(
        weightKg: 60,
        hasStrengthWork: true,
        recentDays: const [],
      ).proteinG,
      102,
    );
    expect(
      macroTargetsFor(
        weightKg: 95,
        hasStrengthWork: true,
        recentDays: const [],
      ).fatG,
      48,
    );
  });

  test('without strength work the floors are not advised', () {
    final targets = macroTargetsFor(
      weightKg: 80,
      hasStrengthWork: false,
      recentDays: [day('2026-08-01', protein: 40, fat: 20)],
    );
    // The numbers still compute — the Body may show them — but nothing leans
    // on somebody who does not lift.
    expect(targets.appliesBecauseOfStrength, isFalse);
  });

  test('a day nobody logged is unknown, never a shortfall', () {
    final targets = macroTargetsFor(
      weightKg: 80,
      hasStrengthWork: true,
      recentDays: [
        day('2026-08-01'),
        day('2026-08-02'),
        day('2026-08-03'),
      ],
    );
    expect(targets.recordedDays, 0);
    expect(targets.shortfallDays, 0);
    expect(targets.windowIsSilent, isTrue);
    expect(targets.shouldLean, isFalse);
  });

  test('a measure that was not logged cannot be short', () {
    // Protein written, fat not. The fat is unknown for that day and must not
    // be counted against the person.
    final targets = macroTargetsFor(
      weightKg: 80,
      hasStrengthWork: true,
      recentDays: [day('2026-08-01', protein: 150)],
    );
    expect(targets.recordedDays, 1);
    expect(targets.shortfallDays, 0);
  });

  test('a recorded day under either floor is a shortfall', () {
    final short = macroTargetsFor(
      weightKg: 80,
      hasStrengthWork: true,
      recentDays: [
        day('2026-08-01', protein: 100, fat: 60), // protein short
        day('2026-08-02', protein: 150, fat: 20), // fat short
      ],
    );
    expect(short.shortfallDays, 2);
  });

  test('one short day is a Tuesday; two is worth leaning on', () {
    final one = macroTargetsFor(
      weightKg: 80,
      hasStrengthWork: true,
      recentDays: [
        day('2026-08-01', protein: 100, fat: 60),
        day('2026-08-02', protein: 150, fat: 60),
      ],
    );
    expect(one.shortfallDays, 1);
    expect(one.shouldLean, isFalse);

    final two = macroTargetsFor(
      weightKg: 80,
      hasStrengthWork: true,
      recentDays: [
        day('2026-08-01', protein: 100, fat: 60),
        day('2026-08-02', protein: 110, fat: 60),
      ],
    );
    expect(two.shouldLean, isTrue);
  });

  test('two shortfalls out of one recorded day is impossible, and one is not enough',
      () {
    // A single recorded day can never justify leaning, however bad it was.
    final targets = macroTargetsFor(
      weightKg: 80,
      hasStrengthWork: true,
      recentDays: [
        day('2026-08-01', protein: 10, fat: 1),
        day('2026-08-02'),
        day('2026-08-03'),
      ],
    );
    expect(targets.recordedDays, 1);
    expect(targets.shortfallDays, 1);
    expect(targets.shouldLean, isFalse);
  });

  test('a day exactly on the floor has met it', () {
    final targets = macroTargetsFor(
      weightKg: 80,
      hasStrengthWork: true,
      recentDays: [day('2026-08-01', protein: 136, fat: 40)],
    );
    expect(targets.shortfallDays, 0);
  });
}
