import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/journal/day_story.dart';
import 'package:flutter_test/flutter_test.dart';

/// The day story writes to the database and is made of the person's own prose,
/// which makes it the one composer where consent, the cache and the parser's
/// bounds all have to hold at once.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<void> profile({
    bool aiConsent = true,
    bool journalConsent = true,
  }) =>
      database.saveProfile(ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'other',
        weightKg: 70,
        units: 'metric',
        firstName: const Value('Private name'),
        aiConsentAt:
            Value(aiConsent ? DateTime.utc(2026, 7, 1) : null),
        journalAiConsentAt:
            Value(journalConsent ? DateTime.utc(2026, 7, 1) : null),
      ));

  Future<void> entry(
    String text, {
    required DateTime at,
    bool excludedFromAi = false,
    String status = 'classified',
  }) =>
      database.addJournalEntry(JournalEntriesCompanion.insert(
        createdAt: at,
        entryText: text,
        status: Value(status),
        excludedFromAi: Value(excludedFromAi),
      ));

  final day = DateTime(2026, 7, 28);
  final now = DateTime.utc(2026, 7, 28, 20);

  group('consent', () {
    test('refuses without AI consent', () async {
      await profile(aiConsent: false);
      await entry('Walked to the river.', at: DateTime(2026, 7, 28, 9));
      final provider = _Provider();

      await expectLater(
        JournalDayStoryComposer(database: database, provider: provider)
            .refresh(day: day, now: now),
        throwsA(isA<JournalDayStoryException>()),
      );
      expect(provider.calls, 0);
    });

    test('refuses with AI consent but without journal consent', () async {
      await profile(journalConsent: false);
      await entry('Walked to the river.', at: DateTime(2026, 7, 28, 9));
      final provider = _Provider();

      await expectLater(
        JournalDayStoryComposer(database: database, provider: provider)
            .refresh(day: day, now: now),
        throwsA(isA<JournalDayStoryException>()),
      );
      expect(provider.calls, 0);
    });

    test('refuses when there is no profile at all', () async {
      final provider = _Provider();
      await expectLater(
        JournalDayStoryComposer(database: database, provider: provider)
            .refresh(day: day, now: now),
        throwsA(isA<JournalDayStoryException>()),
      );
      expect(provider.calls, 0);
    });
  });

  group('what reaches the provider', () {
    test('excluded and empty entries are not part of the day', () async {
      await profile();
      await entry('Kept in.', at: DateTime(2026, 7, 28, 8), excludedFromAi: true);
      await entry('   ', at: DateTime(2026, 7, 28, 9));
      await entry('Ran six kilometres.', at: DateTime(2026, 7, 28, 10));
      final provider = _Provider();

      await JournalDayStoryComposer(database: database, provider: provider)
          .refresh(day: day, now: now);

      final sent = jsonEncode(provider.lastRequest!.context);
      expect(sent, contains('Ran six kilometres'));
      expect(sent, isNot(contains('Kept in')));
      expect(sent, isNot(contains('Private name')));
    });

    test('a day with nothing usable calls no provider and stores nothing',
        () async {
      await profile();
      await entry('Kept in.', at: DateTime(2026, 7, 28, 8), excludedFromAi: true);
      final provider = _Provider();

      final result =
          await JournalDayStoryComposer(database: database, provider: provider)
              .refresh(day: day, now: now);

      expect(provider.calls, 0);
      expect(result.row, isNull);
      expect(result.fromCache, isTrue);
      expect(await database.loadDayStory('2026-07-28'), isNull);
    });

    test('yesterday and tomorrow are not this day', () async {
      await profile();
      await entry('Yesterday.', at: DateTime(2026, 7, 27, 23, 59));
      await entry('Today.', at: DateTime(2026, 7, 28, 0, 1));
      await entry('Tomorrow.', at: DateTime(2026, 7, 29, 0, 1));
      final provider = _Provider();

      await JournalDayStoryComposer(database: database, provider: provider)
          .refresh(day: day, now: now);

      final sent = jsonEncode(provider.lastRequest!.context);
      expect(sent, contains('Today.'));
      expect(sent, isNot(contains('Yesterday.')));
      expect(sent, isNot(contains('Tomorrow.')));
    });
  });

  group('the fingerprint cache', () {
    test('an unchanged day is not recomposed', () async {
      await profile();
      await entry('Slept badly.', at: DateTime(2026, 7, 28, 7));
      final provider = _Provider();
      final composer =
          JournalDayStoryComposer(database: database, provider: provider);

      final first = await composer.refresh(day: day, now: now);
      final second = await composer.refresh(day: day, now: now);

      expect(provider.calls, 1);
      expect(first.fromCache, isFalse);
      expect(second.fromCache, isTrue);
      expect(second.row!.story, first.row!.story);
    });

    test('a new entry recomposes', () async {
      await profile();
      await entry('Slept badly.', at: DateTime(2026, 7, 28, 7));
      final provider = _Provider();
      final composer =
          JournalDayStoryComposer(database: database, provider: provider);

      await composer.refresh(day: day, now: now);
      await entry('Then the day turned.', at: DateTime(2026, 7, 28, 18));
      final again = await composer.refresh(day: day, now: now);

      expect(provider.calls, 2);
      expect(again.fromCache, isFalse);
      expect(again.row!.entryCount, 2);
    });

    test('excluding an entry afterwards recomposes the day without it',
        () async {
      await profile();
      await entry('Kept.', at: DateTime(2026, 7, 28, 7));
      final id =
          await database.addJournalEntry(JournalEntriesCompanion.insert(
        createdAt: DateTime(2026, 7, 28, 8),
        entryText: 'Withdrawn later.',
        status: const Value('classified'),
      ));
      final provider = _Provider();
      final composer =
          JournalDayStoryComposer(database: database, provider: provider);

      final first = await composer.refresh(day: day, now: now);
      await database.setJournalExcludedFromAi(id, true);
      final second = await composer.refresh(day: day, now: now);

      expect(provider.calls, 2);
      expect(second.row!.entryCount, 1);
      expect(
        second.row!.sourceFingerprint,
        isNot(first.row!.sourceFingerprint),
      );
      expect(
        jsonEncode(provider.lastRequest!.context),
        isNot(contains('Withdrawn later')),
      );
    });

    test('a stored story from another day is not reused', () async {
      await profile();
      await entry('Today.', at: DateTime(2026, 7, 28, 9));
      await entry('Yesterday.', at: DateTime(2026, 7, 27, 9));
      final provider = _Provider();
      final composer =
          JournalDayStoryComposer(database: database, provider: provider);

      await composer.refresh(day: day, now: now);
      await composer.refresh(day: DateTime(2026, 7, 27), now: now);

      expect(provider.calls, 2);
      expect(await database.loadDayStory('2026-07-27'), isNotNull);
      expect(await database.loadDayStory('2026-07-28'), isNotNull);
    });
  });

  group('the parser', () {
    const parser = JournalDayStoryParser();

    void rejects(String raw) => expect(
          () => parser.parse(raw),
          throwsA(isA<JournalDayStoryException>()),
          reason: raw,
        );

    test('accepts a well-formed story and digest', () {
      final parsed = parser.parse(jsonEncode({
        'story': 'The day began slowly and then found its footing.',
        'digest': {
          'movement': 'a long walk',
          'mood': '  steady  ',
          'notable': ['a deadline', '  ', 'a cold'],
        },
      }));

      expect(parsed.story, 'The day began slowly and then found its footing.');
      expect(parsed.digest.movement, 'a long walk');
      expect(parsed.digest.mood, 'steady');
      expect(parsed.digest.notable, ['a deadline', 'a cold']);
      expect(parsed.digest.food, isNull);
      expect(parsed.digest.isEmpty, isFalse);
    });

    test('an empty digest is empty rather than absent', () {
      final parsed = parser.parse(
        jsonEncode({'story': 'A quiet day.', 'digest': <String, Object?>{}}),
      );
      expect(parsed.digest.isEmpty, isTrue);
      expect(parsed.digest.toJson(), isEmpty);
    });

    test('rejects malformed, empty, oversized and unexpected shapes', () {
      rejects('not json at all');
      rejects('[]');
      rejects(jsonEncode({'digest': <String, Object?>{}}));
      rejects(jsonEncode({'story': '   ', 'digest': <String, Object?>{}}));
      rejects(jsonEncode({'story': 'A day.'}));
      rejects(jsonEncode({'story': 'A day.', 'digest': 'prose'}));
      rejects(jsonEncode({
        'story': 'A' * 701,
        'digest': <String, Object?>{},
      }));
      rejects(jsonEncode({
        'story': 'A day.',
        'digest': {'diagnosis': 'anaemia'},
      }));
      rejects(jsonEncode({
        'story': 'A day.',
        'digest': {'notable': ['one', 'two', 'three', 'four']},
      }));
      rejects(jsonEncode({
        'story': 'A day.',
        'digest': {'notable': 'a deadline'},
      }));
      rejects(jsonEncode({
        'story': 'A day.',
        'digest': {'notable': [1, 2]},
      }));
      rejects(jsonEncode({
        'story': 'A day.',
        'digest': {'mood': 'x' * 161},
      }));
      rejects(jsonEncode({
        'story': 'A day.',
        'digest': {'mood': 7},
      }));
    });

    test('a rejected response writes nothing', () async {
      await profile();
      await entry('Slept badly.', at: DateTime(2026, 7, 28, 7));

      await expectLater(
        JournalDayStoryComposer(
          database: database,
          provider: _Provider(raw: 'not json at all'),
        ).refresh(day: day, now: now),
        throwsA(isA<JournalDayStoryException>()),
      );
      expect(await database.loadDayStory('2026-07-28'), isNull);
    });
  });

  test('the stored row carries the digest, the model and the count', () async {
    await profile();
    await entry('Ran, then ate well.', at: DateTime(2026, 7, 28, 9));

    final result = await JournalDayStoryComposer(
      database: database,
      provider: _Provider(),
      model: 'test-model',
    ).refresh(day: day, now: now);

    final row = result.row!;
    expect(row.date, '2026-07-28');
    expect(row.model, 'test-model');
    expect(row.entryCount, 1);
    expect(row.generatedAt, now);
    expect(
      JournalDayDigest.fromJson(
        jsonDecode(row.digestJson) as Map<String, Object?>,
      ).movement,
      'a run',
    );
  });
}

class _Provider implements JournalDayStoryProvider {
  _Provider({this.raw});

  final String? raw;
  int calls = 0;
  JournalDayStoryProviderRequest? lastRequest;

  @override
  Future<String> compose(JournalDayStoryProviderRequest request) async {
    calls += 1;
    lastRequest = request;
    return raw ??
        jsonEncode({
          'story': 'The day held together.',
          'digest': {'movement': 'a run'},
        });
  }
}
