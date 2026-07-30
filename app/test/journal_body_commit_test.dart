import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/health/record_error.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/journal/body_commit.dart';
import 'package:eter/core/journal/classification_contract.dart';
import 'package:eter/core/journal/classifier.dart';
import 'package:flutter_test/flutter_test.dart';

/// Weight, activity and strength reaching the record from a journal page.
///
/// The point of routing them through the existing services rather than
/// writing their rows here is that the same run logged two different ways has
/// to produce the same day. These tests are mostly about that equivalence, and
/// about the bounds that keep a sentence from becoming a measurement.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<void> profile({double weightKg = 70}) =>
      database.saveProfile(ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'other',
        weightKg: weightKg,
        units: 'metric',
        heightCm: const Value(175),
        aiConsentAt: Value(DateTime.utc(2026, 7, 1)),
      ));

  final recordedAt = DateTime(2026, 7, 28, 18, 30);

  group('the parser', () {
    const parser = JournalClassificationParser();

    JournalClassification parse(Map<String, Object?> body) =>
        parser.parse(jsonEncode({
          'status': 'classified',
          'food': const [],
          'lifestyle': const [],
          ...body,
        }));

    void rejects(Map<String, Object?> body) => expect(
          () => parse(body),
          throwsA(isA<JournalClassificationException>()),
          reason: jsonEncode(body),
        );

    test('the three lists are optional, and absent means empty', () {
      final parsed = parser.parse(jsonEncode({
        'status': 'classified',
        'food': const [],
        'lifestyle': const [],
      }));
      expect(parsed.weight, isEmpty);
      expect(parsed.activity, isEmpty);
      expect(parsed.strength, isEmpty);
      expect(parsed.isEmpty, isTrue);
    });

    test('a weight is read as stated', () {
      final parsed = parse({
        'weight': [
          {'kg': 84.2},
        ],
      });
      expect(parsed.weight.single.kg, 84.2);
      expect(parsed.isEmpty, isFalse);
    });

    test('an impossible weight is refused rather than recorded', () {
      rejects({
        'weight': [
          {'kg': 0},
        ],
      });
      rejects({
        'weight': [
          {'kg': 19},
        ],
      });
      rejects({
        'weight': [
          {'kg': 501},
        ],
      });
      rejects({
        'weight': [
          {'kg': 'heavier'},
        ],
      });
      rejects({
        'weight': [
          {'note': 'felt heavy'},
        ],
      });
    });

    test('an activity carries its estimate and what the estimate assumed', () {
      final parsed = parse({
        'activity': [
          {
            'activity': 'Easy run',
            'durationMinutes': 34,
            'kcal': 320,
            'confidence': 0.6,
            'assumptions': ['assumed a conversational pace'],
          },
        ],
      });
      final activity = parsed.activity.single;
      expect(activity.activity, 'Easy run');
      expect(activity.durationMinutes, 34);
      expect(activity.kcal, 320);
      expect(activity.confidence, 0.6);
      expect(activity.assumptions, ['assumed a conversational pace']);
    });

    test('activities outside the service\'s own bounds are refused', () {
      Map<String, Object?> activity(Map<String, Object?> overrides) => {
            'activity': [
              {
                'activity': 'Run',
                'durationMinutes': 30,
                'kcal': 300,
                'confidence': 0.5,
                'assumptions': const <String>[],
                ...overrides,
              },
            ],
          };

      rejects(activity({'durationMinutes': 0}));
      rejects(activity({'durationMinutes': 1441}));
      rejects(activity({'kcal': 0}));
      rejects(activity({'kcal': 10001}));
      rejects(activity({'confidence': 1.5}));
      rejects(activity({'activity': ''}));
      rejects(activity({'activity': 'x' * 81}));
      rejects(activity({'assumptions': 'a guess'}));
    });

    test('strength keeps sets, and load stays absent for bodyweight work', () {
      final parsed = parse({
        'strength': [
          {
            'name': 'Back squat',
            'sets': [
              {'reps': 5, 'loadKg': 100},
              {'reps': 5, 'loadKg': 100},
            ],
          },
          {
            'name': 'Pull-up',
            'sets': [
              {'reps': 8},
            ],
          },
        ],
      });
      expect(parsed.strength, hasLength(2));
      expect(parsed.strength.first.sets.first.loadKg, 100);
      expect(parsed.strength.last.sets.single.loadKg, isNull);
      expect(parsed.strength.last.sets.single.reps, 8);
    });

    test('impossible sets are refused', () {
      Map<String, Object?> strength(List<Object?> sets) => {
            'strength': [
              {'name': 'Squat', 'sets': sets},
            ],
          };

      rejects(strength(const []));
      rejects(strength([
        {'reps': 0},
      ]));
      rejects(strength([
        {'reps': 501},
      ]));
      rejects(strength([
        {'reps': 5, 'loadKg': 1001},
      ]));
      rejects(strength([
        {'loadKg': 60},
      ]));
      rejects({
        'strength': [
          {'name': '', 'sets': const []},
        ],
      });
    });

    test('an ambiguous page may not carry any of the three', () {
      for (final key in ['weight', 'activity', 'strength']) {
        expect(
          () => parser.parse(jsonEncode({
            'status': 'needsDetail',
            'clarifyingQuestion': 'How long was the run?',
            'food': const [],
            'lifestyle': const [],
            key: [
              if (key == 'weight')
                {'kg': 80}
              else if (key == 'activity')
                {
                  'activity': 'Run',
                  'durationMinutes': 30,
                  'kcal': 300,
                  'confidence': 0.5,
                  'assumptions': const <String>[],
                }
              else
                {
                  'name': 'Squat',
                  'sets': [
                    {'reps': 5},
                  ],
                },
            ],
          })),
          throwsA(isA<JournalClassificationException>()),
          reason: key,
        );
      }
    });

    test('a list that is not a list is refused', () {
      rejects({'weight': 84.2});
      rejects({'activity': 'a run'});
      rejects({'strength': const {}});
    });
  });

  group('committing', () {
    test('a weight lands where a manually entered one lands', () async {
      await profile();
      final result = await JournalBodyCommitter(database).commit(
        classification: const JournalClassification(
          status: 'classified',
          food: [],
          lifestyle: [],
          weight: [WeightObservation(kg: 84.2)],
        ),
        recordedAt: recordedAt,
      );

      expect(result.weights, 1);
      expect(result.failures, isEmpty);
      final weights = await database.watchWeightEntries().first;
      expect(weights.single.kg, 84.2);
    });

    test('an activity becomes a session and reaches the day total', () async {
      await profile();
      final result = await JournalBodyCommitter(database).commit(
        classification: const JournalClassification(
          status: 'classified',
          food: [],
          lifestyle: [],
          activity: [
            ActivityObservation(
              activity: 'Easy run',
              durationMinutes: 34,
              kcal: 320,
              confidence: 0.6,
              assumptions: ['assumed a conversational pace'],
            ),
          ],
        ),
        recordedAt: recordedAt,
      );

      expect(result.activities, 1);
      final sessions = await database.loadSessions(
        DateTime(2026, 7, 28).toUtc(),
        DateTime(2026, 7, 29).toUtc(),
      );
      expect(sessions, hasLength(1));
      final day = await database.loadDaySummary('2026-07-28');
      expect(day!.activeKcal, greaterThan(0));
    });

    test('strength is estimated from body weight, not from the page', () async {
      await profile();
      final result = await JournalBodyCommitter(database).commit(
        classification: const JournalClassification(
          status: 'classified',
          food: [],
          lifestyle: [],
          strength: [
            StrengthObservation(
              name: 'Back squat',
              sets: [
                StrengthSetObservation(reps: 5, loadKg: 100),
                StrengthSetObservation(reps: 5, loadKg: 100),
              ],
            ),
          ],
        ),
        recordedAt: recordedAt,
      );

      expect(result.workouts, 1);
      final workouts = await database.watchStrengthWorkouts().first;
      expect(workouts, hasLength(1));
      expect(workouts.single.finalKcal, greaterThan(0));
      expect(workouts.single.bodyWeightKgAtTime, 70);
    });

    test('one failure does not cost the rest of the page', () async {
      // No profile at all: strength has no body weight to estimate from and
      // refuses, but the weight reading itself is still a fact.
      final result = await JournalBodyCommitter(database).commit(
        classification: const JournalClassification(
          status: 'classified',
          food: [],
          lifestyle: [],
          weight: [WeightObservation(kg: 84.2)],
          strength: [
            StrengthObservation(
              name: 'Back squat',
              sets: [StrengthSetObservation(reps: 5, loadKg: 100)],
            ),
          ],
        ),
        recordedAt: recordedAt,
      );

      expect(result.weights, 1);
      expect(result.workouts, 0);
      expect(result.failures, hasLength(1));
      // The bound that was hit, not a sentence about it: the sentence lives in
      // the string tables now, so the commit layer reports a code and the
      // Journal words it.
      expect(
        result.failures.single,
        BodyRecordError.strengthNeedsBodyWeight,
      );
      expect((await database.watchWeightEntries().first).single.kg, 84.2);
    });

    test('a page naming none of the three writes nothing', () async {
      await profile();
      final result = await JournalBodyCommitter(database).commit(
        classification: const JournalClassification(
          status: 'classified',
          food: [],
          lifestyle: [],
        ),
        recordedAt: recordedAt,
      );

      expect(result.wroteNothing, isTrue);
      expect(result.failures, isEmpty);
      expect(await database.watchWeightEntries().first, isEmpty);
    });
  });

  group('through the classifier', () {
    Future<int> entry(String text) =>
        database.addJournalEntry(JournalEntriesCompanion.insert(
          createdAt: recordedAt,
          entryText: text,
        ));

    test('a page with a weight and a run commits both, once', () async {
      await profile();
      final id = await entry('84.2 this morning. Easy run, half an hour.');
      final provider = _Provider(jsonEncode({
        'status': 'classified',
        'food': const [],
        'lifestyle': const [],
        'weight': [
          {'kg': 84.2},
        ],
        'activity': [
          {
            'activity': 'Easy run',
            'durationMinutes': 30,
            'kcal': 300,
            'confidence': 0.6,
            'assumptions': ['assumed a conversational pace'],
          },
        ],
      }));
      final classifier =
          JournalClassifier(database: database, provider: provider);

      final first = await classifier.classify(id);
      expect(first.body!.weights, 1);
      expect(first.body!.activities, 1);

      // Re-running an applied entry replays the stored reading and must not
      // log the run a second time.
      final second = await classifier.classify(id);
      expect(second.body, isNull);
      expect(provider.calls, 1);
      expect(await database.watchWeightEntries().first, hasLength(1));
      expect(
        await database.loadSessions(
          DateTime(2026, 7, 28).toUtc(),
          DateTime(2026, 7, 29).toUtc(),
        ),
        hasLength(1),
      );
    });

    test('an ambiguous page commits nothing to the body', () async {
      await profile();
      final id = await entry('Went for a run.');
      final classifier = JournalClassifier(
        database: database,
        provider: _Provider(jsonEncode({
          'status': 'needsDetail',
          'clarifyingQuestion': 'How long was the run?',
          'food': const [],
          'lifestyle': const [],
        })),
      );

      final outcome = await classifier.classify(id);
      expect(outcome.body, isNull);
      expect(
        await database.loadSessions(
          DateTime(2026, 7, 28).toUtc(),
          DateTime(2026, 7, 29).toUtc(),
        ),
        isEmpty,
      );
    });
  });
}

class _Provider implements JournalClassificationProvider {
  _Provider(this.raw);

  final String raw;
  int calls = 0;

  @override
  Future<String> classify(JournalClassificationRequest request) async {
    calls += 1;
    return raw;
  }
}
