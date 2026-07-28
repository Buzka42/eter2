import 'dart:convert';

import '../db/app_database.dart';
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

  Future<JournalClassification> classify(int journalEntryId) async {
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
      return parser.parse(entry.extractionJson!);
    }

    final raw = await provider.classify(JournalClassificationRequest(
      text: entry.entryText,
      source: entry.source,
      responseSchema: journalClassificationSchema,
    ));
    final result = parser.parse(raw);
    await database.applyJournalClassification(
      entry: entry,
      status: result.status,
      extractionJson: jsonEncode(result.toJson()),
      model: model,
      food: result.food,
      lifestyle: result.lifestyle,
    );
    return result;
  }
}
