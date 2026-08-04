import 'dart:convert';

import '../db/app_database.dart';
import '../i18n/language.dart';
import 'body_commit.dart';
import 'classification_contract.dart';

class JournalClassificationConsentException implements Exception {
  const JournalClassificationConsentException(this.reason);
  final String reason;
}

class JournalClassifier {
  const JournalClassifier({
    required this.database,
    required this.provider,
    this.parser = const JournalClassificationParser(),
    this.model = 'provider',
  });

  final AppDatabase database;
  final JournalClassificationProvider provider;
  final JournalClassificationParser parser;
  final String model;

  Future<JournalClassificationOutcome> classify(
    int journalEntryId, {
    String? clarification,
  }) async {
    final profile = await database.loadProfile();
    if (profile?.aiConsentAt == null) {
      throw const JournalClassificationConsentException(
        'AI processing is not permitted',
      );
    }
    final entry = await database.loadJournalEntry(journalEntryId);
    if (entry == null || entry.status == 'discarded') {
      throw const JournalClassificationException(
        'Journal entry is not available',
      );
    }
    if (entry.appliedAt != null && entry.extractionJson != null) {
      return JournalClassificationOutcome(
        classification: parser.parse(entry.extractionJson!),
      );
    }

    final raw = await provider.classify(JournalClassificationRequest(
      text: entry.entryText,
      source: entry.source,
      responseSchema: journalClassificationSchema,
      language: AppLanguage.forProfile(profile?.language),
      clarification:
          clarification?.trim().isEmpty == true ? null : clarification?.trim(),
      // What an energy estimate is made against. Absent fields are omitted
      // rather than defaulted — see `JournalBodyContext`.
      body: JournalBodyContext(
        weightKg: profile?.weightKg,
        heightCm: profile?.heightCm,
        bodyFatPercent: profile?.bodyFatPercent,
        ageYears: profile == null ? null : _ageYears(profile.dob, DateTime.now()),
        sex: profile?.sex,
      ),
    ));
    final result = parser.parse(raw);
    final alreadyApplied =
        (await database.loadJournalEntry(journalEntryId))?.appliedAt != null;
    await database.applyJournalClassification(
      entry: entry,
      status: result.status,
      extractionJson: jsonEncode(result.toJson()),
      model: model,
      food: result.food,
      lifestyle: result.lifestyle,
    );

    // Weight, activity and strength go through their own services, which own
    // the arithmetic that keeps the day's totals consistent no matter which
    // surface recorded the work. Guarded on the entry not having been applied
    // before, so a retry cannot log the same run twice.
    final body = result.status == 'classified' && !alreadyApplied
        ? await JournalBodyCommitter(database).commit(
            classification: result,
            recordedAt: entry.createdAt,
          )
        : null;
    return JournalClassificationOutcome(classification: result, body: body);
  }
}

/// What one interpretation produced: the reading itself, and — when it named
/// weight, activity or strength — what reached the body log.
class JournalClassificationOutcome {
  const JournalClassificationOutcome({required this.classification, this.body});

  final JournalClassification classification;

  /// Null when nothing was committed through the body services, either because
  /// the page named none of them or because it had already been applied.
  final JournalBodyCommitResult? body;
}

/// Whole years, from a date of birth that never leaves the device.
///
/// The same shape guidance uses: an age crosses the boundary as a number and a
/// date of birth does not.
int _ageYears(DateTime dob, DateTime on) {
  var age = on.year - dob.year;
  if (on.month < dob.month || (on.month == dob.month && on.day < dob.day)) {
    age -= 1;
  }
  return age;
}
