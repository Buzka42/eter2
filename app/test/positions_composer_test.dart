import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/aether/guidance_mode.dart';
import 'package:eter/core/aether/safety_policy.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:eter/core/symbolic/transits.dart';
import 'package:eter/core/vessel/positions_composer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Positions is the one surface where arithmetic and prose meet: the contacts
/// are free and always present, the passage costs a provider call and is
/// therefore cached per day and per chart, and the single sentence that leaves
/// for guidance passes the same safety gate guidance itself does.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<void> profile({bool aiConsent = true}) =>
      database.saveProfile(ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'other',
        weightKg: 70,
        units: 'metric',
        aiConsentAt: Value(aiConsent ? DateTime.utc(2026, 7, 1) : null),
      ));

  const reading = TransitReading(
    forDate: '2026-07-28',
    sky: [
      ZodiacPosition(name: 'Sun', longitude: 125.4),
      ZodiacPosition(name: 'Moon', longitude: 12.2),
    ],
    contacts: [
      TransitContact(
        transiting: 'Saturn',
        natal: 'Sun',
        type: 'square',
        orb: 1.4,
        applying: true,
      ),
    ],
    moonPhase: 0.5,
  );

  final now = DateTime.utc(2026, 7, 28, 20);

  group('reading without composing', () {
    test('returns the contacts and never calls a provider', () async {
      await profile();
      final provider = _Provider();
      final result = await PositionsComposer(
        database: database,
        provider: provider,
      ).forDay(
        reading: reading,
        inputHash: 'chart',
        mode: GuidanceMode.balanced,
        ascendantReliable: true,
        now: now,
      );

      expect(provider.calls, 0);
      expect(result.passage, isNull);
      expect(result.fromCache, isFalse);
      expect(result.reading.contacts, hasLength(1));
      expect(await database.loadTransitReading(
        date: '2026-07-28',
        inputHash: 'chart',
      ), isNull);
    });
  });

  group('the cache', () {
    test('a second compose on the same day and chart costs nothing', () async {
      await profile();
      final provider = _Provider();
      final composer =
          PositionsComposer(database: database, provider: provider);

      final first = await composer.forDay(
        reading: reading,
        inputHash: 'chart',
        mode: GuidanceMode.balanced,
        ascendantReliable: true,
        now: now,
        compose: true,
      );
      final second = await composer.forDay(
        reading: reading,
        inputHash: 'chart',
        mode: GuidanceMode.balanced,
        ascendantReliable: true,
        now: now,
        compose: true,
      );

      expect(provider.calls, 1);
      expect(first.fromCache, isFalse);
      expect(second.fromCache, isTrue);
      expect(second.passage!.passage, first.passage!.passage);
    });

    test('a cached day is returned even when composing was not asked for',
        () async {
      await profile();
      final provider = _Provider();
      final composer =
          PositionsComposer(database: database, provider: provider);
      await composer.forDay(
        reading: reading,
        inputHash: 'chart',
        mode: GuidanceMode.balanced,
        ascendantReliable: true,
        now: now,
        compose: true,
      );

      final read = await composer.forDay(
        reading: reading,
        inputHash: 'chart',
        mode: GuidanceMode.balanced,
        ascendantReliable: true,
        now: now,
      );

      expect(provider.calls, 1);
      expect(read.fromCache, isTrue);
      expect(read.passage, isNotNull);
    });

    test('another chart is another reading', () async {
      await profile();
      final provider = _Provider();
      final composer =
          PositionsComposer(database: database, provider: provider);

      await composer.forDay(
        reading: reading,
        inputHash: 'chart',
        mode: GuidanceMode.balanced,
        ascendantReliable: true,
        now: now,
        compose: true,
      );
      await composer.forDay(
        reading: reading,
        inputHash: 'a-corrected-birth-time',
        mode: GuidanceMode.balanced,
        ascendantReliable: true,
        now: now,
        compose: true,
      );

      expect(provider.calls, 2);
    });

    test('another day is another reading', () async {
      await profile();
      final provider = _Provider();
      final composer =
          PositionsComposer(database: database, provider: provider);

      await composer.forDay(
        reading: reading,
        inputHash: 'chart',
        mode: GuidanceMode.balanced,
        ascendantReliable: true,
        now: now,
        compose: true,
      );
      await composer.forDay(
        reading: TransitReading(
          forDate: '2026-07-29',
          sky: reading.sky,
          contacts: reading.contacts,
          moonPhase: reading.moonPhase,
        ),
        inputHash: 'chart',
        mode: GuidanceMode.balanced,
        ascendantReliable: true,
        now: now,
        compose: true,
      );

      expect(provider.calls, 2);
    });

    test('an unreadable stored passage degrades to no passage, not a crash',
        () async {
      await profile();
      await database.saveTransitReading(TransitReadingsCompanion.insert(
        date: '2026-07-28',
        inputHash: 'chart',
        generatedAt: now,
        contactsJson: '{}',
        passage: 'not json',
      ));

      final result = await PositionsComposer(
        database: database,
        provider: _Provider(),
      ).forDay(
        reading: reading,
        inputHash: 'chart',
        mode: GuidanceMode.balanced,
        ascendantReliable: true,
        now: now,
        compose: true,
      );

      expect(result.fromCache, isTrue);
      expect(result.passage, isNull);
    });
  });

  group('gates', () {
    test('no transport says so, and writes nothing', () async {
      await profile();
      await expectLater(
        PositionsComposer(database: database, provider: null).forDay(
          reading: reading,
          inputHash: 'chart',
          mode: GuidanceMode.balanced,
          ascendantReliable: true,
          now: now,
          compose: true,
        ),
        throwsA(isA<PositionsException>()),
      );
      expect(
        await database.loadTransitReading(
            date: '2026-07-28', inputHash: 'chart'),
        isNull,
      );
    });

    test('no consent, no call', () async {
      await profile(aiConsent: false);
      final provider = _Provider();
      await expectLater(
        PositionsComposer(database: database, provider: provider).forDay(
          reading: reading,
          inputHash: 'chart',
          mode: GuidanceMode.balanced,
          ascendantReliable: true,
          now: now,
          compose: true,
        ),
        throwsA(isA<PositionsException>()),
      );
      expect(provider.calls, 0);
    });
  });

  group('the parser and the safety gate', () {
    Future<void> rejects(String raw, {GuidanceMode? mode}) async {
      await profile();
      await expectLater(
        PositionsComposer(
          database: database,
          provider: _Provider(raw: raw),
        ).forDay(
          reading: reading,
          inputHash: 'chart',
          mode: mode ?? GuidanceMode.balanced,
          ascendantReliable: true,
          now: now,
          compose: true,
        ),
        throwsA(anything),
        reason: raw,
      );
      expect(
        await database.loadTransitReading(
            date: '2026-07-28', inputHash: 'chart'),
        isNull,
        reason: raw,
      );
    }

    test('rejects malformed and unbounded responses', () async {
      await rejects('not json');
      await rejects('[]');
      await rejects(jsonEncode({'passage': 'A passage.'}));
      await rejects(jsonEncode({'passage': '  ', 'guidanceNote': 'Rest.'}));
      await rejects(jsonEncode({
        'passage': 'A' * 1201,
        'guidanceNote': 'Rest.',
      }));
      await rejects(jsonEncode({
        'passage': 'A passage.',
        'guidanceNote': 'x' * 141,
      }));
      await rejects(jsonEncode({'passage': 'A passage.', 'guidanceNote': ''}));
      await rejects(jsonEncode({'passage': 12, 'guidanceNote': 'Rest.'}));
    });

    test('an unsafe note never reaches the database', () async {
      await rejects(jsonEncode({
        'passage': 'Saturn squares your Sun.',
        'guidanceNote': 'Push through the pain today.',
      }));
    });

    test('fated phrasing is refused in grounded mode', () async {
      await rejects(
        jsonEncode({
          'passage': 'You are fated to repeat this.',
          'guidanceNote': 'Rest.',
        }),
        mode: GuidanceMode.grounded,
      );
    });

    test('the same phrasing is allowed in immersive mode', () async {
      await profile();
      final result = await PositionsComposer(
        database: database,
        provider: _Provider(
          raw: jsonEncode({
            'passage': 'You are fated to repeat this.',
            'guidanceNote': 'Rest.',
          }),
        ),
      ).forDay(
        reading: reading,
        inputHash: 'chart',
        mode: GuidanceMode.immersive,
        ascendantReliable: true,
        now: now,
        compose: true,
      );

      expect(result.passage!.guidanceNote, 'Rest.');
    });

    test('the safety policy is the injected one', () async {
      await profile();
      await expectLater(
        PositionsComposer(
          database: database,
          provider: _Provider(),
          safetyPolicy: const _RefusingPolicy(),
        ).forDay(
          reading: reading,
          inputHash: 'chart',
          mode: GuidanceMode.balanced,
          ascendantReliable: true,
          now: now,
          compose: true,
        ),
        throwsA(isA<AetherSafetyException>()),
      );
    });
  });

  group('what is sent and what is stored', () {
    test('the request carries derived positions only', () async {
      await profile();
      final provider = _Provider();
      await PositionsComposer(database: database, provider: provider).forDay(
        reading: reading,
        inputHash: 'a-private-chart-hash',
        mode: GuidanceMode.balanced,
        ascendantReliable: false,
        now: now,
        compose: true,
      );

      final sent = jsonEncode(provider.lastRequest!.context);
      expect(sent, isNot(contains('a-private-chart-hash')));
      expect(sent, isNot(contains('1990')));
      expect(provider.lastRequest!.responseSchema, isNotEmpty);
    });

    test('the stored row keeps the contacts, the passage and the model',
        () async {
      await profile();
      await PositionsComposer(
        database: database,
        provider: _Provider(),
        model: 'test-model',
      ).forDay(
        reading: reading,
        inputHash: 'chart',
        mode: GuidanceMode.balanced,
        ascendantReliable: true,
        now: now,
        compose: true,
      );

      final row = await database.loadTransitReading(
        date: '2026-07-28',
        inputHash: 'chart',
      );
      expect(row!.model, 'test-model');
      expect(row.generatedAt, now);
      expect(jsonDecode(row.contactsJson), isA<Map<String, Object?>>());
      expect(
        PositionsPassage.tryParseStored(row.passage)!.guidanceNote,
        isNotEmpty,
      );
    });

    test('a stored passage round-trips, and a foreign shape does not',
        () {
      const passage =
          PositionsPassage(passage: 'A passage.', guidanceNote: 'A note.');
      final again =
          PositionsPassage.tryParseStored(jsonEncode(passage.toJson()))!;
      expect(again.passage, passage.passage);
      expect(again.guidanceNote, passage.guidanceNote);
      expect(PositionsPassage.tryParseStored('{"passage":1}'), isNull);
      expect(PositionsPassage.tryParseStored('nonsense'), isNull);
    });
  });
}

class _Provider implements PositionsProvider {
  _Provider({this.raw});

  final String? raw;
  int calls = 0;
  PositionsProviderRequest? lastRequest;

  @override
  Future<String> compose(PositionsProviderRequest request) async {
    calls += 1;
    lastRequest = request;
    return raw ??
        jsonEncode({
          'passage': 'Saturn holds a square to your Sun this week.',
          'guidanceNote': 'Expect friction; take the slower route.',
        });
  }
}

class _RefusingPolicy extends AetherSafetyPolicy {
  const _RefusingPolicy();

  @override
  void validateGuidance({
    required List<String> sentences,
    required String primaryAction,
    GuidanceMode mode = GuidanceMode.balanced,
  }) =>
      throw const AetherSafetyException('refused');
}
