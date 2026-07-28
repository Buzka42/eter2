import 'package:eter/core/arcana/matrix.dart';
import 'package:eter/core/arcana/major_arcana.dart';
import 'package:eter/core/symbolic/numerology.dart';
import 'package:flutter_test/flutter_test.dart';

/// The figure is arithmetic, so it is checkable, and it should be checked:
/// a construction nobody can verify is indistinguishable from one nobody
/// thought about.
void main() {
  group('reduction', () {
    test('numbers already in range are left alone', () {
      for (var value = 1; value <= 22; value++) {
        expect(reduceToArcana(value), value, reason: '$value');
      }
    });

    test('larger numbers come down by digit sums', () {
      expect(reduceToArcana(23), 5);
      expect(reduceToArcana(1990), 19); // 1+9+9+0
      expect(reduceToArcana(2026), 10);
      expect(reduceToArcana(999999), 9); // 54 → 9
    });

    test('everything lands inside the deck', () {
      for (var value = 0; value < 5000; value++) {
        final reduced = reduceToArcana(value);
        expect(reduced, greaterThanOrEqualTo(1), reason: '$value');
        expect(reduced, lessThanOrEqualTo(22), reason: '$value');
      }
    });

    test('twenty-two is a resting place, not a stop on the way to four', () {
      // The figure is built on twenty-two cards; the last of them has to be
      // reachable or one card could never appear.
      expect(reduceToArcana(22), 22);
      expect(reduceToArcana(0), 22);
    });
  });

  group('the figure', () {
    final matrix = buildArcanaMatrix(DateTime(1990, 3, 14));

    test('every position is filled', () {
      expect(matrix.cards.keys.toSet(), MatrixPosition.values.toSet());
      expect(matrix.inReadingOrder, hasLength(MatrixPosition.values.length));
    });

    test('every position carries a real card in range', () {
      for (final entry in matrix.cards.values) {
        expect(entry.value, inInclusiveRange(1, 22));
        expect(entry.card.title, isNotEmpty);
      }
    });

    test('the parts are the parts of the date', () {
      // 14 March 1990: day 14, month 3, year 1+9+9+0 = 19.
      expect(matrix[MatrixPosition.given].value, 14);
      expect(matrix[MatrixPosition.inherited].value, 3);
      expect(matrix[MatrixPosition.era].value, 19);
    });

    test('the derived places are derived from them', () {
      final given = matrix[MatrixPosition.given].value;
      final inherited = matrix[MatrixPosition.inherited].value;
      final era = matrix[MatrixPosition.era].value;
      expect(
        matrix[MatrixPosition.meeting].value,
        reduceToArcana(given + inherited),
      );
      expect(
        matrix[MatrixPosition.longThread].value,
        reduceToArcana(given + era),
      );
      expect(
        matrix[MatrixPosition.centre].value,
        reduceToArcana(given + inherited + era),
      );
    });

    test('the centre agrees with the Life Path the Vessel already shows', () {
      // The figure has to explain the card the product already gives someone,
      // not contradict it. Both reduce the same date; they must not disagree
      // about what it sums to.
      final lifePath = calculateLifePath(DateTime(1990, 3, 14));
      expect(
        reduceToArcana(lifePath),
        anyOf(
          matrix[MatrixPosition.centre].value,
          reduceToArcana(matrix[MatrixPosition.centre].value),
        ),
      );
    });

    test('it is deterministic', () {
      final again = buildArcanaMatrix(DateTime(1990, 3, 14));
      for (final position in MatrixPosition.values) {
        expect(again[position].value, matrix[position].value);
        expect(again[position].card, matrix[position].card);
      }
    });

    test('a different date gives a different figure', () {
      final other = buildArcanaMatrix(DateTime(1984, 11, 2));
      expect(
        other.inReadingOrder.map((c) => c.value).toList(),
        isNot(matrix.inReadingOrder.map((c) => c.value).toList()),
      );
    });
  });

  group('across many dates', () {
    test('no date produces a hole, a crash or an out-of-deck card', () {
      for (var year = 1920; year <= 2026; year += 1) {
        for (final month in const [1, 2, 6, 9, 12]) {
          for (final day in const [1, 9, 22, 28]) {
            final matrix = buildArcanaMatrix(DateTime(year, month, day));
            expect(
              matrix.cards,
              hasLength(MatrixPosition.values.length),
              reason: '$year-$month-$day',
            );
            for (final card in matrix.inReadingOrder) {
              expect(card.value, inInclusiveRange(1, 22));
            }
          }
        }
      }
    });

    test('the deck is actually used, not clustered on a few cards', () {
      final seen = <MajorArcana>{};
      for (var year = 1950; year <= 2010; year++) {
        for (var month = 1; month <= 12; month++) {
          seen.addAll(
            buildArcanaMatrix(DateTime(year, month, 17))
                .inReadingOrder
                .map((card) => card.card),
          );
        }
      }
      // A construction that only ever reaches a handful of cards is a bad
      // construction, however defensible its arithmetic.
      expect(seen.length, greaterThan(15));
    });
  });

  group('positions', () {
    test('each has a label, a description and a stable key', () {
      final keys = <String>{};
      for (final position in MatrixPosition.values) {
        expect(position.label, isNotEmpty, reason: position.name);
        expect(position.detail, isNotEmpty, reason: position.name);
        expect(position.key, startsWith('matrix.'));
        keys.add(position.key);
      }
      // Keys are cache keys for written readings; a collision would show one
      // position's passage under another.
      expect(keys, hasLength(MatrixPosition.values.length));
    });
  });
}
