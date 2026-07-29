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
    test('guidance schema names the four dimensions and the note', () {
      final schema = EterPrompts.guidance(buildRequest()).responseSchema;

      expect(
        (schema['required'] as List).toSet(),
        {
          ...AetherGuidanceParser.dimensionKeys,
          AetherGuidanceParser.recallKey,
        },
      );
      expect(schema['additionalProperties'], isFalse);

      // The note is a string with the ceiling the instruction states, not a
      // fifth dimension.
      final recall = (schema['properties'] as Map)[
          AetherGuidanceParser.recallKey] as Map<String, Object?>;
      expect(recall['type'], 'string');
      expect(recall['maxLength'], AetherGuidanceParser.maxRecallCharacters);

      final synthesis =
          (schema['properties'] as Map)['synthesis'] as Map<String, Object?>;
      final sentences =
          (synthesis['properties'] as Map)['sentences'] as Map<String, Object?>;
      expect(sentences['minItems'], 1);
      expect(sentences['maxItems'], 3);
    });

    test('journal schema allows exactly the lifestyle kinds the parser takes',
        () {
      final schema = EterPrompts.journalInterpretation(
        entryText: 'anything',
      ).responseSchema;
      final lifestyle =
          (schema['properties'] as Map)['lifestyle'] as Map<String, Object?>;
      final item = lifestyle['items'] as Map<String, Object?>;
      final kind = (item['properties'] as Map)['kind'] as Map<String, Object?>;

      // The wider vocabulary a page can report: felt states, connection,
      // meaning, and whatever the person is carrying. The margin's check-in
      // still offers only three readings and two practices — this is what
      // prose is allowed to say, and the two are not the same list.
      expect(
        (kind['enum'] as List).toSet(),
        {
          'mood',
          'stress',
          'recovery',
          'energy',
          'focus',
          'motivation',
          'social',
          'spirit',
          'carrying',
          'sleep',
          'meditation',
          'breathwork',
        },
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
    // Steps and heart rate come from a device and are still out of scope.
    // Weight, activity and strength are in scope now, and each carries the
    // rule that keeps it honest.
    expect(system, contains('Steps or heart rate'));
    expect(system, contains('Never a guess and never a feeling'));
    expect(system, contains('Do not estimate the energy'));
  });

  test('interpretation asks for the fields the parser requires', () {
    final schema = EterPrompts.journalInterpretation(
      entryText: 'Squatted 100 for five, twice.',
    ).responseSchema;
    final properties = schema['properties'] as Map<String, Object?>;

    for (final field in ['weight', 'activity', 'strength']) {
      expect(properties[field], isNotNull, reason: field);
    }
    final activity = ((properties['activity'] as Map)['items'] as Map);
    expect(
      activity['required'],
      containsAll(<String>['activity', 'durationMinutes', 'kcal']),
    );
    // The energy of lifted work is derived on the device, so the model is
    // never asked for it.
    final strength = ((properties['strength'] as Map)['items'] as Map);
    expect(
      (strength['properties'] as Map).keys,
      isNot(contains('kcal')),
    );
  });
  group('what a reading is drawn from', () {
    AetherRequest requestFor(GuidanceMode mode, {bool journal = true}) =>
        const AetherRequestBuilder().build(
          aiConsented: true,
          journalConsented: journal,
          ageYears: 30,
          mode: mode,
          health: const [AetherHealthContext(localDate: '2026-07-27')],
          digests: journal
              ? const [
                  AetherJournalDigest(
                    localDate: '2026-07-27',
                    points: {'mood': 'flat'},
                  ),
                ]
              : const [],
        );

    test('three shares, and the journal has the largest', () {
      for (final mode in GuidanceMode.values) {
        final weights = EterPrompts.weightsFor(mode);
        expect(
          weights.journal + weights.symbolic + weights.measured,
          100,
          reason: '${mode.name} must add up',
        );
        expect(
          weights.journal,
          greaterThanOrEqualTo(weights.symbolic),
          reason: 'what someone wrote is never the smaller voice',
        );
      }

      expect(
        EterPrompts.weightsFor(GuidanceMode.balanced),
        (journal: 50, symbolic: 25, measured: 25),
      );
      expect(
        EterPrompts.weightsFor(GuidanceMode.grounded),
        (journal: 40, symbolic: 20, measured: 40),
      );
      expect(
        EterPrompts.weightsFor(GuidanceMode.immersive),
        (journal: 40, symbolic: 40, measured: 20),
      );
    });

    test('the proportions reach the instruction', () {
      final system = EterPrompts.guidance(requestFor(GuidanceMode.balanced)).system;
      expect(system, contains('50% from what the person wrote'));
      expect(system, contains('25% from the symbolic context'));
      expect(system, contains('25% from the measured records'));
    });

    test('with no journal material the share is redistributed, not left open',
        () {
      final system =
          EterPrompts.guidance(requestFor(GuidanceMode.balanced, journal: false))
              .system;
      // Naming a 50% share of something absent invites the model to fill it.
      expect(system, contains('no journal material'));
      expect(system, isNot(contains('50% from what the person wrote')));
      expect(
        EterPrompts.weightsWithoutJournal(GuidanceMode.balanced),
        (symbolic: 50, measured: 50),
      );
      expect(
        EterPrompts.weightsWithoutJournal(GuidanceMode.immersive),
        (symbolic: 67, measured: 33),
      );
    });

    test('absence is stated in all five instructions, not just guidance', () {
      const marker = 'Missing data is information';
      expect(EterPrompts.guidance(requestFor(GuidanceMode.balanced)).system,
          contains(marker));
      expect(
        EterPrompts.journalDayStory(date: '2026-07-27', entries: const [])
            .system,
        contains(marker),
      );
      expect(
        EterPrompts.journalInterpretation(entryText: 'anything').system,
        contains(marker),
      );
      expect(
        EterPrompts.positions(
          mode: GuidanceMode.balanced,
          transits: const {},
          ascendantReliable: true,
        ).system,
        contains(marker),
      );
      expect(
        EterPrompts.vesselReading(const VesselReadingRequest(
          mode: GuidanceMode.balanced,
          positions: [
            VesselReadingPosition(
              key: 'sun',
              label: 'Sun',
              card: 'Strength',
              keywords: ['courage'],
            ),
          ],
          approximateTime: false,
          approximatePlace: false,
        )).system,
        contains(marker),
      );
    });

    test('the deficit rule is gone and the floor is not', () {
      final system = EterPrompts.guidance(requestFor(GuidanceMode.balanced)).system;
      // Someone choosing to lose weight is not someone to be talked out of it.
      expect(system, isNot(contains('under-eating')));
      expect(system, contains('Never recommend eating under 1200 kcal'));
      expect(system, contains('never frame food as punishment'));
    });
  });

}
