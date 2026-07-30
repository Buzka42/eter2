import 'package:eter/core/register.dart';
import 'package:eter/core/symbolic/solar.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tolerance for the closed-form NOAA equation against published almanac
/// times. The register needs to know which side of sunset it is on, so a few
/// minutes is far tighter than the product requires.
const _tolerance = Duration(minutes: 5);

void _expectNear(DateTime? actual, DateTime expected, String label) {
  expect(actual, isNotNull, reason: '$label should exist');
  final drift = actual!.difference(expected).abs();
  expect(
    drift <= _tolerance,
    isTrue,
    reason: '$label was $actual, expected near $expected (drift $drift)',
  );
}

void main() {
  group('solarDayFor', () {
    test('London at the June solstice', () {
      final solar = solarDayFor(
        instant: DateTime.utc(2026, 6, 21, 12),
        latitude: 51.5074,
        longitude: -0.1278,
      );
      // Almanac: 04:43 / 21:21 BST -> 03:43 / 20:21 UTC.
      _expectNear(solar.sunriseUtc, DateTime.utc(2026, 6, 21, 3, 43), 'sunrise');
      _expectNear(solar.sunsetUtc, DateTime.utc(2026, 6, 21, 20, 21), 'sunset');
    });

    test('London at the December solstice', () {
      final solar = solarDayFor(
        instant: DateTime.utc(2026, 12, 21, 12),
        latitude: 51.5074,
        longitude: -0.1278,
      );
      // Almanac: 08:03 / 15:53 GMT.
      _expectNear(solar.sunriseUtc, DateTime.utc(2026, 12, 21, 8, 3), 'sunrise');
      _expectNear(solar.sunsetUtc, DateTime.utc(2026, 12, 21, 15, 53), 'sunset');
    });

    test('the day is longer in June than in December', () {
      final june = solarDayFor(
        instant: DateTime.utc(2026, 6, 21, 12),
        latitude: 51.5074,
        longitude: -0.1278,
      );
      final december = solarDayFor(
        instant: DateTime.utc(2026, 12, 21, 12),
        latitude: 51.5074,
        longitude: -0.1278,
      );
      final juneLength = june.sunsetUtc!.difference(june.sunriseUtc!);
      final decemberLength =
          december.sunsetUtc!.difference(december.sunriseUtc!);
      expect(juneLength, greaterThan(decemberLength));
      expect(juneLength.inHours, greaterThan(15));
      expect(decemberLength.inHours, lessThan(9));
    });

    test('the midnight sun has no sunrise or sunset', () {
      // Tromsø in midsummer: the sun does not set.
      final solar = solarDayFor(
        instant: DateTime.utc(2026, 6, 21, 12),
        latitude: 69.6492,
        longitude: 18.9553,
      );
      expect(solar.sunCrossesHorizon, isFalse);
    });

    test('polar night has no sunrise or sunset', () {
      final solar = solarDayFor(
        instant: DateTime.utc(2026, 12, 21, 12),
        latitude: 69.6492,
        longitude: 18.9553,
      );
      expect(solar.sunCrossesHorizon, isFalse);
    });

    test('the southern hemisphere inverts the seasons', () {
      final sydneyJune = solarDayFor(
        instant: DateTime.utc(2026, 6, 21, 2),
        latitude: -33.8688,
        longitude: 151.2093,
      );
      final sydneyDecember = solarDayFor(
        instant: DateTime.utc(2026, 12, 21, 2),
        latitude: -33.8688,
        longitude: 151.2093,
      );
      expect(
        sydneyDecember.sunsetUtc!.difference(sydneyDecember.sunriseUtc!),
        greaterThan(sydneyJune.sunsetUtc!.difference(sydneyJune.sunriseUtc!)),
      );
    });
  });

  group('dayPhaseAt', () {
    test('noon is day and midnight is night in London', () {
      const london = (lat: 51.5074, lon: -0.1278);
      expect(
        dayPhaseAt(
          instant: DateTime.utc(2026, 6, 21, 12),
          latitude: london.lat,
          longitude: london.lon,
        ),
        DayPhase.day,
      );
      expect(
        dayPhaseAt(
          instant: DateTime.utc(2026, 6, 21, 23, 30),
          latitude: london.lat,
          longitude: london.lon,
        ),
        DayPhase.night,
      );
    });

    test('the register turns at the real horizon, not at a clock hour', () {
      const london = (lat: 51.5074, lon: -0.1278);
      // 20:00 UTC on the June solstice is still before a 20:21 sunset, so it
      // is day -- a fixed evening threshold would already have called it night.
      expect(
        dayPhaseAt(
          instant: DateTime.utc(2026, 6, 21, 20),
          latitude: london.lat,
          longitude: london.lon,
        ),
        DayPhase.day,
      );
      // The same wall-clock hour in December is well after a 15:53 sunset.
      expect(
        dayPhaseAt(
          instant: DateTime.utc(2026, 12, 21, 20),
          latitude: london.lat,
          longitude: london.lon,
        ),
        DayPhase.night,
      );
    });

    test('falls back to the clock when there are no coordinates', () {
      expect(
        dayPhaseAt(instant: DateTime(2026, 6, 21, 12)),
        DayPhase.day,
      );
      expect(
        dayPhaseAt(instant: DateTime(2026, 6, 21, 23)),
        DayPhase.night,
      );
    });

    test('falls back to the clock under the midnight sun', () {
      // Rather than pinning a Tromsø user in one register for weeks.
      expect(
        dayPhaseAt(
          instant: DateTime(2026, 6, 21, 12),
          latitude: 69.6492,
          longitude: 18.9553,
        ),
        DayPhase.day,
      );
      expect(
        dayPhaseAt(
          instant: DateTime(2026, 6, 21, 23),
          latitude: 69.6492,
          longitude: 18.9553,
        ),
        DayPhase.night,
      );
    });
  });

  group('nextPhaseChangeAfter', () {
    test('returns the coming sunset during the day', () {
      final next = nextPhaseChangeAfter(
        instant: DateTime.utc(2026, 6, 21, 12),
        latitude: 51.5074,
        longitude: -0.1278,
      );
      _expectNear(next, DateTime.utc(2026, 6, 21, 20, 21), 'next boundary');
    });

    test('returns tomorrow morning late at night', () {
      final next = nextPhaseChangeAfter(
        instant: DateTime.utc(2026, 6, 21, 23),
        latitude: 51.5074,
        longitude: -0.1278,
      );
      expect(next, isNotNull);
      expect(next!.isAfter(DateTime.utc(2026, 6, 21, 23)), isTrue);
      expect(next.day, 22);
    });

    test('is null where the sun does not cross the horizon', () {
      expect(
        nextPhaseChangeAfter(
          instant: DateTime.utc(2026, 6, 21, 12),
          latitude: 69.6492,
          longitude: 18.9553,
        ),
        isNull,
      );
    });
  });

  /// Which horizon the register reads, which is *not* the one the chart uses.
  ///
  /// The bug this replaces: `dayPhaseAt` was fed the birth coordinates, because
  /// they were the only ones stored. Someone born in Warsaw and living in
  /// Vancouver got a register computed on Warsaw's sun — nine hours out, in the
  /// default register, silently. These tests are all about telling "still there"
  /// apart from "has moved" using nothing but the device clock.
  group('registerCoordinates', () {
    // Warsaw, and the offset a phone in Warsaw reports in summer.
    const warsaw = (lat: 52.2297, lon: 21.0122);
    const warsawOffset = Duration(hours: 2);
    // Vancouver, and its own summer offset.
    const vancouver = (lat: 49.2827, lon: -123.1207);
    const vancouverOffset = Duration(hours: -7);

    test('home coordinates win whenever they exist', () {
      final at = registerCoordinates(
        homeLatitude: vancouver.lat,
        homeLongitude: vancouver.lon,
        birthLatitude: warsaw.lat,
        birthLongitude: warsaw.lon,
        utcOffset: vancouverOffset,
      );
      expect(at?.latitude, vancouver.lat);
      expect(at?.longitude, vancouver.lon);
    });

    test('a home place is honoured even where birth would have served', () {
      // Someone who moved across their own country: the clock would never have
      // caught it, and their explicit answer still has to be obeyed.
      final at = registerCoordinates(
        homeLatitude: 54.3520,
        homeLongitude: 18.6466,
        birthLatitude: warsaw.lat,
        birthLongitude: warsaw.lon,
        utcOffset: warsawOffset,
      );
      expect(at?.longitude, 18.6466);
    });

    test('birth coordinates serve someone who never moved', () {
      final at = registerCoordinates(
        birthLatitude: warsaw.lat,
        birthLongitude: warsaw.lon,
        utcOffset: warsawOffset,
      );
      expect(at?.longitude, warsaw.lon);
    });

    test('birth coordinates are refused once the clock disproves them', () {
      // The whole defect, in one case: born in Warsaw, phone in Vancouver.
      expect(
        registerCoordinates(
          birthLatitude: warsaw.lat,
          birthLongitude: warsaw.lon,
          utcOffset: vancouverOffset,
        ),
        isNull,
      );
    });

    test('a zone running ahead of its meridian is not mistaken for a move', () {
      // Spain sits on Greenwich's meridian and keeps central European time, so
      // a Madrid phone is an hour off its own sun while being exactly where it
      // was born. A tighter tolerance would strand every Spaniard on the clock
      // fallback.
      expect(
        registerCoordinates(
          birthLatitude: 40.4168,
          birthLongitude: -3.7038,
          utcOffset: const Duration(hours: 2),
        ),
        isNotNull,
      );
    });

    test('the far edge of a single-zone country is still that country', () {
      // Kashgar is about five hours of sun from Beijing and shares its offset.
      expect(
        registerCoordinates(
          birthLatitude: 39.4704,
          birthLongitude: 75.9898,
          utcOffset: const Duration(hours: 8),
        ),
        isNotNull,
      );
    });

    test('nothing known means nothing claimed', () {
      expect(registerCoordinates(utcOffset: warsawOffset), isNull);
      // Half a pair is not a location.
      expect(
        registerCoordinates(birthLatitude: 52.2297, utcOffset: warsawOffset),
        isNull,
      );
    });

    group('registerNeedsHomePlace', () {
      test('asks only when it can prove the birth place cannot be current', () {
        expect(
          registerNeedsHomePlace(
            birthLatitude: warsaw.lat,
            birthLongitude: warsaw.lon,
            utcOffset: vancouverOffset,
          ),
          isTrue,
        );
        expect(
          registerNeedsHomePlace(
            birthLatitude: warsaw.lat,
            birthLongitude: warsaw.lon,
            utcOffset: warsawOffset,
          ),
          isFalse,
        );
      });

      test('does not nag someone who has already answered', () {
        expect(
          registerNeedsHomePlace(
            homeLatitude: vancouver.lat,
            homeLongitude: vancouver.lon,
            birthLatitude: warsaw.lat,
            birthLongitude: warsaw.lon,
            utcOffset: vancouverOffset,
          ),
          isFalse,
        );
      });

      test('does not nag someone who never gave a birth place either', () {
        // Already served the dull 07:00–19:00 default, honestly. There is
        // nothing here to correct, so there is nothing to ask about.
        expect(
          registerNeedsHomePlace(utcOffset: vancouverOffset),
          isFalse,
        );
      });
    });
  });
}
