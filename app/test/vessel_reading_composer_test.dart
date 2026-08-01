import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/aether/guidance_mode.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/vessel/reading_composer.dart';
import 'package:flutter_test/flutter_test.dart';

/// The chart's reading: one call per chart, about the configuration.
///
/// It used to be one passage per position, composed a few at a time and cached
/// per position. What it wrote was correct and generic — eighteen entries that
/// had each seen one placement and never the chart — so the call now returns
/// movements about how placements stand to each other, and the whole reading
/// is one cached artifact.
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

  test('composes once per chart, and carries no identity or raw birth input',
      () async {
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

    // A chart is paid for once. This is the assertion that matters most here:
    // the reading is fixed for life, so a second call is pure cost.
    expect(provider.calls, 1);
    expect(first.movements, hasLength(3));
    expect(first.fromCache, isFalse);
    expect(second.fromCache, isTrue);
    expect(second.movements, hasLength(3));

    final encoded = jsonEncode(provider.lastRequest!.context);
    expect(encoded, isNot(contains('Private name')));
    expect(encoded, isNot(contains('Private place')));
    expect(encoded, isNot(contains('1990')));
    expect(encoded, isNot(contains('local-only-hash')));
    // The whole configuration goes in one request; that is the point.
    final positions =
        provider.lastRequest!.context['positions'] as List<Object?>;
    expect(positions, hasLength(4));
  });

  test('the reading is stored under one reserved key', () async {
    await VesselReadingComposer(database: database, provider: _Provider())
        .compose(inputHash: 'chart', request: _request());

    final row = await database.loadVesselReading(
      inputHash: 'chart',
      positionKey: vesselConfigurationKey,
    );
    expect(row, isNotNull);
    expect(VesselConfiguration.decode(row!.contentJson), hasLength(3));
    // And nothing is written per position any more.
    expect(
      await database.loadVesselReading(
        inputHash: 'chart',
        positionKey: 'sun',
      ),
      isNull,
    );
  });

  test('composing clears the per-position passages it replaced', () async {
    // A chart composed by an older build. Those rows are never read again, but
    // they are still exported and still synced, so they go.
    for (final key in const ['lifePath', 'sun', 'moon']) {
      await database.saveVesselReading(
        VesselReadingsCompanion.insert(
          inputHash: 'chart',
          positionKey: key,
          createdAt: DateTime.utc(2026, 7, 27),
          contentJson: '{"passage":"An older, lonelier passage."}',
          model: 'old',
        ),
      );
    }
    // Another chart's rows are not this call's business.
    await database.saveVesselReading(
      VesselReadingsCompanion.insert(
        inputHash: 'someone-elses-chart',
        positionKey: 'sun',
        createdAt: DateTime.utc(2026, 7, 27),
        contentJson: '{"passage":"Left alone."}',
        model: 'old',
      ),
    );

    await VesselReadingComposer(database: database, provider: _Provider())
        .compose(inputHash: 'chart', request: _request());

    for (final key in const ['lifePath', 'sun', 'moon']) {
      expect(
        await database.loadVesselReading(inputHash: 'chart', positionKey: key),
        isNull,
        reason: '$key survived the rewrite',
      );
    }
    expect(
      await database.loadVesselReading(
        inputHash: 'someone-elses-chart',
        positionKey: 'sun',
      ),
      isNotNull,
    );
  });

  test('too few movements is refused, and writes nothing', () async {
    final provider = _Provider(movements: 2);

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
        positionKey: vesselConfigurationKey,
      ),
      isNull,
    );
  });

  test('too many movements is refused', () async {
    await expectLater(
      VesselReadingComposer(
        database: database,
        provider: _Provider(movements: 6),
      ).compose(inputHash: 'chart', request: _request()),
      throwsA(isA<VesselReadingException>()),
    );
  });

  test('movements that repeat a title are refused', () async {
    // A model that has run out of things to say says the same thing twice, and
    // two movements under one name is what that looks like from here.
    await expectLater(
      VesselReadingComposer(
        database: database,
        provider: _Provider(sameTitle: true),
      ).compose(inputHash: 'chart', request: _request()),
      throwsA(isA<VesselReadingException>()),
    );
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

  test('an unsafe movement writes nothing at all', () async {
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
        positionKey: vesselConfigurationKey,
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
    this.movements = 3,
    this.sameTitle = false,
    this.passage = 'A personal but non-directive reflection.',
  });

  final int movements;
  final bool sameTitle;
  final String passage;
  int calls = 0;
  VesselReadingProviderRequest? lastRequest;

  @override
  Future<String> compose(VesselReadingProviderRequest request) async {
    calls += 1;
    lastRequest = request;
    return jsonEncode({
      'movements': [
        for (var i = 0; i < movements; i++)
          {
            'title': sameTitle ? 'The same shape' : 'Movement $i',
            'passage': passage,
          },
      ],
    });
  }
}
