import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:eter/core/symbolic/transits.dart';
import 'package:eter/core/vessel/positions_natal.dart';
import 'package:flutter_test/flutter_test.dart';

/// What today's sky is landing on.
///
/// Positions used to be given the contacts and nothing about the chart being
/// contacted, so it could name a transit and could not say what it touched.
/// "Mercury is retrograde" is true for everybody alive and is a reading of
/// nobody; the house it is crossing and the placement it squares are what make
/// it somebody's day.
void main() {
  final chart = NatalChartEngine().calculate(NatalInput(
    localDateTime: DateTime(1993, 7, 25, 12, 30),
    utcOffsetMinutes: 120,
    latitude: 52.2297,
    longitude: 21.0122,
  ));

  final reading = TransitEngine().forDay(
    natal: chart,
    at: DateTime(2026, 8, 4, 12),
    latitude: 52.2297,
    longitude: 21.0122,
  );

  test('the sky carries retrograde, which was computed and thrown away', () {
    final json = reading.toJson();
    final sky = json['sky'] as List;
    expect(sky, isNotEmpty);
    for (final entry in sky) {
      final body = entry as Map<String, Object?>;
      expect(body['body'], isA<String>());
      expect(body['sign'], isA<String>());
      expect(body['degrees'], isA<double>());
    }
    // The convenience list and the per-body flag must agree, or the reading
    // could be told two different things about the same sky.
    final flagged = [
      for (final entry in sky)
        if ((entry as Map)['retrograde'] == true) entry['body'] as String,
    ];
    expect(flagged.toSet(), reading.retrograde.toSet());
    expect(json['retrograde'], reading.retrograde);
  });

  test('the natal context says which house each body is crossing today', () {
    final natal = positionsNatalContext(
      chart: chart,
      reading: reading,
      ascendantReliable: true,
    );
    expect(natal['housesReliable'], isTrue);

    final placements = natal['placements'] as List;
    expect(placements, hasLength(chart.positions.length));
    for (final entry in placements) {
      final placement = entry as Map<String, Object?>;
      expect(placement['point'], isA<String>());
      expect(placement['house'], inInclusiveRange(1, 12));
    }

    expect(natal['houses'], hasLength(12));

    // The join the reading could not make: today's bodies, in this person's
    // houses.
    final skyInHouses = natal['skyInHouses'] as List;
    expect(skyInHouses, isNotEmpty);
    for (final entry in skyInHouses) {
      final body = entry as Map<String, Object?>;
      expect(body['house'], inInclusiveRange(1, 12));
    }
  });

  test('without reliable angles it offers no houses rather than wrong ones', () {
    // A house nobody can stand behind is worse than no house: the reading
    // would say "in your house of work" about a cusp derived from a noon
    // guess, and cache it.
    final natal = positionsNatalContext(
      chart: chart,
      reading: reading,
      ascendantReliable: false,
    );
    expect(natal['housesReliable'], isFalse);
    expect(natal.containsKey('houses'), isFalse);
    expect(natal['skyInHouses'], isEmpty);
    for (final entry in natal['placements'] as List) {
      expect((entry as Map).containsKey('house'), isFalse);
    }
  });

  test('it carries no birth input and no identity', () {
    final natal = positionsNatalContext(
      chart: chart,
      reading: reading,
      ascendantReliable: true,
    );
    final text = natal.toString();
    // Derived positions only — the same bound every other request works under.
    expect(text, isNot(contains('1993')));
    expect(text, isNot(contains('52.2')));
    expect(text, isNot(contains('21.0')));
  });
}
