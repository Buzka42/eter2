// `Element` here is the zodiac element, not the framework's render-tree
// Element. The same hide is on `core/widgets.dart` for the same reason.
import 'package:flutter/widgets.dart' hide Element;

import '../account/account.dart';
import '../arcana/matrix.dart';
import '../health/record_error.dart';
import '../arcana/zodiac.dart';
import '../profile/birth_context.dart';
import '../sync/cloud_mirror.dart';
import '../profile/birth_time.dart';
import 'dictation.dart';
import 'language.dart';
import 'strings_en.dart';
import 'strings_pl.dart';

/// Every word Eter says, in one place per language.
///
/// A sealed set of getters and methods rather than an ARB file and generated
/// lookups, for one reason that outweighs the tooling: the analyzer becomes the
/// completeness check. Adding a member here is a compile error in
/// [EterStringsEn] and [EterStringsPl] until both answer it, so a half-finished
/// translation cannot ship as a screen that silently falls back to English. A
/// map of keys gives you a missing-key crash at runtime, on somebody's phone,
/// on the one screen nobody opened during review.
///
/// Three rules govern what belongs here:
///
/// 1. **Only what a person reads.** Semantic labels count — a screen reader is
///    somebody reading. Debug prints, `debugPrint` reasons, the sync layer's
///    documentation of what it deliberately does not mirror, and every string
///    that is really an identifier do not.
/// 2. **Identifiers stay English.** `Zodiac.aries` is matched against the chart
///    engine's `'Aries'`, aspects are keyed `'conjunction'`, sleep stages
///    `'deep'`, guidance dimensions `'health'`. Those never move. What moves is
///    the *display* of them, which is why this class is full of
///    `somethingName(String canonical)` lookups rather than translated enums.
///    Translating a value that something later parses is the single failure mode
///    that would break the symbolic engine in Polish only.
/// 3. **Sentences are composed here, not concatenated at the call site.** Polish
///    inflects and does not put its numbers, cases or word order where English
///    does, so anything with a value in it is a method taking that value. A call
///    site that builds `'$count steps'` itself cannot be translated.
abstract class EterStrings {
  const EterStrings();

  /// Which language this table speaks. Read by the dictation locale, the date
  /// formatters, the symbolic content loader and the model instruction, so all
  /// of them agree with the words on screen by construction.
  AppLanguage get language;

  static EterStrings forLanguage(AppLanguage language) => switch (language) {
        AppLanguage.english => const EterStringsEn(),
        AppLanguage.polish => const EterStringsPl(),
      };

  /// The table in force here.
  ///
  /// Defaults to English when no [EterStringsScope] is above — which is a real
  /// state during the first frames and in a widget test that pumps a bare
  /// widget, and must not throw. It is not the shipped path: [EterApp] installs
  /// the scope at the root.
  static EterStrings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EterStringsScope>()?.strings ??
      const EterStringsEn();

  // ---------------------------------------------------------------- identity

  /// Never translated. The product is called Eter in every language, and the
  /// wordmark is drawn type rather than copy.
  String get wordmark => 'ETER';

  /// Never translated either — it is Latin, and the whole point of the line is
  /// that it is the one sentence Eter did not write.
  String get motto => 'Anima Sana In Corpore Sano';

  // ------------------------------------------------------------------ common

  String get close;
  String get cancel;
  String get save;
  String get saving;
  String get edit;
  String get review;
  String get reviewing;
  String get confirm;
  String get delete;
  String get deleteNow;
  String get keep;
  String get back;
  String get proceed;
  String get next;
  String get skip;
  String get begin;
  String get refresh;
  String get connect;
  String get export;
  String get copyPath;
  String get prepare;
  String get dismiss;
  String get clear;
  String get clearNow;
  String get reset;
  String get composing;
  String get off;
  String get allowed;

  // --------------------------------------------------------------- the shell

  /// The two destinations, letterspaced caps. The hairline beneath them is
  /// measured from the rendered word rather than a table of pixel widths, so
  /// these may be any length.
  String get destinationJournal;
  String get destinationDashboard;
  String get sanctum;
  String get openSanctumSemantic;

  // ----------------------------------------------------------- the dashboard

