# Eter · what it means for Eter to speak a language

Current as of 30 July 2026. English and Polish.

Eter speaks two languages, and "speaks" is the whole claim: not that the buttons
are translated, but that every word a person reads is in their language —
including the ones Aether writes, the ones a screen reader is given, the date on
the Journal, the keywords in the Vessel, and the language dictation listens in.

---

## 1. Where the words live

`app/lib/core/i18n/` holds three files that matter:

| File | What it is |
|---|---|
| `language.dart` | `AppLanguage` — two values, four codes each |
| `strings.dart` | `EterStrings` — the abstract table, and `EterStringsScope` |
| `strings_en.dart` / `strings_pl.dart` | one table per language |

`EterStrings` is an **abstract class**, not a map of keys, for one reason that
outweighs the tooling: the analyzer becomes the completeness check. Adding a
member is a compile error in both tables until both answer it, so a
half-finished translation cannot ship as a screen that silently falls back. A
key-based lookup gives you a missing-key crash at runtime, on somebody's phone,
on the one screen nobody opened during review.

Widgets read words through `EterStrings.of(context)` and never touch
`AppLanguage` or the profile row. The scope is installed once, at the root, next
to `EterRegisterScope` — so the language of a surface is decided in one place and
every surface rebuilds together when it changes.

## 2. The rule that keeps the symbolic engine working

**Identifiers stay English. Only their display moves.**

`Zodiac.aries` carries the label `'Aries'`, and that is what the chart engine
emits and what the enum is matched against. Aspects are keyed `'conjunction'`,
sleep stages `'deep'`, guidance dimensions `'health'`, arcana `'the-fool'` —
which also names a file. None of those ever change.

That is why `EterStrings` is full of `somethingName(String canonical)` lookups
rather than translated enums:

```dart
strings.signName('Pisces')   // 'Pisces' | 'Ryby'
strings.bodyName('Moon')     // 'Moon'   | 'Księżyc'
strings.aspectName('square') // 'square' | 'kwadratura'
```

Translating a value that something later parses is the single failure mode that
would break the symbolic engine in Polish and nowhere else. It nearly happened:
the Vessel used to build `'Aries 12.4°'` for display and then **split that string
back apart** to look up the glyph. The moment `Aries` became `Baran`, every glyph
in the Vessel would have vanished — silently, because a failed glyph lookup
returns null and null draws nothing. `_VesselPosition` now carries the canonical
sign and the degree as data, and composes the line at render time.

The same rule governs the model. See `docs/AI_FLOW.md` §6a.

## 3. Sentences are composed in the table, never at the call site

Polish inflects, and does not put its numbers, cases or word order where English
does. So anything with a value in it is a **method taking that value**:

```dart
strings.sleptSummary(hours: 7, minutes: 41, from: '00:44', to: '09:09')
```

A call site that builds `'$count steps'` itself cannot be translated. Two
consequences worth knowing about:

* **Declension.** `positionsSummary` and `sunSitsIn` take *canonical* sign names
  rather than already-localised ones, because Polish needs the locative —
  `Ryby` becomes `Rybach` — and no concatenation gets there from the nominative.
* **Plurals.** Polish has three forms, not two: one for 1, one for 2–4, one for
  5+, with the trap that the teens take the *many* form while 22–24 go back to
  *few*. `EterStringsPl._plural` applies that once and the noun tables sit beside
  it. `intl`'s plural rules would give the right category but the noun still has
  to be written out per case.

## 4. Errors carry codes, not sentences

A validation failure is raised deep in a service that has no idea who is
reading, and surfaces at the top of a screen that does. So the failing layer
names the problem and the language table words it:

| Enum | Raised by | Worded by |
|---|---|---|
| `AccountFailure` | `core/account/` | `accountFailure` |
| `SyncRefusal` | `core/sync/` | `syncRefusal` |
| `BirthContextError` | `core/profile/birth_context.dart` | `birthContextError` |
| `BodyRecordError` | the write services | `bodyRecordError` |

`AccountFailure.wrongPassword` and `AccountFailure.noSuchAccount` must answer
**identically** in every language, or the interface becomes an
account-enumeration oracle. A test asserts that per language.

Provider-supplied strings — a Firestore error, a parser's refusal reason — are
passed through untranslated. Inventing Polish for an arbitrary backend error
would be inventing a diagnosis.

## 5. Content, dates, numbers

