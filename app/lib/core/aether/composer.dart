import 'dart:convert';

import 'package:drift/drift.dart';

import '../ai/prompts.dart';
import '../db/app_database.dart';
import '../widget/home_screen_widget.dart';
import '../i18n/language.dart';
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

  /// [force] composes again even when the day's fingerprint already has a
  /// complete reading.
  ///
  /// The cache is keyed on the context, so a day whose records have not
  /// changed will not recompose on its own however many times it is asked —
  /// which is right for the automatic path and wrong for a person who has
  /// deliberately pressed a button asking for another reading. There is one
  /// such button, in the Sanctum, and this is what it means.
  Future<AetherComposition> compose(
    AetherRequest request, {
    DateTime? now,
    bool force = false,
  }) async {
    final existing = await database.loadGuidanceByFingerprint(
      request.contextFingerprint,
    );
    if (!force && _isComplete(existing)) {
      return AetherComposition(rows: existing, fromCache: true);
    }

    // From the profile rather than from the caller: guidance composes itself
    // on the day's first look, with no surface involved to pass anything in.
    final profile = await database.loadProfile();
    final language = AppLanguage.forProfile(profile?.language);
    final prompt = EterPrompts.guidance(
      request,
      language: language,
      // Polish has to agree with somebody. The profile's own answer where
      // there is one, and the masculine where there is not — the owner's
      // rule, and the language's own default.
      gender: EterGrammaticalGender.forProfileSex(profile?.sex),
    );
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

    // The home screen, from here rather than from a surface.
    //
    // It was hooked to the Dashboard's own compose at first, which is one of
    // the ways a day gets composed and not the only one: the Sanctum's `AGAIN`
    // goes through this same method by another route, and on the phone the
    // widget's preference had simply never been written. Every path that
    // stores guidance passes through this line.
    //
    // Awaited but never allowed to matter: the sink swallows a missing plugin
    // — which is every platform but Android and every test binding — and a
    // launcher that fails to redraw must not fail a composition.
    await HomeScreenWidget(database: database).refresh(now: generatedAt);

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
