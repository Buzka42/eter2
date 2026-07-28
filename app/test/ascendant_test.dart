import 'dart:math' as math;

import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:flutter_test/flutter_test.dart';

/// Is the rising sign actually the rising sign?
///
/// The engine's ascendant comes from a closed-form formula, and a sign error
/// inside one of those is invisible: it still returns a longitude, still lands
/// in a real sign, and still reads plausibly in a passage. So this does not
/// inspect the formula. It finds the ascendant a second, independent way —
/// by asking which degree of the ecliptic is actually on the eastern horizon —
/// and requires the two to agree.
///
/// The independent method uses nothing from the engine but the midheaven,
/// which fixes the sidereal time, and standard spherical trigonometry:
///
///   δ(λ)  = asin(sin ε · sin λ)
///   RA(λ) = atan2(sin λ · cos ε, cos λ)
///   H     = RAMC − RA          (hour angle; negative east of the meridian)
///   alt   = asin(sin φ · sin δ + cos φ · cos δ · cos H)
///
/// The ascendant is the λ with alt = 0 that is east of the meridian.
void main() {
  final engine = NatalChartEngine();

  /// Obliquity for the epochs used below. The scan tolerance is a degree, so
  /// a fixed mean value is ample.
  const epsilon = 23.4393 * math.pi / 180;

  double radians(double degrees) => degrees * math.pi / 180;
  double degrees(double radians) => (radians * 180 / math.pi) % 360;

  double rightAscension(double lambdaDeg) {
    final lambda = radians(lambdaDeg);
    return degrees(
      math.atan2(math.sin(lambda) * math.cos(epsilon), math.cos(lambda)),
    );
  }

  double declination(double lambdaDeg) =>
      math.asin(math.sin(epsilon) * math.sin(radians(lambdaDeg)));

  /// Altitude of ecliptic degree [lambdaDeg], in degrees.
  double altitude({
    required double lambdaDeg,
    required double ramcDeg,
    required double latitude,
  }) {
    final phi = radians(latitude);
    final delta = declination(lambdaDeg);
    final hourAngle = radians(ramcDeg - rightAscension(lambdaDeg));
    return degrees(
          math.asin(
            math.sin(phi) * math.sin(delta) +
                math.cos(phi) * math.cos(delta) * math.cos(hourAngle),
          ),
        ) %
        360;
  }

  /// Signed altitude in [-90, 90].
  double signedAltitude({
    required double lambdaDeg,
    required double ramcDeg,
    required double latitude,
  }) {
    final value = altitude(
      lambdaDeg: lambdaDeg,
      ramcDeg: ramcDeg,
      latitude: latitude,
    );
    return value > 180 ? value - 360 : value;
  }

  /// True when the degree lies east of the meridian, which is where things
  /// rise. `sin H < 0` is the whole test.
  bool isEast({required double lambdaDeg, required double ramcDeg}) {
    final hourAngle = radians(ramcDeg - rightAscension(lambdaDeg));
    return math.sin(hourAngle) < 0;
  }

  /// Scans the ecliptic for the degree on the eastern horizon.
  double horizonAscendant({
    required double ramcDeg,
    required double latitude,
  }) {
    double? best;
    var bestError = double.infinity;
    for (var step = 0; step < 3600; step++) {
      final lambda = step / 10;
      if (!isEast(lambdaDeg: lambda, ramcDeg: ramcDeg)) continue;
      final error = signedAltitude(
        lambdaDeg: lambda,
        ramcDeg: ramcDeg,
        latitude: latitude,
      ).abs();
      if (error < bestError) {
        bestError = error;
        best = lambda;
      }
    }
    return best!;
  }

  /// How far apart two longitudes are, the short way round.
  double separation(double a, double b) {
    final delta = (a - b).abs() % 360;
    return delta > 180 ? 360 - delta : delta;
  }

  void checkChart({
    required String label,
    required DateTime local,
    required int offsetMinutes,
    required double latitude,
    required double longitude,
  }) {
    final chart = engine.calculate(NatalInput(
      localDateTime: local,
      utcOffsetMinutes: offsetMinutes,
      latitude: latitude,
      longitude: longitude,
    ));
    final midheaven =
        chart.positions.firstWhere((p) => p.name == 'Midheaven').longitude;
    final ramc = rightAscension(midheaven);
    final expected = horizonAscendant(ramcDeg: ramc, latitude: latitude);
    final actual = chart.ascendant.longitude;

    expect(
      separation(actual, expected),
      lessThan(1.5),
      reason: '$label: engine says ${actual.toStringAsFixed(1)}, the eastern '
          'horizon holds ${expected.toStringAsFixed(1)} '
          '(off by ${separation(actual, expected).toStringAsFixed(1)}, and '
          '${separation(actual, expected + 180).toStringAsFixed(1)} from its '
          'opposite)',
    );
  }

  test('a spring morning in Warsaw rises where the sky says', () {
    checkChart(
      label: 'Warsaw 1990-03-14 09:20',
      local: DateTime(1990, 3, 14, 9, 20),
      offsetMinutes: 60,
      latitude: 52.23,
      longitude: 21.01,
    );
  });

  test('an evening in the southern hemisphere agrees too', () {
    checkChart(
      label: 'Sydney 1984-11-02 20:45',
      local: DateTime(1984, 11, 2, 20, 45),
      offsetMinutes: 11 * 60,
      latitude: -33.87,
      longitude: 151.21,
    );
  });

  test('the equator, where the geometry is simplest', () {
    checkChart(
      label: 'Quito 2001-06-21 06:00',
      local: DateTime(2001, 6, 21, 6, 0),
      offsetMinutes: -5 * 60,
      latitude: -0.18,
      longitude: -78.47,
    );
  });

  test('a winter midnight in the north', () {
    checkChart(
      label: 'Reykjavik 1975-01-05 00:30',
      local: DateTime(1975, 1, 5, 0, 30),
      offsetMinutes: 0,
      latitude: 64.15,
      longitude: -21.94,
    );
  });

  test('the ascendant is never the descendant', () {
    // The specific failure this file exists for: a formula half a turn out
    // still produces a real sign, and nothing downstream can tell.
    final chart = engine.calculate(NatalInput(
      localDateTime: DateTime(1990, 3, 14, 9, 20),
      utcOffsetMinutes: 60,
      latitude: 52.23,
      longitude: 21.01,
    ));
    final midheaven =
        chart.positions.firstWhere((p) => p.name == 'Midheaven').longitude;
    final expected =
        horizonAscendant(ramcDeg: rightAscension(midheaven), latitude: 52.23);
    expect(
      separation(chart.ascendant.longitude, expected + 180),
      greaterThan(5),
      reason: 'the engine is returning the point setting in the west',
    );
  });
}