* **Symbolic attributes** live in `assets/content/<code>/` — one directory per
  language, both listed in `pubspec.yaml` because Flutter's asset directories are
  not recursive. Every file carries the same join keys; only prose differs, and
  `symbol_content_test.dart` asserts both halves of that: identical keys, and
  *different* copy, so a Polish directory cannot be a copy of the English one.
* **Dates** go through `DateFormat(pattern, language.code)`. `main()` calls
  `initializeDateFormatting()` before the first frame — `intl` ships `en_US`
  alone until it runs, and the Journal's own date throws without it. Tests call
  `eterInitializeFormatting()`.
* **Numbers** go through `NumberFormat('#,##0', language.code)`: `1,870` in
  English, `1 870` in Polish.
* **Dictation** has its own section below — it is the only part that depends on
  the device rather than on Eter.

## 5a. Dictation

The one place Eter's language is a claim about the **device**. Every other
surface is Polish because Eter says so; dictation is Polish only if the phone
carries a Polish acoustic model, and no application code installs one.

Getting it wrong is quiet. A recogniser handed a locale it does not have will
*not* refuse — it falls back to its own default and transcribes Polish speech as
English words. The page fills with nonsense that reads as though Eter mangled the
dictation, with nothing on screen or in the transcript to say otherwise.

So two decisions live in `core/i18n/dictation.dart`, both pure and both tested:

* `DictationLocale.resolve` picks the id to ask for — exact match, then any
  region of the same language (so `en_GB` serves an `en_US` request, and `pl-PL`
  matches `pl_PL` across the separator difference between Android and iOS), then
  null. An **empty** list is the one case that does not mean "not installed":
  some Android recognisers decline to enumerate while dictating perfectly well,
  so the request goes through unchanged.
* `DictationFailure.fromRecogniserCode` turns the recogniser's own codes into
  one of five outcomes, because the advice differs completely between them.
  `error_language_not_supported` must never become "tap to try again" — tapping
  again will fail identically until a language pack is installed.

Both were originally inline in `_JournalPageState`, which held its own
`SpeechToText` and so could not be tested at all. `test/dictation_locale_test.dart`
covers 20 cases including the prefix trap (`ben_IN` must not satisfy a request
for `en`).

Platform requirements, both already in place:

* **Android** — `RECORD_AUDIO`, plus `<queries>` entries for
  `android.speech.RecognitionService` and `android.speech.action.RECOGNIZE_SPEECH`.
  Without the queries, Android 11+ package visibility hides the recogniser
  entirely, `initialize()` returns false, and dictation reports itself
  unavailable on a phone that supports it perfectly well.
* **iOS** — `NSMicrophoneUsageDescription` and
  `NSSpeechRecognitionUsageDescription`, translated in
  `ios/Runner/{en,pl}.lproj/InfoPlist.strings`.

The iOS prompts have a limit worth knowing: **iOS picks the localisation by
device language, not by the language chosen inside Eter.** A Polish reader who
manually switched Eter to Polish on an English phone still sees the English
sentence in the system dialog, and no Info.plist arrangement changes that. It is
correct for the default case, which is the overwhelming majority — Eter follows
the phone unless somebody overrides it.

## 6. Choosing, and what it costs

Default is the **OS language**, resolved from the device's whole preference list
in the user's own order. `Profile.language` is nullable and null means *nobody
has chosen*: that install keeps following the phone. Defaulting the column to
`'en'` would have quietly converted a first launch into a choice and stranded
every Polish-speaking install in English.

It is asked as the **first onboarding step**, pre-selected, because every step
after it is written in whatever it chooses. It can be changed any time in the
Sanctum, where it sits above the register and the consents for the same reason.

Changing it discards every composed passage. See `docs/DATA_STORAGE.md` §4.

## 7. Adding a third language

1. Add an `AppLanguage` value with its four codes.
2. Write `strings_xx.dart`. The analyzer lists what is missing.
3. Add `assets/content/xx/` and the `pubspec.yaml` line.
4. Add the code to `firestore.rules`' profile validation.
5. Run `flutter test test/golden --update-goldens`. The golden suite loops over
   `AppLanguage.values`, so the new language gets its own full set of captures
   automatically — at 320 dp and 200% text, in both registers, which is where
   translation actually breaks layouts.

Step 5 is not a formality. Polish found two real overflows that English never
would have: `ODZIEDZICZONE` past the end of a Vessel row, and `rozchodzi się`
pushing an orb reading ten pixels off the edge — both because a non-flex child
beside an `Expanded` is laid out at its full intrinsic width first.
