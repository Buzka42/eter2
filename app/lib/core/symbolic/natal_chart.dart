import 'dart:math' as math;

import 'package:astronomia/astronomia.dart';
import 'package:astronomia/coord.dart' as coord;
import 'package:astronomia/elliptic.dart' as elliptic;
import 'package:astronomia/moonposition.dart' as moon;
import 'package:astronomia/nutation.dart' as nutation;
import 'package:astronomia/planetposition.dart';
import 'package:astronomia/pluto.dart' as pluto;
import 'package:astronomia/sidereal.dart' as sidereal;
import 'package:astronomia/solar.dart' as solar;

const _signs = <String>[
  'Aries',
  'Taurus',
  'Gemini',
  'Cancer',
  'Leo',
  'Virgo',
  'Libra',
  'Scorpio',
  'Sagittarius',
  'Capricorn',
  'Aquarius',
  'Pisces',
];

/// Bumped whenever a correction changes what the engine computes.
///
/// It travels inside [natalInputHash], so a cached reading written by an
/// older engine no longer matches and is recomposed rather than shown. The
/// ascendant fix is exactly why this exists: without it, every reading written
/// against the descendant would have survived the fix indefinitely.
const natalEngineVersion = 'astronomia-meeus-2';

/// Identifies the chart a reading was written against.
///
/// One definition, because there were five and they had to agree forever.
String natalInputHash({
  required DateTime dob,
  int? birthTimeMinutes,
  int? birthUtcOffsetMinutes,
  double? birthLatitude,
  double? birthLongitude,
}) =>
    [
      dob.toIso8601String(),
      birthTimeMinutes ?? 'unknown-time',
      birthUtcOffsetMinutes ?? 'unknown-offset',
      birthLatitude ?? 'unknown-latitude',
      birthLongitude ?? 'unknown-longitude',
      natalEngineVersion,
    ].join('|');

class NatalInput {
  const NatalInput({
    required this.localDateTime,
    required this.utcOffsetMinutes,
    required this.latitude,
    required this.longitude,
  });

  final DateTime localDateTime;
  final int utcOffsetMinutes;
  final double latitude;
  final double longitude;

  DateTime get utcDateTime => DateTime.utc(
        localDateTime.year,
        localDateTime.month,
        localDateTime.day,
        localDateTime.hour,
        localDateTime.minute,
      ).subtract(Duration(minutes: utcOffsetMinutes));
}

class ZodiacPosition {
  const ZodiacPosition({
    required this.name,
    required this.longitude,
    this.retrograde = false,
  });

  final String name;
  final double longitude;
  final bool retrograde;

  int get signIndex => (longitude / 30).floor() % 12;
  String get sign => _signs[signIndex];
  double get degreeInSign => longitude % 30;

  Map<String, Object?> toJson() => {
        'name': name,
        'longitude': double.parse(longitude.toStringAsFixed(4)),
        'sign': sign,
        'degree': double.parse(degreeInSign.toStringAsFixed(2)),
        'retrograde': retrograde,
      };
}

class NatalAspect {
  const NatalAspect({
    required this.first,
    required this.second,
    required this.type,
    required this.orb,
  });

  final String first;
  final String second;
  final String type;
  final double orb;

  Map<String, Object?> toJson() => {
        'first': first,
        'second': second,
        'type': type,
        'orb': double.parse(orb.toStringAsFixed(2)),
      };
}

class NatalChart {
  const NatalChart({
    required this.calculatedAtUtc,
    required this.positions,
    required this.houseCusps,
    required this.aspects,
    required this.houseSystem,
    required this.engine,
  });

  final DateTime calculatedAtUtc;
  final List<ZodiacPosition> positions;
  final List<double> houseCusps;
  final List<NatalAspect> aspects;
  final String houseSystem;
  final String engine;

  ZodiacPosition get sun =>
      positions.firstWhere((position) => position.name == 'Sun');
  ZodiacPosition get moon =>
      positions.firstWhere((position) => position.name == 'Moon');
  ZodiacPosition get ascendant =>
      positions.firstWhere((position) => position.name == 'Ascendant');

