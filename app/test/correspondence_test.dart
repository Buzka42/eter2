import 'package:eter/core/correspondence/correspondence.dart';
import 'package:flutter_test/flutter_test.dart';

/// The boundary of the only feature in Eter where one person's device shows
/// another person's day.
///
/// Every other bug in the Correspondence shows you the wrong sentence. A bug
/// here shows somebody else your body, so the policy is checked on the way out
/// and again on the way in, and both directions are tested.
void main() {
  CorrespondenceLine line(String sentence, {String date = '2026-07-31'}) =>
      CorrespondenceLine(date: date, sentence: sentence);

  group('what may cross', () {
    test('a sentence of guidance', () {
      final checked = CorrespondencePolicy.check(
        line('A slower start would suit today better than a hard one.'),
      );
      expect(checked.sentence, startsWith('A slower start'));
    });

    test('nothing carrying a measurement, even in words around it', () {
      // Eter's synthesis never quotes a figure — the numbers live in
      // `evidence`, which does not cross. A digit here means something
      // upstream changed, and trimming it would leave a sentence still *about*
      // the measurement.
      expect(
        () => CorrespondencePolicy.check(line('You slept 5 hours again.')),
        throwsA(isA<CorrespondenceRefusal>()),
      );
      expect(
        () => CorrespondencePolicy.check(line('Resting heart rate is 58.')),
        throwsA(isA<CorrespondenceRefusal>()),
      );
    });

    test('nothing longer than one sentence', () {
      expect(
        () => CorrespondencePolicy.check(line('a' * 401)),
        throwsA(isA<CorrespondenceRefusal>()),
      );
    });

    test('nothing empty, and nothing undated', () {
      expect(
        () => CorrespondencePolicy.check(line('   ')),
        throwsA(isA<CorrespondenceRefusal>()),
      );
      expect(
        () => CorrespondencePolicy.check(line('A line.', date: 'someday')),
        throwsA(isA<CorrespondenceRefusal>()),
      );
      expect(
        () => CorrespondencePolicy.check(line('A line.', date: '2026-02-31')),
        throwsA(isA<CorrespondenceRefusal>()),
      );
    });
  });

  group('what arrives', () {
    test('is checked again, not trusted because it came from a peer', () {
      // Outbound protects them from this device. Inbound protects this device
      // from a compromised peer, a stale document, or a bug on the other end.
      expect(
        () => CorrespondenceLine.fromJson({
          'date': '2026-07-31',
          'sentence': 'You logged 1800 kcal.',
        }),
        throwsA(isA<CorrespondenceRefusal>()),
      );
    });

    test('is refused when it is not a line at all', () {
      expect(
        () => CorrespondenceLine.fromJson({'date': 5, 'sentence': null}),
        throwsA(isA<CorrespondenceRefusal>()),
      );
      expect(
        () => CorrespondenceLine.fromJson(const {}),
        throwsA(isA<CorrespondenceRefusal>()),
      );
    });

    test('round-trips through its own JSON', () {
      final sent = CorrespondencePolicy.check(line('A quiet day, by the look.'));
      final received = CorrespondenceLine.fromJson(sent.toJson());
      expect(received.date, sent.date);
      expect(received.sentence, sent.sentence);
    });

    test('carries no identity', () {
      // The gateway knows whose document it read. A payload that carries an
      // identity is a payload that can leak one.
      expect(line('A day.').toJson().keys, unorderedEquals(['date', 'sentence']));
    });
  });

  group('only today is shown', () {
    test('yesterday’s sentence is not today’s', () {
      // It appears as one unlabelled line beneath today's guidance, so a stale
      // one sitting there would read as today's.
      expect(
        CorrespondencePolicy.isCurrent(
          line('A day.', date: '2026-07-30'),
          today: '2026-07-31',
        ),
        isFalse,
      );
      expect(
        CorrespondencePolicy.isCurrent(line('A day.'), today: '2026-07-31'),
        isTrue,
      );
    });
  });

  group('the pairing code', () {
    test('leaves out every glyph that fails when read aloud', () {
      for (final ambiguous in const ['0', 'O', '1', 'I', 'L']) {
        expect(
          PairingCode.alphabet.contains(ambiguous),
          isFalse,
          reason: ambiguous,
        );
      }
    });

    test('forgives case, spaces and hyphens', () {
      expect(PairingCode.normalise(' 23fg-hjkm '), '23FGHJKM');
      expect(PairingCode.isWellFormed(PairingCode.normalise('23fg hjkm')), isTrue);
    });

    test('does not repair an excluded glyph into a different valid code', () {
      // A bearer token that silently corrects itself hands somebody else's
      // code to whoever typed a near miss.
      expect(PairingCode.isWellFormed(PairingCode.normalise('23FGHJKO')), isFalse);
      expect(PairingCode.isWellFormed('SHORT'), isFalse);
    });

    test('is long enough that guessing is not a strategy', () {
      // 31^8 is about 2^39, against a rule that only lets a signed-in caller
      // read a code they can already name.
      expect(PairingCode.length, greaterThanOrEqualTo(8));
      expect(PairingCode.alphabet.length, greaterThanOrEqualTo(31));
    });
  });
}
