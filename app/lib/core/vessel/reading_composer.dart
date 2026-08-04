import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../aether/guidance_mode.dart';
import '../aether/safety_policy.dart';
import '../ai/prompts.dart';
import '../db/app_database.dart';
import '../i18n/language.dart';

class VesselReadingException implements Exception {
  const VesselReadingException(this.reason);
  final String reason;
}

class VesselReadingPosition {
  const VesselReadingPosition({
    required this.key,
    required this.label,
    required this.card,
    required this.keywords,
    this.detail,
  });

  final String key;
  final String label;
  final String card;
  final List<String> keywords;
  final String? detail;

  Map<String, Object> toJson() => {
        'key': key,
        'label': label,
        'card': card,
        'keywords': keywords,
        if (detail != null) 'detail': detail!,
      };
}

/// One of the twelve houses, as the reading is given it.
class VesselReadingHouse {
  const VesselReadingHouse({
    required this.house,
    required this.sign,
    required this.degrees,
    required this.card,
    required this.keywords,
    this.isAscendant = false,
    this.occupants = const [],
  });

  final int house;
  final String sign;
  final String degrees;
  final String card;
  final List<String> keywords;

  /// True for the first house only. The reading is told rather than left to
  /// notice, because the Ascendant's card is shown above the list and this is
  /// the same point rather than a second one.
  final bool isAscendant;

  /// The bodies standing in this house, if any. An empty house is empty, and
  /// saying so is information — absent, never zero.
  final List<String> occupants;

  Map<String, Object> toJson() => {
        'house': house,
        'sign': sign,
        'degrees': degrees,
        'card': card,
        'keywords': keywords,
        if (isAscendant) 'isAscendant': true,
        'occupants': occupants,
      };
}

/// One angle between two bodies.
class VesselReadingAspect {
  const VesselReadingAspect({
    required this.first,
    required this.second,
    required this.type,
    required this.orb,
  });

  final String first;
  final String second;
  final String type;
  final double orb;

  Map<String, Object> toJson() => {
        'first': first,
        'second': second,
        'type': type,
        'orb': double.parse(orb.toStringAsFixed(2)),
      };
}

class VesselReadingRequest {
  const VesselReadingRequest({
    required this.mode,
    required this.positions,
    required this.approximateTime,
    required this.approximatePlace,
    this.houses = const [],
    this.aspects = const [],
  });

  final GuidanceMode mode;
  final List<VesselReadingPosition> positions;
  final bool approximateTime;
  final bool approximatePlace;

  /// The twelve houses. Empty when the birth time cannot support them, in
  /// which case the houses part is not composed at all rather than composed
  /// about cusps nobody gave.
  final List<VesselReadingHouse> houses;

  /// The chart's angles, already measured on the device.
  final List<VesselReadingAspect> aspects;

  /// Cards that hold more than one position, and which positions they hold.
  ///
  /// Computed here rather than left to the model to spot. A card recurring is
  /// the strongest thing a spread can say — it is the difference between a list
  /// of eleven positions and a configuration that keeps returning to something —
  /// and "the model will probably notice" is not a guarantee. Everything else
  /// in this request is calculated on the device and handed over as fact; this
  /// is no different.
  ///
  /// It also answers the thing that reads as a bug on screen. Two positions can
  /// legitimately resolve to one card — a birth on the 25th reduces to 7 and a
  /// birth in July is 7 already — and the surface then draws the same plate
  /// twice with the same keywords, one under the other, looking like a repeat
  /// that nobody meant. Naming the coincidence in the writing is what makes it
  /// read as a finding instead.
  ///
  /// Ordered by the position list rather than by card name, so the same chart
  /// always produces the same request and the cache key stays stable.
  ///
  /// **Labels only, never keys.** It carried both until 4 August, and the first
  /// live figure synopsis wrote "The Moon across the sun, the era, and mercury"
  /// — internal identifiers, lowercased, one of them (`era`) a word that means
  /// nothing at all to a reader. A field the answer must not quote is a field
  /// the request should not contain: the labels say the same thing and are
  /// already in the reader's own language.
  List<Map<String, Object>> get recurrences {
    final byCard = <String, List<VesselReadingPosition>>{};
    for (final position in positions) {
      byCard.putIfAbsent(position.card, () => []).add(position);
    }
    return [
      for (final entry in byCard.entries)
        if (entry.value.length > 1)
          {
            'card': entry.key,
            'positions': [for (final item in entry.value) item.label],
          },
    ];
  }

