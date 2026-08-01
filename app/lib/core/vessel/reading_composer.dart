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

class VesselReadingRequest {
  const VesselReadingRequest({
    required this.mode,
    required this.positions,
    required this.approximateTime,
    required this.approximatePlace,
  });

  final GuidanceMode mode;
  final List<VesselReadingPosition> positions;
  final bool approximateTime;
  final bool approximatePlace;

  Map<String, Object> toJson() => {
        'mode': mode.name,
        'positions': positions.map((item) => item.toJson()).toList(),
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
