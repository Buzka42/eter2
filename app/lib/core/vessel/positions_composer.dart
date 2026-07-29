import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../aether/guidance_mode.dart';
import '../aether/safety_policy.dart';
import '../ai/prompts.dart';
import '../db/app_database.dart';
import '../symbolic/transits.dart';

class PositionsException implements Exception {
  const PositionsException(this.reason);
  final String reason;

  @override
  String toString() => reason;
}

abstract interface class PositionsProvider {
  Future<String> compose(PositionsProviderRequest request);
}

class PositionsProviderRequest {
  const PositionsProviderRequest({
    required this.system,
    required this.context,
    required this.responseSchema,
  });

  final String system;
  final Map<String, Object?> context;
  final Map<String, Object?> responseSchema;
}

class PositionsPassage {
  const PositionsPassage({required this.passage, required this.guidanceNote});

  final String passage;

  /// The single sentence the day's guidance may carry. It is the only part of
  /// Positions that leaves this surface.
  final String guidanceNote;

  Map<String, Object?> toJson() => {
        'passage': passage,
        'guidanceNote': guidanceNote,
      };

  static PositionsPassage? tryParseStored(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map &&
          decoded['passage'] is String &&
          decoded['guidanceNote'] is String) {
        return PositionsPassage(
          passage: decoded['passage'] as String,
          guidanceNote: decoded['guidanceNote'] as String,
        );
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

class PositionsResult {
  const PositionsResult({
    required this.reading,
    required this.passage,
    required this.fromCache,
  });

  /// Always present: the contacts are arithmetic and never need a provider.
  final TransitReading reading;

  /// Null until a provider has written today's passage.
  final PositionsPassage? passage;
  final bool fromCache;
}

/// Today's positions: computed locally, described once.
///
/// The contacts themselves cost nothing and are recomputed freely. The prose
/// costs a provider call, so it is cached per day and per chart — and a change
/// of birth context retires it along with the vessel readings, because a
/// reading against a chart the person no longer has is not a reading.
class PositionsComposer {
  const PositionsComposer({
    required this.database,
    required this.provider,
    this.safetyPolicy = const AetherSafetyPolicy(),
    this.model = 'provider',
  });

  final AppDatabase database;
  final PositionsProvider? provider;
  final AetherSafetyPolicy safetyPolicy;
  final String model;

  /// Returns today's contacts, and its passage if one exists or can be written.
  ///
  /// [compose] false reads without ever calling a provider, which is what the
  /// Vessel does when it opens: the contacts appear immediately and the prose
  /// arrives only when it is asked for.
  Future<PositionsResult> forDay({
    required TransitReading reading,
    required String inputHash,
    required GuidanceMode mode,
    required bool ascendantReliable,
    required DateTime now,
    bool compose = false,
  }) async {
    final existing = await database.loadTransitReading(
      date: reading.forDate,
      inputHash: inputHash,
    );
    if (existing != null) {
      return PositionsResult(
        reading: reading,
        passage: PositionsPassage.tryParseStored(existing.passage),
        fromCache: true,
      );
    }
    if (!compose) {
      return PositionsResult(reading: reading, passage: null, fromCache: false);
    }

    final transport = provider;
    if (transport == null) {
      throw const PositionsException(
        'Positions are not connected on this build yet',
      );
    }
    final profile = await database.loadProfile();
    if (profile?.aiConsentAt == null) {
      throw const PositionsException('AI processing is not permitted');
    }

    final prompt = EterPrompts.positions(
      mode: mode,
      transits: reading.toJson(),
      ascendantReliable: ascendantReliable,
    );
    final raw = await transport.compose(PositionsProviderRequest(
      system: prompt.system,
      context: prompt.user,
      responseSchema: prompt.responseSchema,
    ));

    final parsed = _parse(raw, mode: mode);
    await database.saveTransitReading(TransitReadingsCompanion.insert(
      date: reading.forDate,
      inputHash: inputHash,
      generatedAt: now.toUtc(),
      contactsJson: jsonEncode(reading.toJson()),
      passage: jsonEncode(parsed.toJson()),
      model: Value(model),
      promptVersion: const Value(EterPrompts.version),
    ));
    return PositionsResult(
      reading: reading,
      passage: parsed,
      fromCache: false,
    );
  }

  PositionsPassage _parse(String raw, {required GuidanceMode mode}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const PositionsException('Response is not JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const PositionsException('Response must be an object');
    }
    final passage = decoded['passage'];
    final note = decoded['guidanceNote'];
    if (passage is! String ||
        passage.trim().isEmpty ||
        passage.trim().length > 1200) {
      throw const PositionsException('A passage of readable length is required');
    }
    if (note is! String || note.trim().isEmpty || note.trim().length > 140) {
      throw const PositionsException(
        'One short guidance note is required',
      );
    }
    // The note reaches the daily guidance, so it passes the same safety gate
    // guidance itself does.
    safetyPolicy.validateGuidance(
      sentences: [passage.trim()],
      primaryAction: note.trim(),
      mode: mode,
    );
    return PositionsPassage(
      passage: passage.trim(),
      guidanceNote: note.trim(),
    );
  }
}