  String get guidanceNotComposedYet;
  String get composingTodaysGuidance;
  String get composeNow;
  String get guidanceComposed;
  String get guidanceAlreadyCurrent;
  String get aetherNotConnected;
  String get enableAiBeforeComposing;
  String get responseNotAcceptedSafely;
  String get compositionUnavailable;

  String get lookDeeper;
  String get sectionGuidance;
  String get sectionBody;
  String get sectionVessel;

  /// The three dimensions, headed by name. Keyed on the stored
  /// `'health' | 'mind' | 'spirit'`, which is a contract value and does not
  /// move.
  String guidanceDimension(String canonical);
  String evidenceFor(String dimension);
  String evidenceReceipt({
    required Object? n,
    required Object? window,
    required Object? coefficient,
    required Object? note,
  });
  String get evidenceUnknownCount;
  String get evidenceWindowUnavailable;
  String get evidenceCoefficientUnavailable;
  String get evidenceUnreadable;

  // ------------------------------------------------------------------- body

  String get theBody;
  String get bodyExpandsHint;
  String factResting(int bpm);
  String factSteps(String formattedSteps);

  String get conclusionNothingRecorded;
  String get conclusionNothingEaten;
  String conclusionNoActivityYet(String eaten);
  String conclusionLevel({required String eaten, required String burned});
  String conclusionOver({required String eaten, required String burned});
  String conclusionUnder({required String eaten, required String burned});

  String get estimateWaitingBelow;
  String get headingFoodNotes;
  String get headingRecoverySignals;
  String get noRecoverySignals;
  String get headingRestingHeartRate;
  String get headingHeartRateVariability;
  String get headingSleep;
  String get headingLastNight;
  String get headingWeight;
  String get headingActivityByTime;

  String get recoveryTrendUnavailable;
  String get noSleepRecorded;
  String get lastNightNotStaged;
  String get sleepHistoryNeedsTwoNights;
  String get weightNeedsTwoEntries;
  String get activityByTimeUnavailable;

  String sleptSummary({
    required int hours,
    required int minutes,
    required String from,
    required String to,
  });

  String windowDays(int days);

  String signalRestingHeartRate(int bpm);
  String signalHrv(int ms);
  String signalRespiratoryRate(String perMinute);

  String get trendRestingHeartRate;
  String get trendHeartRateVariability;
  String get trendWeight;
  String get unitBpm;
  String get unitMs;
  String get unitKg;

  String get fieldKcal;
  String kcalConfirmed(int kcal);
  String kcalEstimateNotCounted(int kcal);
  String get correctEstimateFirst;

  // ------------------------------------------------------------- instruments

  String get balanceEaten;
  String get balanceBurned;

  String trendSemantic({
    required String label,
    required int readings,
    required String latest,
    required String unit,
    required String low,
    required String high,
  });
  String trendDayCount(int days);

  /// The display name of a sleep stage. Keyed on the stored stage, which is
  /// `'deep' | 'light' | 'rem' | 'awake' | 'unknown'` and does not move.
  String sleepStageName(String canonical);
  String sleepStageMinutes(String canonical, int minutes);
  String sleepStagesSemantic(String stageSummary);
  String sleepStageSemanticEntry(String canonical, int minutes);
  String sleepHistorySemantic({
    required int windowDays,
    required int nights,
    required String averageHours,
    required String nightSummary,
  });
  String sleepNightSemantic(int index, String stages);
  String averageHoursMark(String hours);

  String activityDaySemantic({
    required String totalKilocalories,
    required String detail,
  });
  String activityHourSemantic({required String clock, required int kcal});

  // ----------------------------------------------------------------- vessel

  String get theVessel;
  String get readingChartOnDevice;
  String get birthDetailsNeededForVessel;

  String get headingYourCard;
  String sunCardSemantic(String cardTitle);

  /// Takes the *canonical* sign name, not a display one.
  ///
  /// English puts the sign after "in" unchanged; Polish has to decline it
  /// ("w Baranie", "w Rybach"), which cannot be done to a string that has
  /// already been localised into the nominative. Null when the chart has no
  /// sign to name, which the sentence states rather than omits.
  String sunSitsIn(String? canonicalSign);
  String positionCardSemantic({
    required String cardTitle,
    required String positionLabel,
  });

