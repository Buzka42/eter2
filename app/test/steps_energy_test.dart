import 'package:eter/core/energy/energy.dart';
import 'package:flutter_test/flutter_test.dart';

/// Walking energy from steps, for the source that counts steps and reports no
/// calories.
///
/// Found on a phone: Health Connect delivered 22,720 steps across three days
/// and zero active kilocalories, so the day's burn was resting alone and
/// somebody who had walked ten thousand steps saw the same figure as somebody
/// who had not left a chair.
void main() {
  test('a real day of walking is a plausible number', () {
    // 88 kg, 180 cm, 9,730 steps — the day this was found on.
    final kcal = activeKcalFromSteps(
      steps: 9730,
      weightKg: 88,
      heightCm: 180,
      sex: Sex.male,
    );
    // Stride 0.747 m → about 7.3 km → about 320 kcal net.
    expect(kcal, closeTo(320, 15));
  });

  test('it is net, so it cannot double-charge the resting burn', () {
    // Resting for a 88 kg body at 10% fat is about 2,080 a day. A day of
    // ordinary walking must not come anywhere near doubling that: gross
    // walking cost would, because those minutes are already counted at rest.
    final walking = activeKcalFromSteps(
      steps: 10000,
      weightKg: 88,
      heightCm: 180,
      sex: Sex.male,
    );
    expect(netWalkKcalPerKgPerKm, 0.5);
    expect(walking, lessThan(400));
  });

  test('a taller body covers more ground in the same steps', () {
    final tall = activeKcalFromSteps(
      steps: 10000, weightKg: 80, heightCm: 195, sex: Sex.male);
    final short = activeKcalFromSteps(
      steps: 10000, weightKg: 80, heightCm: 160, sex: Sex.male);
    expect(tall, greaterThan(short));
  });

  test('a heavier body spends more over the same distance', () {
    final heavy = activeKcalFromSteps(
      steps: 10000, weightKg: 110, heightCm: 180, sex: Sex.male);
    final light = activeKcalFromSteps(
      steps: 10000, weightKg: 60, heightCm: 180, sex: Sex.male);
    expect(heavy, greaterThan(light));
  });

  test('no steps is no energy, and nothing is invented from nothing', () {
    // The absent-not-zero rule pointing the other way: this may only ever turn
    // a *measurement* into energy, never fill a silence.
    expect(
      activeKcalFromSteps(steps: 0, weightKg: 88, heightCm: 180, sex: Sex.male),
      0,
    );
    expect(
      activeKcalFromSteps(
          steps: -5, weightKg: 88, heightCm: 180, sex: Sex.male),
      0,
    );
  });

  test('a body nobody has measured produces nothing rather than a guess', () {
    expect(
      activeKcalFromSteps(steps: 9000, weightKg: 0, heightCm: 180, sex: Sex.male),
      0,
    );
    expect(
      activeKcalFromSteps(steps: 9000, weightKg: 88, heightCm: 0, sex: Sex.male),
      0,
    );
  });
}
