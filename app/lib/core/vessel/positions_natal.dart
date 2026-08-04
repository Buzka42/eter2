import '../arcana/house_cards.dart';
import '../symbolic/natal_chart.dart';
import '../symbolic/transits.dart';

/// The natal half of today's Positions.
///
/// Today's contacts said which of a person's points the sky was touching and
/// nothing about the chart being touched — so the reading could name a transit
/// and could not say what it was landing on. "Mercury is retrograde" is true
/// for everybody alive and is therefore a reading of nobody; what makes it a
/// particular person's day is which of *their* houses it is crossing and which
/// of *their* placements it contacts.
///
/// Derived positions only. No birth date, no time, no coordinates, no
/// identity — the same bound every other request in this product works under.
Map<String, Object?> positionsNatalContext({
  required NatalChart chart,
  required TransitReading reading,
  required bool ascendantReliable,
}) {
  final cusps = chart.houseCusps;
  final houses = ascendantReliable ? houseCardsFor(chart) : const <HouseCard>[];

  /// Which of this person's houses a longitude is in, or null when the birth
  /// time cannot support houses. Null rather than a guess: a house nobody can
  /// stand behind is worse than no house at all.
  int? houseFor(double longitude) =>
      ascendantReliable ? houseOf(longitude, cusps) : null;

  return {
    'placements': [
      for (final position in chart.positions)
        {
          'point': position.name,
          'sign': position.sign,
          'degrees': double.parse(position.degreeInSign.toStringAsFixed(1)),
          if (position.retrograde) 'retrograde': true,
          if (houseFor(position.longitude) case final house?) 'house': house,
        },
    ],
    if (houses.isNotEmpty)
      'houses': [
        for (final house in houses)
          {
            'house': house.house,
            'sign': house.sign.label,
            'card': house.card.title,
          },
      ],
    // Where today's bodies are standing in this person's chart. This is the
    // join the reading could not make: a retrograde is only ever retrograde in
    // *a* house, and which one is the whole difference between a horoscope and
    // a reading.
    'skyInHouses': [
      for (final position in reading.sky)
        if (houseFor(position.longitude) case final house?)
          {
            'body': position.name,
            'house': house,
            if (position.retrograde) 'retrograde': true,
          },
    ],
    'housesReliable': ascendantReliable,
  };
}