  String get readDeeper;
  String get showLess;
  String get composeReadings;
  String get personalReadingNotConnected;
  String get everyReadingAlreadyComposed;
  String get missingReadingsComposed;
  String readingNotAccepted(String reason);
  String get compositionUnavailableCachedRemain;
  String get personalReadingNotComposedYet;

  String get approximateTimeAndPlace;
  String get approximateTime;
  String get approximatePlace;

  String get headingPositionsToday;

  /// Canonical values throughout, for the same declension reason as
  /// [sunSitsIn]: Polish needs the phase in the genitive and both signs in the
  /// locative, and only the language table can put them there.
  String positionsSummary({
    required String moonPhaseCanonical,
    required String moonSignCanonical,
    required String sunSignCanonical,
  });
  String get nothingCloseInTheSky;
  String contactLine({
    required String transiting,
    required String aspect,
    required String natal,
  });
  String contactOrb({required String degrees, required bool applying});
  String get readToday;
  String get readingToday;
  String get todaysReadingNotConnected;
  String get todaysReadingCouldNotBeWritten;
  String get enableAiBeforeReadingToday;

  String lifePathLabel(int value);

  /// A chart position's degree and sign, as the Vessel prints it.
  ///
  /// Composed here rather than at the call site because it used to be built by
  /// string interpolation and then *parsed back* to find the glyph — the sign
  /// name was both the label and the key. The caller now keeps the sign and
  /// passes it, so this is display only and safe to inflect.
  String positionDetail({
    required String signName,
    required String degrees,
    required bool retrograde,
  });

  // ---------------------------------------------------------------- journal

  String get journalHistory;
  String get openJournalHistorySemantic;
  String get closeHistorySemantic;
  String get headingHistory;
  String get headingTheDaySoFar;
  String get writingFieldHint;
  String get nothingWrittenOnThisPage;
  String get thisPageIsClosed;
  String get previousJournalDay;
  String get nextJournalDay;
  String get nextJournalDayUnavailable;

  String get listening;
  String get dictate;
  String get stop;
  String get dictateSemantic;
  String get stopDictationSemantic;
  String get dictationNeedsMicrophone;
  String get dictationNothingHeard;
  String get dictationNeedsConnection;
  String get dictationStopped;
  String get dictationNoRecogniser;
  String get dictationUnavailable;

  /// Said when the recogniser works but has nothing installed for this
  /// language. Names the language, because "dictation is unavailable" sends
  /// somebody to the microphone permission they have already granted.
  String dictationLanguageUnavailable(String languageName);

  /// The sentence for a [DictationFailure]. Composed from the five above rather
  /// than written again, so there is exactly one wording per outcome.
  String dictationFailure(DictationFailure failure) => switch (failure) {
        DictationFailure.microphone => dictationNeedsMicrophone,
        DictationFailure.nothingHeard => dictationNothingHeard,
        DictationFailure.connection => dictationNeedsConnection,
        DictationFailure.languageMissing =>
          dictationLanguageUnavailable(language.endonym),
        DictationFailure.stopped => dictationStopped,
      };

  String get keptFromAether;
  String get allowAether;
  String get keepLocal;
  String get allowAetherSemantic;
  String get keepLocalSemantic;
  String get undoInterpretation;
  String get undoInterpretationSemantic;
  String get deleteEntrySemantic;
  String get deleteEntryTitle;
  String get deleteEntryBody;
  String get fieldAddMissingDetail;
  String get addMoreDetailFirst;
  String get journalInterpretationNotConnected;
  String get enableAiBeforeSendingEntry;
  String get entryNotInterpretedSafely;
  String get interpretationUnavailable;
  String get interpretationAndDerivedRemoved;
  String get tapToRevealImmediately;

  /// What interpreting a page actually did.
  ///
  /// The list of written things is assembled from [derivedWeight] and its
  /// neighbours and handed back here as a whole, because Polish needs the verb
  /// to agree with what follows it and cannot have the sentence built around a
  /// pre-joined English fragment.
  String get aetherNeedsOneDetail;
  String get entryWasInterpreted;
  String get entryWasInterpretedAndLogged;
  String recordedItems(List<String> items);

