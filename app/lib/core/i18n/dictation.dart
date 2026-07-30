import 'language.dart';

/// Which locale the speech recogniser should be asked to listen in.
///
/// Dictation is the one place where Eter's language is a claim about the
/// *device* rather than about Eter. Every other surface can be Polish because
/// Eter says so; dictation can only be Polish if the phone actually has a Polish
/// acoustic model, and that is not something the app can install.
///
/// Getting this wrong is worse than it sounds. A recogniser handed a locale it
/// has never heard of does not refuse — it falls back to its own default and
/// transcribes Polish speech as English words. The result is a page of nonsense
/// that looks like Eter mangled the dictation, with nothing on screen to explain
/// it and nothing in the transcript to diagnose it from.
///
/// Extracted from the Journal as a pure function on purpose: it is the fiddliest
/// logic in the feature — four tag shapes, two platforms that normalise
/// differently, and a plugin that sometimes declines to enumerate at all — and
/// inside a `State` holding its own `SpeechToText` there was no way to test any
/// of it.
abstract final class DictationLocale {
  /// The locale id to pass to `speech_to_text`, or null when the recogniser has
  /// nothing for [language].
  ///
  /// [available] is the plugin's own list of `LocaleName.localeId` values, in the
  /// order it reported them. Matching runs in three passes:
  ///
  /// 1. **The exact id**, case-insensitively — `pl_PL` when the language asked
  ///    for `pl_PL`.
  /// 2. **Any region of the same language**, so a phone carrying only `en_GB`
  ///    still dictates for an `en_US` request, and `pl-PL` matches `pl_PL`
  ///    across the separator difference between Android and iOS.
  /// 3. **Nothing.** Null, and the Journal says which language is missing rather
  ///    than blaming the microphone permission the person already granted.
  ///
  /// An *empty* list is the one case that does not mean "not installed": some
  /// Android recognisers decline to enumerate their locales while still
  /// dictating perfectly well. Refusing there would break dictation on working
  /// phones, so the request goes through unchanged and the recogniser decides.
  static String? resolve({
    required AppLanguage language,
    required List<String> available,
  }) {
    if (available.isEmpty) return language.speechLocaleId;

    final wanted = language.speechLocaleId.toLowerCase();
    for (final id in available) {
      if (id.toLowerCase() == wanted) return id;
    }

    final subtag = _subtag(language.speechLocaleId);
    for (final id in available) {
      if (_subtag(id) == subtag) return id;
    }
    return null;
  }

  /// The language part of a locale id, lower-cased.
  ///
  /// Splits on both separators because Android reports `pl_PL` and iOS reports
  /// `pl-PL`, and a build that only understood one would silently fall through
  /// to "not installed" on the other.
  static String _subtag(String localeId) =>
      localeId.split(RegExp('[_-]')).first.toLowerCase();
}

/// Why dictation stopped, in terms a sentence can be written about.
///
/// The recogniser reports its own codes — `error_no_match`,
/// `error_language_not_supported` — and they are useless to a person and
/// different on each platform. Mapping them here rather than inside the Journal
/// means the mapping is testable, which matters because the codes that actually
/// happen mean very different things: try again, grant something, connect
/// something, install something, or give up on this phone. Telling somebody to
/// tap and try again when the real answer is "your phone has no Polish" is the
/// one outcome worth engineering against.
enum DictationFailure {
  /// The microphone was refused, or the audio session could not open.
  microphone,

  /// Nothing was said, or nothing was recognised in it.
  nothingHeard,

  /// This recogniser needs a network and there is none.
  connection,

  /// The recogniser has nothing for Eter's language after all.
  ///
  /// Reached even though `DictationLocale.resolve` checked first: a downloaded
  /// language pack can go missing, and some recognisers only hold a language
  /// online. Rare, and the one failure whose advice is completely different.
  languageMissing,

  /// Anything else. The honest answer is that it stopped and can be retried.
  stopped;

  /// Maps a `speech_to_text` error code onto one of the five.
  ///
  /// Unknown codes become [stopped] deliberately: a code this build has never
  /// seen is not grounds for guessing at a cause, and "it stopped, you can try
  /// again or type" is true of all of them.
  static DictationFailure fromRecogniserCode(String code) => switch (code) {
        'error_permission' ||
        'error_insufficient_permissions' ||
        'error_audio_error' =>
          microphone,
        'error_no_match' || 'error_speech_timeout' => nothingHeard,
        'error_network' || 'error_network_timeout' => connection,
        'error_language_not_supported' ||
        'error_language_unavailable' =>
          languageMissing,
        _ => stopped,
      };
}