  Map<String, Object> toJson() => {
        'mode': mode.name,
        'positions': positions.map((item) => item.toJson()).toList(),
        'recurrences': recurrences,
        if (houses.isNotEmpty)
          'houses': houses.map((item) => item.toJson()).toList(),
        if (aspects.isNotEmpty)
          'aspects': aspects.map((item) => item.toJson()).toList(),
        'reliability': {
          'birthTimeApproximate': approximateTime,
          'birthPlaceApproximate': approximatePlace,
          'ascendantReliable': !approximateTime && !approximatePlace,
        },
      };
}

abstract interface class VesselReadingProvider {
  Future<String> compose(VesselReadingProviderRequest request);
}

class VesselReadingProviderRequest {
  const VesselReadingProviderRequest({
    required this.system,
    required this.context,
    required this.responseSchema,
  });

  /// Built on the device by `EterPrompts.vesselReading`, for the reason given
  /// on [AetherProviderRequest.system].
  final String system;

  final Map<String, Object> context;
  final Map<String, Object> responseSchema;
}

/// One movement of the reading: a titled passage about how several placements
/// stand to each other.
///
/// Never one per card. The reading used to be exactly that — eighteen passages,
/// each about a single position with the rest of the chart out of view — and it
/// read as eighteen encyclopaedia entries about a stranger. A chart means
/// something as a configuration or it means very little.
class VesselMovement {
  const VesselMovement({required this.title, required this.passage});

  final String title;
  final String passage;

  Map<String, Object> toJson() => {'title': title, 'passage': passage};

  static VesselMovement? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final title = raw['title'];
    final passage = raw['passage'];
    if (title is! String || passage is! String) return null;
    return VesselMovement(title: title, passage: passage);
  }
}

/// The whole chart, read as one thing.
class VesselConfiguration {
  const VesselConfiguration({
    required this.movements,
    required this.fromCache,
  });

  final List<VesselMovement> movements;
  final bool fromCache;

  static List<VesselMovement> decode(String contentJson) {
    try {
      final decoded = jsonDecode(contentJson);
      if (decoded is! Map || decoded['movements'] is! List) return const [];
      return [
        for (final item in decoded['movements'] as List)
          if (VesselMovement.fromJson(item) case final movement?) movement,
      ];
    } on FormatException {
      return const [];
    }
  }
}

/// A passage written about one keyed thing — a house, or a place in the
/// figure.
class VesselKeyedPassage {
  const VesselKeyedPassage({required this.key, required this.passage});

  /// The house number as a string, or the figure position's key.
  final String key;
  final String passage;

  static VesselKeyedPassage? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final key = raw['key'];
    final passage = raw['passage'];
    if (key is! String || passage is! String) return null;
    if (key.trim().isEmpty || passage.trim().isEmpty) return null;
    return VesselKeyedPassage(key: key, passage: passage);
  }

  static List<VesselKeyedPassage> decode(String contentJson) {
    try {
      final decoded = jsonDecode(contentJson);
      if (decoded is! Map || decoded['passages'] is! List) return const [];
      return [
        for (final item in decoded['passages'] as List)
          if (VesselKeyedPassage.fromJson(item) case final passage?) passage,
      ];
    } on FormatException {
      return const [];
    }
  }
}

/// The two long parts: one passage, and nothing else.
class VesselSynopsis {
  const VesselSynopsis(this.passage);

  final String passage;

  static String decode(String contentJson) {
    try {
      final decoded = jsonDecode(contentJson);
      if (decoded is Map && decoded['passage'] is String) {
        return decoded['passage'] as String;
      }
    } on FormatException {
      // Falls through to empty, which the surface reads as "not written yet".
    }
    return '';
  }
}

