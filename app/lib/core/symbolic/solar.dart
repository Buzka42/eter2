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

/// Where the register should read the sun from, and whether it can.
///
/// The register turns at the user's real horizon, which means *where they live*
/// — and the only coordinates this app has ever stored are the ones it needs for
/// the natal chart, which are where they were **born**. Those are the same place
/// for most people and nine hours apart for anyone who has moved. Fed birth
/// coordinates, Eter turned symbolic mid-morning for every migrant, expat and
/// student using it, in the default register, and never said so.
///
/// So: home coordinates when they have been given. Otherwise birth coordinates,
/// but only while the device's own clock agrees they are plausible — a birth
/// longitude implies a solar offset, and if the phone is hours away from it the
/// person is demonstrably not there any more. When they disagree, this returns
/// null and the register falls back to the clock rather than to a confident
/// wrong answer, and the Sanctum asks where they live.
///
/// [utcOffset] is the device's current offset, passed in rather than read here
/// so the whole decision stays pure and testable.
({double latitude, double longitude})? registerCoordinates({
  double? homeLatitude,
  double? homeLongitude,
  double? birthLatitude,
  double? birthLongitude,
  required Duration utcOffset,
}) {
  if (homeLatitude != null && homeLongitude != null) {
    return (latitude: homeLatitude, longitude: homeLongitude);
  }
  if (birthLatitude == null || birthLongitude == null) return null;

  // 15° of longitude is an hour of sun. Political timezones wander from solar
  // time — Spain runs an hour ahead of its meridian, China spans five hours on
  // one offset — so this tolerance has to be loose enough not to reject someone
  // who never moved. Three hours clears every real zone/meridian mismatch and
  // still catches an actual continental move, which is what it is for.
  const tolerance = Duration(hours: 3);
  final impliedHours = birthLongitude / 15.0;
  final implied = Duration(minutes: (impliedHours * 60).round());
  final drift = (utcOffset - implied).abs();
  return drift <= tolerance
      ? (latitude: birthLatitude, longitude: birthLongitude)
      : null;
}

/// True when Eter is falling back to the clock and a home place would fix it.
///
/// Drives the Sanctum's prompt. Deliberately false when there are no birth
/// coordinates either: that person has told Eter nothing about where they are
/// and is already being served the dull default honestly, so there is nothing
/// to correct.
bool registerNeedsHomePlace({
  double? homeLatitude,
  double? homeLongitude,
  double? birthLatitude,
  double? birthLongitude,
  required Duration utcOffset,
}) =>
    birthLatitude != null &&
    birthLongitude != null &&
    registerCoordinates(
          homeLatitude: homeLatitude,
          homeLongitude: homeLongitude,
          birthLatitude: birthLatitude,
          birthLongitude: birthLongitude,
          utcOffset: utcOffset,
        ) ==
        null;

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
