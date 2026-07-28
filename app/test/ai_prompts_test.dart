import 'dart:convert';

import 'package:eter/core/ai/prompts.dart';
import 'package:eter/core/aether/guidance_contract.dart';
import 'package:eter/core/aether/guidance_mode.dart';
import 'package:eter/core/aether/request_contract.dart';
import 'package:eter/core/vessel/reading_composer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AetherRequest buildRequest({
    GuidanceMode mode = GuidanceMode.balanced,
    bool journalConsented = true,
  }) =>
      const AetherRequestBuilder().build(
        aiConsented: true,
        journalConsented: journalConsented,
        ageYears: 32,
        mode: mode,
        health: const [
          AetherHealthContext(
            localDate: '2026-07-27',
            steps: 8420,
            activeKcal: 512,
            sleepMinutes: 402,
            restingHeartRate: 58,
            hrvMs: 61,
          ),
        ],
        journal: [
          AetherJournalContext(
            createdAt: DateTime.utc(2026, 7, 27, 8),
            text: 'I slept badly but the morning walk helped.',
          ),
        ],
      );

  group('the payload is the payload', () {
    test('guidance carries only what the request contract permitted', () {
      final request = buildRequest();

      final prompt = EterPrompts.guidance(request);

      expect(prompt.user, equals(request.toJson()));
      expect(
        (prompt.user['health'] as List).single,
        containsPair('localDate', '2026-07-27'),
      );
      // Identity is absent by construction, not by filtering.
      final encoded = jsonEncode(prompt.user).toLowerCase();
      for (final forbidden in [
        'name',
        'dob',
        'birth',
        'latitude',
        'longitude',
        'email',
        'userid',
      ]) {
        expect(encoded.contains(forbidden), isFalse, reason: forbidden);
      }
    });

    test('a vessel reading sends derived positions, never birth inputs', () {
      const request = VesselReadingRequest(
        mode: GuidanceMode.immersive,
        positions: [
          VesselReadingPosition(
            key: 'sun',
            label: 'Sun',
            card: 'The Emperor',
            keywords: ['authority', 'structure'],
            detail: 'Aries 22.3°',
          ),
        ],
        approximateTime: true,
        approximatePlace: false,
      );

      final prompt = EterPrompts.vesselReading(request);
      final encoded = jsonEncode(prompt.user);

      expect(encoded, contains('The Emperor'));
      expect(encoded, contains('birthTimeApproximate'));
      expect(encoded, isNot(contains('1994')));
      expect(prompt.user.containsKey('inputHash'), isFalse);
    });

    test('journal interpretation sends the page and nothing else', () {
      final prompt = EterPrompts.journalInterpretation(
        entryText: 'Soup for lunch, then a long walk.',
        clarification: 'A medium bowl.',
      );

      expect(prompt.user.keys, containsAll(['entry', 'clarification']));
      expect(prompt.user.keys, hasLength(2));
    });

    test('an empty clarification is omitted rather than sent blank', () {
      final prompt = EterPrompts.journalInterpretation(
        entryText: 'Soup for lunch.',
        clarification: '   ',
      );

      expect(prompt.user.keys, ['entry']);
    });
  });

  group('the register reaches the model', () {
    test('grounded forbids the symbolic register outright', () {
      final system = EterPrompts.guidance(
        buildRequest(mode: GuidanceMode.grounded),
      ).system;

      expect(system, contains('VOICE — GROUNDED'));
      expect(system, contains('no stars'));
      expect(system, isNot(contains('VOICE — IMMERSIVE')));
    });

    test('immersive keeps symbolism subordinate to the records', () {
      final system = EterPrompts.guidance(
        buildRequest(mode: GuidanceMode.immersive),
      ).system;

      expect(system, contains('VOICE — IMMERSIVE'));
      expect(system, contains('every recommendation rests on the records'));
    });

    test('every mode carries the safety and absence rules', () {
      for (final mode in GuidanceMode.values) {
        final system = EterPrompts.guidance(buildRequest(mode: mode)).system;
        expect(system, contains('SAFETY'), reason: mode.name);
        expect(system, contains('ABSENCE'), reason: mode.name);
        expect(system, contains('1200 kcal'), reason: mode.name);
      }
    });
  });

  test('the journal prompt is told when no prose was included', () {
    final withProse = EterPrompts.guidance(buildRequest()).system;
    final without = EterPrompts.guidance(
      buildRequest(journalConsented: false),
    ).system;

    expect(withProse, contains('journal passages'));
    expect(without, contains('No journal prose is included'));
    // Prose that never crossed the boundary cannot be described as available.
    expect(without, isNot(contains('in their own words')));
  });

  group('the response schema is the one the parser enforces', () {
    test('guidance schema names exactly the four dimensions', () {
      final schema = EterPrompts.guidance(buildRequest()).responseSchema;

      expect(
        (schema['required'] as List).toSet(),
        AetherGuidanceParser.dimensionKeys,
      );
      expect(schema['additionalProperties'], isFalse);

      final synthesis =
          (schema['properties'] as Map)['synthesis'] as Map<String, Object?>;
      final sentences =
          (synthesis['properties'] as Map)['sentences'] as Map<String, Object?>;
      expect(sentences['minItems'], 1);
      expect(sentences['maxItems'], 3);
    });

    test('journal schema allows only the six canonical lifestyle kinds', () {
      final schema = EterPrompts.journalInterpretation(
        entryText: 'anything',
      ).responseSchema;
      final lifestyle =
          (schema['properties'] as Map)['lifestyle'] as Map<String, Object?>;
      final item = lifestyle['items'] as Map<String, Object?>;
      final kind = (item['properties'] as Map)['kind'] as Map<String, Object?>;

      expect(
        (kind['enum'] as List).toSet(),
        {'mood', 'stress', 'recovery', 'sleep', 'meditation', 'breathwork'},
      );
    });

    test('journal schema bounds kcal exactly where the parser rejects', () {
      final schema = EterPrompts.journalInterpretation(
        entryText: 'anything',
      ).responseSchema;
      final food = (schema['properties'] as Map)['food'] as Map<String, Object?>;
      final item = food['items'] as Map<String, Object?>;
      final kcal = (item['properties'] as Map)['kcal'] as Map<String, Object?>;

      expect(kcal['exclusiveMinimum'], 0);
      expect(kcal['maximum'], 5000);
    });

    test('vessel schema bounds a passage where the composer does', () {
      const request = VesselReadingRequest(
        mode: GuidanceMode.balanced,
        positions: [
          VesselReadingPosition(
            key: 'moon',
            label: 'Moon',
            card: 'Death',
            keywords: ['threshold'],
          ),
        ],
        approximateTime: false,
        approximatePlace: false,
      );

      final schema = EterPrompts.vesselReading(request).responseSchema;
      final readings =
          (schema['properties'] as Map)['readings'] as Map<String, Object?>;
      final item = readings['items'] as Map<String, Object?>;
      final passage =
          (item['properties'] as Map)['passage'] as Map<String, Object?>;

      expect(passage['maxLength'], vesselReadingResponseSchema['maxPassageCharacters']);
    });
  });

  test('interpretation refuses to invent, and says so', () {
    final system = EterPrompts.journalInterpretation(
      entryText: 'A hard morning.',
    ).system;

    expect(system, contains('Anything they did not say'));
    expect(system, contains('better to ask than to'));
    // Weight, activity and strength are explicitly out of scope today; see
    // ROADMAP.md 1a, which tracks giving them a route in.
    expect(system, contains('Weight, workouts, steps or heart rate'));
  });
}
