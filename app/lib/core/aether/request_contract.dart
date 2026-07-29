import 'dart:convert';

import 'guidance_mode.dart';

class AetherConsentException implements Exception {
  const AetherConsentException(this.reason);
  final String reason;
}

class AetherHealthContext {
  const AetherHealthContext({
    required this.localDate,
    this.steps,
    this.activeKcal,
    this.sleepMinutes,
    this.restingHeartRate,
    this.hrvMs,
  });

  final String localDate;
  final int? steps;
  final double? activeKcal;
  final int? sleepMinutes;
  final double? restingHeartRate;
  final double? hrvMs;

  Map<String, Object?> toJson() => {
        'localDate': localDate,
        'steps': steps,
        'activeKcal': activeKcal,
        'sleepMinutes': sleepMinutes,
        'restingHeartRate': restingHeartRate,
        'hrvMs': hrvMs,
      };
}

class AetherJournalContext {
  const AetherJournalContext({
    required this.createdAt,
    required this.text,
    this.excludedFromAi = false,
  });

  final DateTime createdAt;
  final String text;
  final bool excludedFromAi;
}

/// The chart, as guidance is allowed to see it: derived placements and a Life
/// Path number, never the inputs they were computed from.
class AetherSymbolicContext {
  const AetherSymbolicContext({
    required this.sunSign,
    required this.moonSign,
    this.ascendantSign,
    required this.lifePath,
    this.personalYear,
    this.sunCard,
    this.positionsNote,
  });

  final String sunSign;
  final String moonSign;

  /// Absent when birth time or place is unknown — never guessed at noon for
  /// the purposes of guidance, because a provisional ascendant that reads as
  /// certain is worse than none.
  final String? ascendantSign;
  final int lifePath;
  final int? personalYear;
  /// The Arcana of the person's Sun sign — fixed at birth, not a daily draw.
  final String? sunCard;

  /// The one sentence Positions is allowed to hand to guidance. It is prose
  /// the model wrote earlier today about the day's transits, already validated.
  final String? positionsNote;

  Map<String, Object> toJson() => {
        'sunSign': sunSign,
        'moonSign': moonSign,
        if (ascendantSign != null) 'ascendantSign': ascendantSign!,
        'lifePath': lifePath,
        if (personalYear != null) 'personalYear': personalYear!,
        if (sunCard != null) 'sunCard': sunCard!,
        if (positionsNote != null) 'positionsNote': positionsNote!,
      };
}

/// One day of the journal, as the day's own story pass compressed it.
///
/// Guidance sends these instead of raw prose. A digest is bounded by
/// construction, so a person who writes at length costs no more than one who
/// writes a line.
class AetherJournalDigest {
  const AetherJournalDigest({required this.localDate, required this.points});

  final String localDate;
  final Map<String, Object?> points;

  Map<String, Object> toJson() => {
        'localDate': localDate,
        'points': points,
      };
}

class AetherRequest {
  const AetherRequest({
    required this.schemaVersion,
    required this.mode,
    required this.ageYears,
    required this.health,
    required this.journal,
    required this.contextFingerprint,
    this.symbolic,
    this.digests = const [],
    this.patterns = const [],
    this.bodyFatPercent,
  });

  final int schemaVersion;
  final GuidanceMode mode;
  final int ageYears;
  final List<AetherHealthContext> health;
  final List<Map<String, Object>> journal;
  final String contextFingerprint;

  /// Absent when the chart could not be calculated — guidance still composes,
  /// with the measured half only, and the prompt is told so.
  final AetherSymbolicContext? symbolic;

  /// Bounded per-day journal digests, newest last.
  final List<AetherJournalDigest> digests;

  /// What the device noticed about this person, in its own words.
  ///
  /// Correlations found locally over the last four weeks — "you sleep 40
  /// minutes less after training past nine" — computed by
  /// `LocalPatternDiscovery` from records that never left. Guidance was
  /// reasoning from seven days at a time and could not see a habit; these are
  /// the only long-range statements it gets, and they arrive as findings
  /// rather than as raw history.
  ///
  /// Dismissed patterns are not here: the person said the observation was
  /// wrong, and repeating it to a model would be arguing with them.
  final List<String> patterns;

