import 'package:eter/core/ai/prompts.dart';
import 'package:eter/core/i18n/language.dart';
import 'package:eter/core/journal/classification_contract.dart';
import 'package:flutter_test/flutter_test.dart';

/// The body an energy estimate is made against.
///
/// Owner's decision, 4 August, and a change to what crosses the boundary: a
/// model asked what a described training cost was estimating for nobody, since
/// it was told nothing about the body doing it.
void main() {
  String promptFor(JournalBodyContext body) => EterPrompts.journalInterpretation(
        entryText: 'Ran for half an hour along the river.',
        language: AppLanguage.english,
        body: body,
      ).system;

  test('the body reaches the instruction when there is one', () {
    final system = promptFor(const JournalBodyContext(
      weightKg: 88,
      heightCm: 180,
      bodyFatPercent: 10,
      ageYears: 33,
      sex: 'male',
    ));
    expect(system, contains('"weightKg":88'));
    expect(system, contains('"bodyFatPercent":10'));
    expect(system, contains('"ageYears":33'));
  });

  test('an absent field is omitted, never defaulted', () {
    // A guessed body produces a confident number about somebody who never gave
    // one, which is the failure this product exists not to have.
    const partial = JournalBodyContext(weightKg: 88, sex: 'male');
    expect(partial.toJson().containsKey('bodyFatPercent'), isFalse);
    expect(partial.toJson().containsKey('heightCm'), isFalse);

    final system = promptFor(partial);
    expect(system, contains('"weightKg":88'));
    expect(system, isNot(contains('bodyFatPercent')));
    // And it says what it could not account for.
    expect(system, contains('do not treat'));
  });

  test('no body at all says so, rather than inventing an average', () {
    final system = promptFor(const JournalBodyContext());
    expect(system, contains('You are given nothing about this body'));
    expect(system, contains('Do not invent a weight'));
  });

  test('identity still never crosses', () {
    // An age in years is a number; a date of birth is not sent, and neither is
    // a name or a place. The same rule guidance already follows.
    final body = const JournalBodyContext(
      weightKg: 88,
      ageYears: 33,
      sex: 'male',
    ).toJson();
    expect(body.keys, everyElement(isNot(contains('dob'))));
    expect(body.keys, everyElement(isNot(contains('name'))));
    expect(body.containsKey('ageYears'), isTrue);
  });

  test('the energy estimate is asked for against that body', () {
    final system = promptFor(const JournalBodyContext(weightKg: 88));
    expect(system, contains('Estimate the energy against the body above'));
    // Lifting is still device arithmetic: the sets and the body weight are
    // enough, and the model is told not to guess at it.
    expect(system, contains('Do not estimate the energy'));
  });
}
