import 'dart:convert';

import 'package:eter/core/i18n/language.dart';
import 'package:eter/core/aether/guidance_contract.dart';
import 'package:eter/core/aether/guidance_mode.dart';
import 'package:eter/core/aether/request_contract.dart';
import 'package:eter/core/aether/safety_policy.dart';
import 'package:eter/core/ai/prompts.dart';
import 'package:eter/core/aether/composer.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Aether request boundary', () {
    const builder = AetherRequestBuilder(
      maxJournalEntries: 2,
      maxJournalCharacters: 12,
    );

    test('requires AI consent', () {
      expect(
        () => builder.build(
          aiConsented: false,
          journalConsented: false,
          ageYears: 30,
          mode: GuidanceMode.balanced,
          health: const [],
        ),
        throwsA(isA<AetherConsentException>()),
      );
    });

    test('journal needs separate consent and excluded prose never leaves', () {
      final entries = [
        AetherJournalContext(
          createdAt: DateTime.utc(2026, 7, 28),
          text: 'private words',
          excludedFromAi: true,
        ),
        AetherJournalContext(
          createdAt: DateTime.utc(2026, 7, 27),
          text: 'allowed journal text',
        ),
      ];
      final withoutJournal = builder.build(
        aiConsented: true,
        journalConsented: false,
        ageYears: 30,
        mode: GuidanceMode.grounded,
        health: const [],
        journal: entries,
      );
      expect(withoutJournal.journal, isEmpty);

      final withJournal = builder.build(
        aiConsented: true,
        journalConsented: true,
        ageYears: 30,
        mode: GuidanceMode.grounded,
        health: const [],
        journal: entries,
      );
      // Twelve characters cannot hold a clause, so nothing is sent rather
      // than 'allowed jour' — a fragment ending mid-word reads to the model
      // as a thought the person abandoned.
      expect(withJournal.journal, isEmpty);
      expect(jsonEncode(withJournal.toJson()), isNot(contains('private')));
    });

    test('a passage cut to fit ends on a word and says that it was cut', () {
      const wide = AetherRequestBuilder(maxJournalCharacters: 80);
      final request = wide.build(
        aiConsented: true,
        journalConsented: true,
        ageYears: 30,
        mode: GuidanceMode.balanced,
        health: const [],
        journal: [
          AetherJournalContext(
            createdAt: DateTime.utc(2026, 7, 27),
            text: 'The train was late again and I stood on the platform for '
                'forty minutes thinking about the conversation I had been '
                'putting off since Tuesday.',
          ),
        ],
      );

      final text = request.journal.single['text']! as String;
      expect(text.length, lessThanOrEqualTo(80));
      expect(text, endsWith('…'));
      // No half-words: the character before the marker ends a whole one.
      expect(text.replaceAll('…', '').trim(), isNot(endsWith(' ')));
      expect(request.journal.single['truncated'], isTrue);

      // And the model is told, rather than left to read a severed sentence as
      // a complete one.
      expect(request.journalTruncated, isTrue);
      expect(
          EterPrompts.guidance(request, language: AppLanguage.english).system,
          contains('is incomplete'));
    });

    test('payload has no identity fields and fingerprint is deterministic', () {
      AetherRequest make() => builder.build(
            aiConsented: true,
            journalConsented: false,
            ageYears: 30,
            mode: GuidanceMode.balanced,
            health: const [AetherHealthContext(localDate: '2026-07-28')],
          );
      final json = make().toJson();
      expect(json.keys, isNot(containsAll(['name', 'uid', 'dob', 'location'])));
      expect(make().contextFingerprint, make().contextFingerprint);
    });
  });

  group('Aether response boundary', () {
    const parser = AetherGuidanceParser();

    String response({String action = 'Take a short walk.'}) => jsonEncode({
          for (final key in AetherGuidanceParser.dimensionKeys)
            key: {
              'sentences': ['A quiet observation.'],
              'primaryAction': action,
            },
        });

    test('accepts exact schema', () {
      final result = parser.parse(
        response(),
        mode: GuidanceMode.balanced,
      );
      expect(result.dimensions.map((item) => item.key).toSet(),
          AetherGuidanceParser.dimensionKeys);
    });

    test('rejects missing or extra dimensions', () {
      expect(
        () => parser.parse('{}', mode: GuidanceMode.balanced),
        throwsA(isA<AetherContractException>()),
      );
    });

    test('rejects unsafe guidance before persistence', () {
      expect(
        () => parser.parse(
          response(action: 'Stop taking your medication.'),
          mode: GuidanceMode.balanced,
        ),
        throwsA(isA<AetherSafetyException>()),
      );
    });
  });

  group('Aether composition', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    AetherRequest request() => const AetherRequestBuilder().build(
          aiConsented: true,
          journalConsented: false,
          ageYears: 30,
          mode: GuidanceMode.balanced,
          health: const [AetherHealthContext(localDate: '2026-07-28')],
        );

    test('persists one complete set and reuses it for unchanged context',
        () async {
      final provider = _FakeProvider(_validResponse());
      final composer = AetherComposer(database: database, provider: provider);

      final first = await composer.compose(request());
      final second = await composer.compose(request());

      expect(first.rows, hasLength(4));
      expect(first.fromCache, isFalse);
      expect(second.fromCache, isTrue);
      expect(provider.calls, 1);
      expect(await database.loadGuidanceForDate('2026-07-28'), hasLength(4));
    });

    test('unsafe output writes no partial guidance', () async {
      final composer = AetherComposer(
        database: database,
        provider: _FakeProvider(
          _validResponse(action: 'Stop taking your medication.'),
        ),
      );

      await expectLater(
        composer.compose(request()),
        throwsA(isA<AetherSafetyException>()),
      );
      expect(await database.loadGuidanceForDate('2026-07-28'), isEmpty);
    });

    test('an empty-health composition uses the caller day', () async {
      final emptyHealth = const AetherRequestBuilder().build(
        aiConsented: true,
        journalConsented: false,
        ageYears: 35,
        mode: GuidanceMode.balanced,
        health: const [],
      );
      final composer = AetherComposer(
        database: database,
        provider: _FakeProvider(_validResponse()),
      );

      await composer.compose(
        emptyHealth,
        now: DateTime(2026, 7, 28, 10),
      );

      expect(await database.loadGuidanceForDate('2026-07-28'), hasLength(4));
    });
  });

  group('evidence is checked against what the model was actually sent', () {
    const scope = AetherRequestBuilder();

    AetherRequest requestWith() => scope.build(
          aiConsented: true,
          journalConsented: false,
          ageYears: 30,
          mode: GuidanceMode.balanced,
          health: const [
            AetherHealthContext(
              localDate: '2026-07-27',
              steps: 8412,
              sleepMinutes: 402,
            ),
          ],
        );

    String responseCiting(Map<String, Object?> evidence) => jsonEncode({
          for (final key in AetherGuidanceParser.dimensionKeys)
            key: {
              'sentences': ['A quiet observation.'],
              'primaryAction': 'Take a short walk.',
              if (key == 'health') 'evidence': evidence,
            },
        });

    test('a citation copied exactly is kept', () {
      final request = requestWith();
      final guidance = const AetherGuidanceParser().parse(
        responseCiting({'sleepMinutes': 402, 'localDate': '2026-07-27'}),
        mode: GuidanceMode.balanced,
        evidence: AetherEvidenceScope.fromContext(
          EterPrompts.guidance(request, language: AppLanguage.english).user,
        ),
      );

      final health =
          guidance.dimensions.firstWhere((item) => item.key == 'health');
      expect(health.evidence!['sleepMinutes'], 402);
    });

    test('a number that was never in the context is refused', () {
      final request = requestWith();
      expect(
        () => const AetherGuidanceParser().parse(
          // Plausible, adjacent to a real figure, and invented. This is the
          // one that used to reach the surface dressed as a measurement.
          responseCiting({'sleepMinutes': 400}),
          mode: GuidanceMode.balanced,
          evidence: AetherEvidenceScope.fromContext(
            EterPrompts.guidance(request, language: AppLanguage.english).user,
          ),
        ),
        throwsA(isA<AetherContractException>()),
      );
    });

    test('a field name the payload never used is refused', () {
      final request = requestWith();
      expect(
        () => const AetherGuidanceParser().parse(
          responseCiting({'caloriesBurned': 8412}),
          mode: GuidanceMode.balanced,
          evidence: AetherEvidenceScope.fromContext(
            EterPrompts.guidance(request, language: AppLanguage.english).user,
          ),
        ),
        throwsA(isA<AetherContractException>()),
      );
    });

    test('without a scope the shape is still checked and nothing else', () {
      // The offline composition has no payload to check against, and must not
      // start failing because of it.
      final guidance = const AetherGuidanceParser().parse(
        responseCiting({'sleepMinutes': 400}),
        mode: GuidanceMode.balanced,
      );
      expect(guidance.dimensions, hasLength(4));
    });
  });

  group('self-reports', () {
    const builder = AetherRequestBuilder();

    AetherRequest buildWith({required bool journalConsented}) => builder.build(
          aiConsented: true,
          journalConsented: journalConsented,
          ageYears: 30,
          mode: GuidanceMode.balanced,
          health: const [],
          lifestyle: const [
            AetherLifestyleContext(
              localDate: '2026-07-27',
              kind: 'mood',
              value: 3,
            ),
            AetherLifestyleContext(
              localDate: '2026-07-27',
              kind: 'carrying',
              note: 'the conversation I keep putting off',
              fromJournal: true,
            ),
          ],
        );

    test('a margin check-in crosses on general AI consent', () {
      final request = buildWith(journalConsented: false);
      expect(request.lifestyle, hasLength(1));
      expect(request.lifestyle.single.kind, 'mood');
      expect(jsonEncode(request.toJson()), contains('"kind":"mood"'));
    });

    test('one derived from a page needs the journal consent', () {
      // It is prose in another shape, so it crosses on the consent prose does.
      expect(
        jsonEncode(buildWith(journalConsented: false).toJson()),
        isNot(contains('putting off')),
      );
      expect(
        jsonEncode(buildWith(journalConsented: true).toJson()),
        contains('putting off'),
      );
    });

    test('the prompt explains them, and only when there are any', () {
      expect(
        EterPrompts.guidance(buildWith(journalConsented: true),
                language: AppLanguage.english)
            .system,
        contains('WHAT THEY REPORTED THEMSELVES'),
      );
      expect(
        EterPrompts.guidance(
          builder.build(
            aiConsented: true,
            journalConsented: true,
            ageYears: 30,
            mode: GuidanceMode.balanced,
            health: const [],
          ),
          language: AppLanguage.english,
        ).system,
        isNot(contains('WHAT THEY REPORTED THEMSELVES')),
      );
    });
  });

  group('memory', () {
    late AppDatabase memoryDb;

    setUp(() => memoryDb = AppDatabase(NativeDatabase.memory()));
    tearDown(() => memoryDb.close());

    String responseWith(String recall) => jsonEncode({
          for (final key in AetherGuidanceParser.dimensionKeys)
            key: {
              'sentences': ['A quiet observation.'],
              'primaryAction': 'Take a short walk.',
            },
          'recall': recall,
        });

    test('a composition writes the note the next day will read', () async {
      await memoryDb.saveProfile(ProfilesCompanion.insert(
        dob: DateTime.utc(1993, 7, 25),
        sex: 'male',
        weightKg: 78,
        units: 'metric',
        aiConsentAt: Value(DateTime.utc(2026, 7, 29)),
      ));

      final composer = AetherComposer(
        database: memoryDb,
        provider: _FakeProvider(
          responseWith('third short night. hrv down. offered early wind-down.'),
        ),
      );
      await composer.compose(
        const AetherRequestBuilder().build(
          aiConsented: true,
          journalConsented: false,
          ageYears: 33,
          mode: GuidanceMode.balanced,
          health: const [AetherHealthContext(localDate: '2026-07-29')],
        ),
        now: DateTime(2026, 7, 29, 9),
      );

      final notes = await memoryDb.loadGuidanceRecalls(today: '2026-07-30');
      expect(notes, hasLength(1));
      expect(notes.single.date, '2026-07-29');
      expect(notes.single.note, startsWith('third short night'));
      // The action travels too, so tomorrow does not offer the same walk.
      expect(notes.single.action, 'Take a short walk.');
      expect(notes.single.promptVersion, EterPrompts.version);
      // Nothing journal-derived was in this request.
      expect(notes.single.usedJournal, isFalse);
    });

    test('today is never in its own memory', () async {
      // Otherwise composing would invalidate the fingerprint it just cached
      // under, and the same day would want recomposing the moment it finished.
      await memoryDb.saveGuidanceRecall(GuidanceRecallsCompanion.insert(
        date: '2026-07-29',
        generatedAt: DateTime.utc(2026, 7, 29),
        note: 'today.',
      ));
      await memoryDb.saveGuidanceRecall(GuidanceRecallsCompanion.insert(
        date: '2026-07-28',
        generatedAt: DateTime.utc(2026, 7, 28),
        note: 'yesterday.',
      ));

      final notes = await memoryDb.loadGuidanceRecalls(today: '2026-07-29');
      expect(notes.map((row) => row.note), ['yesterday.']);
    });

    test('a fortnight, oldest first, and nothing older', () async {
      for (var day = 1; day <= 30; day++) {
        await memoryDb.saveGuidanceRecall(GuidanceRecallsCompanion.insert(
          date: '2026-07-${day.toString().padLeft(2, '0')}',
          generatedAt: DateTime.utc(2026, 7, day),
          note: 'day $day.',
        ));
      }

      final notes = await memoryDb.loadGuidanceRecalls(today: '2026-07-29');
      expect(notes, hasLength(14));
      expect(notes.first.date, '2026-07-15');
      expect(notes.last.date, '2026-07-28');
    });

    test('a recomposed day replaces its note rather than adding one', () async {
      for (final note in ['first pass.', 'second pass.']) {
        await memoryDb.saveGuidanceRecall(GuidanceRecallsCompanion.insert(
          date: '2026-07-28',
          generatedAt: DateTime.utc(2026, 7, 28),
          note: note,
        ));
      }
      final notes = await memoryDb.loadGuidanceRecalls(today: '2026-07-29');
      expect(notes, hasLength(1));
      expect(notes.single.note, 'second pass.');
    });

    test('withdrawing journal consent withdraws the notes that saw a page',
        () async {
      await memoryDb.saveGuidanceRecall(GuidanceRecallsCompanion.insert(
        date: '2026-07-27',
        generatedAt: DateTime.utc(2026, 7, 27),
        note: 'read a page.',
        usedJournal: const Value(true),
      ));
      await memoryDb.saveGuidanceRecall(GuidanceRecallsCompanion.insert(
        date: '2026-07-28',
        generatedAt: DateTime.utc(2026, 7, 28),
        note: 'sensors only.',
        usedJournal: const Value(false),
      ));

      expect(
        (await memoryDb.loadGuidanceRecalls(today: '2026-07-29'))
            .map((row) => row.note),
        ['read a page.', 'sensors only.'],
      );
      // A note composed while the consent was on may paraphrase a page, so
      // revoking has to stop it travelling — otherwise last week's pages keep
      // reaching the model, laundered through Eter's own prose.
      expect(
        (await memoryDb.loadGuidanceRecalls(
          today: '2026-07-29',
          journalAllowed: false,
        ))
            .map((row) => row.note),
        ['sensors only.'],
      );
    });

    test('clearing Aether memory clears the notes with it', () async {
      await memoryDb.saveGuidanceRecall(GuidanceRecallsCompanion.insert(
        date: '2026-07-28',
        generatedAt: DateTime.utc(2026, 7, 28),
        note: 'something.',
      ));
      await memoryDb.resetPersonalization();
      expect(await memoryDb.loadGuidanceRecalls(today: '2026-07-29'), isEmpty);
    });

    test('the note is bounded, and an overlong one fails the composition', () {
      expect(
        () => const AetherGuidanceParser().parse(
          responseWith('x' * 400),
          mode: GuidanceMode.balanced,
        ),
        throwsA(isA<AetherContractException>()),
      );
    });

    test('a response with no note still composes', () {
      // A day with no memory of itself is a smaller loss than no guidance.
      final guidance = const AetherGuidanceParser()
          .parse(_validResponse(), mode: GuidanceMode.balanced);
      expect(guidance.dimensions, hasLength(4));
      expect(guidance.recall, isNull);
    });

    test('an unsafe note is refused even though nobody would see it', () {
      // It is read back into the next request, so it would seed tomorrow.
      expect(
        () => const AetherGuidanceParser().parse(
          responseWith('told them to push through the pain.'),
          mode: GuidanceMode.balanced,
        ),
        throwsA(isA<AetherSafetyException>()),
      );
    });

    test('the prompt explains the notes, and only when there are any', () {
      AetherRequest requestWith(List<AetherRecallContext> recalled) =>
          const AetherRequestBuilder().build(
            aiConsented: true,
            journalConsented: false,
            ageYears: 33,
            mode: GuidanceMode.balanced,
            health: const [AetherHealthContext(localDate: '2026-07-29')],
            recalled: recalled,
          );

      final withMemory = EterPrompts.guidance(
              requestWith(const [
                AetherRecallContext(
                  localDate: '2026-07-28',
                  note: 'second short night. offered a walk.',
                  action: 'Take a short walk.',
                ),
              ]),
              language: AppLanguage.english)
          .system;

      expect(withMemory, contains('WHAT YOU HAVE ALREADY SAID'));
      // The three limits that make referring back safe.
      expect(withMemory, contains('These are your words, never theirs'));
      expect(withMemory, contains('A note is not evidence'));
      expect(withMemory, contains('Today outranks the thread'));
      // And that referring back is wanted rather than merely tolerated.
      expect(withMemory, contains('cannot say "again"'));

      expect(
        EterPrompts.guidance(requestWith(const []),
                language: AppLanguage.english)
            .system,
        isNot(contains('WHAT YOU HAVE ALREADY SAID')),
      );
    });

    test('the fortnight is bounded and lands in the payload', () {
      final request = const AetherRequestBuilder().build(
        aiConsented: true,
        journalConsented: false,
        ageYears: 33,
        mode: GuidanceMode.balanced,
        health: const [],
        recalled: [
          for (var day = 1; day <= 20; day++)
            AetherRecallContext(
              localDate: '2026-07-${day.toString().padLeft(2, '0')}',
              note: 'day $day.',
            ),
        ],
      );

      expect(request.recalled, hasLength(14));
      // The newest fourteen, not the oldest.
      expect(request.recalled.first.localDate, '2026-07-07');
      expect(request.recalled.last.localDate, '2026-07-20');
      expect(jsonEncode(request.toJson()), contains('"recalled"'));
    });

    test('a new note is itself a reason to recompose', () {
      AetherRequest requestWith(List<AetherRecallContext> recalled) =>
          const AetherRequestBuilder().build(
            aiConsented: true,
            journalConsented: false,
            ageYears: 33,
            mode: GuidanceMode.balanced,
            health: const [],
            recalled: recalled,
          );

      expect(
        requestWith(const [
          AetherRecallContext(localDate: '2026-07-28', note: 'a note.'),
        ]).contextFingerprint,
        isNot(requestWith(const []).contextFingerprint),
      );
    });
  });
}

String _validResponse({String action = 'Take a short walk.'}) => jsonEncode({
      for (final key in AetherGuidanceParser.dimensionKeys)
        key: {
          'sentences': ['A quiet observation.'],
          'primaryAction': action,
        },
    });

class _FakeProvider implements AetherProvider {
  _FakeProvider(this.response);
  final String response;
  int calls = 0;

  @override
  Future<String> compose(AetherProviderRequest request) async {
    calls += 1;
    return response;
  }
}
