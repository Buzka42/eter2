import 'package:eter/core/arcana/major_arcana.dart';
import 'package:eter/core/arcana/zodiac.dart';
import 'package:eter/core/symbolic/numerology.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateLifePath', () {
    test('reduces an ordinary date to a single digit', () {
      // 1988-03-12 -> 1+9+8+8+0+3+1+2 = 32 -> 5.
      expect(calculateLifePath(DateTime(1988, 3, 12)), 5);
    });

    test('preserves each master number', () {
      // 1990-05-14 -> 1+9+9+0+0+5+1+4 = 29 -> 11.
      expect(calculateLifePath(DateTime(1990, 5, 14)), 11);
      // 1970-01-04 -> 1+9+7+0+0+1+0+4 = 22, which stands rather than reducing.
      expect(calculateLifePath(DateTime(1970, 1, 4)), 22);
      // 1965-12-27 -> 1+9+6+5+1+2+2+7 = 33.
      expect(calculateLifePath(DateTime(1965, 12, 27)), 33);
      expect(masterNumbers, <int>{11, 22, 33});
    });

    test('every reachable life path has a card', () {
      // The v1 crash: calculateLifePath preserved 33 while MajorArcana had no
      // case for it, so a date of birth summing to 33 threw out of the Vessel.
      // Sweep a wide date range and assert the two never disagree again.
      final seen = <int>{};
      for (var year = 1920; year <= 2026; year++) {
        for (final month in const [1, 2, 3, 6, 9, 12]) {
          for (final day in const [1, 9, 17, 27, 28]) {
            final path = calculateLifePath(DateTime(year, month, day));
            seen.add(path);
            expect(
              () => MajorArcana.forLifePath(path),
              returnsNormally,
              reason: 'life path $path from $year-$month-$day has no card',
            );
          }
        }
      }
      expect(
        seen.difference(MajorArcana.supportedLifePaths.toSet()),
        isEmpty,
        reason: 'a life path was produced that the catalog does not declare',
      );
    });

    test('life path 33 resolves rather than throwing', () {
      // 1965-12-27 -> 1+9+6+5+1+2+2+7 = 33. This is the exact input that threw
      // ArgumentError out of the v1 Vessel.
      expect(calculateLifePath(DateTime(1965, 12, 27)), 33);
      expect(MajorArcana.forLifePath(33), MajorArcana.world);
    });

    test('rejects a life path the catalog does not support', () {
      expect(() => MajorArcana.forLifePath(10), throwsArgumentError);
      expect(() => MajorArcana.forLifePath(0), throwsArgumentError);
    });

    test('the declared life paths all map', () {
      for (final path in MajorArcana.supportedLifePaths) {
        expect(() => MajorArcana.forLifePath(path), returnsNormally);
      }
    });
  });

  group('calculatePersonalYear', () {
    test('always reduces to a single digit', () {
      final dob = DateTime(1990, 5, 14);
      for (var year = 2020; year <= 2035; year++) {
        final value = calculatePersonalYear(dob, DateTime(year, 6, 1));
        expect(value, inInclusiveRange(1, 9));
      }
    });

    test('advances by one each year', () {
      final dob = DateTime(1990, 5, 14);
      final first = calculatePersonalYear(dob, DateTime(2026, 6, 1));
      final second = calculatePersonalYear(dob, DateTime(2027, 6, 1));
      expect(second, first == 9 ? 1 : first + 1);
    });
  });

  group('MajorArcana', () {
    test('the catalog is complete and slugs are unique', () {
      expect(MajorArcana.values.length, 22);
      expect(
        MajorArcana.values.map((c) => c.assetSlug).toSet().length,
        22,
      );
      expect(
        MajorArcana.values.map((c) => c.number).toList(),
        List<int>.generate(22, (i) => i),
      );
    });

    test('every card round-trips through its slug', () {
      for (final card in MajorArcana.values) {
        expect(MajorArcana.bySlug(card.assetSlug), card);
      }
      expect(MajorArcana.bySlug('not-a-card'), isNull);
    });

    test('every zodiac sign maps to a card', () {
      final mapped = Zodiac.values.map(MajorArcana.forZodiac).toSet();
      expect(Zodiac.values.length, 12);
      // The Golden Dawn correspondence is injective: twelve signs, twelve
      // distinct cards.
      expect(mapped.length, 12);
    });

    test('every card ships production art in both themes', () {
      for (final card in MajorArcana.values) {
        expect(card.hasProductionArt, isTrue, reason: '${card.title}');
        expect(card.assetFor(Brightness.light), endsWith('-light.webp'));
        expect(card.assetFor(Brightness.dark), endsWith('-dark.webp'));
      }
    });

    test('motion is a night-only affordance', () {
      // Day is still, night moves. A day loop must never be requested -- there
      // are none, and under the automatic register that is deliberate.
      for (final card in MajorArcana.values) {
        expect(card.nightLoopFor(Brightness.light), isNull);
        if (card.hasNightLoop) {
          expect(card.nightLoopFor(Brightness.dark), endsWith('-dark.mp4'));
        }
      }
    });
  });
}