  /// The four things a page can turn into, in whatever grammatical case
  /// [recordedItems] needs them in. They appear in that sentence and nowhere
  /// else, so Polish supplies them already in the accusative rather than
  /// inventing a case system for a list of four nouns.
  String get derivedWeight;
  String get derivedActivity;
  String get derivedActivities;
  String get derivedWorkout;
  String get derivedFoodAwaitingReview;

  // ---------------------------------------------------------------- sanctum

  String get headingSanctum;
  String get howEterMeetsYou;
  String get historyStaysOnThisDevice;
  String get cloudContinuityAllowed;

  String get headingOpeningPage;
  String get choiceJournal;
  String get choiceDashboard;

  String get headingGuidanceRegister;
  String get registerGrounded;
  String get registerBalanced;
  String get registerImmersive;
  String get registerGroundedDetail;
  String get registerBalancedDetail;
  String get registerImmersiveDetail;

  String get headingLanguage;
  String get languageDetail;

  /// Said in the language just switched *to*, and counting what the switch
  /// discarded. The first sentence of the new language a person reads.
  String languageChanged(int clearedPassages);

  String get headingYourData;
  String get permissionsAreIndependent;

  String get headingAiGuidance;
  String get aiGuidanceOffDetail;
  String get aiGuidanceAllowedDetail;
  String get headingJournalAwareGuidance;
  String get journalAwareOffDetail;
  String get journalAwareAllowedDetail;
  String get headingCloudContinuity;
  String get localOnly;
  String get cloudOffDetail;
  String get cloudAllowedDetail;
  String get headingJournalInTheMirror;
  String get staysHere;
  String get journalMirrorOffDetail;
  String get journalMirrorAllowedDetail;
  String get headingCrashReports;
  String get crashReportsOffDetail;
  String get crashReportsAllowedDetail;

  String get headingBirthContext;
  String birthContextSummary({
    required String place,
    required String time,
    required String utcOffset,
  });
  String get locatedPlace;
  String get birthContextProvisional;
  String get headingHowWellIsTimeKnown;
  String get precisionExact;
  String get precisionApproximate;
  String get precisionUnknown;
  String get precisionExactDetail;
  String get precisionApproximateDetail;
  String get precisionUnknownDetail;
  String get headingWhichPartOfDay;
  String get fieldLocalBirthTime;
  String get fieldUtcOffsetAtBirth;
  String get fieldBirthCityAndCountry;
  String get placeLookupNote;
  String get offsetSuggestedFromPhone;
  String get locatingBirthContext;
  String get birthContextSaved;

  String get headingAetherMemory;
  String get onlyStructuredPatternsRetained;
  String get headingWeekInView;
  String get noWeeklyViewPrepared;
  String get headingLocalPatterns;
  String get noActivePatterns;
  String patternReceipt({
    required int confidencePercent,
    required Object? observations,
    required String? window,
    required num? coefficientMinutes,
  });
  String get correlationNotCause;
  String patternSemantic({required String summary, required String receipt});
  String get notEnoughConsistentEvidence;
  String patternsRefreshed({required int patterns, required int observations});
  String get preparingSevenDayView;
  String get notEnoughHistoryForWeekly;
  String get sevenDayViewPrepared;
  String get patternDismissed;
  String get resetPersonalizationWarning;
  String get aetherMemoryAlreadyEmpty;
  String get aetherMemoryCleared;
  String retrospectiveSemantic({
    required String headline,
    required String passages,
    required String caveat,
    required String window,
  });
  String retrospectiveWindow({required String from, required String to});

  String get headingOldPages;
  String get oldPagesNote;
  String get pruneProseWarning;
  String get noPagesOlderThanAYear;
  String clearedPageText(int pages);

  /// Where the person lives — the register's horizon, not the chart's.
  String get headingWhereYouLive;
  String get whereYouLiveNote;
  String get whereYouLivePrompt;
  String get fieldHomePlace;
  String homePlaceSaved(String place);
  String get homePlaceForgotten;
  String get usingBirthPlaceForNow;

  String get headingDeleteFromThisDevice;
  String get deleteLocalIntro;
  String get deleteLocalWarning;