/// The two synopses are the long parts of the Vessel and are allowed to be.
///
/// Four times a movement's ceiling. The owner asked for "the longest part" and
/// for the figure's synopsis to match it, and a limit that quietly truncated
/// either would be the product disagreeing with its own instruction.
const vesselMaximumSynopsisCharacters = 5600;

/// A house or figure passage. Shorter than a movement on purpose: twelve of
/// these are read one after another, and the relating is saved for the
/// synopsis that follows them.
const vesselMaximumKeyedPassageCharacters = 900;

/// How many movements a reading may have, and how long each may run.
///
/// Three is the floor because two is a pair rather than a shape; five is the
/// ceiling because the sixth is always the one that starts listing placements
/// again.
const vesselMinimumMovements = 3;
const vesselMaximumMovements = 5;
const vesselMaximumPassageCharacters = 1400;
const vesselMaximumTitleCharacters = 48;

/// The single row a chart's reading is stored under.
///
/// The table is keyed `(inputHash, positionKey)` and this is a reserved key
/// rather than a position, so the whole-configuration reading needed no
/// migration and no second table.
const vesselConfigurationKey = 'configuration';

/// The parts the Vessel is read in, in the order it shows them.
///
/// Five written parts, not one. The reading used to be a single call — three
/// to five movements about the whole configuration — and it was good at what
/// it did and could not be more than that: a chart, a figure, twelve houses
/// and the geometry between the bodies all competing for the same five
/// passages. The owner's structure separates them, and each part gets a call
/// of its own with only what it needs.
///
/// All five go out under the **existing `vesselReadings` call name**. The
/// worker checks the name and nothing else — the prompt and the schema are
/// built on the device — so this adds no new call and needs no redeploy.
/// `server/worker.js` would answer a new name with `400 Unknown call`, and
/// only the owner can deploy.
///
/// Each caches under its own reserved key in the same table, so a part that
/// fails is retried alone and the four that succeeded are not paid for twice.
enum VesselReadingPart {
  /// A passage for each of the twelve houses. Written first because it is the
  /// part that may glance at the others; the relating proper is saved for the
  /// synopsis.
  houses('houses'),

  /// What the geometry says — the angles between bodies, which is the one
  /// thing a list of placements cannot show.
  aspects('aspects'),

  /// The long one. The whole chart, read as a single thing.
  chartSynopsis(vesselConfigurationKey),

  /// The figure, position by position.
  matrix('matrix'),

  /// The figure, read as a whole, and as long as the chart's synopsis.
  matrixSynopsis('matrixSynopsis');

  const VesselReadingPart(this.storageKey);

  /// The reserved `positionKey` this part is cached under.
  final String storageKey;
}

const vesselReadingResponseSchema = <String, Object>{
  'shape': 'movements: [{title, passage}]',
  'minMovements': vesselMinimumMovements,
  'maxMovements': vesselMaximumMovements,
  'maxTitleCharacters': vesselMaximumTitleCharacters,
  'maxPassageCharacters': vesselMaximumPassageCharacters,
};

/// Composes the chart's reading once, and never sends raw birth inputs or
/// identity.
///
/// One call per chart rather than one per position. The cache key is the
/// chart's own input hash, so a chart is paid for once and a person who never
/// changes their birth details never pays again.
class VesselReadingComposer {
  const VesselReadingComposer({
    required this.database,
    required this.provider,
    this.model = 'provider',
    this.safetyPolicy = const AetherSafetyPolicy(),
  });

  final AppDatabase database;
  final VesselReadingProvider provider;
  final String model;
  final AetherSafetyPolicy safetyPolicy;

