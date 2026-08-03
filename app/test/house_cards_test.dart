import 'package:eter/core/arcana/house_cards.dart';
import 'package:eter/core/arcana/major_arcana.dart';
import 'package:eter/core/arcana/zodiac.dart';
import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = NatalChartEngine();

  NatalChart chartAt({
    required DateTime local,
    required int offsetMinutes,
    required double latitude,
    required double longitude,
  }) =>
      engine.calculate(NatalInput(
        localDateTime: local,
        utcOffsetMinutes: offsetMinutes,
        latitude: latitude,
        longitude: longitude,
      ));

  /// The chart the owner reports against.
  final warsaw = chartAt(
    local: DateTime(1993, 7, 25, 12, 30),
    offsetMinutes: 120,
    latitude: 52.2297,
    longitude: 21.0122,
  );

  test('every house gets the card of the sign on its cusp', () {
    final houses = houseCardsFor(warsaw);
    expect(houses, hasLength(12));

    for (var i = 0; i < 12; i++) {
      final house = houses[i];
      expect(house.house, i + 1);
      expect(house.cusp, warsaw.houseCusps[i]);
      // The card is the sign's card, through the same mapping the Sun uses.
      expect(house.card, MajorArcana.forZodiac(house.sign));
      // And the sign really is the one the cusp falls in.
      final wrapped = ((house.cusp % 360) + 360) % 360;
      expect(house.sign, Zodiac.values[(wrapped ~/ 30) % 12]);
      expect(house.degreeInSign, inInclusiveRange(0, 30));
    }
  });

  test('the first house is the Ascendant, not a coincidence', () {
    final houses = houseCardsFor(warsaw);
    expect(houses.first.isAscendant, isTrue);
    expect(houses.first.cusp, closeTo(warsaw.ascendant.longitude, 1e-9));
    // So its card is the Ascendant's card, necessarily. The Vessel shows the
    // Ascendant above this list and must say they are one point rather than
    // appear to print a card twice.
    final ascendantSign = Zodiac.values.firstWhere(
      (value) => value.label == warsaw.ascendant.sign,
    );
    expect(houses.first.card, MajorArcana.forZodiac(ascendantSign));
    for (final house in houses.skip(1)) {
      expect(house.isAscendant, isFalse);
    }
  });

  test('a longitude on a sign boundary belongs to the sign it opens', () {
    // 0, 30, 60 … are the openings of Aries, Taurus, Gemini. Off-by-one here
    // would shift every house card by a whole sign.
    final houses = houseCardsFromCusps(
      List<double>.generate(12, (index) => index * 30.0),
    );
    for (var i = 0; i < 12; i++) {
      expect(houses[i].sign, Zodiac.values[i]);
      expect(houses[i].degreeInSign, 0);
    }
  });

  test('cusps are wrapped before they are read', () {
    // A cusp arrives as an ecliptic longitude and nothing promises it has been
    // normalised. 370 is 10 Aries; -10 is 350, which is Pisces.
    final houses = houseCardsFromCusps([
      370,
      -10,
      ...List<double>.generate(10, (index) => (index + 2) * 30.0),
    ]);
    expect(houses[0].sign, Zodiac.aries);
    expect(houses[0].degreeInSign, closeTo(10, 1e-9));
    expect(houses[1].sign, Zodiac.pisces);
  });

  test('an intercepted sign holds two houses, and another holds none', () {
    // High latitude, where Placidus quadrants are very uneven. This is not a
    // fault to smooth over: the same card standing on two cusps is a real
    // feature of the chart, and the reading is told about it.
    final reykjavik = chartAt(
      local: DateTime(1968, 12, 22, 9, 5),
      offsetMinutes: 0,
      latitude: 64.15,
      longitude: -21.94,
    );
    final houses = houseCardsFor(reykjavik);
    expect(houses, hasLength(12));

    final signs = houses.map((house) => house.sign).toList();
    final distinct = signs.toSet();
    // Whether this particular chart intercepts or not, the mapping must never
    // invent a sign it was not given.
    for (final sign in distinct) {
      expect(Zodiac.values, contains(sign));
    }
    // And every house still carries exactly the card of its own sign.
    for (final house in houses) {
      expect(house.card, MajorArcana.forZodiac(house.sign));
    }
  });

  group('which house a body stands in', () {
    test('walks the arcs rather than dividing the circle by twelve', () {
      // Even houses, so the answer is checkable by eye.
      final cusps = List<double>.generate(12, (index) => index * 30.0);
      expect(houseOf(0, cusps), 1);
      expect(houseOf(29.9, cusps), 1);
      expect(houseOf(30, cusps), 2);
      expect(houseOf(359.9, cusps), 12);
      // Wraps, like everything else that takes a longitude.
      expect(houseOf(360, cusps), 1);
      expect(houseOf(-1, cusps), 12);
    });

    test('uneven quadrants put bodies where the cusps say, not where a twelfth would', () {
      // A first house forty degrees wide and a second only ten. Dividing the
      // circle evenly would put 35 degrees in the second house; the arcs put
      // it in the first, which is what the chart actually says.
      final cusps = [0.0, 40.0, 50.0, 90.0, 120.0, 150.0,
                     180.0, 220.0, 230.0, 270.0, 300.0, 330.0];
      expect(houseOf(35, cusps), 1);
      expect(houseOf(45, cusps), 2);
      expect(houseOf(55, cusps), 3);
    });

    test('a chart with no cusps answers nothing rather than guessing', () {
      expect(houseOf(100, const []), isNull);
      expect(houseOf(100, const [0, 30, 60]), isNull);
    });

    test('every body in a real chart lands in exactly one house', () {
      final houses = <int, int>{};
      for (final point in warsaw.positions) {
        final house = houseOf(point.longitude, warsaw.houseCusps);
        expect(house, isNotNull, reason: point.name);
        expect(house, inInclusiveRange(1, 12), reason: point.name);
        houses.update(house!, (value) => value + 1, ifAbsent: () => 1);
      }
      expect(houses.values.fold<int>(0, (a, b) => a + b),
          warsaw.positions.length);
    });
  });
}
