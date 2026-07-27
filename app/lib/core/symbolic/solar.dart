import 'dart:math' as math;

import '../register.dart';

/// Sunrise and sunset, so the register can turn at the user's real horizon.
///
/// This is the NOAA sunrise equation rather than a call into `astronomia`.
/// The register needs minute accuracy, not arc-seconds, and implementing the
/// closed form here keeps the calculation pure, dependency-free and testable
/// against known fixtures without constructing an ephemeris. `natal_chart.dart`
/// still uses the full package where precision genuinely matters.
///
/// Deterministic by construction — the brief requires that symbolic timing
/// never be improvised by the model.
class SolarDay {
  const SolarDay({required this.sunriseUtc, required this.sunsetUtc});

  /// Null on a polar day or polar night, where the sun does not cross the
  /// horizon at all. [SolarDay.phaseAt] resolves those cases explicitly.
  final DateTime? sunriseUtc;
  final DateTime? sunsetUtc;

  bool get sunCrossesHorizon => sunriseUtc != null && sunsetUtc != null;
}

/// Civil-ish horizon: the standard −0.833°, which folds in refraction and the
/// solar disc's radius, so "sunset" means the moment the upper limb vanishes.
const _horizonDegrees = -0.833;
const _obliquityDegrees = 23.4397;

const _julianEpoch = 2440587.5;
const _j2000 = 2451545.0;

double _radians(double degrees) => degrees * math.pi / 180.0;
double _degrees(double radians) => radians * 180.0 / math.pi;

double _julianDay(DateTime utc) =>
    utc.millisecondsSinceEpoch / 86400000.0 + _julianEpoch;

DateTime _fromJulianDay(double jd) => DateTime.fromMillisecondsSinceEpoch(
      ((jd - _julianEpoch) * 86400000.0).round(),
      isUtc: true,
    );

/// Sunrise and sunset for the calendar day containing [instant], at
/// [latitude]/[longitude] in signed degrees (north and east positive).
SolarDay solarDayFor({
  required DateTime instant,
  required double latitude,
  required double longitude,
}) {
  final utc = instant.toUtc();
  final n = (_julianDay(utc) - _j2000 + 0.0008).roundToDouble();

  // Mean solar time at this meridian.
  final meanSolarTime = n - longitude / 360.0;

  final meanAnomaly = (357.5291 + 0.98560028 * meanSolarTime) % 360.0;
  final m = _radians(meanAnomaly);

  // Equation of the centre.
  final centre = 1.9148 * math.sin(m) +
      0.0200 * math.sin(2 * m) +
      0.0003 * math.sin(3 * m);

  final eclipticLongitude = (meanAnomaly + centre + 180.0 + 102.9372) % 360.0;
  final lambda = _radians(eclipticLongitude);

  final transit = _j2000 +
      meanSolarTime +
      0.0053 * math.sin(m) -
      0.0069 * math.sin(2 * lambda);

  final declination =
      math.asin(math.sin(lambda) * math.sin(_radians(_obliquityDegrees)));

  final phi = _radians(latitude);
  final cosHourAngle =
      (math.sin(_radians(_horizonDegrees)) - math.sin(phi) * math.sin(declination)) /
          (math.cos(phi) * math.cos(declination));

  // |cos ω₀| > 1 means the sun never reaches the horizon: polar night when the
  // required angle is above +1, midnight sun when it is below −1.
  if (cosHourAngle.abs() > 1 || cosHourAngle.isNaN) {
    return const SolarDay(sunriseUtc: null, sunsetUtc: null);
  }

  final hourAngle = _degrees(math.acos(cosHourAngle));
  return SolarDay(
    sunriseUtc: _fromJulianDay(transit - hourAngle / 360.0),
    sunsetUtc: _fromJulianDay(transit + hourAngle / 360.0),
  );
}

/// Which half of the day [instant] falls in.
///
/// [latitude]/[longitude] are nullable because birth place is an optional
/// onboarding field and location permission is never required. With no
/// coordinates this falls back to the device clock, 07:00–19:00 local — a
/// deliberately dull default, since the alternative is asking for a permission
/// the product does not otherwise need.
DayPhase dayPhaseAt({
  required DateTime instant,
  double? latitude,
  double? longitude,
}) {
  if (latitude == null || longitude == null) {
    final hour = instant.toLocal().hour;
    return hour >= 7 && hour < 19 ? DayPhase.day : DayPhase.night;
  }

  final solar = solarDayFor(
    instant: instant,
    latitude: latitude,
    longitude: longitude,
  );

  if (!solar.sunCrossesHorizon) {
    // Polar day or polar night. Above the Arctic circle in midsummer there is
    // no sunset to turn on, so fall back to the clock rather than pinning a
    // user in one register for weeks.
    final hour = instant.toLocal().hour;
    return hour >= 7 && hour < 19 ? DayPhase.day : DayPhase.night;
  }

  final utc = instant.toUtc();
  final isDay =
      utc.isAfter(solar.sunriseUtc!) && utc.isBefore(solar.sunsetUtc!);
  return isDay ? DayPhase.day : DayPhase.night;
}

/// When the register next flips, so the shell can schedule a rebuild instead of
/// polling. Null when the sun does not cross the horizon.
DateTime? nextPhaseChangeAfter({
  required DateTime instant,
  required double latitude,
  required double longitude,
}) {
  final utc = instant.toUtc();
  for (var dayOffset = 0; dayOffset <= 1; dayOffset++) {
    final solar = solarDayFor(
      instant: utc.add(Duration(days: dayOffset)),
      latitude: latitude,
      longitude: longitude,
    );
    if (!solar.sunCrossesHorizon) return null;
    for (final boundary in [solar.sunriseUtc!, solar.sunsetUtc!]) {
      if (boundary.isAfter(utc)) return boundary;
    }
  }
  return null;
}
