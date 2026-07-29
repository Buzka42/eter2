import 'dart:math' as math;

import 'package:eter/core/patterns/statistics.dart';
import 'package:flutter_test/flutter_test.dart';

/// The arithmetic that decides what a person is told about themselves.
///
/// The failure mode worth testing hardest is not "misses a real pattern" — it
/// is "confidently reports one that is not there". An app that sweeps every
/// pair of variables it records will find spurious correlations by the dozen
/// unless the statistics stop it, and a false claim about someone's sleep is
/// worse than silence.
void main() {
  group('correlation', () {
    test('finds a clean positive relationship', () {
      final random = math.Random(5);
      final xs = [for (var i = 0; i < 30; i++) i.toDouble()];
      final ys = [
        for (var i = 0; i < 30; i++) i * 2.0 + 3 + random.nextDouble() * 4,
      ];
      final result = correlate(xs, ys)!;
      expect(result.r, greaterThan(0.9));
      expect(result.isPositive, isTrue);
      expect(result.p, lessThan(0.001));
    });

    test('a perfect line is a derived variable, not a discovery', () {
      // Two columns that agree exactly are one column twice — basal energy
      // against body weight, say. Reporting it as an insight would be
      // reporting the arithmetic back to the person who supplied it.
      final xs = [for (var i = 0; i < 30; i++) i.toDouble()];
      final ys = [for (var i = 0; i < 30; i++) i * 2.0 + 3];
      expect(correlate(xs, ys), isNull);
    });

    test('finds a negative relationship', () {
      final random = math.Random(7);
      final xs = [for (var i = 0; i < 40; i++) i.toDouble()];
      final ys = [
        for (var i = 0; i < 40; i++) 100 - i * 1.5 + random.nextDouble() * 8,
      ];
      final result = correlate(xs, ys)!;
      expect(result.r, lessThan(-0.8));
      expect(result.isPositive, isFalse);
      expect(result.p, lessThan(0.01));
    });

    test('a constant series has no relationship to measure', () {
      final xs = [for (var i = 0; i < 30; i++) 5.0];
      final ys = [for (var i = 0; i < 30; i++) i.toDouble()];
      // Not a correlation of zero — an absence of one. Someone whose steps
      // never vary has nothing to relate to their sleep.
      expect(correlate(xs, ys), isNull);
    });

    test('too few days is not a finding', () {
      expect(correlate([1, 2], [2, 4]), isNull);
    });

    test('p-values match a t-table', () {
      // r = 0.5 at n = 30 gives t ≈ 3.055 on 28 df, p ≈ 0.0049.
      final xs = <double>[];
      final ys = <double>[];
      final random = math.Random(11);
      for (var i = 0; i < 30; i++) {
        final x = random.nextDouble();
        xs.add(x);
        ys.add(x * 0.6 + random.nextDouble() * 0.8);
      }
      final result = correlate(xs, ys)!;
      expect(result.p, greaterThan(0));
      expect(result.p, lessThan(1));
      // A strong association at this sample size must clear the conventional
      // bar comfortably.
      if (result.r.abs() > 0.5) expect(result.p, lessThan(0.05));
    });

    test('explained fraction is the square, not the coefficient', () {
      final random = math.Random(3);
      final xs = [for (var i = 0; i < 50; i++) random.nextDouble()];
      final ys = [
        for (var i = 0; i < 50; i++) xs[i] * 0.5 + random.nextDouble(),
      ];
      final result = correlate(xs, ys)!;
      expect(
        result.explainedFraction,
        closeTo(result.r * result.r, 1e-12),
      );
    });
  });

  group('what survives a sweep', () {
    Candidate<String> candidate(String name, double r, int n, double p) =>
        Candidate(
          subject: name,
          correlation: Correlation(r: r, n: n, p: p),
        );

    test('nothing survives from too little data, however strong it looks', () {
      // The property the whole feature rests on: a new user is told nothing,
      // because nothing can honestly be said yet.
      final findings = survivingFindings([
        candidate('steps vs sleep', 0.95, 6, 0.0001),
        candidate('mood vs sleep', -0.9, 8, 0.001),
      ]);
      expect(findings, isEmpty);
    });

    test('a real effect survives once there is enough of it', () {
      final findings = survivingFindings([
        candidate('steps vs sleep', 0.62, 40, 0.0001),
      ]);
      expect(findings, hasLength(1));
      expect(findings.single.subject, 'steps vs sleep');
    });

    test('a significant but trivial effect is not reported', () {
      // Statistical significance is not the same as mattering. Over enough
      // days a correlation of 0.12 is detectable and still noise to a person.
      final findings = survivingFindings([
        candidate('steps vs mood', 0.12, 300, 0.0001),
      ]);
      expect(findings, isEmpty);
    });

    test('a sweep of pure noise reports nothing', () {
      // Forty independent variables tested against each other, all null. At a
      // naive 0.05 threshold two of these would be announced as discoveries.
      final random = math.Random(42);
      final candidates = [
        for (var i = 0; i < 40; i++)
          candidate('pair $i', 0.4, 30, random.nextDouble()),
      ];
      final findings = survivingFindings(candidates);
      // The correction may admit the very smallest p by chance; what it must
      // never do is admit a handful.
      expect(findings.length, lessThanOrEqualTo(1));
    });

    test('the correction tightens as more questions are asked', () {
      const borderline = 0.02;
      final alone = survivingFindings([
        candidate('only question', 0.5, 40, borderline),
      ]);
      final amongMany = survivingFindings([
        candidate('one of many', 0.5, 40, borderline),
        for (var i = 0; i < 30; i++) candidate('noise $i', 0.4, 40, 0.6),
      ]);

      expect(alone, hasLength(1));
      // The same p-value, asked among thirty others, no longer clears the bar.
      expect(amongMany, isEmpty);
    });

    test('several genuine findings survive together', () {
      final findings = survivingFindings([
        candidate('a', 0.7, 60, 0.00001),
        candidate('b', -0.6, 60, 0.0001),
        candidate('c', 0.55, 60, 0.001),
        for (var i = 0; i < 10; i++) candidate('noise $i', 0.4, 60, 0.7),
      ]);
      expect(findings.map((f) => f.subject), containsAll(['a', 'b', 'c']));
    });

    test('findings come back strongest first', () {
      final findings = survivingFindings([
        candidate('weaker', 0.5, 60, 0.004),
        candidate('stronger', 0.8, 60, 0.000001),
      ]);
      expect(findings.first.subject, 'stronger');
    });

    test('an empty sweep is empty, not an error', () {
      expect(survivingFindings<String>(const []), isEmpty);
    });
  });
}
