import 'package:eter/core/arcana/major_arcana.dart';
import 'package:eter/core/arcana/symbol_content.dart';
import 'package:eter/core/arcana/zodiac.dart';
import 'package:eter/core/i18n/language.dart';
import 'package:eter/core/i18n/strings_pl.dart';
import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:eter/core/symbolic/numerology.dart';
import 'package:flutter_test/flutter_test.dart';

/// The point names NatalChartEngine emits. Derived from a real chart below
/// rather than hard-coded, so renaming a point in the engine fails here.
Set<String> _enginePointNames() {
  final chart = NatalChartEngine().calculate(
    NatalInput(
      localDateTime: DateTime(1990, 5, 14, 9, 30),
      utcOffsetMinutes: 120,
      latitude: 52.2297,
      longitude: 21.0122,
    ),
  );
  return chart.positions.map((position) => position.name).toSet();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final loaded = <AppLanguage, SymbolContent>{};

  setUpAll(() async {
    for (final language in AppLanguage.values) {
      loaded[language] = await SymbolContent.load(language: language);
    }
  });

  // Completeness is a property of every language directory, not of English.
  // A missing Polish entry renders a blank position in the Vessel exactly as a
  // missing English one does, and nobody would notice until a Polish-speaking
  // user opened the card.
  for (final language in AppLanguage.values) {
    group('completeness (${language.code})', () {
      SymbolContent content() => loaded[language]!;

      test('every Major Arcana card has attributes', () {
        for (final card in MajorArcana.values) {
          final attributes = content().card(card);
          expect(attributes, isNotNull, reason: '${card.assetSlug} has no entry');
          expect(attributes!.keywords, hasLength(inInclusiveRange(3, 5)));
          expect(attributes.subtitle, isNotEmpty);
          expect(attributes.correspondence, isNotEmpty);
        }
        expect(content().cards, hasLength(22));
      });

      test('every zodiac sign has attributes', () {
        for (final sign in Zodiac.values) {
          expect(content().sign(sign), isNotNull, reason: sign.label);
        }
        expect(content().signs, hasLength(12));
      });

      test('every supported life path has attributes', () {
        for (final path in MajorArcana.supportedLifePaths) {
          final attributes = content().lifePath(path);
          expect(attributes, isNotNull, reason: 'life path $path has no entry');
          expect(attributes!.master, masterNumbers.contains(path));
          expect(attributes.title, isNotEmpty);
        }
        expect(content().lifePaths, hasLength(12));
      });

      test('all twelve houses have attributes', () {
        for (var house = 1; house <= 12; house++) {
          final attributes = content().house(house);
          expect(attributes, isNotNull, reason: 'house $house');
          expect(attributes!.domain, isNotEmpty);
        }
        expect(content().houses, hasLength(12));
      });

      test('every point the chart engine emits has attributes', () {
        // The failure this prevents: adding a body to NatalChartEngine and
        // rendering a blank position in the Vessel because nobody wrote its
        // copy. In a translated build it also catches a point name that was
        // translated by mistake — the name is the join key.
        for (final name in _enginePointNames()) {
          expect(
            content().point(name),
            isNotNull,
            reason: 'the chart emits "$name" but ${language.code}/points.json '
                'has no entry',
          );
        }
      });

      test('points declares nothing the chart engine does not emit', () {
        expect(
          content().points.keys.toSet().difference(_enginePointNames()),
          isEmpty,
          reason: '${language.code}/points.json has entries the chart never '
              'produces',
        );
      });

      test('no keyword is duplicated within an entry', () {
        for (final card in content().cards.values) {
          expect(card.keywords.toSet(), hasLength(card.keywords.length),
              reason: '${card.slug} repeats a keyword');
        }
        for (final path in content().lifePaths.values) {
          expect(path.keywords.toSet(), hasLength(path.keywords.length),
              reason: 'life path ${path.value} repeats a keyword');
        }
      });
    });
  }

  group('the languages agree on their keys', () {
    // The keys are join columns: slugs name asset files, sign keys match the
    // `Zodiac` enum, point names match the chart engine, and life-path and house
    // numbers are arithmetic. Prose differs between directories; nothing else
    // may. This is the test that makes translating a key a build failure rather
    // than a blank card.
    test('every language carries exactly the same entries', () {
      final reference = loaded[AppLanguage.english]!;
      for (final language in AppLanguage.values) {
        final content = loaded[language]!;
        final where = language.code;
        expect(content.cards.keys.toSet(), reference.cards.keys.toSet(),
            reason: '$where card slugs differ');
        expect(content.signs.keys.toSet(), reference.signs.keys.toSet(),
            reason: '$where sign keys differ');
        expect(content.lifePaths.keys.toSet(), reference.lifePaths.keys.toSet(),
            reason: '$where life-path numbers differ');
        expect(content.houses.keys.toSet(), reference.houses.keys.toSet(),
            reason: '$where house numbers differ');
        expect(content.points.keys.toSet(), reference.points.keys.toSet(),
            reason: '$where point names differ');
      }
    });

    test('the prose actually differs, so nothing was left untranslated', () {
      // The other half of the check above: identical keys with identical copy
      // would mean the Polish directory is a copy of the English one, which
      // would pass every completeness test and ship an English Vessel.
      final en = loaded[AppLanguage.english]!;
      final pl = loaded[AppLanguage.polish]!;
      for (final slug in en.cards.keys) {
        expect(
          pl.cards[slug]!.subtitle,
          isNot(en.cards[slug]!.subtitle),
          reason: '$slug has the same subtitle in both languages',
        );
      }
      for (final number in en.houses.keys) {
        expect(
          pl.houses[number]!.domain,
          isNot(en.houses[number]!.domain),
          reason: 'house $number has the same domain in both languages',
        );
      }
    });
  });

  group('content quality (English is the reference table)', () {
    SymbolContent content() => loaded[AppLanguage.english]!;

    test('Death and The Devil keep their names and are reframed', () {
      expect(MajorArcana.death.title, 'Death');
      expect(MajorArcana.devil.title, 'The Devil');
      expect(
          content().card(MajorArcana.death)!.subtitle, 'Card of Transformation');
      expect(content().card(MajorArcana.devil)!.subtitle, 'Card of Ambition');
      // Polish keeps the authentic names too: softening `Śmierć` into something
      // gentler would be a different deck.
      const strings = EterStringsPl();
      expect(strings.arcanaTitle('death'), 'Śmierć');
      expect(strings.arcanaTitle('the-devil'), 'Diabeł');
    });

    test('the example from the product brief renders as specified', () {
      final strength = content().card(MajorArcana.strength)!;
      expect(
        strength.keywords,
        ['power', 'energy', 'action', 'courage', 'magnanimity'],
      );
    });

    test('sign rulers name real chart points', () {
      final emitted = _enginePointNames();
      for (final sign in content().signs.values) {
        expect(
          emitted.contains(sign.ruler),
          isTrue,
          reason: '${sign.key} is ruled by "${sign.ruler}", which is not a '
              'point the chart engine emits',
        );
      }
    });

    test('a translated ruler still names a real chart point', () {
      // `ruler` is display copy, so it is translated — but it must remain the
      // *name of a body*, not a free-text field. Checked by running the engine's
      // own point names through the language table and requiring a match.
      const strings = EterStringsPl();
      final translated = {
        for (final name in _enginePointNames()) strings.bodyName(name),
      };
      for (final sign in loaded[AppLanguage.polish]!.signs.values) {
        expect(
          translated.contains(sign.ruler),
          isTrue,
          reason: '${sign.key} is ruled by "${sign.ruler}", which is not any '
              'chart point translated into Polish',
        );
      }
    });
  });
}
