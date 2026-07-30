import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/ai/prompts.dart';
import 'package:eter/core/aether/letter.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sixth call: one page a month, written to the person.
///
/// Three things here are worth more than the rest. It must never compose a
/// month twice, because the month is the cache key and a monthly page that
/// silently re-bills is the worst kind of quiet cost. It must not run at all
/// without consent. And a note written while journal consent was on must stop
/// travelling when that consent is withdrawn — otherwise revoking leaves last
/// month's pages reaching the model laundered through Eter's own prose.
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
        aiConsentAt: Value(aiConsent ? DateTime.utc(2026, 6, 1) : null),
        journalAiConsentAt:
            Value(journalConsent ? DateTime.utc(2026, 6, 1) : null),
      ));

  Future<void> recall(
    String date, {
    required String note,
    bool usedJournal = false,
  }) =>
      database.saveGuidanceRecall(GuidanceRecallsCompanion.insert(
        date: date,
        generatedAt: DateTime.utc(2026, 7, 1),
        note: note,
        usedJournal: Value(usedJournal),
      ));

  Future<void> month({int days = 8, bool usedJournal = false}) async {
    for (var day = 1; day <= days; day++) {
      await recall(
        '2026-07-${day.toString().padLeft(2, '0')}',
        note: 'note for day $day',
        usedJournal: usedJournal,
      );
    }
  }

  test('composes a month once and never pays for it twice', () async {
    await profile();
    await month();
    final provider = _Recording('The month, as it looked.');
    final composer = LetterComposer(database: database, provider: provider);

    final first = await composer.compose(
      month: '2026-07',
      now: DateTime.utc(2026, 8, 1),
    );
    expect(first.fromCache, isFalse);
    expect(first.row?.body, 'The month, as it looked.');
    expect(provider.calls, 1);

    final second = await composer.compose(
      month: '2026-07',
      now: DateTime.utc(2026, 8, 2),
    );
    expect(second.fromCache, isTrue);
    expect(second.row?.body, 'The month, as it looked.');
    // The whole cost model of this feature.
    expect(provider.calls, 1);
  });

  test('records the prompt version that composed it', () async {
    await profile();
    await month();
    await LetterComposer(database: database, provider: _Recording('A page.'))
        .compose(month: '2026-07', now: DateTime.utc(2026, 8, 1));
    final row = await database.loadLetter('2026-07');
    expect(row?.promptVersion, EterPrompts.version);
  });

  test('refuses without AI consent, and writes nothing', () async {
    await profile(aiConsent: false);
    await month();
    final provider = _Recording('Should never be composed.');
    await expectLater(
      LetterComposer(database: database, provider: provider)
          .compose(month: '2026-07', now: DateTime.utc(2026, 8, 1)),
      throwsA(isA<LetterException>()),
    );
    expect(provider.calls, 0);
    expect(await database.loadLetter('2026-07'), isNull);
  });

  test('a thin month is not written at all', () async {
    // The instruction already tells the model to keep a quiet month short. This
    // is the floor below which asking is not worth the request: paying to be
    // told "there is not much here yet" is worse than not writing.
    await profile();
    await month(days: 3);
    final provider = _Recording('Should never be composed.');
    final result = await LetterComposer(database: database, provider: provider)
        .compose(month: '2026-07', now: DateTime.utc(2026, 8, 1));
    expect(result.row, isNull);
    expect(result.fromCache, isFalse);
    expect(provider.calls, 0);
  });

  test('notes that saw the journal stop travelling when consent is gone',
      () async {
    await profile(journalConsent: false);
    await month(usedJournal: true);
    final provider = _Recording('A page.');
    final result = await LetterComposer(database: database, provider: provider)
        .compose(month: '2026-07', now: DateTime.utc(2026, 8, 1));
    // Every note was journal-derived, so with the consent withdrawn there is
    // nothing left to write from — and nothing was sent.
    expect(result.row, isNull);
    expect(provider.calls, 0);
  });

  test('only the month asked for reaches the model', () async {
    await profile();
    await month();
    await recall('2026-06-30', note: 'the month before');
    await recall('2026-08-01', note: 'the month after');
    final provider = _Recording('A page.');
    await LetterComposer(database: database, provider: provider)
        .compose(month: '2026-07', now: DateTime.utc(2026, 8, 1));
    final sent = (provider.last!['recalls']! as List).cast<String>();
    expect(sent, hasLength(8));
    expect(sent.any((note) => note.contains('month before')), isFalse);
    expect(sent.any((note) => note.contains('month after')), isFalse);
  });

  test('the retrospective travels so the letter has figures to use', () async {
    await profile();
    await month();
    await database.saveRetrospective(RetrospectivesCompanion.insert(
      id: 'r1',
      kind: 'weekly',
      periodStart: '2026-07-06',
      periodEnd: '2026-07-12',
      generatedAt: DateTime.utc(2026, 7, 13),
      contentJson: jsonEncode({
        'passages': ['Sleep was available for 5 of 7 nights.'],
      }),
      model: 'device',
    ));
    final provider = _Recording('A page.');
    await LetterComposer(database: database, provider: provider)
        .compose(month: '2026-07', now: DateTime.utc(2026, 8, 1));
    expect(
      (provider.last!['retrospective']! as List).single,
      'Sleep was available for 5 of 7 nights.',
    );
  });

  group('the parser', () {
    const parser = LetterParser();

    test('accepts one page of prose', () {
      expect(
        parser.parse(jsonEncode({'letter': '  A month, told back.  '})),
        'A month, told back.',
      );
    });

    test('rejects anything that is not the contract', () {
      expect(() => parser.parse('not json'), throwsA(isA<LetterException>()));
      expect(() => parser.parse('[]'), throwsA(isA<LetterException>()));
      expect(
        () => parser.parse(jsonEncode({'letter': '   '})),
        throwsA(isA<LetterException>()),
      );
    });

    test('rejects a letter that is not one page', () {
      // The schema says 2400 too. This is the second wall, because the schema
      // is the endpoint's promise rather than a boundary this app controls.
      expect(
        () => parser.parse(jsonEncode({'letter': 'x' * 2401})),
        throwsA(isA<LetterException>()),
      );
    });

    test('an unsafe letter is refused like anything else composed here', () {
      expect(
        () => parser.parse(
          jsonEncode({'letter': 'You should stop taking your medication.'}),
        ),
        throwsA(anything),
      );
    });
  });
}

class _Recording implements LetterProvider {
  _Recording(this.body);

  final String body;
  int calls = 0;
  Map<String, Object?>? last;

  @override
  Future<String> compose(LetterProviderRequest request) async {
    calls++;
    last = request.context;
    return jsonEncode({'letter': body});
  }
}
