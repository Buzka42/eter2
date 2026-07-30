import 'dart:convert';

import 'package:drift/drift.dart';

import '../ai/prompts.dart';
import '../clock.dart';
import '../db/app_database.dart';
import '../i18n/language.dart';

/// The day, read back to the person — and the same day, compressed for Aether.
///
/// One pass over everything written on a local day produces two things:
///
/// * a **story**: a few sentences of continuous prose the Journal always
///   shows. It is not advice and not a summary of achievements. It is the day
///   as its own pages tell it.
/// * a **digest**: the few structured points guidance actually needs. Guidance
///   sends this instead of the raw prose, which is what keeps the request
///   bounded however much someone writes — a person who journals two thousand
///   words a day costs the same as one who writes forty.
///
/// The digest is deliberately small and deliberately typed. It is not a
/// summary in prose; it is the handful of facts a body-and-attention companion
/// can act on.
class JournalDayDigest {
  const JournalDayDigest({
    this.movement,
    this.food,
    this.mood,
    this.energy,
    this.sleep,
    this.notable = const [],
  });

  /// What the person recorded doing with their body, in a few words.
  final String? movement;

  /// What they recorded eating, in a few words. Never an estimate — the
  /// estimates come from interpretation, which is a separate, reviewed path.
  final String? food;

  /// The day's felt state, in a few words.
  final String? mood;

  /// How they described their energy.
  final String? energy;

  /// What they said about sleeping, as distinct from what a watch measured.
  final String? sleep;

  /// At most three short phrases for anything else that would change what a
  /// reasonable companion said today — a deadline, an illness, a loss.
  final List<String> notable;

  bool get isEmpty =>
      movement == null &&
      food == null &&
      mood == null &&
      energy == null &&
      sleep == null &&
      notable.isEmpty;

  Map<String, Object?> toJson() => {
        if (movement != null) 'movement': movement,
        if (food != null) 'food': food,
        if (mood != null) 'mood': mood,
        if (energy != null) 'energy': energy,
        if (sleep != null) 'sleep': sleep,
        if (notable.isNotEmpty) 'notable': notable,
      };

  static JournalDayDigest fromJson(Map<String, Object?> json) =>
      JournalDayDigest(
        movement: _text(json['movement']),
        food: _text(json['food']),
        mood: _text(json['mood']),
        energy: _text(json['energy']),
        sleep: _text(json['sleep']),
        notable: [
          for (final item in (json['notable'] as List<Object?>? ?? const []))
            if (item is String && item.trim().isNotEmpty) item.trim(),
        ],
      );

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class JournalDayStory {
  const JournalDayStory({required this.story, required this.digest});

  final String story;
  final JournalDayDigest digest;
}

class JournalDayStoryException implements Exception {
  const JournalDayStoryException(this.reason);
  final String reason;

  @override
  String toString() => reason;
}

/// Validates provider output before any of it is stored.
class JournalDayStoryParser {
  const JournalDayStoryParser({this.maxStoryCharacters = 700});

  final int maxStoryCharacters;

  static const _digestFields = {
    'movement',
    'food',
    'mood',
    'energy',
    'sleep',
    'notable',
  };

  JournalDayStory parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const JournalDayStoryException('Response is not JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const JournalDayStoryException('Response must be an object');
    }
    final story = decoded['story'];
    final digest = decoded['digest'];
    if (story is! String || story.trim().isEmpty) {
      throw const JournalDayStoryException('A story is required');
    }
    if (story.trim().length > maxStoryCharacters) {
      throw const JournalDayStoryException('The story is not a few sentences');
    }
    if (digest is! Map<String, dynamic>) {
      throw const JournalDayStoryException('A digest object is required');
    }
    if (digest.keys.toSet().difference(_digestFields).isNotEmpty) {
      throw const JournalDayStoryException('The digest carries unknown fields');
    }
    final notable = digest['notable'];
    if (notable != null &&
        (notable is! List ||
            notable.length > 3 ||
            notable.any((item) => item is! String))) {
      throw const JournalDayStoryException(
        'Notable points must be at most three short phrases',
      );
    }
    for (final key in _digestFields.where((key) => key != 'notable')) {
      final value = digest[key];
      if (value != null && (value is! String || value.length > 160)) {
        throw JournalDayStoryException('Digest field $key must be a phrase');
      }
    }
    return JournalDayStory(
      story: story.trim(),
      digest: JournalDayDigest.fromJson(digest),
    );
  }
}

