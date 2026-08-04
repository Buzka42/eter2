import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/widget/home_screen_widget.dart';
import 'package:flutter_test/flutter_test.dart';

/// The smallest surface Eter has, and the only one somebody's household can
/// read over their shoulder.
void main() {
  late AppDatabase database;
  late _Sink sink;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    sink = _Sink();
  });
  tearDown(() => database.close());

  HomeScreenWidget widget() =>
      HomeScreenWidget(database: database, sink: sink);

  Future<void> withConsent() => database.saveProfile(
        ProfilesCompanion.insert(
          dob: DateTime(1990, 1, 1),
          sex: 'other',
          weightKg: 70,
          units: 'metric',
          aiConsentAt: Value(DateTime.utc(2026, 8, 4)),
        ),
      );

  Future<void> writeSynthesis({
    required String date,
    required List<String> sentences,
    String dimension = 'synthesis',
  }) =>
      database.into(database.guidanceHistory).insert(
            GuidanceHistoryCompanion.insert(
              date: date,
              dimension: dimension,
              generatedAt: DateTime.utc(2026, 8, 4),
              contentJson: jsonEncode({
                'sentences': sentences,
                'primaryAction': 'Sit with this for a minute.',
              }),
              contextFingerprint: 'fingerprint',
              source: 'provider',
            ),
          );

  test('it publishes the first sentence of the day\'s synthesis', () async {
    // The first rather than all of them: a home-screen widget is a glance, and
    // the synthesis is written so its opening sentence stands alone.
    await withConsent();
    await writeSynthesis(
      date: '2026-08-04',
      sentences: const ['Rest has been shorter than usual.', 'And so on.'],
    );

    await widget().refresh(now: DateTime(2026, 8, 4, 9));

    expect(sink.sentence, 'Rest has been shorter than usual.');
    expect(sink.date, '2026-08-04');
    expect(sink.today, '2026-08-04');
  });

  test('the synthesis, and never one of the three dimensions', () async {
    // The synthesis is the passage already thought about as something somebody
    // else might see — it is what the Correspondence is allowed to send. The
    // dimensions are not.
    await withConsent();
    await writeSynthesis(
      date: '2026-08-04',
      dimension: 'health',
      sentences: const ['Something about the body.'],
    );

    await widget().refresh(now: DateTime(2026, 8, 4, 9));

    expect(sink.sentence, isNull);
  });

  test('a sentence from another day is not shown as today\'s', () async {
    // The one thing this surface must not do.
    await withConsent();
    await writeSynthesis(
      date: '2026-08-03',
      sentences: const ['Yesterday\'s sentence.'],
    );

    await widget().refresh(now: DateTime(2026, 8, 4, 9));

    expect(sink.sentence, isNull);
    // And the widget is told which day the app believes it is, so a redraw the
    // system triggers at midnight cannot disagree with the app about it.
    expect(sink.today, '2026-08-04');
  });

  test('withdrawing consent takes the words off the home screen', () async {
    // The rows stay and a launcher goes on drawing whatever it was last given.
    // This is the one surface a revocation cannot reach on its own.
    await withConsent();
    await writeSynthesis(
      date: '2026-08-04',
      sentences: const ['Rest has been shorter than usual.'],
    );
    await widget().refresh(now: DateTime(2026, 8, 4, 9));
    expect(sink.sentence, isNotNull);

    await database.updateProfileConsents(aiAllowed: false);
    await widget().refresh(now: DateTime(2026, 8, 4, 9));

    expect(sink.sentence, isNull);
    expect(sink.published, 2, reason: 'clearing must be published, not skipped');
  });

  test('a day with nothing composed clears rather than keeping yesterday',
      () async {
    await withConsent();
    await widget().refresh(now: DateTime(2026, 8, 4, 9));
    expect(sink.sentence, isNull);
    expect(sink.published, 1);
  });

  test('no profile at all is not an error', () async {
    await widget().refresh(now: DateTime(2026, 8, 4, 9));
    expect(sink.sentence, isNull);
  });

  group('reading a stored passage', () {
    test('the first sentence with anything in it', () {
      expect(
        HomeScreenWidget.firstSentence(
          jsonEncode({'sentences': ['  ', 'The second one.']}),
        ),
        'The second one.',
      );
    });

    test('a row that will not decode shows nothing', () {
      // Which is what every other surface would do with it too.
      expect(HomeScreenWidget.firstSentence('not json'), isNull);
      expect(HomeScreenWidget.firstSentence('{"sentences": "a string"}'), isNull);
      expect(HomeScreenWidget.firstSentence('{}'), isNull);
    });
  });

  test('the day is the local one, which is what the rows are keyed by', () {
    expect(HomeScreenWidget.isoDate(DateTime(2026, 1, 5, 23, 30)), '2026-01-05');
    expect(HomeScreenWidget.isoDate(DateTime(2026, 12, 31)), '2026-12-31');
  });
}

class _Sink implements HomeWidgetSink {
  String? sentence;
  String? date;
  String? today;
  int published = 0;

  @override
  Future<void> publish({
    required String? sentence,
    required String? date,
    required String today,
  }) async {
    published++;
    this.sentence = sentence;
    this.date = date;
    this.today = today;
  }
}
