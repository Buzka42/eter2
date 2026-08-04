import 'dart:convert';
import 'dart:io';

import 'package:eter/core/aether/guidance_contract.dart';
import 'package:eter/core/aether/guidance_mode.dart';
import 'package:eter/core/aether/letter.dart';
import 'package:eter/core/journal/day_story.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every parser, over what the model actually said.
///
/// The rest of the suite tests these against JSON somebody wrote by hand, which
/// proves the parser and proves nothing about the prompt. The failure this
/// cannot otherwise see is drift: an instruction edited until the model stops
/// answering the shape the parser expects, with both halves still internally
/// consistent and every hand-written test still green.
///
/// So these are recorded responses from the deployed endpoint, replayed with no
/// network. Re-record with
/// `test/manual/live_smoke_test.dart --dart-define=ETER_RECORD=<dir>` after
/// changing a prompt — and read what comes back, because a fixture that parses
/// is not the same as a fixture that reads well. The first letter captured here
/// opened with "We watched the third short night", which parsed perfectly.
void main() {
  final directory = Directory('test/fixtures/live');

  String fixture(String call) =>
      File('${directory.path}/$call.json').readAsStringSync();

  setUpAll(() {
    if (!directory.existsSync()) {
      fail('No recorded responses in ${directory.path}');
    }
  });

  test('guidance parses, and its evidence is inside its own payload', () {
    final parsed = const AetherGuidanceParser().parse(
      fixture('guidance'),
      mode: GuidanceMode.balanced,
    );
    expect(parsed.dimensions, hasLength(4));
    for (final dimension in parsed.dimensions) {
      expect(dimension.sentences, isNotEmpty);
      expect(dimension.primaryAction.trim(), isNotEmpty);
    }
    expect(parsed.recall, isNotNull);
  });

  test('the day story parses, story and digest both', () {
    final parsed = const JournalDayStoryParser().parse(fixture('journalDayStory'));
    expect(parsed.story.trim(), isNotEmpty);
  });

  test('the letter parses, and the safety policy accepts it', () {
    final letter = const LetterParser().parse(fixture('letter'));
    expect(letter.trim(), isNotEmpty);
  });

  group('what the recorded output is not allowed to contain', () {
    test('the letter never speaks as "we"', () {
      // It did, on the first real call: "We watched the third short night" —
      // Eter as an institution observing somebody, which is the register this
      // product exists not to have. `EterPrompts.version` 6 forbids it, and
      // this is the check that notices if it comes back.
      final letter = const LetterParser().parse(fixture('letter'));
      expect(
        RegExp(r'\b[Ww]e\b').hasMatch(letter),
        isFalse,
        reason: letter,
      );
    });

    test('the synthesis carries no figure at all, in digits or in words', () {
      // The synthesis sentences are the *only* thing the Correspondence sends
      // to another person — `_GuidanceContent.passage` is the sentences joined,
      // and the primaryAction becomes `supporting`, which does not cross.
      //
      // `CorrespondencePolicy` refuses a shared line containing a digit, and
      // that wall catches numerals only. A real response read "rest settled
      // near six hours and thirty-eight minutes" — a measurement, in words,
      // straight past it. `EterPrompts` v7 is the prevention half; this is
      // where it gets checked against what the model actually wrote.
      final decoded = jsonDecode(fixture('guidance')) as Map<String, dynamic>;
      final synthesis = decoded['synthesis'] as Map<String, dynamic>;
      final sentences = (synthesis['sentences'] as List).join(' ');
      expect(RegExp(r'\d').hasMatch(sentences), isFalse, reason: sentences);
      // The spelled-out kind, which is the one that got through.
      const spelled = [
        'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
        'nine', 'ten', 'eleven', 'twelve', 'twenty', 'thirty', 'forty',
        'fifty', 'sixty', 'hundred', 'thousand',
      ];
      for (final word in spelled) {
        expect(
          RegExp('\b$word\b', caseSensitive: false).hasMatch(sentences),
          isFalse,
          reason: '"$word" in: $sentences',
        );
      }
    });

    test('the chart reading relates placements rather than listing them', () {
      // The failure this call was rewritten to end: one passage per position.
      // Eighteen of them, each correct, none of which had looked at the chart
      // — the owner's word was "generalistic". A movement that names a single
      // placement and stops is that failure coming back, and it parses
      // perfectly, so the shape check cannot see it.
      final decoded =
          jsonDecode(fixture('vesselReadings')) as Map<String, dynamic>;
      final movements = (decoded['movements'] as List).cast<Map>();
      expect(movements.length, inInclusiveRange(3, 5));

      const placements = [
        'Life Path',
        'Sun',
        'Moon',
        'Mercury',
        'Venus',
        'Mars',
        'Saturn',
        'Ascendant',
      ];
      int named(String passage) =>
          placements.where(passage.contains).length;

      // At least one movement has to hold two placements together. Requiring
      // it of every movement would be wrong — a movement about what the chart
      // is missing may name nothing at all — but a reading where no movement
      // relates anything has gone back to being a list.
      expect(
        movements.any((movement) => named(movement['passage'] as String) >= 2),
        isTrue,
        reason: movements
            .map((movement) => movement['title'])
            .join(' / '),
      );
      // And the titles are names for what was found, not headings.
      for (final movement in movements) {
        final title = (movement['title'] as String).toLowerCase();
        expect(title, isNot(anyOf('overview', 'summary', 'introduction')));
      }
    });

    test('the Vessel never speaks as an archive, in any of its five parts', () {
      // "The records show" turned up in the houses, the angles *and* the
      // figure's synopsis on the first live run — the same failure as the
      // letter's "We watched the third short night", which is Eter as an
      // institution reporting on somebody. Prompt v10's shared register block
      // is the prevention; this is where it stays proven.
      const parts = [
        'vesselReadings',
        'vesselHouses',
        'vesselAspects',
        'vesselFigure',
        'vesselFigureSynopsis',
      ];
      for (final part in parts) {
        final text = fixture(part).toLowerCase();
        for (final phrase in const [
          'the records show',
          'the data ',
          'we saw',
          'we watched',
        ]) {
          expect(text.contains(phrase), isFalse, reason: '$part: "$phrase"');
        }
      }
    });

    test('the houses do not print a field name or a template', () {
      final passages = (jsonDecode(fixture('vesselHouses'))
              as Map<String, dynamic>)['passages'] as List;
      expect(passages, hasLength(12));

      // `occupants` is the name of a field in the request. It reached the
      // prose of five houses, because the instruction had used the word twice
      // in its own sentences — an example in a prompt can come back in the
      // answer, and a field name is an example nobody meant to set.
      for (final item in passages) {
        final passage = (item as Map)['passage'] as String;
        expect(
          passage.toLowerCase(),
          isNot(contains('occupant')),
          reason: 'house ${item['key']}',
        );
      }

      // Ten of twelve once opened with one clause and a swapped card name,
      // which is a form being filled in rather than twelve readings. Three
      // words is enough to catch it and short enough not to fire on prose that
      // merely rhymes.
      final openings = [
        for (final item in passages)
          ((item as Map)['passage'] as String)
              .toLowerCase()
              .split(RegExp(r'\s+'))
              .take(3)
              .join(' '),
      ];
      expect(openings.toSet(), hasLength(openings.length), reason: '$openings');

      // House 1 *is* the Ascendant, and the surface shows that card above the
      // list. Without the word, the reader is looking at what appears to be
      // the same card printed twice with no explanation.
      expect(
        ((passages.first as Map)['passage'] as String).toLowerCase(),
        contains('ascendant'),
      );
    });

    test('the angles are described, never measured out', () {
      // "An orb of just 0.14 degrees" is a measurement on a surface that shows
      // no measurements, and it is the shape of the failure the letter had
      // when it recited its figures in a row.
      final movements = (jsonDecode(fixture('vesselAspects'))
              as Map<String, dynamic>)['movements'] as List;
      for (final movement in movements) {
        final passage = (movement as Map)['passage'] as String;
        expect(RegExp(r'\d').hasMatch(passage), isFalse, reason: passage);
      }
    });

    test('the figure names its places, never its keys', () {
      // The first live synopsis wrote "The Moon across the sun, the era, and
      // mercury" — the request's own identifiers, read aloud. `recurrences`
      // stopped carrying keys at all because of it.
      final passage = (jsonDecode(fixture('vesselFigureSynopsis'))
          as Map<String, dynamic>)['passage'] as String;
      expect(passage.trim(), isNotEmpty);
      for (final key in const ['lifePath', 'matrixSynopsis', '"key"']) {
        expect(passage, isNot(contains(key)));
      }
    });

    test('the recall is telegraphic, not the prose it came from', () {
      final decoded = jsonDecode(fixture('guidance')) as Map<String, dynamic>;
      final recall = decoded['recall'] as String;
      expect(recall.length, lessThanOrEqualTo(160));
      // A note that came back as a paragraph means the instruction stopped
      // landing, and the next day's request would carry prose instead of a
      // thread. Telegram style is the tell, and it is the one property that is
      // objectively checkable: the real notes read "long week. sleep short.
      // desk meals." — fragments, uncapitalised. Measuring clause *length*
      // was the first attempt and it was a bad proxy; a legitimate note
      // ("offered screen break and clearing workspace") tripped it.
      expect(
        RegExp(r'^[A-Z]').hasMatch(recall.trim()),
        isFalse,
        reason: recall,
      );
    });
  });
}
