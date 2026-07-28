import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:eter/core/aether/guidance_mode.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/vessel/reading_composer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'other',
        weightKg: 70,
        units: 'metric',
        firstName: const Value('Private name'),
        birthPlace: const Value('Private place'),
        aiConsentAt: Value(DateTime.utc(2026, 7, 28)),
      ),
    );
  });
  tearDown(() => database.close());

  test('composes only missing positions without raw birth inputs or identity',
      () async {
    await database.saveVesselReading(
      VesselReadingsCompanion.insert(
        inputHash: 'local-only-hash',
        positionKey: 'lifePath',
        createdAt: DateTime.utc(2026, 7, 27),
        contentJson: '{"passage":"Already here."}',
        model: 'old',
      ),
    );
    final provider = _Provider();
    final composer = VesselReadingComposer(
      database: database,
      provider: provider,
      model: 'test',
    );

    final first = await composer.compose(
      inputHash: 'local-only-hash',
      request: _request(),
      now: DateTime.utc(2026, 7, 28),
    );
    final second = await composer.compose(
      inputHash: 'local-only-hash',
      request: _request(),
      now: DateTime.utc(2026, 7, 28),
    );

    expect(provider.calls, 1);
    expect(first.rows, hasLength(4));
    expect(second.fromCache, isTrue);
    final encoded = jsonEncode(provider.lastRequest!.context);
    expect(encoded, isNot(contains('Private name')));
    expect(encoded, isNot(contains('Private place')));
    expect(encoded, isNot(contains('1990')));
    expect(encoded, isNot(contains('local-only-hash')));
    final positions =
        provider.lastRequest!.context['positions'] as List<Object?>;
    expect(positions, hasLength(3));
    expect(
      positions.map((item) => (item as Map<String, Object>)['key']),
      isNot(contains('lifePath')),
    );
  });

  test('malformed partial response writes none of the missing set', () async {
    final provider = _Provider(omitLast: true);
    final composer =
        VesselReadingComposer(database: database, provider: provider);

    await expectLater(
      composer.compose(
        inputHash: 'chart',
        request: _request(),
      ),
      throwsA(isA<VesselReadingException>()),
    );

    for (final position in _request().positions) {
      expect(
        await database.loadVesselReading(
          inputHash: 'chart',
          positionKey: position.key,
        ),
        isNull,
      );
    }
  });

  test('requires current AI consent before calling a provider', () async {
    await database.updateProfileConsents(aiAllowed: false);
    final provider = _Provider();

    await expectLater(
      VesselReadingComposer(database: database, provider: provider).compose(
        inputHash: 'chart',
        request: _request(),
      ),
      throwsA(isA<VesselReadingException>()),
    );
    expect(provider.calls, 0);
  });

  test('unsafe reading writes no partial set', () async {
    final provider = _Provider(
      passage: 'You must consult Aether before making this decision.',
    );

    await expectLater(
      VesselReadingComposer(database: database, provider: provider).compose(
        inputHash: 'chart',
        request: _request(),
      ),
      throwsA(isA<VesselReadingException>()),
    );
    expect(
      await database.loadVesselReading(
        inputHash: 'chart',
        positionKey: 'lifePath',
      ),
      isNull,
    );
  });
}

VesselReadingRequest _request() => const VesselReadingRequest(
      mode: GuidanceMode.balanced,
      approximateTime: true,
      approximatePlace: false,
      positions: [
        VesselReadingPosition(
          key: 'lifePath',
          label: 'Life Path 8',
          card: 'Strength',
          keywords: ['power', 'courage', 'action'],
        ),
        VesselReadingPosition(
          key: 'sun',
          label: 'Sun',
          card: 'The Hermit',
          keywords: ['reflection', 'wisdom', 'solitude'],
        ),
        VesselReadingPosition(
          key: 'moon',
          label: 'Moon',
          card: 'The Star',
          keywords: ['hope', 'renewal', 'clarity'],
        ),
        VesselReadingPosition(
          key: 'ascendant',
          label: 'Ascendant',
          card: 'Justice',
          keywords: ['balance', 'truth', 'measure'],
        ),
      ],
    );

class _Provider implements VesselReadingProvider {
  _Provider({
    this.omitLast = false,
    this.passage = 'A personal but non-directive reflection.',
  });

  final bool omitLast;
  final String passage;
  int calls = 0;
  VesselReadingProviderRequest? lastRequest;

  @override
  Future<String> compose(VesselReadingProviderRequest request) async {
    calls += 1;
    lastRequest = request;
    final positions = request.context['positions'] as List<Object?>;
    final included =
        omitLast ? positions.take(positions.length - 1) : positions;
    return jsonEncode({
      'readings': [
        for (final raw in included)
          {
            'key': (raw as Map<String, Object>)['key'],
            'passage': passage,
          },
      ],
    });
  }
}
