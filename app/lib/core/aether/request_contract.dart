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

class AetherRequest {
  const AetherRequest({
    required this.schemaVersion,
    required this.mode,
    required this.ageYears,
    required this.health,
    required this.journal,
    required this.contextFingerprint,
  });

  final int schemaVersion;
  final GuidanceMode mode;
  final int ageYears;
  final List<AetherHealthContext> health;
  final List<Map<String, Object>> journal;
  final String contextFingerprint;

  Map<String, Object> toJson() => {
        'schemaVersion': schemaVersion,
        'mode': mode.name,
        'ageYears': ageYears,
        'health': health.map((item) => item.toJson()).toList(),
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

    final stableContext = <String, Object>{
      'schemaVersion': 1,
      'mode': mode.name,
      'ageYears': ageYears,
      'health': health.map((item) => item.toJson()).toList(),
      'journal': prose,
    };
    return AetherRequest(
      schemaVersion: 1,
      mode: mode,
      ageYears: ageYears,
      health: List.unmodifiable(health),
      journal: List.unmodifiable(prose),
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
