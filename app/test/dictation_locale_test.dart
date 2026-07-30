import 'package:eter/core/i18n/dictation.dart';
import 'package:eter/core/i18n/language.dart';
import 'package:eter/core/i18n/strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which locale dictation asks for, and what happens when the phone has none.
///
/// This is the only part of the translation that depends on the *device* rather
/// than on Eter. Every other surface is Polish because Eter says so; dictation is
/// Polish only if the phone carries a Polish acoustic model, and no amount of
/// application code installs one.
///
/// The failure being prevented is a quiet one. A recogniser handed a locale it
/// does not have will not refuse — it falls back to its own default and
/// transcribes Polish speech as English words. What lands on the page is nonsense
/// that reads as though Eter mangled the dictation, and there is nothing on
/// screen or in the transcript to tell anyone otherwise.
void main() {
  String? resolve(AppLanguage language, List<String> available) =>
      DictationLocale.resolve(language: language, available: available);

  group('the exact locale, when the phone has it', () {
    test('Polish gets pl_PL', () {
      expect(
        resolve(AppLanguage.polish, const ['en_US', 'pl_PL', 'de_DE']),
        'pl_PL',
      );
    });

    test('English gets en_US', () {
      expect(
        resolve(AppLanguage.english, const ['pl_PL', 'en_US']),
        'en_US',
      );
    });

    test('the exact id wins over another region of the same language', () {
      // Order in the device's list must not decide this: `en_GB` first is not a
      // reason to dictate British English for an `en_US` request.
      expect(
        resolve(AppLanguage.english, const ['en_GB', 'en_AU', 'en_US']),
        'en_US',
      );
    });

    test('case is not part of the match', () {
      // Some Android recognisers report `pl_pl`.
      expect(resolve(AppLanguage.polish, const ['pl_pl']), 'pl_pl');
      // And the id is returned exactly as the plugin gave it, not normalised —
      // it is handed straight back to that plugin.
      expect(resolve(AppLanguage.polish, const ['PL_pl']), 'PL_pl');
    });
  });

  group('any region of the right language', () {
    test('a hyphen still matches an underscore', () {
      // Android reports `pl_PL`, iOS reports `pl-PL`. A build that understood
      // only one would report dictation unavailable on the other platform.
      expect(resolve(AppLanguage.polish, const ['pl-PL']), 'pl-PL');
      expect(resolve(AppLanguage.english, const ['en-GB']), 'en-GB');
    });

    test('a bare language tag matches', () {
      expect(resolve(AppLanguage.polish, const ['pl']), 'pl');
    });

    test('a different region of the same language is accepted', () {
      // Better British English than no dictation. The words are the same.
      expect(resolve(AppLanguage.english, const ['en_GB']), 'en_GB');
      expect(resolve(AppLanguage.polish, const ['pl_DE']), 'pl_DE');
    });

    test('a language whose code is a prefix of another is not confused', () {
      // `pl` must not match `pl` inside something else, and must not be found
      // by a substring search. Only the subtag counts.
      expect(resolve(AppLanguage.polish, const ['pls_PL', 'xpl']), isNull);
      // `en` must not be satisfied by a language that merely contains it.
      expect(resolve(AppLanguage.english, const ['ben_IN']), isNull);
    });
  });

  group('when the phone has nothing for the language', () {
    test('Polish on an English-only phone refuses', () {
      // The important case, and the whole reason this function exists. Returning
      // `en_US` here would transcribe Polish speech into English words.
      expect(resolve(AppLanguage.polish, const ['en_US', 'en_GB']), isNull);
    });

    test('English on a Polish-only phone refuses', () {
      expect(resolve(AppLanguage.english, const ['pl_PL']), isNull);
    });

    test('the refusal names the language, not the microphone', () {
      // The sentence the Journal shows. Sending somebody to a permission they
      // have already granted is the wrong instruction, so the copy has to point
      // at the language.
      for (final language in AppLanguage.values) {
        final strings = EterStrings.forLanguage(language);
        final note = strings.dictationLanguageUnavailable(language.endonym);
        expect(note, contains(language.endonym));
        expect(note, isNot(contains('microphone')));
        expect(note, isNot(contains('mikrofon')));
        // And it says what can still be done instead.
        expect(note, isNotEmpty);
        expect(
          note,
          language == AppLanguage.polish
              ? contains('pisać')
              : contains('type'),
        );
      }
    });
  });

  group('an empty list is not the same as nothing installed', () {
    test('the request goes through unchanged', () {
      // Some Android recognisers decline to enumerate their locales while
      // dictating perfectly well. Refusing on an empty list would break
      // dictation on phones that support it — so the recogniser decides.
      expect(resolve(AppLanguage.polish, const []), 'pl_PL');
      expect(resolve(AppLanguage.english, const []), 'en_US');
    });

    test('it asks for exactly what the language declares', () {
      for (final language in AppLanguage.values) {
        expect(resolve(language, const []), language.speechLocaleId);
      }
    });
  });

  group('the ids Eter asks for are plugin ids', () {
    test('underscored and region-qualified, not BCP 47', () {
      // `speech_to_text` uses this shape on both platforms. Reusing a BCP 47 tag
      // here would silently fail to match on Android.
      expect(AppLanguage.polish.speechLocaleId, 'pl_PL');
      expect(AppLanguage.english.speechLocaleId, 'en_US');
      for (final language in AppLanguage.values) {
        expect(language.speechLocaleId, contains('_'));
        expect(language.speechLocaleId, startsWith(language.code));
        // And distinct from the `Locale` used for dates and Material strings,
        // which carries no region at all.
        expect(language.speechLocaleId, isNot(language.locale.toString()));
      }
    });

    test('a realistic device list resolves for both languages', () {
      // A Polish phone with Google's recogniser installed, roughly as reported.
      const onDevice = [
        'en_US',
        'en_GB',
        'pl_PL',
        'de_DE',
        'fr_FR',
        'es_ES',
      ];
      expect(resolve(AppLanguage.polish, onDevice), 'pl_PL');
      expect(resolve(AppLanguage.english, onDevice), 'en_US');
    });
  });

  group('why it stopped, and what to do about it', () {
    test('every code that actually happens is classified', () {
      // The set `speech_to_text` can produce. Grouped by the advice they earn,
      // which is the only reason the mapping exists.
      const cases = <String, DictationFailure>{
        'error_permission': DictationFailure.microphone,
        'error_insufficient_permissions': DictationFailure.microphone,
        'error_audio_error': DictationFailure.microphone,
        'error_no_match': DictationFailure.nothingHeard,
        'error_speech_timeout': DictationFailure.nothingHeard,
        'error_network': DictationFailure.connection,
        'error_network_timeout': DictationFailure.connection,
        'error_language_not_supported': DictationFailure.languageMissing,
        'error_language_unavailable': DictationFailure.languageMissing,
      };
      cases.forEach((code, expected) {
        expect(
          DictationFailure.fromRecogniserCode(code),
          expected,
          reason: code,
        );
      });
    });

    test('a language failure never says "try again"', () {
      // The bug this guards. A missing language used to fall through to the
      // generic "tap to try again", which is advice that cannot possibly work:
      // tapping again will fail identically until a language pack is installed.
      for (final language in AppLanguage.values) {
        final strings = EterStrings.forLanguage(language);
        final note = strings.dictationFailure(DictationFailure.languageMissing);
        expect(note, contains(language.endonym));
        expect(note, isNot(strings.dictationStopped));
        expect(
          note,
          strings.dictationLanguageUnavailable(language.endonym),
        );
      }
    });

    test('an unrecognised code is stopped, not guessed at', () {
      // A code this build has never seen is not grounds for inventing a cause.
      for (final code in const [
        'error_busy',
        'error_client',
        'error_server',
        'error_listen_failed',
        '',
        'something_new_in_a_future_android',
      ]) {
        expect(
          DictationFailure.fromRecogniserCode(code),
          DictationFailure.stopped,
          reason: code,
        );
      }
    });

    test('every failure has a sentence in every language', () {
      for (final language in AppLanguage.values) {
        final strings = EterStrings.forLanguage(language);
        for (final failure in DictationFailure.values) {
          final note = strings.dictationFailure(failure);
          expect(note, isNotEmpty, reason: '${language.code}/${failure.name}');
          // No recogniser code ever reaches the page.
          expect(note, isNot(contains('error_')), reason: failure.name);
        }
      }
    });

    test('the five outcomes are five different sentences', () {
      // If two collapsed together the distinction would be decorative, and the
      // advice would be wrong for one of them.
      for (final language in AppLanguage.values) {
        final strings = EterStrings.forLanguage(language);
        final notes = {
          for (final failure in DictationFailure.values)
            strings.dictationFailure(failure),
        };
        expect(notes, hasLength(DictationFailure.values.length),
            reason: language.code);
      }
    });
  });
}
