import 'dart:convert';

import 'package:eter/core/aether/guidance_contract.dart';
import 'package:eter/core/aether/guidance_mode.dart';
import 'package:eter/core/aether/request_contract.dart';
import 'package:eter/core/aether/safety_policy.dart';
import 'package:eter/core/aether/composer.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Aether request boundary', () {
    const builder = AetherRequestBuilder(
      maxJournalEntries: 2,
      maxJournalCharacters: 12,
    );

    test('requires AI consent', () {
      expect(
        () => builder.build(
          aiConsented: false,
          journalConsented: false,
          ageYears: 30,
          mode: GuidanceMode.balanced,
          health: const [],
        ),
        throwsA(isA<AetherConsentException>()),
      );
    });

    test('journal needs separate consent and excluded prose never leaves', () {
      final entries = [
        AetherJournalContext(
          createdAt: DateTime.utc(2026, 7, 28),
          text: 'private words',
          excludedFromAi: true,
        ),
        AetherJournalContext(
          createdAt: DateTime.utc(2026, 7, 27),
          text: 'allowed journal text',
        ),
      ];
      final withoutJournal = builder.build(
        aiConsented: true,
        journalConsented: false,
        ageYears: 30,
        mode: GuidanceMode.grounded,
        health: const [],
        journal: entries,
      );
      expect(withoutJournal.journal, isEmpty);

      final withJournal = builder.build(
        aiConsented: true,
        journalConsented: true,
        ageYears: 30,
        mode: GuidanceMode.grounded,
        health: const [],
        journal: entries,
      );
      expect(withJournal.journal.single['text'], 'allowed jour');
      expect(jsonEncode(withJournal.toJson()), isNot(contains('private')));
    });

    test('payload has no identity fields and fingerprint is deterministic', () {
      AetherRequest make() => builder.build(
            aiConsented: true,
            journalConsented: false,
            ageYears: 30,
            mode: GuidanceMode.balanced,
            health: const [AetherHealthContext(localDate: '2026-07-28')],
          );
      final json = make().toJson();
      expect(json.keys, isNot(containsAll(['name', 'uid', 'dob', 'location'])));
      expect(make().contextFingerprint, make().contextFingerprint);
    });
  });

  group('Aether response boundary', () {
    const parser = AetherGuidanceParser();

    String response({String action = 'Take a short walk.'}) => jsonEncode({
          for (final key in AetherGuidanceParser.dimensionKeys)
            key: {
              'sentences': ['A quiet observation.'],
              'primaryAction': action,
            },
        });

    test('accepts exact schema', () {
      final result = parser.parse(
        response(),
        mode: GuidanceMode.balanced,
      );
      expect(result.dimensions.map((item) => item.key).toSet(),
          AetherGuidanceParser.dimensionKeys);
    });

    test('rejects missing or extra dimensions', () {
      expect(
        () => parser.parse('{}', mode: GuidanceMode.balanced),
        throwsA(isA<AetherContractException>()),
      );
    });

    test('rejects unsafe guidance before persistence', () {
      expect(
        () => parser.parse(
          response(action: 'Stop taking your medication.'),
          mode: GuidanceMode.balanced,
        ),
        throwsA(isA<AetherSafetyException>()),
      );
    });
  });

  group('Aether composition', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    AetherRequest request() => const AetherRequestBuilder().build(
          aiConsented: true,
          journalConsented: false,
          ageYears: 30,
          mode: GuidanceMode.balanced,
          health: const [AetherHealthContext(localDate: '2026-07-28')],
        );

    test('persists one complete set and reuses it for unchanged context',
        () async {
      final provider = _FakeProvider(_validResponse());
      final composer = AetherComposer(database: database, provider: provider);

      final first = await composer.compose(request());
      final second = await composer.compose(request());

      expect(first.rows, hasLength(4));
      expect(first.fromCache, isFalse);
      expect(second.fromCache, isTrue);
      expect(provider.calls, 1);
      expect(await database.loadGuidanceForDate('2026-07-28'), hasLength(4));
    });

    test('unsafe output writes no partial guidance', () async {
      final composer = AetherComposer(
        database: database,
        provider: _FakeProvider(
          _validResponse(action: 'Stop taking your medication.'),
        ),
      );

      await expectLater(
        composer.compose(request()),
        throwsA(isA<AetherSafetyException>()),
      );
      expect(await database.loadGuidanceForDate('2026-07-28'), isEmpty);
    });

    test('an empty-health composition uses the caller day', () async {
      final emptyHealth = const AetherRequestBuilder().build(
        aiConsented: true,
        journalConsented: false,
        ageYears: 35,
        mode: GuidanceMode.balanced,
        health: const [],
      );
      final composer = AetherComposer(
        database: database,
        provider: _FakeProvider(_validResponse()),
      );

      await composer.compose(
        emptyHealth,
        now: DateTime(2026, 7, 28, 10),
      );

      expect(await database.loadGuidanceForDate('2026-07-28'), hasLength(4));
    });
  });
}

String _validResponse({String action = 'Take a short walk.'}) => jsonEncode({
      for (final key in AetherGuidanceParser.dimensionKeys)
        key: {
          'sentences': ['A quiet observation.'],
          'primaryAction': action,
        },
    });

class _FakeProvider implements AetherProvider {
  _FakeProvider(this.response);
  final String response;
  int calls = 0;

  @override
  Future<String> compose(AetherProviderRequest request) async {
    calls += 1;
    return response;
  }
}
