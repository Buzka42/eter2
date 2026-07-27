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
}
