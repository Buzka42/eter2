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

/// One self-reported reading or practice, as guidance is allowed to see it.
///
/// The margin's check-in, and anything a page said about mood, energy, focus,
/// meaning or what the person is carrying. These are the only statements in
/// the payload about the inside of a day: everything else is a sensor or a
/// derived placement.
class AetherLifestyleContext {
  const AetherLifestyleContext({
    required this.localDate,
    required this.kind,
    this.value,
    this.durationMinutes,
    this.note,
    this.fromJournal = false,
  });

  final String localDate;
  final String kind;

  /// 0..10 where the kind is a rating. Absent where it is not.
  final double? value;
  final double? durationMinutes;

  /// The person's own words about it, when they wrote any.
  final String? note;

  /// Derived from a journal page rather than the margin's check-in. Journal
  /// consent gates these separately, because prose is what they came from.
  final bool fromJournal;

  Map<String, Object> toJson() => {
        'localDate': localDate,
        'kind': kind,
        if (value != null) 'value': value!,
        if (durationMinutes != null) 'durationMinutes': durationMinutes!,
        if (note != null) 'note': note!,
      };
}

/// A locally discovered correlation, with the strength of the finding beside
/// it.
///
/// The summary travelled alone until now, which meant a finding at 55%
/// confidence over nine days read exactly like one at 95% over thirty. The
/// model cannot weigh what it cannot see.
class AetherPatternContext {
  const AetherPatternContext({
    required this.summary,
    required this.confidence,
    this.observations,
    this.window,
  });

  final String summary;

  /// 0..1, as `LocalPatternDiscovery` computed it.
  final double confidence;

  /// How many days the comparison rested on.
  final int? observations;

  /// The span it was computed over, e.g. `28 days`.
  final String? window;

  Map<String, Object> toJson() => {
        'summary': summary,
        'confidence': double.parse(confidence.toStringAsFixed(2)),
        if (observations != null) 'observations': observations!,
        if (window != null) 'window': window!,
      };
}

/// What Aether said on an earlier day, compressed to the substance of it.
///
/// The only thing in the payload that is Eter's own prior output rather than a
/// record of the person. That distinction is stated to the model in the prompt,
/// because a note about what *it* said reads exactly like a note about what
/// *they* said, and confusing the two would put words in someone's mouth.
class AetherRecallContext {
  const AetherRecallContext({
    required this.localDate,
    required this.note,
    this.action,
  });

  final String localDate;

  /// Telegraphic. The prose it came from stays on the device.
  final String note;

  /// What that day offered to do, so today does not offer it again.
  final String? action;

