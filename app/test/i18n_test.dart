import 'dart:ui' show Locale;

import 'package:eter/core/account/account.dart';
import 'package:eter/core/arcana/matrix.dart';
import 'package:eter/core/arcana/zodiac.dart';
import 'package:eter/core/health/record_error.dart';
import 'package:eter/core/patterns/daily_series.dart';
import 'package:eter/core/i18n/language.dart';
import 'package:eter/core/i18n/strings.dart';
import 'package:eter/core/i18n/strings_en.dart';
import 'package:eter/core/i18n/strings_pl.dart';
import 'package:eter/core/profile/birth_context.dart';
import 'package:eter/core/profile/birth_time.dart';
import 'package:eter/core/sync/cloud_mirror.dart';
import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rules the language layer has to keep, in every language.
///
/// The analyzer already guarantees that both tables answer every member — that
/// is the whole reason `EterStrings` is an abstract class rather than a map. What
/// it cannot check is whether the answers are *usable*: an override that returns
/// an empty string, or that quietly hands back an English identifier because a
/// `switch` fell through to its default, compiles perfectly and renders a blank
/// or a leaked key. That is what this file is for.
void main() {
  group('resolving which language is in force', () {
    test('a stored choice is obeyed', () {
      expect(AppLanguage.forProfile('pl'), AppLanguage.polish);
      expect(AppLanguage.forProfile('en'), AppLanguage.english);
    });

    test('an unrecognised code speaks English rather than throwing', () {
      // A profile row is the one thing that has to keep opening the app. A
      // language code no version of Eter ever wrote is not a reason to refuse.
      expect(AppLanguage.fromCode('de'), AppLanguage.english);
      expect(AppLanguage.fromCode(''), AppLanguage.english);
      expect(AppLanguage.fromCode(null), AppLanguage.english);
    });

    test('no choice follows the phone, matched on the language subtag', () {
      expect(
        AppLanguage.resolveFromPlatform(locales: const [Locale('pl', 'PL')]),
        AppLanguage.polish,
      );
      // A Pole living in Germany still reads Polish.
      expect(
        AppLanguage.resolveFromPlatform(locales: const [Locale('pl', 'DE')]),
        AppLanguage.polish,
      );
      expect(
        AppLanguage.resolveFromPlatform(locales: const [Locale('pl')]),
        AppLanguage.polish,
      );
    });

    test('the device preference order is respected', () {
      // Somebody who prefers French but also reads Polish gets Polish, not
      // English: the first *supported* language in their own order wins.
      expect(
        AppLanguage.resolveFromPlatform(
          locales: const [Locale('fr'), Locale('pl'), Locale('en')],
        ),
        AppLanguage.polish,
      );
    });

    test('a phone in a language Eter does not speak gets English', () {
      expect(
        AppLanguage.resolveFromPlatform(locales: const [Locale('ja')]),
        AppLanguage.english,
      );
      expect(
        AppLanguage.resolveFromPlatform(locales: const []),
        AppLanguage.english,
      );
    });

    test('null means unchosen, which is not the same as choosing English', () {
      // The distinction the nullable column exists for: an install that has
      // never been asked follows the phone, so switching the OS to Polish is
      // met in Polish. Storing `'en'` on first launch would have frozen it.
      expect(
        AppLanguage.forProfile(null),
        AppLanguage.resolveFromPlatform(),
      );
    });

    test('the locale carries no region', () {
      // Eter varies by language, never by region. A region would fork the string
      // tables and the asset directories for no gain.
      for (final language in AppLanguage.values) {
        expect(language.locale, Locale(language.code));
        expect(language.locale.countryCode, isNull);
      }
    });
  });

  group('every table answers everything, in its own language', () {
    for (final language in AppLanguage.values) {
      final strings = EterStrings.forLanguage(language);

      test('${language.code}: the table reports the language it speaks', () {
        expect(strings.language, language);
      });

      test('${language.code}: no lookup returns an empty string', () {
        // Every keyed lookup, exercised over its whole domain. A `switch` whose
        // default returns the canonical key is how a Polish screen ends up
        // showing `waxing crescent`, and the default is invisible until the one
        // value that reaches it does.
        for (final element in Element.values) {
          expect(strings.elementName(element), isNotEmpty);
          expect(strings.elementMedallionSemantic(element), isNotEmpty);
        }
        for (final position in MatrixPosition.values) {
          expect(strings.matrixPositionLabel(position), isNotEmpty);
          expect(strings.matrixPositionDetail(position), isNotEmpty);
        }
        for (final period in BirthTimePeriod.values) {
          expect(strings.birthPeriodLabel(period), isNotEmpty);
          expect(strings.birthPeriodDetail(period), isNotEmpty);
        }
        for (final failure in AccountFailure.values) {
          expect(strings.accountFailure(failure), isNotEmpty);
        }
        for (final refusal in SyncRefusal.values) {
          expect(strings.syncRefusal(refusal), isNotEmpty);
        }
        for (final error in BirthContextError.values) {
          expect(strings.birthContextError(error), isNotEmpty);
        }
        for (final error in BodyRecordError.values) {
          expect(strings.bodyRecordError(error), isNotEmpty);
        }
      });

      test('${language.code}: every Arcana card has a title', () {
        for (final slug in _arcanaSlugs) {
          final title = strings.arcanaTitle(slug);
          expect(title, isNotEmpty, reason: slug);
          // The slug leaking through means the switch fell to its default.
          expect(title, isNot(slug), reason: '$slug fell through to default');
        }
      });

      test('${language.code}: every sign, body, aspect and phase is named', () {
        for (final sign in Zodiac.values) {
          expect(strings.signName(sign.label), isNotEmpty);
        }
        for (final name in _engineBodyNames()) {
          expect(strings.bodyName(name), isNotEmpty, reason: name);
        }
        for (final aspect in _aspects) {
          expect(strings.aspectName(aspect), isNotEmpty, reason: aspect);
        }
        for (final phase in _moonPhases) {
          expect(strings.moonPhaseName(phase), isNotEmpty, reason: phase);
        }
      });

      test('${language.code}: every sleep stage and dimension is named', () {
        for (final stage in const [
          'deep',
          'light',
          'rem',
          'awake',
          'unknown',
        ]) {
          final name = strings.sleepStageName(stage);
          expect(name, isNotEmpty, reason: stage);
          expect(name, isNot(stage), reason: '$stage fell through to default');
        }
        for (final dimension in const [
          'health',
          'mind',
          'spirit',
          'synthesis',
        ]) {
          final name = strings.guidanceDimension(dimension);
          expect(name, isNotEmpty, reason: dimension);
          expect(name, name.toUpperCase(), reason: '$dimension is not caps');
        }
      });

      test('${language.code}: the endonym names the language in itself', () {
        expect(language.endonym, isNotEmpty);
        // Never translated: a picker row reading "Polish" is no use to somebody
        // who needs it. Both tables see the same word.
        expect(
          EterStrings.forLanguage(AppLanguage.english).language.endonym,
          AppLanguage.english.endonym,
        );
      });
    }
  });

  group('Polish is actually Polish', () {
    const en = EterStringsEn();
    const pl = EterStringsPl();

    test('nothing was left in English by accident', () {
      // A spot check across surfaces rather than a blanket diff: `wordmark`,
      // `motto` and the unit `ms` and `kg` are deliberately identical, so a
      // whole-table inequality assertion would be wrong. These are sentences.
      for (final pair in <(String, String)>[
        (en.howEterMeetsYou, pl.howEterMeetsYou),
        (en.writingFieldHint, pl.writingFieldHint),
        (en.guidanceNotComposedYet, pl.guidanceNotComposedYet),
        (en.theVessel, pl.theVessel),
        (en.headingSanctum, pl.headingSanctum),
        (en.welcomeTitle, pl.welcomeTitle),
        (en.consentStepTitle, pl.consentStepTitle),
        (en.deleteEntryTitle, pl.deleteEntryTitle),
        (en.restoreOnlyFillsEmptyDevice, pl.restoreOnlyFillsEmptyDevice),
      ]) {
        expect(pair.$2, isNot(pair.$1));
      }
    });

    test('the product and the Latin motto are never translated', () {
      expect(pl.wordmark, en.wordmark);
      expect(pl.motto, en.motto);
      expect(pl.motto, 'Anima Sana In Corpore Sano');
    });

    test('the tutorial has four passages in both languages', () {
      expect(en.tutorialPassages, hasLength(4));
      expect(pl.tutorialPassages, hasLength(4));
      for (var i = 0; i < 4; i++) {
        expect(pl.tutorialPassages[i].lines,
            hasLength(en.tutorialPassages[i].lines.length));
        for (final line in pl.tutorialPassages[i].lines) {
          expect(line, isNotEmpty);
        }
      }
    });

    group('plurals take all three Polish forms', () {
      // Polish has one form for 1, one for 2–4, and one for 5+ — with the trap
      // that the teens take the many form while 22–24 go back to the few form.
      // A two-form English-shaped plural gets 2, 5 and 22 wrong.
      test('days', () {
        expect(pl.windowDays(1), '1 dzień');
        expect(pl.windowDays(3), '3 dni');
        expect(pl.windowDays(7), '7 dni');
      });

      test('records, across the teens and back again', () {
        expect(pl.copiedRecords(1), contains('1 zapis.'));
        expect(pl.copiedRecords(2), contains('2 zapisy'));
        expect(pl.copiedRecords(5), contains('5 zapisów'));
        // 12 is a teen: many, not few.
        expect(pl.copiedRecords(12), contains('12 zapisów'));
        // 22 ends in 2 and is not a teen: few again.
        expect(pl.copiedRecords(22), contains('22 zapisy'));
        expect(pl.copiedRecords(25), contains('25 zapisów'));
      });

      test('journal entries', () {
        expect(pl.retrospectiveJournal(1), contains('1 wpis '));
        expect(pl.retrospectiveJournal(3), contains('3 wpisy'));
        expect(pl.retrospectiveJournal(11), contains('11 wpisów'));
      });
    });

    test('signs decline into the locative for "the Moon in …"', () {
      // The reason `positionsSummary` takes canonical names rather than
      // already-localised ones: `Ryby` becomes `Rybach`, and no amount of
      // string concatenation gets there from the nominative.
      final summary = pl.positionsSummary(
        moonPhaseCanonical: 'full',
        moonSignCanonical: 'Pisces',
        sunSignCanonical: 'Aries',
      );
      expect(summary, contains('pełni'));
      expect(summary, contains('w Rybach'));
      expect(summary, contains('w Baranie'));
      // And never the bare nominative, which would read as a typo.
      expect(summary, isNot(contains('w Ryby')));
    });

    test('the Sun sentence declines too, and states an absent sign', () {
      expect(pl.sunSitsIn('Capricorn'), contains('w Koziorożcu'));
      expect(pl.sunSitsIn(null), contains('własnym znaku'));
      expect(en.sunSitsIn(null), contains('its own sign'));
    });
  });

  group('what must never be translated', () {
    test('a canonical identifier passes through English unchanged', () {
      // English is the reference table, and its lookups are the identity for
      // exactly the values other layers key on. If one of these ever started
      // returning something else, the chart engine and the contracts would
      // disagree with the screen.
      const strings = EterStringsEn();
      for (final sign in Zodiac.values) {
        expect(strings.signName(sign.label), sign.label);
      }
      for (final name in _engineBodyNames()) {
        expect(strings.bodyName(name), name);
      }
      for (final aspect in _aspects) {
        expect(strings.aspectName(aspect), aspect);
      }
      for (final phase in _moonPhases) {
        expect(strings.moonPhaseName(phase), phase);
      }
    });

    test('the dictation locale is a plugin id, not a BCP 47 tag', () {
      // Underscored and region-qualified, because that is the shape
      // `speech_to_text` uses on both platforms. Reusing it as a locale tag
      // would silently fail to match.
      expect(AppLanguage.english.speechLocaleId, 'en_US');
      expect(AppLanguage.polish.speechLocaleId, 'pl_PL');
      for (final language in AppLanguage.values) {
        expect(language.speechLocaleId, contains('_'));
        expect(language.speechLocaleId, startsWith(language.code));
      }
    });

    test('the model is told the language in English', () {
      // An English directive inside an otherwise-English system prompt is
      // followed far more reliably than the same directive in the target
      // language. See `EterPrompts.languageFor`.
      expect(AppLanguage.polish.modelName, 'Polish');
      expect(AppLanguage.english.modelName, 'English');
    });
  });

  group('locally composed prose', () {
    // The three sentences Eter writes itself rather than asking Aether for. They
    // are the ones that would have silently stayed English in a translated
    // build, because no prompt is involved to carry a language instruction.
    for (final language in AppLanguage.values) {
      final strings = EterStrings.forLanguage(language);

      test('${language.code}: every daily series has a spoken name', () {
        for (final definition in dailySeriesDefinitions) {
          final label = strings.seriesLabel(definition.key);
          expect(label, isNotEmpty, reason: definition.key);
          expect(
            label,
            isNot(definition.key),
            reason: '${definition.key} fell through to default',
          );
        }
      });

      test('${language.code}: a sweep finding reads as a sentence', () {
        for (final lagged in const [true, false]) {
          for (final positive in const [true, false]) {
            final summary = strings.patternSweepSummary(
              fromKey: 'activeKcal',
              toKey: 'sleep',
              lagged: lagged,
              positive: positive,
              percent: 18,
              days: 42,
            );
            expect(summary, isNotEmpty);
            // The receipt is the part that stops it being a horoscope.
            expect(summary, contains('18'));
            expect(summary, contains('42'));
            expect(summary, endsWith('.'));
            // And the series are named, not keyed.
            expect(summary, isNot(contains('activeKcal')));
            expect(summary, isNot(contains('sleep,')));
          }
        }
      });

      test('${language.code}: the retrospective states its window and caveat',
          () {
        expect(strings.retrospectiveHeadline(complete: true), isNotEmpty);
        expect(strings.retrospectiveHeadline(complete: false), isNotEmpty);
        expect(
          strings.retrospectiveHeadline(complete: true),
          isNot(strings.retrospectiveHeadline(complete: false)),
        );
        expect(strings.retrospectiveCaveat, isNotEmpty);
        // The movement sentence grows a clause only when steps were measured.
        final withoutSteps = strings.retrospectiveMovement(
          days: 5,
          averageActiveKcal: 430,
        );
        final withSteps = strings.retrospectiveMovement(
          days: 5,
          averageActiveKcal: 430,
          averageSteps: 8200,
          stepDays: 4,
        );
        expect(withoutSteps, isNot(contains('8200')));
        expect(withSteps, contains('8200'));
        expect(withSteps.length, greaterThan(withoutSteps.length));
        expect(withoutSteps, endsWith('.'));
        expect(withSteps, endsWith('.'));
      });

      test('${language.code}: a lifestyle sentence names its kinds', () {
        final sentence = strings.retrospectiveLifestyle(
          signals: 3,
          kinds: const ['mood', 'stress'],
        );
        expect(sentence, contains(strings.lifestyleKindName('mood')));
        expect(sentence, contains(strings.lifestyleKindName('stress')));
        for (final kind in const [
          'mood',
          'stress',
          'recovery',
          'meditation',
          'breathwork',
        ]) {
          expect(strings.lifestyleKindName(kind), isNotEmpty, reason: kind);
          // English is deliberately the identity here — the stored kind *is*
          // the English word — so only Polish can be checked for a fallthrough.
          if (language == AppLanguage.polish) {
            expect(strings.lifestyleKindName(kind), isNot(kind),
                reason: '$kind fell through to default');
          }
        }
      });
    }
  });
}

const _arcanaSlugs = <String>[
  'the-fool',
  'the-magician',
  'the-high-priestess',
  'the-empress',
  'the-emperor',
  'the-hierophant',
  'the-lovers',
  'the-chariot',
  'strength',
  'the-hermit',
  'wheel-of-fortune',
  'justice',
  'the-hanged-man',
  'death',
  'temperance',
  'the-devil',
  'the-tower',
  'the-star',
  'the-moon',
  'the-sun',
  'judgement',
  'the-world',
];

const _aspects = <String>[
  'conjunction',
  'sextile',
  'square',
  'trine',
  'opposition',
];

const _moonPhases = <String>[
  'new',
  'waxing crescent',
  'first quarter',
  'waxing gibbous',
  'full',
  'waning gibbous',
  'last quarter',
  'waning crescent',
];

/// The bodies the chart engine actually emits, so a new one fails this file
/// rather than rendering untranslated.
Set<String> _engineBodyNames() {
  final chart = NatalChartEngine().calculate(
    NatalInput(
      localDateTime: DateTime(1990, 5, 14, 9, 30),
      utcOffsetMinutes: 120,
      latitude: 52.2297,
      longitude: 21.0122,
    ),
  );
  return chart.positions.map((position) => position.name).toSet();
}
