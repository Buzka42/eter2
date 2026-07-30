import 'dart:ui' show Locale, PlatformDispatcher;

/// Which language Eter speaks.
///
/// Two, and the pair is deliberate rather than a first instalment. English is
/// the language the product was written in; Polish is the language it is
/// actually used in. Adding a third means writing a third [EterStrings], a
/// third set of `assets/content/<code>/`, and a third column of goldens — the
/// work is bounded and visible, which is the point of a sealed enum over a map
/// of translation files that can silently go half-empty.
///
/// The name is deliberately not `Locale`. Eter never varies by region: there is
/// no en_GB that spells "kilocalories" differently from en_US, and no pl_PL
/// distinct from a pl anywhere else. What varies is the language, and the four
/// codes below are the whole of what the rest of the app needs to know.
enum AppLanguage {
  english(
    code: 'en',
    endonym: 'English',
    speechLocaleId: 'en_US',
    modelName: 'English',
  ),

  /// Addressed informally — second person singular, no honorifics. The English
  /// copy already speaks quietly and directly ("your day", "you slept"), and
  /// `Pan/Pani` would both distance it and force a grammatical gender the
  /// profile has no business deciding for every sentence.
  polish(
    code: 'pl',
    endonym: 'Polski',
    speechLocaleId: 'pl_PL',
    modelName: 'Polish',
  );

  const AppLanguage({
    required this.code,
    required this.endonym,
    required this.speechLocaleId,
    required this.modelName,
  });

  /// ISO 639-1. Stored in `Profile.language`, used as the `assets/content/`
  /// directory name, and validated by `firestore.rules`. Do not change one
  /// without the others.
  final String code;

  /// The language's name *in* that language. A language picker that says
  /// "Polish" to somebody who cannot read English has failed at the one job it
  /// has, so this is never translated — it is the same in both string tables.
  final String endonym;

  /// The dictation locale handed to `speech_to_text`.
  ///
  /// Underscored and region-qualified because that is the shape the plugin's
  /// platform channels use on both Android and iOS; it is not a BCP 47 tag and
  /// must not be reused as one.
  final String speechLocaleId;

  /// How the language is named *to the model*, in English.
  ///
  /// The instruction that tells Aether to answer in Polish has to be written in
  /// a language the instruction itself is reliable in, and "Respond in Polish"
  /// is far more dependable than "Odpowiadaj po polsku" embedded in an
  /// otherwise-English system prompt. See `core/ai/prompts.dart`.
  final String modelName;

  /// The tag `intl` and `MaterialApp` want. Region-free on purpose: see the
  /// class comment.
  Locale get locale => Locale(code);

  /// The stored code, or [english] when the column is null, empty or holds
  /// something no version of this app ever wrote.
  ///
  /// Never throws. A profile row is the one thing that has to keep opening the
  /// app, and an unrecognised language code is not a reason to refuse — it is a
  /// reason to speak English until somebody chooses otherwise.
  static AppLanguage fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return english;
  }

  /// The language in force for a profile, chosen or not.
  ///
  /// The one rule, in one place: a stored code is the person's choice and is
  /// obeyed; null means nobody has chosen and the phone decides. Both the
  /// interface and every composer resolve through this, which is what keeps the
  /// language Aether writes in identical to the language on screen — the
  /// alternative is a Polish Dashboard whose guidance arrives in English because
  /// the composer read the column and the shell read the device.
  static AppLanguage forProfile(String? storedCode) => storedCode == null
      ? resolveFromPlatform()
      : fromCode(storedCode);

  /// What the phone is set to, when nobody has chosen yet.
  ///
  /// The default is the OS language rather than English: someone whose phone is
  /// in Polish should not have to find a setting to be spoken to in Polish, and
  /// onboarding happens before a profile exists to hold a choice. Matched on the
  /// language subtag alone, so `pl_PL`, `pl_DE` and a bare `pl` all resolve
  /// together.
  ///
  /// [locales] is injectable so the resolution can be tested without a platform;
  /// production passes nothing and reads the real device preference list, in the
  /// user's own order of preference.
  static AppLanguage resolveFromPlatform({List<Locale>? locales}) {
    final preferred = locales ?? PlatformDispatcher.instance.locales;
    for (final locale in preferred) {
      for (final language in values) {
        if (locale.languageCode == language.code) return language;
      }
    }
    return english;
  }
}
