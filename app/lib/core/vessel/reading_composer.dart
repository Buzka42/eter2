import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../aether/guidance_mode.dart';
import '../aether/safety_policy.dart';
import '../ai/prompts.dart';
import '../db/app_database.dart';

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

const vesselReadingResponseSchema = <String, Object>{
  'shape': 'readings: [{key, passage}]',
  'exactRequestedKeys': true,
  'maxPassageCharacters': 1800,
};

class VesselReadingComposition {
  const VesselReadingComposition({
    required this.rows,
    required this.fromCache,
  });

  final Map<String, VesselReadingRow> rows;
  final bool fromCache;
}

/// Composes only missing positions and never sends raw birth inputs or identity.
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

  Future<VesselReadingComposition> compose({
    required String inputHash,
    required VesselReadingRequest request,
    DateTime? now,
  }) async {
    final profile = await database.loadProfile();
    if (profile?.aiConsentAt == null) {
      throw const VesselReadingException('AI processing is not permitted');
    }
    final existing = <String, VesselReadingRow>{};
    for (final position in request.positions) {
      final row = await database.loadVesselReading(
        inputHash: inputHash,
        positionKey: position.key,
      );
      if (row != null) existing[position.key] = row;
    }
    final missing = request.positions
        .where((position) => !existing.containsKey(position.key))
        .toList();
    if (missing.isEmpty) {
      return VesselReadingComposition(rows: existing, fromCache: true);
    }

    final prompt = EterPrompts.vesselReading(VesselReadingRequest(
      mode: request.mode,
      positions: missing,
      approximateTime: request.approximateTime,
      approximatePlace: request.approximatePlace,
    ));
    final raw = await provider.compose(
      VesselReadingProviderRequest(
        system: prompt.system,
        context: prompt.user.cast<String, Object>(),
        responseSchema: prompt.responseSchema.cast<String, Object>(),
      ),
    );
    final passages = _parse(
      raw,
      requestedKeys: missing.map((item) => item.key).toSet(),
      mode: request.mode,
    );
    final createdAt = (now ?? DateTime.now()).toUtc();
    await database.saveVesselReadingSet([
      for (final entry in passages.entries)
        VesselReadingsCompanion.insert(
          inputHash: inputHash,
          positionKey: entry.key,
          createdAt: createdAt,
          contentJson: jsonEncode({'passage': entry.value}),
          model: model,
          promptVersion: const Value(EterPrompts.version),
        ),
    ]);
    for (final position in missing) {
      existing[position.key] = (await database.loadVesselReading(
        inputHash: inputHash,
        positionKey: position.key,
      ))!;
    }
    return VesselReadingComposition(rows: existing, fromCache: false);
  }

  Map<String, String> _parse(
    String raw, {
    required Set<String> requestedKeys,
    required GuidanceMode mode,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const VesselReadingException('Response is not JSON');
    }
    if (decoded is! Map<String, dynamic> || decoded['readings'] is! List) {
      throw const VesselReadingException('Response is missing readings');
    }
    final passages = <String, String>{};
    for (final item in decoded['readings'] as List) {
      if (item is! Map<String, dynamic> ||
          item['key'] is! String ||
          item['passage'] is! String) {
        throw const VesselReadingException('Invalid reading shape');
      }
      final key = item['key'] as String;
      final passage = (item['passage'] as String).trim();
      if (!requestedKeys.contains(key) ||
          passages.containsKey(key) ||
          passage.isEmpty ||
          passage.length > 1800) {
        throw const VesselReadingException('Invalid reading content');
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
      passages[key] = passage;
    }
    if (passages.keys.toSet().difference(requestedKeys).isNotEmpty ||
        !passages.keys.toSet().containsAll(requestedKeys)) {
      throw const VesselReadingException(
        'Response must contain every requested position exactly once',
      );
    }
    return passages;
  }
}
