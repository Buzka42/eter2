import 'package:eter/core/arcana/major_arcana.dart';
import 'package:eter/core/arcana/symbol_content.dart';
import 'package:eter/core/arcana/zodiac.dart';
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

  late SymbolContent content;

  setUpAll(() async {
    content = await SymbolContent.load();
  });

  group('completeness', () {
    test('every Major Arcana card has attributes', () {
      for (final card in MajorArcana.values) {
        final attributes = content.card(card);
        expect(attributes, isNotNull, reason: '${card.title} has no entry');
        expect(attributes!.keywords, hasLength(inInclusiveRange(3, 5)));
        expect(attributes.subtitle, isNotEmpty);
        expect(attributes.correspondence, isNotEmpty);
      }
      expect(content.cards, hasLength(22));
    });

    test('every zodiac sign has attributes', () {
      for (final sign in Zodiac.values) {
        expect(content.sign(sign), isNotNull, reason: '${sign.label}');
      }
      expect(content.signs, hasLength(12));
    });

    test('every supported life path has attributes', () {
      for (final path in MajorArcana.supportedLifePaths) {
        final attributes = content.lifePath(path);
        expect(attributes, isNotNull, reason: 'life path $path has no entry');
        expect(attributes!.master, masterNumbers.contains(path));
      }
      expect(content.lifePaths, hasLength(12));
    });

    test('all twelve houses have attributes', () {
      for (var house = 1; house <= 12; house++) {
        expect(content.house(house), isNotNull, reason: 'house $house');
      }
      expect(content.houses, hasLength(12));
    });

    test('every point the chart engine emits has attributes', () {
      // The failure this prevents: adding a body to NatalChartEngine and
      // rendering a blank position in the Vessel because nobody wrote its copy.
      for (final name in _enginePointNames()) {
        expect(
          content.point(name),
          isNotNull,
          reason: 'the chart emits "$name" but points.json has no entry',
        );
      }
    });

    test('points.json declares nothing the chart engine does not emit', () {
      final emitted = _enginePointNames();
      expect(
        content.points.keys.toSet().difference(emitted),
        isEmpty,
        reason: 'points.json has entries the chart never produces',
      );
    });
  });

  group('content quality', () {
    test('no keyword is duplicated within an entry', () {
      for (final card in content.cards.values) {
        expect(card.keywords.toSet(), hasLength(card.keywords.length),
            reason: '${card.slug} repeats a keyword');
      }
      for (final path in content.lifePaths.values) {
        expect(path.keywords.toSet(), hasLength(path.keywords.length),
            reason: 'life path ${path.value} repeats a keyword');
      }
    });

    test('Death and The Devil keep their names and are reframed', () {
      expect(MajorArcana.death.title, 'Death');
      expect(MajorArcana.devil.title, 'The Devil');
      expect(content.card(MajorArcana.death)!.subtitle, 'Card of Transformation');
      expect(content.card(MajorArcana.devil)!.subtitle, 'Card of Ambition');
    });

    test('the example from the product brief renders as specified', () {
      final strength = content.card(MajorArcana.strength)!;
      expect(
        strength.keywords,
        ['power', 'energy', 'action', 'courage', 'magnanimity'],
      );
    });

    test('sign rulers name real chart points', () {
      final emitted = _enginePointNames();
      for (final sign in content.signs.values) {
        expect(
          emitted.contains(sign.ruler),
          isTrue,
          reason: '${sign.key} is ruled by "${sign.ruler}", which is not a '
              'point the chart engine emits',
        );
      }
    });
  });
}