  /// The same warning, for a device whose records also exist in an account.
  ///
  /// Two sentences instead of one, because the single-sentence version was a
  /// lie by omission: it called the deletion permanent while a full copy sat in
  /// the mirror, restorable by the button directly above it. Saying so is not a
  /// caveat — it is the difference between an accurate destructive action and an
  /// inaccurate one.
  String get deleteLocalWarningCopyRemains;

  String get headingHealthHistory;
  String get healthConnectedReconnect;
  String get healthOffer;
  String get healthOnboardingOffer;
  String get healthUnsupportedPlatform;
  String healthRecordsRead(int records);
  String get healthAccessNotGranted;
  String get healthAccessNotGrantedOnboarding;
  String get healthCouldNotBeRead;

  /// Writing Eter's own records into the platform's health store.
  String get writeBack;
  String get writeBackNote;
  String healthWroteBack(int records);
  String get healthNothingToWriteBack;
  String get healthCouldNotWriteBack;
  String get healthCouldNotBeReadOnboarding;

  String get headingLocalExport;
  String get localExportNote;
  String get localExportReady;
  String get localExportFailed;
  String get exportFolderCopied;

  // ------------------------------------------------------------------ aether

  /// Whether Aether may compose, and what it costs.
  ///
  /// Prices arrive as parameters rather than living in these tables. The stores
  /// hold the authoritative, locally formatted price for every market — currency,
  /// separators, tax inclusion — and a number written here would be wrong in most
  /// of them and stale in the rest.
  String get headingAether;
  String aetherTrialDaysLeft(int days);
  String get aetherTrialEndsToday;
  String get aetherTrialExplainsItself;
  String get aetherLapsed;
  String get aetherSubscribed;
  String get aetherUnconfigured;
  String get aetherRecordKeepsWorking;
  String subscribeMonthly(String price);
  String subscribeYearly(String price);
  String get launchPriceWillRise;
  String get restorePurchases;
  String get billingNotOnThisBuild;

  // ---------------------------------------------------------------- account

  String get headingAccount;
  String get buildHasNoAccountSystem;
  String get historyNeedsNoAccount;
  String get fieldEmail;
  String get fieldPassword;
  String get fieldNewPassword;
  String passwordMinimum(int characters);
  String get createAccount;
  String get signIn;
  String get iHaveAnAccount;
  String get createOne;
  String get continueWithGoogle;
  String get forgottenPassword;
  String get resetLinkOnItsWay;
  String confirmationLinkSent(String email);
  String get signedIn;
  String get historyCanBeRestored;
  String get confirmEmailToEnable;
  String get resendLink;
  String get iHaveConfirmed;
  String get verificationSent;
  String get notConfirmedYet;
  String get syncNow;
  String get restore;
  String get restoreOnlyFillsEmptyDevice;
  String get signOut;
  String get signedOutNothingRemoved;
  String get somethingWentWrong;

  /// Deleting the account, and the copy under it. Both stores require this to
  /// exist in-app for any app that lets someone create an account.
  String get headingDeleteAccount;
  String get deleteAccount;
  String get deleteAccountIntro;
  String get deleteAccountWarning;
  String get accountDeletedRecordKept;

  String get syncNotAvailableOnBuild;
  String get everythingAlreadyCopied;
  String copiedRecords(int records);
  String get journalStayedOnThisDevice;
  String get nothingInAccountToRestore;
  String restoredRecords(int records);
  /// One sentence per [SyncRefusal] — the preconditions Eter declines on before
  /// it contacts the mirror at all.
  String syncRefusal(SyncRefusal refusal);

  /// One sentence per [AccountFailure]. Never a hint about whether an address
  /// exists: `wrongPassword` and `noSuchAccount` must answer identically, or
  /// the interface becomes an account-enumeration oracle.
  String accountFailure(AccountFailure failure);

  // ------------------------------------------------------------- onboarding

  String onboardingStepSemantic({required int step, required int total});
  String onboardingStepMark({required int step, required int total});
  String get continueLabel;
  String get enterEter;

  String get welcomeTitle;
  String get welcomeIntro;
  String get fieldWhatShouldEterCallYou;
  String get fieldWhatWouldYouLikeMoreOf;
  String get hintWhatWouldYouLikeMoreOf;

