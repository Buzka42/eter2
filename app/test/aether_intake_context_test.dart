import 'package:eter/core/aether/guidance_mode.dart';
import 'package:eter/core/aether/request_contract.dart';
import 'package:flutter_test/flutter_test.dart';

/// Food reaching guidance at all, and doing it without lying about silence.
///
/// Guidance carried steps, active calories, sleep, resting heart rate and HRV,
/// and nothing about eating — so the one thing a person logs by hand every day
/// was the one thing the day's reading could not mention.
void main() {
  AetherRequest build({
    List<AetherIntakeContext> intake = const [],
    AetherMacroFloors? floors,
  }) =>
      const AetherRequestBuilder().build(
        aiConsented: true,
        journalConsented: false,
        ageYears: 34,
        mode: GuidanceMode.balanced,
        health: const [],
        intake: intake,
        macroFloors: floors,
      );

  test('a day nobody logged is dropped, not sent as a row of zeroes', () {
    final request = build(intake: const [
      AetherIntakeContext(localDate: '2026-08-01', kcal: 2100, proteinG: 140),
      AetherIntakeContext(localDate: '2026-08-02'),
    ]);
    // The silent day is gone entirely. Passing it as nulls invites the model
    // to read it as a day of nothing eaten, which is the product's oldest
    // mistake in a different unit.
    expect(request.intake, hasLength(1));
    expect(request.intake.single.localDate, '2026-08-01');
  });

  test('a macronutrient nobody logged is absent from the payload', () {
    final request = build(intake: const [
      AetherIntakeContext(localDate: '2026-08-01', kcal: 2100, proteinG: 140),
    ]);
    final json = request.intake.single.toJson();
    expect(json['proteinG'], 140);
    // Not `"fatG": null` — the key is simply not there.
    expect(json.containsKey('fatG'), isFalse);
    expect(json.containsKey('carbsG'), isFalse);
    expect(json['recorded'], isTrue);
  });

  test('with nothing logged the payload carries no intake key at all', () {
    final json = build().toJson();
    expect(json.containsKey('intake'), isFalse);
    expect(json.containsKey('macroFloors'), isFalse);
  });

  test('the floors travel only when they were given', () {
    final json = build(
      floors: const AetherMacroFloors(
        proteinG: 136,
        fatG: 40,
        shortfallDays: 2,
        recordedDays: 3,
        lean: true,
      ),
    ).toJson();
    final floors = json['macroFloors'] as Map<String, Object?>;
    expect(floors['proteinG'], 136);
    expect(floors['fatG'], 40);
    expect(floors['lean'], isTrue);
  });

  test('confirming a meal changes the fingerprint, so the day recomposes', () {
    // Otherwise the reading would be about a day whose food arrived after it
    // was written, and the person would see it tomorrow.
    final before = build(intake: const []).contextFingerprint;
    final after = build(intake: const [
      AetherIntakeContext(localDate: '2026-08-01', kcal: 2100, proteinG: 140),
    ]).contextFingerprint;
    expect(after, isNot(before));
  });

  test('the same intake twice is the same fingerprint', () {
    const day =
        AetherIntakeContext(localDate: '2026-08-01', kcal: 2100, fatG: 70);
    expect(
      build(intake: const [day]).contextFingerprint,
      build(intake: const [day]).contextFingerprint,
    );
  });
}