  Map<String, Object?> toJson() => {
        'engine': engine,
        'calculatedAtUtc': calculatedAtUtc.toIso8601String(),
        'houseSystem': houseSystem,
        'positions': positions.map((position) => position.toJson()).toList(),
        'houseCusps': [
          for (var index = 0; index < houseCusps.length; index++)
            {
              'house': index + 1,
              'longitude': double.parse(houseCusps[index].toStringAsFixed(4)),
              'sign': _signs[(houseCusps[index] / 30).floor() % 12],
            },
        ],
        'aspects': aspects.map((aspect) => aspect.toJson()).toList(),
      };

  /// Concise, bounded context for Aether. It contains calculations, not claims.
  Map<String, Object?> toGuidanceSummary() => {
        'sun': sun.toJson(),
        'moon': moon.toJson(),
        'ascendant': ascendant.toJson(),
        'positions': positions
            .where((position) => const {
                  'Mercury',
                  'Venus',
                  'Mars',
                  'Jupiter',
                  'Saturn'
                }.contains(position.name))
            .map((position) => position.toJson())
            .toList(),
        'majorAspects':
            aspects.take(8).map((aspect) => aspect.toJson()).toList(),
        'houseSystem': houseSystem,
      };
}

class NatalChartEngine {
  NatalChartEngine()
      : _earth = Planet(planetEarth),
        _planets = {
          'Mercury': Planet(planetMercury),
          'Venus': Planet(planetVenus),
          'Mars': Planet(planetMars),
          'Jupiter': Planet(planetJupiter),
          'Saturn': Planet(planetSaturn),
          'Uranus': Planet(planetUranus),
          'Neptune': Planet(planetNeptune),
        };

  final Planet _earth;
  final Map<String, Planet> _planets;

  NatalChart calculate(NatalInput input) {
    if (input.latitude < -90 || input.latitude > 90) {
      throw RangeError.range(input.latitude, -90, 90, 'latitude');
    }
    if (input.longitude < -180 || input.longitude > 180) {
      throw RangeError.range(input.longitude, -180, 180, 'longitude');
    }
    if (input.utcOffsetMinutes < -14 * 60 || input.utcOffsetMinutes > 14 * 60) {
      throw RangeError.range(
        input.utcOffsetMinutes,
        -14 * 60,
        14 * 60,
        'utcOffsetMinutes',
      );
    }

    final utc = input.utcDateTime;
    final day = utc.day + (utc.hour + utc.minute / 60 + utc.second / 3600) / 24;
    final jd = calendarGregorianToJD(utc.year, utc.month, day);
    final eps = nutation.meanObliquity(jd) + nutation.nutation(jd).dEps;

    final positions = <ZodiacPosition>[
      ZodiacPosition(
        name: 'Sun',
        longitude: _degrees(solar.apparentVSOP87(_earth, jd).lon),
      ),
      ZodiacPosition(
        name: 'Moon',
        longitude: _degrees(moon.position(jd).lon + nutation.nutation(jd).dPsi),
      ),
      for (final entry in _planets.entries)
        _planetPosition(entry.key, entry.value, jd, eps),
      _plutoPosition(jd),
      ZodiacPosition(
        name: 'North Node',
        longitude: _meanNorthNode(jd),
        retrograde: true,
      ),
    ];

    final angles = _angles(
      jd: jd,
      latitude: input.latitude,
      longitude: input.longitude,
      obliquity: eps,
    );
    positions
      ..add(ZodiacPosition(name: 'Ascendant', longitude: angles.ascendant))
      ..add(ZodiacPosition(name: 'Midheaven', longitude: angles.midheaven));

    final placidus = _placidusCusps(
      ascendant: angles.ascendant,
      midheaven: angles.midheaven,
      ramc: angles.ramc,
      latitude: input.latitude,
      obliquity: eps,
    );
    // Placidus is what "the houses" means to most people who use the word, so
    // it is what Eter computes. It is also genuinely undefined inside the
    // polar circles: a degree that never rises has no semi-arc to divide, so
    // there is no cusp — not a hard one, an absent one. Rather than emit a
    // plausible number there, the chart falls back to equal houses and says
    // so in `houseSystem`, which travels with every reading.
    final houses = placidus ??
        List<double>.generate(
          12,
          (index) => _normalizeDegrees(angles.ascendant + index * 30),
        );

    return NatalChart(
      calculatedAtUtc: utc,
      positions: List.unmodifiable(positions),
      houseCusps: List.unmodifiable(houses),
      aspects: List.unmodifiable(_aspects(positions)),
      houseSystem: placidus == null ? 'equal' : 'placidus',
      engine: natalEngineVersion,
    );
  }

