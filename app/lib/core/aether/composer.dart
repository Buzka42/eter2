import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'guidance_contract.dart';
import 'request_contract.dart';

class AetherComposition {
  const AetherComposition({
    required this.rows,
    required this.fromCache,
  });

  final List<GuidanceHistoryRow> rows;
  final bool fromCache;
}

/// Provider-independent, consent-safe composition coordinator.
///
/// Provider or validation failures propagate to the caller and write nothing.
/// An unchanged context fingerprint returns the prior complete composition.
class AetherComposer {
  const AetherComposer({
    required this.database,
    required this.provider,
    this.parser = const AetherGuidanceParser(),
    this.source = 'provider',
  });

  final AppDatabase database;
  final AetherProvider provider;
  final AetherGuidanceParser parser;
  final String source;

  Future<AetherComposition> compose(
    AetherRequest request, {
    DateTime? now,
  }) async {
    final existing = await database.loadGuidanceByFingerprint(
      request.contextFingerprint,
    );
    if (_isComplete(existing)) {
      return AetherComposition(rows: existing, fromCache: true);
    }

    final raw = await provider.compose(AetherProviderRequest(
      context: request.toJson(),
      responseSchema: aetherResponseSchema,
    ));
    final guidance = parser.parse(raw, mode: request.mode);
    final instant = now ?? DateTime.now();
    final generatedAt = instant.toUtc();
    // The seven-day context is ordered oldest→newest; it must never choose the
    // first evidence day as the destination for today's composition.
    final date = now != null
        ? _localDate(instant)
        : request.health.isEmpty
            ? _localDate(instant)
            : request.health.last.localDate;

    await database.recordGuidanceSet([
      for (final dimension in guidance.dimensions)
        GuidanceHistoryCompanion.insert(
          date: date,
          dimension: dimension.key,
          generatedAt: generatedAt,
          contentJson: jsonEncode(dimension.toJson()),
          evidenceJson: Value(
            dimension.evidence == null ? null : jsonEncode(dimension.evidence),
          ),
          contextFingerprint: request.contextFingerprint,
          source: source,
        ),
    ]);
    return AetherComposition(
      rows: await database.loadGuidanceByFingerprint(
        request.contextFingerprint,
      ),
      fromCache: false,
    );
  }

  bool _isComplete(List<GuidanceHistoryRow> rows) =>
      rows.length == AetherGuidanceParser.dimensionKeys.length &&
      rows.map((row) => row.dimension).toSet().containsAll(
            AetherGuidanceParser.dimensionKeys,
          );

  String _localDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
