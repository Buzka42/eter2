import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../ai/prompts.dart';
import '../db/app_database.dart';
import '../i18n/language.dart';
import 'guidance_mode.dart';
import 'safety_policy.dart';

/// One page a month, written **to** the person.
///
/// The sixth model call, and the only one whose window is a month and whose
/// subject is the person rather than a day, a page or a chart. It reads two
/// things and composes from nothing else:
///
/// * the month's `GuidanceRecalls` — Aether's own compressed notes, one per
///   day. These are **the model's words about what it had already said**. A
///   letter that says "you told me" about a note nobody wrote is the precise
///   failure `AI_FLOW.md` §1a exists to prevent, and the instruction forbids it
///   in as many words.
/// * the retrospectives whose window fell in the month — sentences Eter
///   composed on the device, carrying their own counts. Every figure in a
///   letter comes from there. The model is told not to compute one.
///
/// It costs one request per person per month, because the month *is* the cache
/// key: a month already written is never composed again.
class LetterException implements Exception {
  const LetterException(this.reason);
  final String reason;

  @override
  String toString() => reason;
}

/// Validates provider output before any of it is stored.
///
/// The ceiling is checked here as well as in the response schema. A provider
/// that ignores the schema is a provider Eter still has to survive, and the
/// schema is the endpoint's promise rather than a boundary this app controls.
class LetterParser {
  const LetterParser({
    this.maxCharacters = 2400,
    this.safety = const AetherSafetyPolicy(),
  });

  final int maxCharacters;
  final AetherSafetyPolicy safety;

  String parse(String raw, {GuidanceMode mode = GuidanceMode.balanced}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const LetterException('Response is not JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const LetterException('Response must be an object');
    }
    final body = decoded['letter'];
    if (body is! String || body.trim().isEmpty) {
      throw const LetterException('A letter is required');
    }
    final letter = body.trim();
    if (letter.length > maxCharacters) {
      throw const LetterException('The letter is not one page');
    }
    // A letter is prose rather than an instruction, so it has no
    // `primaryAction` to check. Passing an empty one keeps the policy's own
    // shape rather than inventing a second entry point into it.
    safety.validateGuidance(
      sentences: [letter],
      primaryAction: '',
      mode: mode,
    );
    return letter;
  }
}

abstract interface class LetterProvider {
  Future<String> compose(LetterProviderRequest request);
}

class LetterProviderRequest {
  const LetterProviderRequest({
    required this.system,
    required this.context,
    required this.responseSchema,
  });

  final String system;
  final Map<String, Object?> context;
  final Map<String, Object?> responseSchema;
}

class LetterResult {
  const LetterResult({required this.row, required this.fromCache});

  final LetterRow? row;
  final bool fromCache;
}

/// Composes the letter for a month, once.
class LetterComposer {
  const LetterComposer({
    required this.database,
    required this.provider,
    this.parser = const LetterParser(),
    this.model = 'provider',
    this.minimumRecalls = 5,
  });

  final AppDatabase database;
  final LetterProvider provider;
  final LetterParser parser;
  final String model;

  /// Below this many notes there is not a month to write about.
  ///
  /// The instruction already tells the model to write a short letter for a thin
  /// month, and that is the right behaviour for a month with eight notes. This
  /// is the floor below which no request is worth making at all: a month with
  /// two days in it produces a letter about nothing, and paying a model to say
  /// "there is not much here yet" is worse than Eter simply not writing.
  final int minimumRecalls;

  /// Writes the letter for the month containing [month], or returns the stored
  /// one. Never recomposes a month already written.
  ///
  /// [now] is the composing instant, not a clock read inside — every path in
  /// this app takes its time from the caller so tests are not timing-dependent.
  Future<LetterResult> compose({
    required String month,
    required DateTime now,
  }) async {
    final existing = await database.loadLetter(month);
    if (existing != null) {
      return LetterResult(row: existing, fromCache: true);
    }

    // Consent is re-read, never cached, and the letter is made of Aether's own
    // notes about days that may have included journal material — so it needs
    // the base consent, and it drops journal-derived notes without the second.
    final profile = await database.loadProfile();
    if (profile?.aiConsentAt == null) {
      throw const LetterException('AI guidance is not permitted');
    }
    final journalAllowed = profile?.journalAiConsentAt != null;

    final recalls = await _recallsIn(month, journalAllowed: journalAllowed);
    if (recalls.length < minimumRecalls) {
      return const LetterResult(row: null, fromCache: false);
    }

    final retrospective = await _retrospectiveIn(month);

    final prompt = EterPrompts.letter(
      mode: _mode(profile?.guidanceMode),
      language: AppLanguage.forProfile(profile?.language),
      month: month,
      recalls: recalls,
      retrospective: retrospective,
    );

    final raw = await provider.compose(
      LetterProviderRequest(
        system: prompt.system,
        context: prompt.user,
        responseSchema: prompt.responseSchema,
      ),
    );

    final body = parser.parse(
      raw,
      mode: _mode(profile?.guidanceMode),
    );

    await database.upsertLetter(
      LettersCompanion.insert(
        month: month,
        composedAt: now,
        body: body,
        sourceCount: Value(recalls.length + retrospective.length),
        usedJournal: Value(journalAllowed),
        model: Value(model),
        promptVersion: const Value(EterPrompts.version),
      ),
    );

    return LetterResult(
      row: await database.loadLetter(month),
      fromCache: false,
    );
  }

  /// The month's notes, oldest first.
  ///
  /// Notes written while journal consent was on may paraphrase a page, so
  /// withdrawing that consent has to stop them travelling — otherwise revoking
  /// leaves last month's pages reaching the model laundered through Eter's own
  /// prose. `GuidanceRecalls.usedJournal` is what records that.
  Future<List<String>> _recallsIn(
    String month, {
    required bool journalAllowed,
  }) async {
    final rows = await database.loadGuidanceRecalls(
      today: _lastDayOf(month),
      days: 31,
      journalAllowed: journalAllowed,
    );
    return [
      for (final row in rows)
        if (row.date.startsWith(month)) row.note,
    ];
  }

  /// The month's own arithmetic — every number the letter is allowed to use.
  Future<List<String>> _retrospectiveIn(String month) async {
    final rows = await database.loadRetrospectives();
    return [
      for (final row in rows)
        if (row.periodEnd.startsWith(month))
          ...(_passages(row.contentJson)),
    ];
  }

  static List<String> _passages(String contentJson) {
    try {
      final decoded = jsonDecode(contentJson);
      if (decoded is Map<String, dynamic>) {
        final passages = decoded['passages'];
        if (passages is List) {
          return [
            for (final passage in passages)
              if (passage is String) passage,
          ];
        }
      }
    } on FormatException {
      // A malformed stored retrospective costs the letter its figures, not its
      // existence. It is still Aether's notes that carry the month.
    }
    return const [];
  }

  static GuidanceMode _mode(String? raw) => switch (raw) {
        'grounded' => GuidanceMode.grounded,
        'immersive' => GuidanceMode.immersive,
        _ => GuidanceMode.balanced,
      };

  /// `YYYY-MM` to the last day in it. Day zero of the following month is the
  /// last of this one, and it knows about February.
  static String _lastDayOf(String month) {
    final parts = month.split('-');
    final last = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 0);
    return '${last.year.toString().padLeft(4, '0')}-'
        '${last.month.toString().padLeft(2, '0')}-'
        '${last.day.toString().padLeft(2, '0')}';
  }
}