  ZodiacPosition _planetPosition(
    String name,
    Planet planet,
    double jd,
    double eps,
  ) {
    double longitudeAt(double instant) {
      final equatorial = elliptic.position(planet, _earth, instant);
      return _degrees(coord
          .eqToEcl(
            equatorial.ra,
            equatorial.dec,
            math.sin(eps),
            math.cos(eps),
          )
          .lon);
    }

    final longitude = longitudeAt(jd);
    final previous = longitudeAt(jd - .5);
    final next = longitudeAt(jd + .5);
    return ZodiacPosition(
      name: name,
      longitude: longitude,
      retrograde: _signedDelta(next, previous) < 0,
    );
  }

  ZodiacPosition _plutoPosition(double jd) {
    double longitudeAt(double instant) {
      final body = pluto.heliocentric(instant);
      final earth = _earth.position2000(instant);
      final bx = body.r * math.cos(body.lat) * math.cos(body.lon);
      final by = body.r * math.cos(body.lat) * math.sin(body.lon);
      final bz = body.r * math.sin(body.lat);
      final ex = earth.range * math.cos(earth.lat) * math.cos(earth.lon);
      final ey = earth.range * math.cos(earth.lat) * math.sin(earth.lon);
      final ez = earth.range * math.sin(earth.lat);
      final lon = math.atan2(by - ey, bx - ex);
      final lat = math.atan2(
        bz - ez,
        math.sqrt(math.pow(bx - ex, 2) + math.pow(by - ey, 2)),
      );
      final precessed = EclipticPrecessor(
        2000,
        jdeToJulianYear(instant),
      ).precess(lon, lat);
      return _degrees(precessed.lon);
    }

    final longitude = longitudeAt(jd);
    return ZodiacPosition(
      name: 'Pluto',
      longitude: longitude,
      retrograde: _signedDelta(longitudeAt(jd + .5), longitudeAt(jd - .5)) < 0,
    );
  }

  /// The four intermediate cusps that Placidus actually solves for, or null
  /// where the system has no answer.
  ///
  /// Placidus divides *time*, not space: the cusp of the eleventh is the
  /// degree that has spent a third of its own daytime travelling from the
  /// horizon toward the meridian. In hour-angle terms, with H measured from
  /// the meridian and negative to the east:
  ///
  ///   cusp 11: H = −(1/3)·DSA        cusp 12: H = −(2/3)·DSA
  ///   cusp  9: H = +(1/3)·DSA        cusp  8: H = +(2/3)·DSA
  ///
  /// where DSA = acos(−tan φ · tan δ) is the degree's own semi-diurnal arc.
  /// The second and third cusps are the opposites of the eighth and ninth,
  /// because opposite cusps are opposed in any quadrant system.
  ///
  /// δ depends on the longitude being solved for, so this is a fixed point:
  /// guess, compute the semi-arc, see where that puts the right ascension,
  /// correct, repeat.
  List<double>? _placidusCusps({
    required double ascendant,
    required double midheaven,
    required double ramc,
    required double latitude,
    required double obliquity,
  }) {
    final phi = toRad(latitude);

    /// Solves one cusp. [fraction] is how much of the semi-arc has been
    /// travelled; [east] places it before the meridian rather than after.
    double? solve(double fraction, {required bool east}) {
      // Start from the meridian and walk outward — close enough that the
      // iteration converges without hunting.
      var longitude = _normalizeDegrees(
        midheaven + (east ? 1 : -1) * fraction * 90,
      );
      for (var iteration = 0; iteration < 100; iteration++) {
        final lambda = toRad(longitude);
        final declination = math.asin(math.sin(obliquity) * math.sin(lambda));
        final tangent = math.tan(phi) * math.tan(declination);
        // |tan φ · tan δ| ≥ 1 is a degree that never crosses the horizon.
        if (tangent.abs() >= 1) return null;
        final semiArc = _degrees(math.acos(-tangent));
        final target = ramc + (east ? 1 : -1) * fraction * semiArc;
        final rightAscension = _degrees(
          math.atan2(math.sin(lambda) * math.cos(obliquity), math.cos(lambda)),
        );
        final error = _normalizeDegrees(target - rightAscension + 180) - 180;
        if (error.abs() < 1e-9) return _normalizeDegrees(longitude);
        longitude = _normalizeDegrees(longitude + error);
      }
      return null;
    }

    final eleven = solve(1 / 3, east: true);
    final twelve = solve(2 / 3, east: true);
    final nine = solve(1 / 3, east: false);
    final eight = solve(2 / 3, east: false);
    if (eleven == null || twelve == null || nine == null || eight == null) {
      return null;
    }

    return [
      ascendant,
      _normalizeDegrees(eight + 180),
      _normalizeDegrees(nine + 180),
      _normalizeDegrees(midheaven + 180),
      _normalizeDegrees(eleven + 180),
      _normalizeDegrees(twelve + 180),
      _normalizeDegrees(ascendant + 180),
      eight,
      nine,
      midheaven,
      eleven,
      twelve,
    ];
  }

