import 'dart:convert';

import 'package:drift/drift.dart';

import '../ai/prompts.dart';
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

    final prompt = EterPrompts.guidance(request);
    final raw = await provider.compose(AetherProviderRequest(
      system: prompt.system,
      context: prompt.user.cast<String, Object>(),
      // The prompt's own JSON Schema, not the loose summary in
      // `aetherResponseSchema`: it names the exact fields the parser below
      // requires, and a provider that can constrain decoding to it will stop
      // inventing plausible neighbours like `healthAction`.
      responseSchema: prompt.responseSchema.cast<String, Object>(),
    ));
    // Checked against the payload the model was actually sent, not against the
    // records — a number that is true but was not in this request is still a
    // citation of something the model could not have seen.
    final guidance = parser.parse(
      raw,
      mode: request.mode,
      evidence: AetherEvidenceScope.fromContext(prompt.user),
    );
    final instant = now ?? DateTime.now();
    final generatedAt = instant.toUtc();
    // The seven-day context is ordered oldest→newest; it must never choose the
    // first evidence day as the destination for today's composition.
    final date = now != null
        ? _localDate(instant)
        : request.health.isEmpty
            ? _localDate(instant)
            : request.health.last.localDate;

    // The note for the days after this one, written before the composition is
    // reported as done so a reader on the next day cannot see guidance without
    // the memory of it.
    if (guidance.recall != null) {
      final synthesis = guidance.dimensions
          .firstWhere((dimension) => dimension.key == 'synthesis');
      await database.saveGuidanceRecall(GuidanceRecallsCompanion.insert(
        date: date,
        generatedAt: generatedAt,
        note: guidance.recall!,
        action: Value(synthesis.primaryAction),
        // What this note could have been written from. If journal consent is
        // later withdrawn, a note that saw a page stops travelling.
        usedJournal: Value(request.journal.isNotEmpty ||
            request.digests.isNotEmpty ||
            request.lifestyle.any((item) => item.fromJournal)),
        promptVersion: const Value(EterPrompts.version),
      ));
    }

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
          promptVersion: const Value(EterPrompts.version),
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