  Future<VesselConfiguration> compose({
    required String inputHash,
    required VesselReadingRequest request,
    DateTime? now,
  }) async {
    final profile = await database.loadProfile();
    if (profile?.aiConsentAt == null) {
      throw const VesselReadingException('AI processing is not permitted');
    }

    final existing = await database.loadVesselReading(
      inputHash: inputHash,
      positionKey: vesselConfigurationKey,
    );
    if (existing != null) {
      final movements = VesselConfiguration.decode(existing.contentJson);
      if (movements.isNotEmpty) {
        return VesselConfiguration(movements: movements, fromCache: true);
      }
    }

    final prompt = EterPrompts.vesselReading(
      request,
      language: AppLanguage.forProfile(profile?.language),
    );
    final raw = await provider.compose(
      VesselReadingProviderRequest(
        system: prompt.system,
        context: prompt.user.cast<String, Object>(),
        responseSchema: prompt.responseSchema.cast<String, Object>(),
      ),
    );
    final movements = _parse(raw, mode: request.mode);
    await database.saveVesselReading(
      VesselReadingsCompanion.insert(
        inputHash: inputHash,
        positionKey: vesselConfigurationKey,
        createdAt: (now ?? DateTime.now()).toUtc(),
        contentJson: jsonEncode({
          'movements': [for (final one in movements) one.toJson()],
        }),
        model: model,
        promptVersion: const Value(EterPrompts.version),
      ),
    );
    // The per-position passages this replaced are dead weight now: never read,
    // but still exported and still synced. Cleared for this chart only, so a
    // different chart's rows are left to the retirement sweep that owns them.
    await database.clearVesselPositionReadings(
      inputHash: inputHash,
      keep: vesselConfigurationKey,
    );
    return VesselConfiguration(movements: movements, fromCache: false);
  }

  /// Composes one of the four parts that are not the chart's synopsis, and
  /// caches it under that part's own key.
  ///
  /// Returns the stored JSON, so the caller decodes it with whichever of
  /// [VesselKeyedPassage.decode] or [VesselSynopsis.decode] that part uses.
  /// Kept separate from [compose] rather than folded into it: the synopsis is
  /// the one part that already existed, is already proven against the live
  /// model, and has a shape — three to five titled movements — that the other
  /// four do not share.
  ///
  /// A part already written is never composed again, and a part that throws
  /// leaves the others alone. That is the whole reason each has its own row.
  Future<String> composePart({
    required String inputHash,
    required VesselReadingRequest request,
    required VesselReadingPart part,
    DateTime? now,
  }) async {
    if (part == VesselReadingPart.chartSynopsis) {
      throw const VesselReadingException(
        'The chart synopsis is composed by compose(), which owns its shape',
      );
    }
    final profile = await database.loadProfile();
    if (profile?.aiConsentAt == null) {
      throw const VesselReadingException('AI processing is not permitted');
    }

    final existing = await database.loadVesselReading(
      inputHash: inputHash,
      positionKey: part.storageKey,
    );
    if (existing != null && existing.contentJson.trim().isNotEmpty) {
      return existing.contentJson;
    }

    final prompt = EterPrompts.vesselPart(
      request,
      part: part,
      language: AppLanguage.forProfile(profile?.language),
    );
    final raw = await provider.compose(
      VesselReadingProviderRequest(
        system: prompt.system,
        context: prompt.user.cast<String, Object>(),
        responseSchema: prompt.responseSchema.cast<String, Object>(),
      ),
    );
    final content = _parsePart(raw, part: part, request: request);
    await database.saveVesselReading(
      VesselReadingsCompanion.insert(
        inputHash: inputHash,
        positionKey: part.storageKey,
        createdAt: (now ?? DateTime.now()).toUtc(),
        contentJson: content,
        model: model,
        promptVersion: const Value(EterPrompts.version),
      ),
    );
    return content;
  }

