/// Eter's arcana matrix: a birth date read as a small figure of cards.
///
/// **The construction is Eter's own and is written down here** so that it can
/// be checked, argued with, and kept stable. It is not a reproduction of any
/// published system's diagram or position meanings, and it does not claim to
/// be a tradition. It is arithmetic — reducing the parts of a date to the
/// twenty-two arcana — arranged the way this product already thinks.
///
/// The figure is three pairs and a centre:
///
/// * **The given** (day) and **the inherited** (month) — what arrives with a
///   person. The day is the particular; the month is the season it belongs to.
/// * **The era** (year) and **the turning** (the personal year at birth) —
///   the time that was running when they began.
/// * **The meeting** (day + month) and **the long thread** (day + year) —
///   what the pairs make of each other.
/// * **The centre** — every part summed and reduced. This is the Life Path
///   card the Vessel already shows, arrived at from the other direction, so
///   the figure explains the card rather than repeating it.
///
/// Every position is a Major Arcana between I and XXII. The reduction rule is
/// the ordinary one: sum the digits, and keep summing until the result is
/// within range. Twenty-two is kept rather than reduced to four, because the
/// twenty-second card is a card.
library;

import 'major_arcana.dart';

/// One place in the figure.
enum MatrixPosition {
  given('The given', 'The day itself — the particular fact of arriving.'),
  inherited(
    'The inherited',
    'The month — the season a life is handed, before it chooses anything.',
  ),
  era('The era', 'The year — the weather of the time, not of the person.'),
  turning(
    'The turning',
    'Where that year stood in its own cycle when the person began.',
  ),
  meeting(
    'The meeting',
    'Day and month together — the particular meeting its season.',
  ),
  longThread(
    'The long thread',
    'Day and year together — the part that runs the whole length.',
  ),
  centre(
    'The centre',
    'Everything summed. The same card the Life Path arrives at, reached from '
        'the other side.',
  );

  const MatrixPosition(this.label, this.detail);

  final String label;

  /// What the position is, in Eter's words. Written here rather than in an
  /// asset because it is structural: the figure means nothing without it.
  final String detail;

  /// Stable key for caching a reading against this position.
  String get key => 'matrix.$name';
}

/// One card in its place.
class MatrixCard {
  const MatrixCard({
    required this.position,
    required this.value,
    required this.card,
  });

  final MatrixPosition position;

  /// The reduced number, I–XXII.
  final int value;

  final MajorArcana card;
}

class ArcanaMatrix {
  const ArcanaMatrix(this.cards);

  final Map<MatrixPosition, MatrixCard> cards;

  MatrixCard operator [](MatrixPosition position) => cards[position]!;

  /// The figure, in reading order: the pairs, then what they make, then the
  /// centre they all resolve to.
  List<MatrixCard> get inReadingOrder =>
      [for (final position in MatrixPosition.values) cards[position]!];
}

/// Reduces to the 1–22 range by repeated digit sums.
///
/// Twenty-two is a resting place, not a stop on the way to four: the figure is
/// built on twenty-two cards and the last of them has to be reachable.
int reduceToArcana(int value) {
  var result = value.abs();
  if (result == 0) return 22;
  while (result > 22) {
    var sum = 0;
    var remaining = result;
    while (remaining > 0) {
      sum += remaining % 10;
      remaining ~/= 10;
    }
    result = sum;
  }
  return result == 0 ? 22 : result;
}

/// Builds the figure from a birth date.
///
/// Deterministic, offline, and dependent on nothing but the date — the same
/// promise the natal chart makes. The model is given the result and writes
/// about it; it never computes it.
ArcanaMatrix buildArcanaMatrix(DateTime dob) {
  final day = reduceToArcana(dob.day);
  final month = reduceToArcana(dob.month);
  final year = reduceToArcana(dob.year);

  // The personal year at birth: where the year stood in its own nine-year
  // cycle. Nine, not twenty-two — it is a phase, and phases are short.
  final turning = reduceToArcana(
    ((dob.day + dob.month + _digitSum(dob.year) - 1) % 9) + 1,
  );

  final values = <MatrixPosition, int>{
    MatrixPosition.given: day,
    MatrixPosition.inherited: month,
    MatrixPosition.era: year,
    MatrixPosition.turning: turning,
    MatrixPosition.meeting: reduceToArcana(day + month),
    MatrixPosition.longThread: reduceToArcana(day + year),
    MatrixPosition.centre: reduceToArcana(day + month + year),
  };

  return ArcanaMatrix({
    for (final entry in values.entries)
      entry.key: MatrixCard(
        position: entry.key,
        value: entry.value,
        card: _cardFor(entry.value),
      ),
  });
}

int _digitSum(int value) {
  var sum = 0;
  var remaining = value.abs();
  while (remaining > 0) {
    sum += remaining % 10;
    remaining ~/= 10;
  }
  return sum;
}

/// The arcana numbered [value], where XXII is the unnumbered card.
///
/// The catalog numbers The Fool 0 and runs to The World at 21, so a figure
/// counting I–XXII maps one lower — and 22 comes back round to The Fool,
/// which is where a deck that numbers him last puts him anyway.
MajorArcana _cardFor(int value) => value == 22
    ? MajorArcana.values.firstWhere((card) => card.number == 0)
    : MajorArcana.values.firstWhere((card) => card.number == value - 1);