  /// Optional, 5–40. Present only when the person supplied it.
  final double? bodyFatPercent;

  Map<String, Object> toJson() => {
        'schemaVersion': schemaVersion,
        'mode': mode.name,
        'ageYears': ageYears,
        if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent!,
        'health': health.map((item) => item.toJson()).toList(),
        if (symbolic != null) 'symbolic': symbolic!.toJson(),
        if (digests.isNotEmpty)
          'journalDigests': digests.map((item) => item.toJson()).toList(),
        if (patterns.isNotEmpty) 'patterns': patterns,
        'journal': journal,
        'contextFingerprint': contextFingerprint,
      };
}

/// Builds the only payload providers are allowed to receive.
///
/// Identity, exact birth date, location and database identifiers are absent by
/// construction. Journal prose has a separate consent and a hard character
/// budget; excluded entries never cross the boundary.
class AetherRequestBuilder {
  const AetherRequestBuilder({
    this.maxJournalEntries = 5,
    this.maxJournalCharacters = 1200,
  });

  final int maxJournalEntries;
  final int maxJournalCharacters;

  AetherRequest build({
    required bool aiConsented,
    required bool journalConsented,
    required int ageYears,
    required GuidanceMode mode,
    required List<AetherHealthContext> health,
    List<AetherJournalContext> journal = const [],
    AetherSymbolicContext? symbolic,
    List<AetherJournalDigest> digests = const [],
    List<String> patterns = const [],
    double? bodyFatPercent,
  }) {
    if (!aiConsented) {
      throw const AetherConsentException('AI processing is not permitted');
    }
    if (ageYears < 16) {
      throw const AetherConsentException('Aether requires age 16 or older');
    }

    final prose = <Map<String, Object>>[];
    if (journalConsented) {
      var remaining = maxJournalCharacters;
      for (final entry in journal.where((item) => !item.excludedFromAi)) {
        if (prose.length >= maxJournalEntries || remaining <= 0) break;
        final normalized = entry.text.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (normalized.isEmpty) continue;
        final length =
            normalized.length < remaining ? normalized.length : remaining;
        prose.add({
          'createdAt': entry.createdAt.toUtc().toIso8601String(),
          'text': normalized.substring(0, length),
        });
        remaining -= length;
      }
    }

    // Four at most, and short. A finding that needs a paragraph is not a
    // finding.
    final bounded = [
      for (final pattern in patterns.take(4))
        if (pattern.trim().isNotEmpty) pattern.trim(),
    ];

    // Digests are journal-derived, so they cross only under the same consent
    // the prose itself needs.
    final digestPayload = journalConsented ? digests : const <AetherJournalDigest>[];

    final stableContext = <String, Object>{
      'schemaVersion': 2,
      'mode': mode.name,
      'ageYears': ageYears,
      if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent,
      'health': health.map((item) => item.toJson()).toList(),
      if (symbolic != null) 'symbolic': symbolic.toJson(),
      'journalDigests': digestPayload.map((item) => item.toJson()).toList(),
      'journal': prose,
      // In the fingerprint, so a newly discovered pattern is itself a reason
      // to recompose rather than something guidance learns about tomorrow.
      'patterns': bounded,
    };
    return AetherRequest(
      schemaVersion: 2,
      mode: mode,
      ageYears: ageYears,
      health: List.unmodifiable(health),
      journal: List.unmodifiable(prose),
      symbolic: symbolic,
      digests: List.unmodifiable(digestPayload),
      patterns: List.unmodifiable(bounded),
      bodyFatPercent: bodyFatPercent,
      contextFingerprint: _fnv1a64(jsonEncode(stableContext)),
    );
  }

  String _fnv1a64(String input) {
    var hash = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = BigInt.parse('ffffffffffffffff', radix: 16);
    for (final byte in utf8.encode(input)) {
      hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
