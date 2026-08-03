import '../symbolic/natal_chart.dart';
import 'major_arcana.dart';
import 'zodiac.dart';

/// One of the twelve houses, and the card standing on it.
class HouseCard {
  const HouseCard({
    required this.house,
    required this.cusp,
    required this.sign,
    required this.card,
  });

  /// 1..12.
  final int house;

  /// The cusp's ecliptic longitude, as the chart computed it.
  final double cusp;

  /// The sign the cusp falls in.
  final Zodiac sign;

  /// The card that sign carries.
  final MajorArcana card;

  /// Degrees into [sign], 0..30.
  double get degreeInSign => cusp % 30;

  /// The first house is the Ascendant, by definition rather than by
  /// coincidence: `houseCusps[0]` *is* the ascending degree.
  ///
  /// Worth naming, because the Vessel shows the Ascendant's card above this
  /// list and would otherwise appear to print the same card twice for no
  /// reason. It is the same card, and the reason is that they are the same
  /// point.
  bool get isAscendant => house == 1;
}

/// The twelve houses with a card each, from the sign on every cusp.
///
/// **The rule, and what it was chosen over** (owner's decision, 3 August 2026).
/// A house takes the card of the sign on its cusp, through the same
/// [MajorArcana.forZodiac] that gives the Sun its card. Two alternatives were
/// put and refused: the ruler of the cusp sign, which is more traditional but
/// needs a planet-to-card table that does not exist here and reads less
/// directly off the wheel; and house number to arcana of the same number,
/// which is the simplest of the three and produces *the same twelve cards for
/// every person alive* — twelve cards that say nothing about this chart.
///
/// Interceptions are not smoothed over. Away from the equator a Placidus
/// quadrant can be wide enough to swallow a whole sign, so a sign can sit on
/// two cusps and another on none: the same card then holds two houses, and
/// some cards are absent. That is a real feature of the chart and the reading
/// is told about it rather than shielded from it — see
/// `VesselReadingRequest.recurrences`.
List<HouseCard> houseCardsFor(NatalChart chart) =>
    houseCardsFromCusps(chart.houseCusps);

/// The same rule, over the cusps alone.
///
/// Split out because it is the whole of the arithmetic and a test should not
/// have to fabricate a natal chart — with its positions, aspects and engine —
/// to ask what sign 370 degrees is in.
List<HouseCard> houseCardsFromCusps(List<double> cusps) {
  return [
    for (var index = 0; index < cusps.length; index++)
      HouseCard(
        house: index + 1,
        cusp: cusps[index],
        sign: _signAt(cusps[index]),
        card: MajorArcana.forZodiac(_signAt(cusps[index])),
      ),
  ];
}

/// Which house a longitude falls in, 1..12.
///
/// A house runs from its own cusp forward to the next, and the quadrants are
/// very uneven away from the equator — so this walks the arcs rather than
/// dividing the circle by twelve. Returns null only for a chart with no cusps,
/// which is a chart drawn without a birth time.
int? houseOf(double longitude, List<double> cusps) {
  if (cusps.length != 12) return null;
  final point = ((longitude % 360) + 360) % 360;
  for (var i = 0; i < 12; i++) {
    final from = ((cusps[i] % 360) + 360) % 360;
    final span = _forward(from, cusps[(i + 1) % 12]);
    if (_forward(from, point) < span) return i + 1;
  }
  // Only reachable if the cusps do not span the circle, which the engine does
  // not produce. Falling back to the first house would be a quiet lie.
  return null;
}

double _forward(double from, double to) {
  final delta = (((to - from) % 360) + 360) % 360;
  return delta;
}

/// The sign a longitude falls in.
///
/// Thirty degrees each from 0° Aries, normalised first: a cusp arrives as an
/// ecliptic longitude and nothing guarantees it has been wrapped.
Zodiac _signAt(double longitude) {
  final wrapped = ((longitude % 360) + 360) % 360;
  return Zodiac.values[(wrapped ~/ 30) % 12];
}