  ({double ascendant, double midheaven, double ramc}) _angles({
    required double jd,
    required double latitude,
    required double longitude,
    required double obliquity,
  }) {
    final gst = sidereal.apparent(jd) / 86400 * 2 * math.pi;
    final lst = gst + toRad(longitude);
    final phi = toRad(latitude.clamp(-89.999, 89.999).toDouble());
    // ASC = atan2( cos θ , −(sin θ · cos ε + tan φ · sin ε) )
    //
    // Both signs matter and both were wrong: the previous form negated the
    // numerator instead of the denominator, which returns the antipode. That
    // is the descendant — a real degree, in a real sign, reading perfectly
    // plausibly, and wrong for every chart the app has ever drawn. Verified
    // against the eastern horizon in `test/ascendant_test.dart` rather than by
    // reading the formula, because reading the formula is what missed it.
    final asc = math.atan2(
      math.cos(lst),
      -(math.sin(lst) * math.cos(obliquity) +
          math.tan(phi) * math.sin(obliquity)),
    );
    final mc = math.atan2(
      math.sin(lst),
      math.cos(lst) * math.cos(obliquity),
    );
    return (
      ascendant: _degrees(asc),
      midheaven: _degrees(mc),
      // Right ascension of the meridian: the zero the semi-arcs measure from.
      ramc: _degrees(lst),
    );
  }

  List<NatalAspect> _aspects(List<ZodiacPosition> positions) {
    const targets = <String, double>{
      'conjunction': 0,
      'sextile': 60,
      'square': 90,
      'trine': 120,
      'opposition': 180,
    };
    final bodies = positions
        .where((position) =>
            position.name != 'Ascendant' && position.name != 'Midheaven')
        .toList();
    final result = <NatalAspect>[];
    for (var i = 0; i < bodies.length; i++) {
      for (var j = i + 1; j < bodies.length; j++) {
        final separation =
            _smallestSeparation(bodies[i].longitude, bodies[j].longitude);
        for (final target in targets.entries) {
          final orb = (separation - target.value).abs();
          final allowed = (bodies[i].name == 'Sun' ||
                  bodies[i].name == 'Moon' ||
                  bodies[j].name == 'Sun' ||
                  bodies[j].name == 'Moon')
              ? 8.0
              : 6.0;
          if (orb <= allowed) {
            result.add(NatalAspect(
              first: bodies[i].name,
              second: bodies[j].name,
              type: target.key,
              orb: orb,
            ));
            break;
          }
        }
      }
    }
    result.sort((a, b) => a.orb.compareTo(b.orb));
    return result;
  }
}

double _degrees(double radians) => _normalizeDegrees(radians * 180 / math.pi);

double _normalizeDegrees(double value) {
  final result = value % 360;
  return result < 0 ? result + 360 : result;
}

double _signedDelta(double next, double previous) {
  var delta = _normalizeDegrees(next) - _normalizeDegrees(previous);
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  return delta;
}

double _smallestSeparation(double first, double second) {
  final delta = (_normalizeDegrees(first) - _normalizeDegrees(second)).abs();
  return delta > 180 ? 360 - delta : delta;
}

double _meanNorthNode(double jd) {
  final t = j2000Century(jd);
  return _normalizeDegrees(
    125.0445479 -
        1934.1362891 * t +
        0.0020754 * t * t +
        t * t * t / 467441 -
        t * t * t * t / 60616000,
  );
}
