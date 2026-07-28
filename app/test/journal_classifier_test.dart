import 'dart:convert';

import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/journal/classification_contract.dart';
import 'package:eter/core/journal/classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'other',
        weightKg: 70,
        units: 'metric',
      ),
    );
  });
  tearDown(() => database.close());

  Future<int> entry() => database.addJournalEntry(
        JournalEntriesCompanion.insert(
          createdAt: DateTime.utc(2026, 7, 28, 12),
          entryText: 'Lunch was a chicken sandwich. Meditated for 10 minutes.',
        ),
      );

  test('classification requires current AI consent', () async {
    final id = await entry();
    final classifier = JournalClassifier(
      database: database,
      provider: _FakeProvider(_classifiedResponse()),
    );

    await expectLater(
      classifier.classify(id),
      throwsA(isA<JournalClassificationConsentException>()),
    );
    expect(classifier.provider, isA<_FakeProvider>());
    expect((classifier.provider as _FakeProvider).calls, 0);
  });

  test('food estimates stay unconfirmed and classification is replay-safe',
      () async {
    await database.updateProfileConsents(aiAllowed: true);
    final id = await entry();
    final provider = _FakeProvider(_classifiedResponse());
    final classifier = JournalClassifier(
      database: database,
      provider: provider,
      model: 'test-model',
    );

    await classifier.classify(id);
    await classifier.classify(id);

    final nutrition = await database
        .watchNutritionForRange(
          DateTime.utc(2026, 7, 28),
          DateTime.utc(2026, 7, 29),
        )
        .first;
    final lifestyle = await database.loadLifestyleRange(
      DateTime.utc(2026, 7, 28),
      DateTime.utc(2026, 7, 29),
    );
    final journal = await database.loadJournalEntry(id);

    expect(provider.calls, 1);
    expect(nutrition, hasLength(1));
    expect(nutrition.single.confirmed, isFalse);
    expect(
      await database.intakeKcalForRange(
        DateTime.utc(2026, 7, 28),
        DateTime.utc(2026, 7, 29),
      ),
      0,
    );
    expect(lifestyle.single.kind, 'meditation');
    expect(journal!.status, 'classified');
    expect(journal.appliedAt, isNotNull);
  });

  test('needs-detail creates no records and can be retried after correction',
      () async {
    await database.updateProfileConsents(aiAllowed: true);
    final id = await entry();
    final provider = _FakeProvider(jsonEncode({
      'status': 'needsDetail',
      'food': [],
      'lifestyle': [],
      'clarifyingQuestion': 'How large was the sandwich?',
    }));
    final classifier = JournalClassifier(
      database: database,
      provider: provider,
    );

    final result = await classifier.classify(id);
    final journal = await database.loadJournalEntry(id);

    expect(result.classification.status, 'needsDetail');
    expect(result.body, isNull);
    expect(journal!.appliedAt, isNull);
    expect(
      await database
          .watchNutritionForRange(
            DateTime.utc(2026, 7, 28),
            DateTime.utc(2026, 7, 29),
          )
          .first,
      isEmpty,
    );
  });

  test('passes a clarification separately from the source prose', () async {
    await database.updateProfileConsents(aiAllowed: true);
    final id = await entry();
    final provider = _FakeProvider(_classifiedResponse());
    final classifier = JournalClassifier(
      database: database,
      provider: provider,
    );

    await classifier.classify(
      id,
      clarification: 'It was a large sandwich.',
    );

    expect(provider.lastRequest?.text,
        'Lunch was a chicken sandwich. Meditated for 10 minutes.');
    expect(provider.lastRequest?.clarification, 'It was a large sandwich.');
  });

  test('invalid estimates write no partial state', () async {
    await database.updateProfileConsents(aiAllowed: true);
    final id = await entry();
    final classifier = JournalClassifier(
      database: database,
      provider: _FakeProvider(_classifiedResponse(kcal: 9000)),
    );

    await expectLater(
      classifier.classify(id),
      throwsA(isA<JournalClassificationException>()),
    );
    expect((await database.loadJournalEntry(id))!.status, 'pending');
  });
}

String _classifiedResponse({double kcal = 440}) => jsonEncode({
      'status': 'classified',
      'food': [
        {
          'meal': 'Chicken sandwich',
          'kcal': kcal,
          'proteinG': 31,
          'carbsG': 42,
          'fatG': 14,
          'confidence': 0.62,
          'assumptions': ['One standard sandwich'],
        },
      ],
      'lifestyle': [
        {
          'kind': 'meditation',
          'durationMinutes': 10,
          'note': null,
        },
      ],
      'clarifyingQuestion': null,
    });

class _FakeProvider implements JournalClassificationProvider {
  _FakeProvider(this.response);
  final String response;
  int calls = 0;
  JournalClassificationRequest? lastRequest;

  @override
  Future<String> classify(JournalClassificationRequest request) async {
    calls += 1;
    lastRequest = request;
    return response;
  }
}
