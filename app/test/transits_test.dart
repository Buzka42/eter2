import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:eter/core/symbolic/transits.dart';
import 'package:flutter_test/flutter_test.dart';

/// The moving half of the symbolic layer. Everything here is arithmetic, so
/// everything here is checkable: the aspect a contact claims must match the
/// separation it was found at, the orb must be inside the table's allowance,
/// and applying must mean the contact is still tightening tomorrow.
void main() {
  final engine = TransitEngine();

  // A real chart, so the natal longitudes are the ones the app would use.
  final natal = NatalChartEngine().calculate(NatalInput(
    localDateTime: DateTime(1990, 3, 14, 9, 20),
    utcOffsetMinutes: 60,
    latitude: 52.23,
    longitude: 21.01,
  ));

  TransitReading readingFor(DateTime day) => engine.forDay(
        natal: natal,
        at: day,
        latitude: 52.23,
        longitude: 21.01,
      );

  double separation(double first, double second) {
    final delta = (first - second) % 360;
    final positive = delta < 0 ? delta + 360 : delta;
    return positive > 180 ? 360 - positive : positive;
  }

  group('weighting', () {
    TransitContact contact({
      String transiting = 'Saturn',
      double orb = 1,
      bool applying = true,
    }) =>
        TransitContact(
          transiting: transiting,
          natal: 'Sun',
          type: 'conjunction',
          orb: orb,
          applying: applying,
        );

    test('a slow body outweighs a fast one at the same orb', () {
      expect(
        contact(transiting: 'Saturn').weight,
        greaterThan(contact(transiting: 'Moon').weight),
      );
      expect(
        contact(transiting: 'Jupiter').weight,
        greaterThan(contact(transiting: 'Venus').weight),
      );
    });

    test('a tight orb outweighs a wide one for the same body', () {
      expect(contact(orb: 0.2).weight, greaterThan(contact(orb: 3.8).weight));
    });

    test('separating is discounted against applying', () {
      expect(
        contact(applying: false).weight,
        lessThan(contact(applying: true).weight),
      );
    });

    test('an unlisted body still carries a weight rather than zero', () {
      expect(contact(transiting: 'Pluto').weight, greaterThan(0));
    });

    test('tightness stops falling past the widest orb the table allows', () {
      // Both are already at the clamp, so the only difference left is the body.
      expect(contact(orb: 9).weight, contact(orb: 40).weight);
    });
  });

  group('moon phase labels', () {
    TransitReading withPhase(double phase) => TransitReading(
          forDate: '2026-07-28',
          sky: const [],
          contacts: const [],
          moonPhase: phase,
        );

    test('names each eighth, and both ends of the cycle are new', () {
      expect(withPhase(0).moonPhaseLabel, 'new');
      expect(withPhase(0.99).moonPhaseLabel, 'new');
      expect(withPhase(0.15).moonPhaseLabel, 'waxing crescent');
      expect(withPhase(0.25).moonPhaseLabel, 'first quarter');
      expect(withPhase(0.4).moonPhaseLabel, 'waxing gibbous');
      expect(withPhase(0.5).moonPhaseLabel, 'full');
      expect(withPhase(0.6).moonPhaseLabel, 'waning gibbous');
      expect(withPhase(0.75).moonPhaseLabel, 'last quarter');
      expect(withPhase(0.9).moonPhaseLabel, 'waning crescent');
    });
  });

  group('aspect detection', () {
    final reading = readingFor(DateTime(2026, 7, 28));
    final natalByName = {
      for (final position in natal.positions) position.name: position,
    };
    final skyByName = {
      for (final position in reading.sky) position.name: position,
    };

    test('every contact sits at the separation its aspect claims', () {
      const targets = {
        'conjunction': 0.0,
        'sextile': 60.0,
        'square': 90.0,
        'trine': 120.0,
        'opposition': 180.0,
      };
      for (final contact in reading.contacts) {
        final actual = separation(
          skyByName[contact.transiting]!.longitude,
          natalByName[contact.natal]!.longitude,
        );
        expect(
          (actual - targets[contact.type]!).abs(),
          closeTo(contact.orb, 1e-9),
          reason: '${contact.transiting} ${contact.type} ${contact.natal}',
        );
      }
    });

    test('orbs stay inside the table: six with a luminary, four without', () {
      for (final contact in reading.contacts) {
        const luminaries = {'Sun', 'Moon'};
        final allowed = luminaries.contains(contact.transiting) ||
                luminaries.contains(contact.natal)
            ? 6.0
            : 4.0;
        expect(contact.orb, lessThanOrEqualTo(allowed));
      }
    });

    test('the angles are natal points only, never transiting bodies', () {
      expect(
        reading.contacts.map((contact) => contact.transiting),
        isNot(anyElement(anyOf('Ascendant', 'Midheaven'))),
      );
    });

    test('contacts are measured against the nine natal points and no others',
        () {
      const points = {
        'Sun',
        'Moon',
        'Ascendant',
        'Midheaven',
        'Mercury',
        'Venus',
        'Mars',
        'Jupiter',
        'Saturn',
      };
      for (final contact in reading.contacts) {
        expect(points, contains(contact.natal));
      }
    });

    test('one aspect per transiting-natal pair', () {
      final pairs =
          reading.contacts.map((c) => '${c.transiting}->${c.natal}').toList();
      expect(pairs.toSet(), hasLength(pairs.length));
    });

    test('strongest first', () {
      final weights = reading.contacts.map((c) => c.weight).toList();
      expect(weights, orderedEquals(weights.toList()..sort((a, b) => b.compareTo(a))));
    });

    test('applying means tomorrow is tighter', () {
      final tomorrow = readingFor(DateTime(2026, 7, 29));
      final tomorrowSky = {
        for (final position in tomorrow.sky) position.name: position,
      };
      const targets = {
        'conjunction': 0.0,
        'sextile': 60.0,
        'square': 90.0,
        'trine': 120.0,
        'opposition': 180.0,
      };
      for (final contact in reading.contacts) {
        final next = (separation(
                  tomorrowSky[contact.transiting]!.longitude,
                  natalByName[contact.natal]!.longitude,
                ) -
                targets[contact.type]!)
            .abs();
        expect(
          contact.applying,
          next < contact.orb,
          reason: '${contact.transiting} ${contact.type} ${contact.natal}',
        );
      }
    });

    test('the day is read at noon, so the hour it is asked does not move it',
        () {
      final morning = readingFor(DateTime(2026, 7, 28, 6, 5));
      final evening = readingFor(DateTime(2026, 7, 28, 23, 40));
      expect(morning.forDate, evening.forDate);
      expect(morning.moonPhase, evening.moonPhase);
      expect(
        morning.contacts.map((c) => '${c.transiting}${c.type}${c.natal}'),
        evening.contacts.map((c) => '${c.transiting}${c.type}${c.natal}'),
      );
    });

    test('contacts are unmodifiable', () {
      expect(
        () => reading.contacts.add(reading.contacts.first),
        throwsUnsupportedError,
      );
    });
  });

  group('provider context', () {
    final reading = readingFor(DateTime(2026, 7, 28));

    test('carries derived positions only — no birth inputs, no coordinates',
        () {
      final json = reading.toJson().toString();
      expect(json, isNot(contains('1990')));
      expect(json, isNot(contains('52.23')));
      expect(json, isNot(contains('21.01')));
      expect(json, isNot(contains('longitude')));
    });

    test('is bounded, and the bound is honoured', () {
      expect(
        (reading.toJson(maxContacts: 2)['contacts'] as List).length,
        lessThanOrEqualTo(2),
      );
      expect(
        (reading.toJson()['contacts'] as List).length,
        lessThanOrEqualTo(5),
      );
    });

    test('names the date, the phase and both luminary signs', () {
      final json = reading.toJson();
      expect(json['forDate'], '2026-07-28');
      expect(json['moonPhase'], reading.moonPhaseLabel);
      expect(json['sunSign'], isA<String>());
      expect(json['moonSign'], isA<String>());
    });

    test('orbs reach the provider rounded, not at full precision', () {
      for (final contact in reading.toJson()['contacts'] as List) {
        final orb = (contact as Map<String, Object?>)['orb'] as double;
        expect(orb, closeTo(double.parse(orb.toStringAsFixed(2)), 1e-9));
      }
    });
  });
}