abstract interface class JournalDayStoryProvider {
  Future<String> compose(JournalDayStoryProviderRequest request);
}

class JournalDayStoryProviderRequest {
  const JournalDayStoryProviderRequest({
    required this.system,
    required this.context,
    required this.responseSchema,
  });

  final String system;
  final Map<String, Object?> context;
  final Map<String, Object?> responseSchema;
}

class JournalDayStoryResult {
  const JournalDayStoryResult({required this.row, required this.fromCache});

  final JournalDayStoryRow? row;
  final bool fromCache;
}

/// Keeps one story per local day current with what was written that day.
///
/// Called when the Journal opens and again whenever an entry is saved. The
/// source fingerprint makes both cheap: if the day's prose has not changed
/// since the stored story was written, no provider call happens at all.
class JournalDayStoryComposer {
  const JournalDayStoryComposer({
    required this.database,
    required this.provider,
    this.parser = const JournalDayStoryParser(),
    this.model = 'provider',
  });

  final AppDatabase database;
  final JournalDayStoryProvider provider;
  final JournalDayStoryParser parser;
  final String model;

  /// Recomposes [day]'s story if the day's prose has changed.
  ///
  /// Returns the current row either way. A day with no entries has no story
  /// and any stale one is removed, so an emptied day does not keep narrating
  /// itself.
  Future<JournalDayStoryResult> refresh({
    required DateTime day,
    required DateTime now,
  }) async {
    final profile = await database.loadProfile();
    if (profile?.aiConsentAt == null ||
        profile?.journalAiConsentAt == null) {
      // The story is made of the person's own prose, so it needs the same
      // consent that lets prose cross the boundary at all.
      throw const JournalDayStoryException(
        'Journal-aware guidance is not permitted',
      );
    }

    final date = eterIsoDate(day);
    final (dayStart, dayEnd) = eterDayBounds(day);
    final entries = await database.loadJournalForRange(dayStart, dayEnd);
    final usable = [
      for (final entry in entries)
        if (!entry.excludedFromAi && entry.entryText.trim().isNotEmpty) entry,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final existing = await database.loadDayStory(date);
    if (usable.isEmpty) {
      return JournalDayStoryResult(row: existing, fromCache: true);
    }

    final fingerprint = _fingerprint(usable.map((row) => row.entryText));
    if (existing != null && existing.sourceFingerprint == fingerprint) {
      return JournalDayStoryResult(row: existing, fromCache: true);
    }

    final prompt = EterPrompts.journalDayStory(
      date: date,
      entries: [
        for (final entry in usable)
          (at: entry.createdAt.toLocal(), text: entry.entryText.trim()),
      ],
      language: AppLanguage.forProfile(
        (await database.loadProfile())?.language,
      ),
    );
    final raw = await provider.compose(JournalDayStoryProviderRequest(
      system: prompt.system,
      context: prompt.user,
      responseSchema: prompt.responseSchema,
    ));
    final parsed = parser.parse(raw);

    await database.saveDayStory(JournalDayStoriesCompanion.insert(
      date: date,
      generatedAt: now.toUtc(),
      story: parsed.story,
      digestJson: Value(jsonEncode(parsed.digest.toJson())),
      entryCount: Value(usable.length),
      sourceFingerprint: fingerprint,
      model: Value(model),
      promptVersion: const Value(EterPrompts.version),
    ));
    return JournalDayStoryResult(
      row: await database.loadDayStory(date),
      fromCache: false,
    );
  }

  /// FNV-1a over the day's prose, in order. The same text always produces the
  /// same story request, and any edit produces a different one.
  String _fingerprint(Iterable<String> texts) {
    var hash = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = BigInt.parse('ffffffffffffffff', radix: 16);
    for (final byte in utf8.encode(texts.join(' '))) {
      hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
