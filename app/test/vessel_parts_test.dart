import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/aether/guidance_mode.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/vessel/reading_composer.dart';
import 'package:flutter_test/flutter_test.dart';

/// The four parts of the Vessel that are not the chart's synopsis.
///
/// The reading used to be one call — three to five movements about the whole
/// configuration. It was good at that and could not be more: a chart, a
/// figure, twelve houses and the geometry between the bodies all competing for
/// the same five passages. Each part has its own call and its own cached row
/// now, so one failing is retried alone and the rest are not paid for twice.
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
        aiConsentAt: Value(DateTime.utc(2026, 8, 3)),
      ),
    );
  });
  tearDown(() => database.close());

  VesselReadingRequest request() => VesselReadingRequest(
        mode: GuidanceMode.balanced,
        approximateTime: false,
        approximatePlace: false,
        positions: const [
          VesselReadingPosition(
            key: 'given',
            label: 'Given',
            card: 'The Lovers',
            keywords: ['union'],
          ),
          VesselReadingPosition(
            key: 'centre',
            label: 'Centre',
            card: 'Strength',
            keywords: ['power'],
          ),
        ],
        houses: [
          for (var house = 1; house <= 12; house++)
            VesselReadingHouse(
              house: house,
              sign: 'Libra',
              degrees: '12.0',
              card: 'Justice',
              keywords: const ['balance'],
              isAscendant: house == 1,
            ),
        ],
      );

  List<String> houseKeys([int upTo = 12]) =>
      [for (var house = 1; house <= upTo; house++) house.toString()];

  test('a passage is kept for every house, and only for those', () async {
    final provider = _KeyedProvider(keys: houseKeys());
    final stored =
        await VesselReadingComposer(database: database, provider: provider)
            .composePart(
      inputHash: 'chart',
      request: request(),
      part: VesselReadingPart.houses,
    );
    final passages = VesselKeyedPassage.decode(stored);
    expect(passages, hasLength(12));
    expect(passages.map((one) => one.key).toSet(), houseKeys().toSet());
  });

  test('a house nobody sent is refused, and nothing is stored', () async {
    // A passage about house 13 is a passage about something invented.
    final provider = _KeyedProvider(keys: ['1', '13']);
    await expectLater(
      VesselReadingComposer(database: database, provider: provider).composePart(
        inputHash: 'chart',
        request: request(),
        part: VesselReadingPart.houses,
      ),
      throwsA(isA<VesselReadingException>()),
    );
    expect(
      await database.loadVesselReading(
        inputHash: 'chart',
        positionKey: VesselReadingPart.houses.storageKey,
      ),
      isNull,
    );
  });

  test('a missing house is refused: twelve means twelve', () async {
    final provider = _KeyedProvider(keys: houseKeys(11));
    await expectLater(
      VesselReadingComposer(database: database, provider: provider).composePart(
        inputHash: 'chart',
        request: request(),
        part: VesselReadingPart.houses,
      ),
      throwsA(isA<VesselReadingException>()),
    );
  });

  test('the same house written twice is refused', () async {
    final provider = _KeyedProvider(keys: [...houseKeys(11), '11']);
    await expectLater(
      VesselReadingComposer(database: database, provider: provider).composePart(
        inputHash: 'chart',
        request: request(),
        part: VesselReadingPart.houses,
      ),
      throwsA(isA<VesselReadingException>()),
    );
  });

  test('a written part is never composed again', () async {
    final provider = _KeyedProvider(keys: houseKeys());
    final composer =
        VesselReadingComposer(database: database, provider: provider);
    await composer.composePart(
      inputHash: 'chart',
      request: request(),
      part: VesselReadingPart.houses,
    );
    await composer.composePart(
      inputHash: 'chart',
      request: request(),
      part: VesselReadingPart.houses,
    );
    expect(provider.calls, 1);
  });

  test('the figure is a different row, so it costs its own call', () async {
    await VesselReadingComposer(
      database: database,
      provider: _KeyedProvider(keys: houseKeys()),
    ).composePart(
      inputHash: 'chart',
      request: request(),
      part: VesselReadingPart.houses,
    );
    final figure = _KeyedProvider(keys: const ['given', 'centre']);
    await VesselReadingComposer(database: database, provider: figure)
        .composePart(
      inputHash: 'chart',
      request: request(),
      part: VesselReadingPart.matrix,
    );
    expect(figure.calls, 1);
    for (final part in [
      VesselReadingPart.houses,
      VesselReadingPart.matrix,
    ]) {
      expect(
        await database.loadVesselReading(
          inputHash: 'chart',
          positionKey: part.storageKey,
        ),
        isNotNull,
        reason: part.name,
      );
    }
  });

  test('the figure refuses a place that was never sent', () async {
    final provider = _KeyedProvider(keys: const ['given', 'invented']);
    await expectLater(
      VesselReadingComposer(database: database, provider: provider).composePart(
        inputHash: 'chart',
        request: request(),
        part: VesselReadingPart.matrix,
      ),
      throwsA(isA<VesselReadingException>()),
    );
  });

  /// Prose of a given length. A run of one repeated character is refused by
  /// the safety policy, and rightly — it is not writing.
  String longProse(int characters) {
    const sentence =
        'This figure keeps returning to the same question of balance. ';
    final buffer = StringBuffer();
    while (buffer.length < characters) {
      buffer.write(sentence);
    }
    return buffer.toString().substring(0, characters);
  }

  test('the synopsis of the figure is one passage, and may be long', () async {
    final provider =
        _SynopsisProvider(longProse(vesselMaximumSynopsisCharacters));
    final stored =
        await VesselReadingComposer(database: database, provider: provider)
            .composePart(
      inputHash: 'chart',
      request: request(),
      part: VesselReadingPart.matrixSynopsis,
    );
    expect(
      VesselSynopsis.decode(stored),
      hasLength(vesselMaximumSynopsisCharacters),
    );
  });

  test('a synopsis past the ceiling is refused', () async {
    final provider =
        _SynopsisProvider(longProse(vesselMaximumSynopsisCharacters + 1));
    await expectLater(
      VesselReadingComposer(database: database, provider: provider).composePart(
        inputHash: 'chart',
        request: request(),
        part: VesselReadingPart.matrixSynopsis,
      ),
      throwsA(isA<VesselReadingException>()),
    );
  });

  test('an unsafe passage is refused, whichever part it is in', () async {
    final provider = _SynopsisProvider(
      'This configuration says you should stop taking your medication.',
    );
    await expectLater(
      VesselReadingComposer(database: database, provider: provider).composePart(
        inputHash: 'chart',
        request: request(),
        part: VesselReadingPart.matrixSynopsis,
      ),
      throwsA(isA<VesselReadingException>()),
    );
  });

  test('nothing composes without current AI consent', () async {
    // A fresh database, because consent is re-read and never cached: writing a
    // second profile row would leave the first one's consent standing.
    final withoutConsent = AppDatabase(NativeDatabase.memory());
    addTearDown(withoutConsent.close);
    await withoutConsent.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'other',
        weightKg: 70,
        units: 'metric',
      ),
    );
    final provider = _KeyedProvider(keys: houseKeys());
    await expectLater(
      VesselReadingComposer(database: withoutConsent, provider: provider)
          .composePart(
        inputHash: 'chart',
        request: request(),
        part: VesselReadingPart.houses,
      ),
      throwsA(isA<VesselReadingException>()),
    );
    expect(provider.calls, 0);
  });

  test('the chart synopsis will not be composed by this path', () async {
    // It is the one part that already existed and is already proven against
    // the live model, and its shape — titled movements — is not shared.
    await expectLater(
      VesselReadingComposer(
        database: database,
        provider: _KeyedProvider(keys: const []),
      ).composePart(
        inputHash: 'chart',
        request: request(),
        part: VesselReadingPart.chartSynopsis,
      ),
      throwsA(isA<VesselReadingException>()),
    );
  });

  test('every part has a key of its own, and the synopsis keeps the old one',
      () {
    final keys =
        VesselReadingPart.values.map((part) => part.storageKey).toList();
    expect(keys.toSet(), hasLength(keys.length));
    // Charts read before the split are not re-composed and not re-billed.
    expect(VesselReadingPart.chartSynopsis.storageKey, vesselConfigurationKey);
  });

  test('the request carries houses and aspects only when it has them', () {
    expect(request().toJson()['houses'], hasLength(12));
    const bare = VesselReadingRequest(
      mode: GuidanceMode.balanced,
      approximateTime: true,
      approximatePlace: false,
      positions: [],
    );
    // Without reliable angles there are no houses to read, and the key is
    // absent rather than an empty list pretending the question was asked.
    expect(bare.toJson().containsKey('houses'), isFalse);
    expect(bare.toJson().containsKey('aspects'), isFalse);
  });
}

class _KeyedProvider implements VesselReadingProvider {
  _KeyedProvider({required this.keys});

  final List<String> keys;
  int calls = 0;

  @override
  Future<String> compose(VesselReadingProviderRequest request) async {
    calls++;
    return jsonEncode({
      'passages': [
        for (final key in keys)
          {'key': key, 'passage': 'A reflective passage about $key.'},
      ],
    });
  }
}

class _SynopsisProvider implements VesselReadingProvider {
  _SynopsisProvider(this.passage);

  final String passage;
  int calls = 0;

  @override
  Future<String> compose(VesselReadingProviderRequest request) async {
    calls++;
    return jsonEncode({'passage': passage});
  }
}