  String get birthStepTitle;
  String get birthStepIntro;
  String get fieldBirthDate;
  String get hintBirthDateFormat;
  String get fieldCurrentWeightKg;
  String get fieldCurrentHeightCm;
  String get headingBodyContext;
  String get sexFemale;
  String get sexMale;
  String get sexOther;
  String get fieldBirthPlaceOptional;
  String get hintCityOrRegion;
  String get exactBirthTimeLater;
  String get errorEnterValidBirthDate;
  String get errorMinimumAge;
  String get errorEnterWeightRange;
  String get errorEnterHeightRange;

  String get registerStepTitle;
  String get registerStepIntro;
  String get registerGroundedOnboardingDetail;
  String get registerBalancedOnboardingDetail;
  String get registerImmersiveOnboardingDetail;

  String get languageStepTitle;
  String get languageStepIntro;

  String get consentStepTitle;
  String get consentStepIntro;
  String get consentAiTitle;
  String get consentAiDetail;
  String get consentJournalAiTitle;
  String get consentJournalAiDetail;
  String get consentCloudTitle;
  String get consentCloudDetail;
  String get allowMark;
  String get offMark;
  String consentSemantic({required String title, required bool allowed});
  String get healthHistoryTitle;

  // --------------------------------------------------------------- tutorial

  /// The four passages of the first minute. An eyebrow and one or more lines
  /// each; the first line is set large, the rest quiet beneath it.
  List<TutorialPassage> get tutorialPassages;

  // -------------------------------------------------------------- body fat

  String get fieldBodyFatOptional;
  String get bodyFatNotGiven;
  String get bodyFatSemanticNotGiven;
  String bodyFatSemantic(String formatted);
  String get bodyFatNote;

  /// A bound a derived record exceeded, said plainly. The numbers are the same
  /// in both languages because they are the store's actual limits.
  String bodyRecordError(BodyRecordError error);

  // -------------------------------------------------- birth context errors

  /// Words a [BirthContextError]. The failing layer names the problem; this
  /// says it to whoever is reading.
  String birthContextError(BirthContextError error);

  // --------------------------------------------------- symbolic vocabulary

  String elementName(Element element);
  String elementMedallionSemantic(Element element);

  /// The sign, by its canonical English name as the chart engine emits it.
  String signName(String canonical);

  /// A chart point or transiting body — `'Sun'`, `'Moon'`, `'Ascendant'`,
  /// `'Midheaven'`, the planets. Canonical, because the transit engine keys on
  /// these and `firestore.rules` validates them.
  String bodyName(String canonical);

  /// An aspect — `'conjunction'`, `'sextile'`, `'square'`, `'trine'`,
  /// `'opposition'`.
  String aspectName(String canonical);

  /// A moon phase as `TransitReading` labels it — `'new'`, `'waxing crescent'`
  /// and the rest.
  String moonPhaseName(String canonical);

  /// An Arcana card's title, by its asset slug. The slug is the stable key —
  /// it names a file — so it is what the lookup uses rather than the English
  /// title.
  String arcanaTitle(String slug);

  String matrixPositionLabel(MatrixPosition position);
  String matrixPositionDetail(MatrixPosition position);
  String birthPeriodLabel(BirthTimePeriod period);
  String birthPeriodDetail(BirthTimePeriod period);

  String get applyingWord;
  String get separatingWord;
  String get retrogradeWord;

  // ------------------------------- locally composed prose (never the model)

  /// The one pattern local discovery can find, said in words.
  ///
  /// Composed at display time from the stored evidence rather than stored as a
  /// sentence, so switching language re-words every pattern already found
  /// instead of leaving a Polish screen with an English finding on it.
  String patternSleepAfterLateActivity({required bool shorter});

  /// One of the daily series the sweep correlates, named the way a person would
  /// say it. Keyed on `SeriesDefinition.key`, which never moves.
  String seriesLabel(String canonical);