  /// Checks the answer's shape and its safety, and re-encodes it.
  ///
  /// Re-encoded rather than stored raw so what lands in the row is exactly the
  /// fields this app reads — a model that returns an extra key does not get to
  /// put it in the database.
  String _parsePart(
    String raw, {
    required VesselReadingPart part,
    required VesselReadingRequest request,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const VesselReadingException('Response is not JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const VesselReadingException('Response is not an object');
    }

    void checkSafe(String text) {
      try {
        // `validateReading`, not `validateGuidance`: the synopses are the
        // longest parts of this surface by instruction, and guidance's
        // conciseness rule would refuse them for being what they were asked
        // to be. Every rule that is about safety still applies.
        safetyPolicy.validateReading(text, mode: request.mode);
      } on AetherSafetyException catch (error) {
        throw VesselReadingException(error.reason);
      }
    }

    switch (part) {
      case VesselReadingPart.houses:
      case VesselReadingPart.matrix:
        final items = decoded['passages'];
        if (items is! List || items.isEmpty) {
          throw const VesselReadingException('Response is missing passages');
        }
        final expected = part == VesselReadingPart.houses
            ? request.houses.map((house) => '${house.house}').toSet()
            : request.positions.map((position) => position.key).toSet();
        final passages = <Map<String, Object>>[];
        final seen = <String>{};
        for (final item in items) {
          final passage = VesselKeyedPassage.fromJson(item);
          if (passage == null) {
            throw const VesselReadingException('A passage is malformed');
          }
          if (!expected.contains(passage.key)) {
            // A passage about a house or a place that was never sent is a
            // passage about something invented.
            throw VesselReadingException(
              'Response wrote about "${passage.key}", which was not sent',
            );
          }
          if (!seen.add(passage.key)) {
            throw VesselReadingException(
              'Response wrote about "${passage.key}" twice',
            );
          }
          if (passage.passage.length > vesselMaximumKeyedPassageCharacters) {
            throw const VesselReadingException('A passage runs too long');
          }
          checkSafe(passage.passage);
          passages.add({'key': passage.key, 'passage': passage.passage});
        }
        if (seen.length != expected.length) {
          throw VesselReadingException(
            'Response covered ${seen.length} of ${expected.length}',
          );
        }
        return jsonEncode({'passages': passages});

      case VesselReadingPart.aspects:
        final movements = _parse(raw, mode: request.mode);
        return jsonEncode({
          'movements': [for (final one in movements) one.toJson()],
        });

      case VesselReadingPart.matrixSynopsis:
        final passage = decoded['passage'];
        if (passage is! String || passage.trim().isEmpty) {
          throw const VesselReadingException('Response is missing the passage');
        }
        if (passage.length > vesselMaximumSynopsisCharacters) {
          throw const VesselReadingException('The synopsis runs too long');
        }
        checkSafe(passage);
        return jsonEncode({'passage': passage});

      case VesselReadingPart.chartSynopsis:
        throw const VesselReadingException('Unreachable: handled above');
    }
  }

  List<VesselMovement> _parse(String raw, {required GuidanceMode mode}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const VesselReadingException('Response is not JSON');
    }
    if (decoded is! Map<String, dynamic> || decoded['movements'] is! List) {
      throw const VesselReadingException('Response is missing movements');
    }
    final items = decoded['movements'] as List;
    if (items.length < vesselMinimumMovements ||
        items.length > vesselMaximumMovements) {
      throw const VesselReadingException(
        'Response must carry between three and five movements',
      );
    }
    final movements = <VesselMovement>[];
    final titles = <String>{};
    for (final item in items) {
      final movement = VesselMovement.fromJson(item);
      if (movement == null) {
        throw const VesselReadingException('Invalid movement shape');
      }
      final title = movement.title.trim();
      final passage = movement.passage.trim();
      if (title.isEmpty ||
          passage.isEmpty ||
          title.length > vesselMaximumTitleCharacters ||
          passage.length > vesselMaximumPassageCharacters) {
        throw const VesselReadingException('Invalid movement content');
      }
      // Two movements under one title is the shape of a model that ran out of
      // things to say and repeated itself.
      if (!titles.add(title.toLowerCase())) {
        throw const VesselReadingException('Movements repeat a title');
      }
      try {
        safetyPolicy.validateGuidance(
          sentences: [passage],
          primaryAction:
              'Reflect without treating this reading as instruction.',
          mode: mode,
        );
      } on AetherSafetyException catch (error) {
        throw VesselReadingException(error.reason);
      }
      movements.add(VesselMovement(title: title, passage: passage));
    }
    return movements;
  }
}