  Map<String, Object> toJson() => {
        'localDate': localDate,
        'note': note,
        if (action != null) 'action': action!,
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
    this.positionsPassage,
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

  /// The whole of today's Positions passage, sent only where the sky is the
  /// louder half — see [AetherRequest.leansSymbolic]. Already written and
  /// already validated by the Positions call's own safety policy; this passes
  /// it on rather than composing anything new.
  final String? positionsPassage;

  Map<String, Object> toJson() => {
        'sunSign': sunSign,
        'moonSign': moonSign,
        if (ascendantSign != null) 'ascendantSign': ascendantSign!,
        'lifePath': lifePath,
        if (personalYear != null) 'personalYear': personalYear!,
        if (sunCard != null) 'sunCard': sunCard!,
        if (positionsNote != null) 'positionsNote': positionsNote!,
        if (positionsPassage != null) 'positionsToday': positionsPassage!,
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

/// What was eaten, and what this body's floors are.
///
/// Guidance carried steps, active calories, sleep, resting heart rate and HRV
/// — and nothing at all about food. So the one thing a person logs by hand
/// every day was the one thing the day's reading could not mention, and the
/// protein and fat floors had nowhere to be read from.
///
/// Every figure here is nullable and null means **not recorded**, never zero.
/// A day nobody logged is a day Eter knows nothing about; the difference
/// between "ate no protein" and "did not say" is the difference between a true
/// sentence and a false one.
class AetherIntakeContext {
  const AetherIntakeContext({
    required this.localDate,
    this.kcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  final String localDate;
  final double? kcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  /// Whether anything at all was logged. A day with no entries is absent from
  /// the reasoning rather than present as a row of zeroes.
  bool get recorded =>
      kcal != null || proteinG != null || carbsG != null || fatG != null;

  Map<String, Object?> toJson() => {
        'localDate': localDate,
        if (kcal != null) 'kcal': double.parse(kcal!.toStringAsFixed(0)),
        if (proteinG != null)
          'proteinG': double.parse(proteinG!.toStringAsFixed(0)),
        if (carbsG != null) 'carbsG': double.parse(carbsG!.toStringAsFixed(0)),
        if (fatG != null) 'fatG': double.parse(fatG!.toStringAsFixed(0)),
        'recorded': recorded,
      };
}

/// The floors this body is measured against, when it lifts.
///
/// Sent only when there is strength work in the record: the floors exist
/// because resistance training raises the protein a body can use, and pressing
/// them on somebody who does not lift is dietary advice nobody asked for.
class AetherMacroFloors {
  const AetherMacroFloors({
    required this.proteinG,
    required this.fatG,
    required this.shortfallDays,
    required this.recordedDays,
    required this.lean,
    this.carbHeavyWithLowProtein = false,
  });

  final int proteinG;
  final int fatG;

  /// Counted over recorded days only — a day nobody logged has not missed
  /// anything.
  final int shortfallDays;
  final int recordedDays;

  /// Whether recent days fell short often enough to be worth saying firmly.
  final bool lean;

  /// The only opening for a sentence about carbohydrate: a recorded day that
  /// was very nearly all of it, on which protein also came in under its floor.
  /// Carbohydrate is otherwise counted and never commented on.
  final bool carbHeavyWithLowProtein;

  Map<String, Object?> toJson() => {
        'proteinG': proteinG,
        'fatG': fatG,
        'shortfallDays': shortfallDays,
        'recordedDays': recordedDays,
        'lean': lean,
        'carbHeavyWithLowProtein': carbHeavyWithLowProtein,
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
    this.intake = const [],
    this.macroFloors,
    this.digests = const [],
    this.patterns = const [],
    this.lifestyle = const [],
    this.recalled = const [],
    this.bodyFatPercent,
    this.journalTruncated = false,
    this.leansSymbolic = false,
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

  /// What was eaten over the window, newest last. Empty when nothing was
  /// logged at all, which the prompt is told to read as silence.
  final List<AetherIntakeContext> intake;

  /// The protein and fat floors, when there is strength work to justify them.
  /// Null otherwise, and the prompt then says nothing about macronutrients.
  final AetherMacroFloors? macroFloors;

  /// Whether the sky is the louder half tonight.
  ///
  /// True in the immersive register, and in balanced once the sun is down.
  /// Guidance read as health reporting even on immersive, and the reason was
  /// not the stated proportions: the symbolic half arrived as a single
  /// sentence while the measured half arrived as a table. A model cannot
  /// weight what it was not given, so when this is set the day's sky travels
  /// as prose rather than as a note, and the proportions move with it.
  final bool leansSymbolic;

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
  final List<AetherPatternContext> patterns;

  /// What the person said about the inside of their days — the margin's
  /// check-in, and whatever their pages reported about mood, energy, focus,
  /// meaning or what they are carrying.
  final List<AetherLifestyleContext> lifestyle;

  /// The fortnight behind today, as Aether's own compressed notes, oldest
  /// first and never including today.
  ///
  /// Guidance composed every morning as though it had never spoken to this
  /// person: it could repeat yesterday's observation, contradict Tuesday, and
  /// re-offer an action already declined four times. This is the thread.
  final List<AetherRecallContext> recalled;

  /// At least one journal passage was cut to fit the character budget.
  ///
  /// Stated to the model rather than hidden, because a passage that stops
  /// mid-sentence reads as a complete thought that trailed off, and it is not.
  final bool journalTruncated;

  /// Optional, 5–40. Present only when the person supplied it.
  final double? bodyFatPercent;

  Map<String, Object> toJson() => {
        'schemaVersion': schemaVersion,
        'mode': mode.name,
        'ageYears': ageYears,
        if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent!,
        'health': health.map((item) => item.toJson()).toList(),
        if (intake.isNotEmpty)
          'intake': intake.map((item) => item.toJson()).toList(),
        if (macroFloors != null) 'macroFloors': macroFloors!.toJson(),
        if (symbolic != null) 'symbolic': symbolic!.toJson(),
        if (digests.isNotEmpty)
          'journalDigests': digests.map((item) => item.toJson()).toList(),
        if (patterns.isNotEmpty)
          'patterns': patterns.map((item) => item.toJson()).toList(),
        if (lifestyle.isNotEmpty)
          'selfReports': lifestyle.map((item) => item.toJson()).toList(),
        if (recalled.isNotEmpty)
          'recalled': recalled.map((item) => item.toJson()).toList(),
        'journal': journal,
        if (journalTruncated) 'journalTruncated': true,
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
    this.maxRecalledDays = 14,
    this.maxRecallCharacters = 160,
  });

  final int maxJournalEntries;
  final int maxJournalCharacters;

  /// A fortnight. Long enough to hold a stretch of days rather than a mood,
  /// short enough that the notes never outweigh the records they are about.
  final int maxRecalledDays;
  final int maxRecallCharacters;

  AetherRequest build({
    required bool aiConsented,
    required bool journalConsented,
    required int ageYears,
    required GuidanceMode mode,
    required List<AetherHealthContext> health,
    bool leansSymbolic = false,
    List<AetherJournalContext> journal = const [],
    AetherSymbolicContext? symbolic,
    List<AetherJournalDigest> digests = const [],
    List<AetherPatternContext> patterns = const [],
    List<AetherLifestyleContext> lifestyle = const [],
    List<AetherRecallContext> recalled = const [],
    List<AetherIntakeContext> intake = const [],
    AetherMacroFloors? macroFloors,
    double? bodyFatPercent,
  }) {
    if (!aiConsented) {
      throw const AetherConsentException('AI processing is not permitted');
    }
    if (ageYears < 16) {
      throw const AetherConsentException('Aether requires age 16 or older');
    }

    final prose = <Map<String, Object>>[];
    var truncated = false;
    if (journalConsented) {
      var remaining = maxJournalCharacters;
      for (final entry in journal.where((item) => !item.excludedFromAi)) {
        if (prose.length >= maxJournalEntries || remaining <= 0) break;
        final normalized = entry.text.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (normalized.isEmpty) continue;
        final cut = _fit(normalized, remaining);
        if (cut.text.isEmpty) break;
        if (cut.truncated) truncated = true;
        prose.add({
          'createdAt': entry.createdAt.toUtc().toIso8601String(),
          'text': cut.text,
          if (cut.truncated) 'truncated': true,
        });
        remaining -= cut.text.length;
      }
    }

    // Four at most, strongest first, and short. A finding that needs a
    // paragraph is not a finding.
    final bounded = ([
      for (final pattern in patterns)
        if (pattern.summary.trim().isNotEmpty)
          AetherPatternContext(
            summary: pattern.summary.trim(),
            confidence: pattern.confidence,
            observations: pattern.observations,
            window: pattern.window,
          ),
    ]..sort((a, b) => b.confidence.compareTo(a.confidence)))
        .take(4)
        .toList();

    // Digests are journal-derived, so they cross only under the same consent
    // the prose itself needs.
    final digestPayload = journalConsented ? digests : const <AetherJournalDigest>[];

    // A margin check-in is a self-report the person entered directly; one
    // derived from a page is prose in another shape. Only the first crosses
    // on general AI consent.
    final reports = [
      for (final item in lifestyle)
        if (journalConsented || !item.fromJournal) item,
    ];

    // A fortnight, newest last, each line short. The store already withholds
    // notes that journal consent no longer covers; this bounds what is left.
    final memory = [
      for (final item in recalled.length > maxRecalledDays
          ? recalled.sublist(recalled.length - maxRecalledDays)
          : recalled)
        if (item.note.trim().isNotEmpty)
          AetherRecallContext(
            localDate: item.localDate,
            note: _clip(item.note.trim(), maxRecallCharacters),
            action: item.action?.trim().isEmpty ?? true
                ? null
                : _clip(item.action!.trim(), maxRecallCharacters),
          ),
    ];

    final stableContext = <String, Object>{
      'schemaVersion': 2,
      'mode': mode.name,
      'ageYears': ageYears,
      if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent,
      'health': health.map((item) => item.toJson()).toList(),
      // In the fingerprint: confirming a meal changes what the day is working
      // from, so it should recompose rather than be noticed tomorrow.
      'intake': intake.map((item) => item.toJson()).toList(),
      if (macroFloors != null) 'macroFloors': macroFloors.toJson(),
      if (symbolic != null) 'symbolic': symbolic.toJson(),
      'journalDigests': digestPayload.map((item) => item.toJson()).toList(),
      'journal': prose,
      // In the fingerprint, so a newly discovered pattern is itself a reason
      // to recompose rather than something guidance learns about tomorrow.
      'patterns': bounded.map((item) => item.toJson()).toList(),
      // Likewise a check-in: answering the margin should change the day's
      // reading, not wait for tomorrow's.
      'selfReports': reports.map((item) => item.toJson()).toList(),
      // In the fingerprint too: yesterday's note is a reason to say something
      // different today, which is the entire point of keeping it.
      'recalled': memory.map((item) => item.toJson()).toList(),
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
      lifestyle: List.unmodifiable(reports),
      recalled: List.unmodifiable(memory),
      // Days with nothing logged are dropped rather than sent as empty rows.
      // A silent day is silence, and a row of nulls invites the model to read
      // it as a day of nothing eaten.
      intake: List.unmodifiable(
        intake.where((day) => day.recorded).toList(),
      ),
      macroFloors: macroFloors,
      bodyFatPercent: bodyFatPercent,
      journalTruncated: truncated,
      leansSymbolic: leansSymbolic,
      contextFingerprint: _fnv1a64(jsonEncode(stableContext)),
    );
  }

  /// A hard ceiling on a stored line, in case an older row predates the
  /// schema's own bound.
  String _clip(String text, int limit) =>
      text.length <= limit ? text : text.substring(0, limit);

  /// Fits [text] into [budget] characters without cutting a word in half.
  ///
  /// The old behaviour was `substring(0, budget)`, which handed the model a
  /// passage ending mid-word and told it nothing — so a sentence that was cut
  /// read as a thought the person had abandoned. This backs up to the last
  /// space and marks the cut, and the prompt says a marked passage is
  /// incomplete.
  ({String text, bool truncated}) _fit(String text, int budget) {
    if (text.length <= budget) return (text: text, truncated: false);
    // One character for the marker, which has to fit inside the budget too.
    final room = budget - 1;
    if (room <= 0) return (text: '', truncated: false);
    final head = text.substring(0, room);
    final lastSpace = head.lastIndexOf(' ');
    // Roughly a clause. Below that the remnant says nothing and reads as
    // though the person trailed off, so the entry is dropped instead — and
    // the caller stops adding entries rather than sending shards of them.
    if (lastSpace < 40) return (text: '', truncated: false);
    return (text: '${head.substring(0, lastSpace)}…', truncated: true);
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