  /// A finding from the correlation sweep, worded at display time.
  ///
  /// `PatternCandidates.summary` still holds the English sentence the sweep
  /// wrote, and that is deliberate — it is what travels to the model, which
  /// reads English context. What a person sees is composed here, from the
  /// pattern's key and its stored evidence, so a finding made last month reads
  /// in the language chosen today.
  ///
  /// It says what was compared, which way it went, how much it accounts for and
  /// over how many days, because "your sleep is worse after late training"
  /// without the sample size is a horoscope.
  String patternSweepSummary({
    required String fromKey,
    required String toKey,
    required bool lagged,
    required bool positive,
    required int percent,
    required int days,
  });

  String retrospectiveHeadline({required bool complete});

  /// The movement sentence, which grows a clause when step counts exist.
  ///
  /// `steps` and `stepDays` are null together: the v1 schema cannot tell an
  /// unavailable step count from its default zero, so only positive counts are
  /// described as measured and a week without any simply omits the clause.
  String retrospectiveMovement({
    required int days,
    required int averageActiveKcal,
    int? averageSteps,
    int? stepDays,
  });
  String retrospectiveSleep({
    required int nights,
    required String averageHours,
  });
  String retrospectiveJournal(int entries);
  String retrospectiveLifestyle({
    required int signals,
    required List<String> kinds,
  });
  String get retrospectiveCaveat;

  /// The self-report kinds a lifestyle entry can carry, for the sentence above.
  /// Canonical keys; see `core/lifestyle/daily_check_in.dart`.
  String lifestyleKindName(String canonical);

  // ------------------------------------------------------------- the long view

  /// The axis pulled back. Named in the Sanctum as well as reached by turning,
  /// because extension is discoverable only to somebody already turning pages —
  /// see `docs/DECISIONS.md`.
  String get headingLongView;

  /// Week, month or year, for the mark that says which scale you are on.
  String longViewSpanName(LongViewSpanName span);

  /// How much of the period was recorded at all.
  ///
  /// The headline of every Long View, and the reason it is a *fraction* rather
  /// than a count: an average of four days is not a week, and the surface has to
  /// say which it is before it says anything else.
  String longViewRecorded({required int recorded, required int total});

  /// When the whole window is empty. Not an error and not an empty state to be
  /// apologised for — a stretch of time you did not spend with Eter.
  String get longViewNothingRecorded;

  /// What a series of cells is measuring.
  String longViewMeasure(LongViewMeasure measure);

  /// The whole chart, for a reader who cannot see it. Absent periods are named
  /// as absent rather than skipped, because a gap is the shape of the year.
  String longViewSeriesSemantic({
    required String measure,
    required String cells,
    required int absent,
  });

  /// One cell inside that reading.
  String longViewCellSemantic({required String label, required String value});

  /// A cell nobody recorded, inside that reading.
  String longViewCellAbsent(String label);
}

/// The three scales, named for the string table without dragging
/// `core/longview` into every localisation file.
enum LongViewSpanName { week, month, year }

/// The measures a Long View can draw. Sleep, mood and steps are means over the
/// days that recorded them; pages is a count, and a count of zero is true.
enum LongViewMeasure { sleep, mood, steps, pages }

/// One passage of the tutorial: an eyebrow in caps and the lines beneath it.
@immutable
class TutorialPassage {
  const TutorialPassage({
    required this.eyebrow,
    required this.lines,
    this.showsSanctumMark = false,
  });

  final String eyebrow;
  final List<String> lines;

  /// Draws the Sanctum's own mark beside the passage.
  ///
  /// The one symbol in the product a person has to recognise before they can use
  /// it, so the tutorial shows it rather than describing it. `UI_BRIEF.md`
  /// non-negotiable 7 forbids *unexplained* symbols; this is the explanation, and
  /// without it a glyph-only affordance would not be allowed to exist.
  final bool showsSanctumMark;
}

/// Publishes the active [EterStrings] to the whole tree.
///
/// Installed once, at the root, from the profile's language resolved against the
/// device — exactly as [EterRegisterScope] publishes the register. Widgets read
/// words through `EterStrings.of(context)` and never touch [AppLanguage] or the
/// profile row directly, so the language of a surface is decided in one place
/// and every surface rebuilds together when it changes.
class EterStringsScope extends InheritedWidget {
  const EterStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final EterStrings strings;

  @override
  bool updateShouldNotify(EterStringsScope oldWidget) =>
      oldWidget.strings.language != strings.language;
}
