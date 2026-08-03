import '../account/account.dart';
import '../arcana/matrix.dart';
import '../health/record_error.dart';
import '../arcana/zodiac.dart';
import '../profile/birth_context.dart';
import '../sync/cloud_mirror.dart';
import '../profile/birth_time.dart';
import 'language.dart';
import 'strings.dart';

/// English, and the reference table.
///
/// Every string here is the copy that was already on the surface it belongs to,
/// moved rather than rewritten. That is deliberate: the point of extracting
/// strings is to make a second language possible, not to take the opportunity to
/// re-edit the first one, and a diff that does both is a diff nobody can review.
///
/// Where a value came from an enum field — [MatrixPosition.label],
/// [BirthTimePeriod.detail], [Element.label] — this table returns that field
/// rather than repeating it. Those fields stay the English canon; see
/// [EterStringsPl] for why the translations live in the language table instead
/// of on the enums.
class EterStringsEn extends EterStrings {
  const EterStringsEn();

  @override
  AppLanguage get language => AppLanguage.english;

  // ------------------------------------------------------------------ common

  @override
  String get close => 'Close';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get saving => 'Saving';
  @override
  String get edit => 'Edit';
  @override
  String get review => 'Review';
  @override
  String get reviewing => 'Reviewing recent local signals…';
  @override
  String get confirm => 'Confirm';
  @override
  String get delete => 'Delete';
  @override
  String get deleteNow => 'Delete now';
  @override
  String get keep => 'Keep';
  @override
  String get back => 'Back';
  @override
  String get proceed => 'Review';
  @override
  String get next => 'Next';
  @override
  String get skip => 'Skip';
  @override
  String get begin => 'Begin';
  @override
  String get refresh => 'Refresh';
  @override
  String get connect => 'Connect';
  @override
  String get export => 'Export';
  @override
  String get copyPath => 'Copy path';
  @override
  String get prepare => 'Prepare';
  @override
  String get dismiss => 'Dismiss';
  @override
  String get clear => 'Clear';
  @override
  String get clearNow => 'Clear now';
  @override
  String get reset => 'Reset';
  @override
  String get composing => 'Composing';
  @override
  String get off => 'Off';
  @override
  String get allowed => 'Allowed';

  // --------------------------------------------------------------- the shell

  @override
  String get destinationJournal => 'JOURNAL';
  @override
  String get destinationDashboard => 'DASHBOARD';
  @override
  String get sanctum => 'Sanctum';
  @override
  String get openSanctumSemantic => 'Open Sanctum';

  // ----------------------------------------------------------- the dashboard

  @override
  String get guidanceNotComposedYet =>
      'Today’s guidance has not been composed yet.';
  @override
  String get composingTodaysGuidance => 'Composing today’s guidance…';
  @override
  String get composeNow => 'Compose now';
  @override
  String get guidanceComposed => 'Today’s guidance has been composed.';
  @override
  String get guidanceAlreadyCurrent =>
      'Guidance is already current for the available context.';
  @override
  String get aetherNotConnected =>
      'Aether composition is not connected on this build yet.';
  @override
  String get enableAiBeforeComposing =>
      'Enable AI guidance in the Sanctum before composing.';
  @override
  String get responseNotAcceptedSafely =>
      'The response could not be accepted safely. Nothing changed.';
  @override
  String get compositionUnavailable =>
      'Composition is unavailable right now. Existing guidance remains.';

  @override
  String get lookDeeper => 'LOOK DEEPER';
  @override
  String get sectionGuidance => 'GUIDANCE';
  @override
  String get sectionBody => 'THE BODY';
  @override
  String get sectionVessel => 'VESSEL';

  @override
  String guidanceDimension(String canonical) => switch (canonical) {
        'health' => 'HEALTH',
        'mind' => 'MIND',
        'spirit' => 'SPIRIT',
        'synthesis' => 'SYNTHESIS',
        _ => canonical.toUpperCase(),
      };

  @override
  String evidenceFor(String dimension) => 'Evidence for $dimension';

  @override
  String evidenceReceipt({
    required Object? n,
    required Object? window,
    required Object? coefficient,
    required Object? note,
  }) =>
      'n=$n · $window · coefficient $coefficient\n'
      '$note This is an association, not proof of cause.';

  @override
  String get evidenceUnknownCount => 'unknown';
  @override
  String get evidenceWindowUnavailable => 'window unavailable';
  @override
  String get evidenceCoefficientUnavailable => 'unavailable';
  @override
  String get evidenceUnreadable =>
      'The cached evidence details could not be read.';

  // -------------------------------------------------------------------- body

  @override
  String get theBody => 'THE BODY';
  @override
  String get bodyExpandsHint => 'expands health details';
  @override
  String factResting(int bpm) => '$bpm bpm resting';
  @override
  String factSteps(String formattedSteps) => '$formattedSteps steps';

  @override
  String get conclusionNothingRecorded =>
      'No activity or food has been recorded yet today.';
  @override
  String get conclusionNothingEaten =>
      'Nothing has been logged to eat yet today.';
  @override
  String conclusionNoActivityYet(String eaten) =>
      '$eaten kcal logged; activity has not been recorded yet.';
  @override
  String conclusionLevel({required String eaten, required String burned}) =>
      'Intake and burn sit close to level — '
      '$eaten kcal eaten against $burned kcal burned.';
  @override
  String conclusionOver({required String eaten, required String burned}) =>
      'A little over today — $eaten kcal eaten against $burned kcal burned.';
  @override
  String conclusionUnder({required String eaten, required String burned}) =>
      'A little under today — $eaten kcal eaten against $burned kcal burned.';

  @override
  String get estimateWaitingBelow =>
      'One food estimate is waiting below. It is not included in the balance '
      'until you confirm or correct it.';
  @override
  String get headingFoodNotes => 'FOOD NOTES';
  @override
  String get headingRecoverySignals => 'RECOVERY SIGNALS';
  @override
  String get noRecoverySignals =>
      'No wearable recovery signals are available today.';
  @override
  String get headingRestingHeartRate => 'RESTING HEART RATE';
  @override
  String get headingHeartRateVariability => 'HEART RATE VARIABILITY';
  @override
  String get headingSleep => 'SLEEP';
  @override
  String get headingLastNight => 'LAST NIGHT';
  @override
  String get headingWeight => 'WEIGHT';
  @override
  String get headingActivityByTime => 'ACTIVITY BY TIME';

  @override
  String get recoveryTrendUnavailable =>
      'A historical recovery trend is not available yet.';
  @override
  String get noSleepRecorded => 'No sleep has been recorded yet.';
  @override
  String get lastNightNotStaged => 'Last night was not staged.';
  @override
  String get sleepHistoryNeedsTwoNights =>
      'A history needs at least two recorded nights.';
  @override
  String get weightNeedsTwoEntries =>
      'A weight trend needs at least two entries.';
  @override
  String get activityByTimeUnavailable =>
      'Activity by time of day is unavailable until minute-level movement data '
      'is connected.';

  @override
  String sleptSummary({
    required int hours,
    required int minutes,
    required String from,
    required String to,
  }) =>
      '${hours}h ${minutes}m asleep · $from to $to';

  @override
  String windowDays(int days) => '$days days';

  @override
  String signalRestingHeartRate(int bpm) => '$bpm bpm resting heart rate';
  @override
  String signalHrv(int ms) => '$ms ms HRV';
  @override
  String signalRespiratoryRate(String perMinute) =>
      '$perMinute breaths per minute';

  @override
  String get trendRestingHeartRate => 'Resting heart rate trend';
  @override
  String get trendHeartRateVariability => 'Heart rate variability trend';
  @override
  String get trendWeight => 'Weight trend';
  @override
  String get unitBpm => 'bpm';
  @override
  String get unitMs => 'ms';
  @override
  String get unitKg => 'kg';

  @override
  String get fieldKcal => 'kcal';
  @override
  String kcalConfirmed(int kcal) => '$kcal kcal';
  @override
  String kcalEstimateNotCounted(int kcal) =>
      'ESTIMATE · $kcal KCAL · NOT COUNTED';
  @override
  String get correctEstimateFirst =>
      'Correct the estimate before it enters today’s total.';

  // ------------------------------------------------------------- instruments

  @override
  String get balanceEaten => 'Eaten';
  @override
  String get balanceBurned => 'Burned';

  @override
  String trendSemantic({
    required String label,
    required int readings,
    required String latest,
    required String unit,
    required String low,
    required String high,
  }) =>
      '$label, $readings readings. Latest $latest $unit. '
      'Range $low to $high $unit.';

  @override
  String trendDayCount(int days) => '$days DAYS';

  @override
  String sleepStageName(String canonical) => switch (canonical) {
        'deep' => 'Deep',
        'light' => 'Light',
        'rem' => 'REM',
        'awake' => 'Awake',
        'unknown' => 'Unstaged',
        _ => canonical,
      };

  @override
  String sleepStageMinutes(String canonical, int minutes) =>
      '${sleepStageName(canonical).toUpperCase()} ${minutes}m';

  @override
  String sleepStagesSemantic(String stageSummary) =>
      'Sleep stages. $stageSummary.';

  @override
  String sleepStageSemanticEntry(String canonical, int minutes) =>
      '${sleepStageName(canonical)} $minutes minutes';

  @override
  String sleepHistorySemantic({
    required int windowDays,
    required int nights,
    required String averageHours,
    required String nightSummary,
  }) =>
      '$windowDays day sleep history, $nights nights. '
      'Average $averageHours hours. $nightSummary.';

  @override
  String sleepNightSemantic(int index, String stages) => 'Night $index: $stages';

  @override
  String averageHoursMark(String hours) => '$hours h AVG';

  @override
  String activityDaySemantic({
    required String totalKilocalories,
    required String detail,
  }) =>
      'Activity by time of day. Total $totalKilocalories kilocalories. $detail.';

  @override
  String activityHourSemantic({required String clock, required int kcal}) =>
      '$clock $kcal kilocalories';

  // ------------------------------------------------------------------ vessel

  @override
  String get theVessel => 'THE VESSEL';
  @override
  String get readingChartOnDevice => 'Reading the chart held on this device…';
  @override
  String get birthDetailsNeededForVessel =>
      'Birth details are needed before the Vessel can be drawn.';

  @override
  String get headingYourCard => 'YOUR CARD';
  @override
  String sunCardSemantic(String cardTitle) => '$cardTitle, your Sun card';
  @override
  String sunSitsIn(String? canonicalSign) =>
      'Your Sun sits in ${canonicalSign == null ? 'its own sign' : signName(canonicalSign)}, '
      'which is what sets this card. It does not change.';
  @override
  String positionCardSemantic({
    required String cardTitle,
    required String positionLabel,
  }) =>
      '$cardTitle, $positionLabel';

  @override
  String get readDeeper => 'Read deeper';

  // A noun, and a short one. The action row at 320 dp with text doubled has
  // room for about nine characters — 'Read the chart' overflowed it by 9.4 px
  // — and a verb here would have read as a second 'READ DEEPER' anyway, which
  // is the button directly beneath it.
  //
  // Above the `@override`, not below it: `tool/pair_translations.py` drops any
  // member whose comment sits between the annotation and the signature, and a
  // string missing from `TRANSLATIONS.md` is a string nobody reviews.
  @override
  String get chartGoDeeper => 'The chart';
  @override
  String get showLess => 'Show less';
  @override
  String get composeReadings => 'Compose readings';

  @override
  String get recomposeToday => 'Again';
  @override
  String get recomposeTodayNote =>
      'Composes today’s guidance again — all of it, not one section.';
  @override
  String get recomposedToday => 'Today has been read again.';

  @override
  String get recomposeChartReading => 'Again';
  @override
  String get recomposeChartReadingNote =>
      'The chart’s reading is written once and kept. Ask for it again '
      'after correcting anything above.';
  @override
  String get recomposedChartReading => 'The chart has been read again.';

  @override
  String get readingWaitsForBirthTime =>
      'The reading waits for your birth time. Without it the angles are a '
      'guess at noon, and a chart is mostly its angles.';

  @override
  String get composingChartReading => 'Reading the chart…';

  @override
  String get chartReadingNotWrittenYet =>
      'The reading is not written yet. Eter will try again the next time you '
      'open this.';
  @override
  String get personalReadingNotConnected =>
      'Personal reading composition is not connected on this build yet.';
  @override
  String get everyReadingAlreadyComposed =>
      'Every personal reading is already composed for this chart.';
  @override
  String get missingReadingsComposed =>
      'The missing personal readings have been composed.';
  @override
  String readingNotAccepted(String reason) =>
      'The reading could not be accepted: $reason. Nothing changed.';
  @override
  String get compositionUnavailableCachedRemain =>
      'Composition is unavailable right now. Cached readings remain.';
  @override
  String get personalReadingNotComposedYet =>
      'This personal reading has not been composed yet. The keywords are '
      'shipped with the app and stand on their own.';

  @override
  String get approximateTimeAndPlace =>
      'Birth time and place are incomplete. Noon and zero coordinates are used '
      'provisionally; the Ascendant is not reliable.';
  @override
  String get approximateTime =>
      'Birth time is unknown. Noon is used provisionally; the Ascendant is not '
      'reliable.';
  @override
  String get approximatePlace =>
      'Birth place is incomplete. The Ascendant is provisional.';

  @override
  String get headingPositionsToday => 'POSITIONS TODAY';
  @override
  String positionsSummary({
    required String moonPhaseCanonical,
    required String moonSignCanonical,
    required String sunSignCanonical,
  }) =>
      'A ${moonPhaseName(moonPhaseCanonical)} moon in '
      '${signName(moonSignCanonical)}, the sun in '
      '${signName(sunSignCanonical)}.';
  @override
  String get nothingCloseInTheSky =>
      'Nothing in the sky stands close to your chart today.';
  @override
  String contactLine({
    required String transiting,
    required String aspect,
    required String natal,
  }) =>
      '$transiting $aspect natal $natal';
  @override
  String contactOrb({required String degrees, required bool applying}) =>
      '$degrees° ${applying ? applyingWord : separatingWord}';
  @override
  String get readToday => 'Read today';
  @override
  String get readingToday => 'Reading';
  @override
  String get todaysReadingNotConnected =>
      'Today’s reading is not connected on this build yet. The positions below '
      'are calculated on this device.';
  @override
  String get todaysReadingCouldNotBeWritten =>
      'Today’s reading could not be written. The positions below are '
      'unchanged.';
  @override
  String get enableAiBeforeReadingToday =>
      'Enable AI guidance in the Sanctum before reading today.';

  @override
  String lifePathLabel(int value) => 'Life Path $value';

  @override
  String positionDetail({
    required String signName,
    required String degrees,
    required bool retrograde,
  }) =>
      '$signName $degrees°${retrograde ? ' $retrogradeWord' : ''}';

  // ----------------------------------------------------------------- journal

  @override
  String get journalHistory => 'History';
  @override
  String get openJournalHistorySemantic => 'Open journal history';
  @override
  String get closeHistorySemantic => 'Close history';
  @override
  String get headingHistory => 'HISTORY';
  @override
  String get headingTheDaySoFar => 'THE DAY SO FAR';
  @override
  String get writingFieldHint => 'What is asking for your attention?';
  @override
  String get nothingWrittenOnThisPage => 'Nothing was written on this page.';
  @override
  String get thisPageIsClosed =>
      'This page is closed. Today’s page is the one you can write on.';
  @override
  String get previousJournalDay => 'Previous journal day';
  @override
  String get nextJournalDay => 'Next journal day';
  @override
  String get nextJournalDayUnavailable => 'Next journal day unavailable';

  @override
  String get listening => 'Listening…';
  @override
  String get dictate => 'Dictate';
  @override
  String get stop => 'Stop';
  @override
  String get dictateSemantic => 'Dictate';
  @override
  String get stopDictationSemantic => 'Stop dictation';
  @override
  String get dictationNeedsMicrophone =>
      'Eter needs microphone access to take dictation. You can grant it in '
      'your phone’s settings.';
  @override
  String get dictationNothingHeard => 'Nothing was heard. Tap to try again.';
  @override
  String get dictationNeedsConnection =>
      'Dictation needs a connection on this phone. You can still type.';
  @override
  String get dictationStopped =>
      'Dictation stopped. You can tap to try again, or type.';
  @override
  String get dictationNoRecogniser =>
      'This phone has no speech recogniser Eter can use. You can still type.';
  @override
  String get dictationUnavailable => 'Dictation is unavailable right now.';
  @override
  String dictationLanguageUnavailable(String languageName) =>
      'This phone has no $languageName dictation installed. You can add it in '
      'your phone’s settings, or type.';

  @override
  String get keptFromAether => 'Kept from Aether';
  @override
  String get allowAether => 'Allow Aether';
  @override
  String get keepLocal => 'Keep local';
  @override
  String get allowAetherSemantic =>
      'Allow this journal entry in Aether guidance';
  @override
  String get keepLocalSemantic =>
      'Keep this journal entry out of Aether guidance';
  @override
  String get undoInterpretation => 'Undo interpretation';
  @override
  String get undoInterpretationSemantic =>
      'Remove interpretation and derived records';
  @override
  String get deleteEntrySemantic =>
      'Delete this journal entry and anything derived from it';
  @override
  String get deleteEntryTitle => 'Delete this entry?';
  @override
  String get deleteEntryBody =>
      'The page and anything derived from it are removed from this device. '
      'This cannot be undone.';
  @override
  String get fieldAddMissingDetail => 'Add the missing detail';
  @override
  String get addMoreDetailFirst => 'Add a little more detail first.';
  @override
  String get journalInterpretationNotConnected =>
      'Journal interpretation is not connected on this build yet.';
  @override
  String get enableAiBeforeSendingEntry =>
      'Enable AI guidance in the Sanctum before sending this entry.';
  @override
  String get entryNotInterpretedSafely =>
      'This entry could not be interpreted safely. Try again.';
  @override
  String get interpretationUnavailable =>
      'Interpretation is unavailable right now. Nothing changed.';
  @override
  String get interpretationAndDerivedRemoved =>
      'The interpretation and its derived records were removed.';
  @override
  String get tapToRevealImmediately => 'Tap to reveal immediately';

  @override
  String get aetherNeedsOneDetail =>
      'Aether needs one detail before applying anything.';
  @override
  String get entryWasInterpreted => 'The entry was interpreted.';
  @override
  String get entryWasInterpretedAndLogged =>
      'The entry was interpreted and logged.';
  @override
  String recordedItems(List<String> items) => switch (items.length) {
        1 => 'Recorded ${items.first}.',
        _ => 'Recorded ${items.take(items.length - 1).join(', ')} '
            'and ${items.last}.',
      };
  @override
  String get derivedWeight => 'a weight';
  @override
  String get derivedActivity => 'an activity';
  @override
  String get derivedActivities => 'activities';
  @override
  String get derivedWorkout => 'a workout';
  @override
  String get derivedFoodAwaitingReview => 'food waiting for review in Body';

  // ----------------------------------------------------------------- sanctum

  @override
  String get headingSanctum => 'SANCTUM';
  @override
  String get howEterMeetsYou => 'How Eter meets you';
  @override
  String get historyStaysOnThisDevice =>
      'Your history stays on this device. Cloud sync is off.';
  @override
  String get cloudContinuityAllowed =>
      'Cloud continuity is allowed. You can revoke it below.';

  @override
  String get headingOpeningPage => 'OPENING PAGE';
  @override
  String get choiceJournal => 'Journal';
  @override
  String get choiceDashboard => 'Dashboard';

  @override
  String get headingGuidanceRegister => 'GUIDANCE REGISTER';
  @override
  String get registerGrounded => 'Grounded';
  @override
  String get registerBalanced => 'Balanced';
  @override
  String get registerImmersive => 'Immersive';
  @override
  String get registerGroundedDetail => 'Daylight clarity at every hour.';
  @override
  String get registerBalancedDetail => 'Changes with sunrise and sunset.';
  @override
  String get registerImmersiveDetail => 'The deeper night register.';

  @override
  String get headingLanguage => 'LANGUAGE';
  @override
  String get languageDetail =>
      'Changes every word Eter says, including what Aether writes. Composed '
      'passages are cleared so nothing is left in the language you just left.';
  @override
  String languageChanged(int clearedPassages) =>
      'Eter now speaks English. $clearedPassages composed '
      '${clearedPassages == 1 ? 'passage was' : 'passages were'} cleared and '
      'will be written again; your records are untouched.';

  @override
  String get headingYourData => 'YOUR DATA';
  @override
  String get permissionsAreIndependent =>
      'Each permission is independent and can be revoked. Revoking AI also '
      'turns off journal-aware guidance.';

  @override
  String get headingAiGuidance => 'AI GUIDANCE';
  @override
  String get aiGuidanceOffDetail =>
      'No health context leaves this device for AI.';
  @override
  String get aiGuidanceAllowedDetail =>
      'Selected context may be sent to compose guidance.';
  @override
  String get headingJournalAwareGuidance => 'JOURNAL-AWARE GUIDANCE';
  @override
  String get journalAwareOffDetail => 'Journal prose is never sent.';
  @override
  String get journalAwareAllowedDetail =>
      'Only entries not marked Keep local may be included.';
  @override
  String get headingCloudContinuity => 'CLOUD CONTINUITY';
  @override
  String get localOnly => 'Local only';
  @override
  String get cloudOffDetail =>
      'No new copies are made. Any copy already in your account stays until you '
      'delete the account.';
  @override
  String get cloudAllowedDetail =>
      'Eligible documents may mirror to your account when sync is connected.';
  @override
  String get headingJournalInTheMirror => 'JOURNAL IN THE MIRROR';
  @override
  String get staysHere => 'Stays here';
  @override
  String get journalMirrorOffDetail =>
      'Your pages exist on this device only, and are lost with it.';
  @override
  String get journalMirrorAllowedDetail =>
      'Pages are copied too, and come back on a new phone.';
  @override
  String get headingCrashReports => 'CRASH REPORTS';
  @override
  String get crashReportsOffDetail => 'Nothing is sent when Eter fails.';
  @override
  String get crashReportsAllowedDetail =>
      'Send the error and your device model when Eter fails. Never your '
      'records.';

  @override
  String get headingBirthContext => 'BIRTH CONTEXT';
  @override
  String birthContextSummary({
    required String place,
    required String time,
    required String utcOffset,
  }) =>
      '$place · $time · UTC$utcOffset';
  @override
  String get locatedPlace => 'Located place';
  @override
  String get birthContextProvisional =>
      'Provisional. Add exact local time, its UTC offset, and a place to '
      'improve chart reliability.';
  @override
  String get headingHowWellIsTimeKnown => 'HOW WELL IS THE TIME KNOWN';
  @override
  String get precisionExact => 'To the minute';
  @override
  String get precisionApproximate => 'Roughly';
  @override
  String get precisionUnknown => 'Not at all';
  @override
  String get precisionExactDetail =>
      'From a record. The ascendant is stated plainly.';
  @override
  String get precisionApproximateDetail =>
      'A remembered part of the day. The chart is drawn, and every angle says '
      'it is provisional.';
  @override
  String get precisionUnknownDetail =>
      'The chart is drawn for noon and says so.';
  @override
  String get headingWhichPartOfDay => 'WHICH PART OF THE DAY';
  @override
  String get fieldLocalBirthTime => 'Local birth time · HH:MM';
  @override
  String get fieldUtcOffsetAtBirth =>
      'UTC offset at birth · for example +01:00';
  @override
  String get fieldBirthCityAndCountry => 'Birth city and country';
  @override
  String get placeLookupNote =>
      'Place lookup uses the device geocoder. The label and coordinates are '
      'stored locally.';
  @override
  String get offsetSuggestedFromPhone =>
      'Offset suggested from this phone’s timezone on that date, summer time '
      'included. Correct it if you were born elsewhere.';
  @override
  String get locatingBirthContext => 'Locating this birth context…';
  @override
  String get birthContextSaved => 'Birth context saved on this device.';

  @override
  String get headingAetherMemory => 'AETHER MEMORY';
  @override
  String get onlyStructuredPatternsRetained =>
      'Only structured patterns are retained. Local correlations are not '
      'treated as causes.';
  @override
  String get headingWeekInView => 'WEEK IN VIEW';
  @override
  String get noWeeklyViewPrepared => 'No weekly view has been prepared.';
  @override
  String get headingLocalPatterns => 'LOCAL PATTERNS';
  @override
  String get noActivePatterns => 'No active patterns.';

  @override
  String patternReceipt({
    required int confidencePercent,
    required Object? observations,
    required String? window,
    required num? coefficientMinutes,
  }) {
    final parts = <String>['$confidencePercent% confidence'];
    if (observations != null) parts.add('$observations observations');
    if (window != null) parts.add(window);
    if (coefficientMinutes != null) {
      final sign = coefficientMinutes > 0 ? '+' : '';
      parts.add('$sign${coefficientMinutes.round()} min difference');
    }
    return '${parts.join(' · ')} · $correlationNotCause';
  }

  @override
  String get correlationNotCause => 'correlation, not cause';
  @override
  String patternSemantic({
    required String summary,
    required String receipt,
  }) =>
      '$summary. $receipt.';
  @override
  String get notEnoughConsistentEvidence =>
      'Not enough consistent local evidence yet.';
  @override
  String patternsRefreshed({
    required int patterns,
    required int observations,
  }) =>
      '$patterns local pattern refreshed from $observations observations.';
  @override
  String get preparingSevenDayView => 'Preparing a factual seven-day view…';
  @override
  String get notEnoughHistoryForWeekly =>
      'There is not enough local history for a weekly view yet.';
  @override
  String get sevenDayViewPrepared => 'Seven-day view prepared on this device.';
  @override
  String get patternDismissed => 'Pattern dismissed. Aether will not use it.';
  @override
  String get resetPersonalizationWarning =>
      'This removes composed guidance, learned patterns, and retrospectives. '
      'Your journal and health history stay.';
  @override
  String get aetherMemoryAlreadyEmpty => 'Aether memory was already empty.';
  @override
  String get aetherMemoryCleared => 'Aether memory cleared from this device.';
  @override
  String retrospectiveSemantic({
    required String headline,
    required String passages,
    required String caveat,
    required String window,
  }) =>
      '$headline. $passages $caveat Window $window.';
  @override
  String retrospectiveWindow({required String from, required String to}) =>
      '$from to $to';

  @override
  String get headingOldPages => 'OLD PAGES';
  @override
  String get oldPagesNote =>
      'Journal text older than a year can be cleared while the meals, workouts '
      'and check-ins it produced stay.';
  @override
  String get pruneProseWarning =>
      'This clears the text of journal pages older than a year. Meals, '
      'workouts and check-ins derived from them stay.';
  @override
  String get noPagesOlderThanAYear => 'No pages are older than a year.';
  @override
  String clearedPageText(int pages) =>
      'Cleared the text of $pages page${pages == 1 ? '' : 's'}.';

  @override
  String get headingWhereYouLive => 'WHERE YOU LIVE';
  @override
  String get whereYouLiveNote =>
      'Eter turns at your own sunset. Your birth place sets the chart and never '
      'changes; this sets the horizon.';
  @override
  String get whereYouLivePrompt =>
      'Your clock does not match your birth place, so Eter is using plain hours '
      'instead of your real sunset. Name the city you live in and it will turn '
      'with the sun again.';
  @override
  String get fieldHomePlace => 'City';
  @override
  String homePlaceSaved(String place) => 'The register now turns at $place.';
  @override
  String get homePlaceForgotten =>
      'Forgotten. Eter reads the sun from your birth place again, if it can.';
  @override
  String get usingBirthPlaceForNow =>
      'Reading the sun from your birth place. Set this if you have moved.';

  @override
  String get headingDeleteFromThisDevice => 'DELETE FROM THIS DEVICE';
  @override
  String get deleteLocalIntro =>
      'Remove every local Eter record and return to onboarding.';
  @override
  String get deleteLocalWarning =>
      'This permanently removes the local profile, journal, health history, '
      'and derived readings. Nothing here is recoverable afterwards.';
  @override
  String get deleteLocalWarningCopyRemains =>
      'This removes the local profile, journal, health history, and derived '
      'readings from this device. Your account copy stays, and Restore would '
      'bring it back — delete the account below to remove that too.';

  @override
  String get headingHealthHistory => 'HEALTH HISTORY';
  @override
  String get healthConnectedReconnect =>
      'Connected. Reconnect to read the latest 30 days; source overlap is '
      'resolved per minute.';
  @override
  String get healthOffer =>
      'Read selected movement, sleep, and recovery signals from your phone’s '
      'health store.';
  @override
  String get healthOnboardingOffer =>
      'Read movement, sleep and recovery from your phone’s health store, so '
      'the Body has something to show from the start.';
  @override
  String get healthUnsupportedPlatform =>
      'Health connection is available on iPhone and Android.';
  @override
  String healthRecordsRead(int records) =>
      '$records health records read. Eter kept one source per minute.';
  @override
  String get healthAccessNotGranted =>
      'Access was not granted. No health values were imported.';
  @override
  String get healthAccessNotGrantedOnboarding =>
      'Access was not granted. Nothing was imported, and you can connect later '
      'in the Sanctum.';
  @override
  String get writeBack => 'Write back';
  @override
  String get writeBackNote =>
      'Sends weights and confirmed meals to your phone’s health record. Only '
      'what you entered here — never anything Eter read from it.';
  @override
  String healthWroteBack(int records) =>
      records == 1 ? '1 record written.' : '$records records written.';
  @override
  String get healthNothingToWriteBack =>
      'Nothing new to write. Everything you entered is already there.';
  @override
  String get healthCouldNotWriteBack =>
      'Could not write to the health record. Nothing was changed.';
  @override
  String get healthCouldNotBeRead =>
      'Health data could not be read. Existing history is unchanged.';
  @override
  String get healthCouldNotBeReadOnboarding =>
      'Health data could not be read. You can try again later in the Sanctum.';

  @override
  String get headingLocalExport => 'LOCAL EXPORT';
  @override
  String get localExportNote =>
      'Prepare a complete JSON snapshot and spreadsheet-friendly movement and '
      'session files. Nothing is uploaded.';
  @override
  String get localExportReady =>
      'Written to this phone’s Downloads folder. Cloud account data is not '
      'included.';
  @override
  String get localExportFailed =>
      'The local export could not be prepared right now.';
  @override
  String get exportFolderCopied => 'Export folder location copied.';

  // ----------------------------------------------------------------- account

  @override
  String get headingAether => 'AETHER';
  @override
  String aetherTrialDaysLeft(int days) => days == 1
      ? 'One day left of your trial.'
      : '$days days left of your trial.';
  @override
  String get aetherTrialEndsToday => 'Your trial ends today.';
  @override
  String get aetherTrialExplainsItself =>
      'Thirty days, because Aether needs about three weeks of your records '
      'before it can tell you something about yourself that you did not '
      'already know.';
  @override
  String get aetherLapsed =>
      'Your trial has ended, so Aether is no longer composing.';
  @override
  String get aetherSubscribed => 'Aether is composing.';
  @override
  String get aetherUnconfigured =>
      'This build has no guidance endpoint, so Aether cannot compose on it. '
      'Nothing you have is affected.';
  @override
  String get aetherRecordKeepsWorking =>
      'Everything you have written and recorded stays, and keeps working — the '
      'journal, your health history, the charts, your astrogram. It is the '
      'composing that stops.';
  @override
  String subscribeMonthly(String price) => 'Subscribe · $price a month';
  @override
  String subscribeYearly(String price) => 'Subscribe · $price a year';
  @override
  String get launchPriceWillRise =>
      'This is a launch price and will rise. Subscribing now does not lock it '
      'in — we would rather say so than surprise you later. A year bought now '
      'is a year at this price.';
  @override
  String get restorePurchases => 'Restore purchase';
  @override
  String get billingNotOnThisBuild =>
      'This build cannot take payment yet.';
  @override
  String get headingAccount => 'ACCOUNT';
  @override
  String get buildHasNoAccountSystem =>
      'This build has no account system. Everything works; nothing is backed '
      'up.';
  @override
  String get historyNeedsNoAccount =>
      'Your history is on this device and needs no account. Sign in only if '
      'you want it back when you change phone.';
  @override
  String get fieldEmail => 'Email';
  @override
  String get fieldPassword => 'Password';
  @override
  String get fieldNewPassword => 'New password';
  @override
  String passwordMinimum(int characters) =>
      'At least $characters characters. A phrase you will remember beats a '
      'short tangle you will not.';
  @override
  String get createAccount => 'Create account';
  @override
  String get signIn => 'Sign in';
  @override
  String get iHaveAnAccount => 'I have an account';
  @override
  String get createOne => 'Create one';
  @override
  String get continueWithGoogle => 'Continue with Google';
  @override
  String get forgottenPassword => 'Forgotten password';
  @override
  String get resetLinkOnItsWay =>
      'If that address has an account, a reset link is on its way.';
  @override
  String confirmationLinkSent(String email) =>
      'Check $email for a confirmation link. Your history stays here until you '
      'follow it.';
  @override
  String get signedIn => 'Signed in';
  @override
  String get historyCanBeRestored =>
      'Your history can be restored on a new phone.';
  @override
  String get confirmEmailToEnable =>
      'Confirm your email to enable that. Until you do, nothing leaves this '
      'device.';
  @override
  String get resendLink => 'Resend link';
  @override
  String get iHaveConfirmed => 'I have confirmed';
  @override
  String get verificationSent => 'Sent. It can take a minute to arrive.';
  @override
  String get notConfirmedYet =>
      'Not confirmed yet. Follow the link in the email, then try again.';
  @override
  String get syncNow => 'Sync now';
  @override
  String get restore => 'Restore';
  @override
  String get restoreOnlyFillsEmptyDevice =>
      'Restore only fills a device that has no history of its own — it will '
      'never overwrite what is already here.';
  @override
  String get signOut => 'Sign out';
  @override
  String get signedOutNothingRemoved =>
      'Signed out. Everything on this device is still here.';

  @override
  String get headingDeleteAccount => 'DELETE ACCOUNT';
  @override
  String get deleteAccount => 'DELETE ACCOUNT';
  @override
  String get deleteAccountIntro =>
      'Remove the account and the copy of your record held under it.';
  @override
  String get deleteAccountWarning =>
      'This deletes the account copy and then the account itself. Everything on '
      'this device stays, and keeps working — deleting the account is '
      'withdrawing from the mirror, not asking Eter to forget you.';
  @override
  String get accountDeletedRecordKept =>
      'Account deleted, along with its copy. Your record is still on this '
      'device.';
  @override
  String get somethingWentWrong => 'Something went wrong. Nothing was changed.';

  @override
  String get syncNotAvailableOnBuild => 'Sync is not available on this build.';
  @override
  String get everythingAlreadyCopied => 'Everything was already copied.';
  @override
  String copiedRecords(int records) =>
      'Copied $records ${records == 1 ? 'record' : 'records'}.';
  @override
  String get journalStayedOnThisDevice => 'Your journal stayed on this device.';
  @override
  String get nothingInAccountToRestore =>
      'There was nothing in your account to restore.';
  @override
  String restoredRecords(int records) =>
      'Restored $records ${records == 1 ? 'record' : 'records'}.';
  @override
  String syncRefusal(SyncRefusal refusal) => switch (refusal) {
        SyncRefusal.nothingToSync => 'There is nothing to sync yet.',
        SyncRefusal.confirmEmailBeforeCopying =>
          'Confirm your email before anything is copied.',
        SyncRefusal.cloudContinuityOff => 'Cloud continuity is off.',
        SyncRefusal.confirmEmailFirst => 'Confirm your email first.',
        SyncRefusal.deviceAlreadyHasHistory =>
          'This device already has history, so nothing was restored.',
      };

  @override
  String accountFailure(AccountFailure failure) => switch (failure) {
        AccountFailure.invalidEmail =>
          'That does not look like an email address.',
        AccountFailure.weakPassword =>
          'Choose a password of at least eight characters.',
        AccountFailure.emailInUse =>
          'That address is already registered. Sign in instead, or reset the '
              'password.',
        // Identical on purpose — see the doc on `accountFailure`.
        AccountFailure.wrongPassword ||
        AccountFailure.noSuchAccount =>
          'That email and password do not match.',
        AccountFailure.cancelled => 'Sign-in was cancelled.',
        AccountFailure.network =>
          'No connection. Eter works offline; sync will wait.',
        AccountFailure.tooManyAttempts =>
          'Too many attempts. Try again in a few minutes.',
        AccountFailure.notVerified =>
          'Confirm your email first — check for the link we sent.',
        AccountFailure.requiresRecentLogin =>
          'Sign in again first, then ask again. Nothing was deleted.',
        AccountFailure.unknown => 'Sign-in failed. Nothing was changed.',
      };

  // -------------------------------------------------------------- onboarding

  @override
  String onboardingStepSemantic({required int step, required int total}) =>
      'Onboarding step $step of $total';
  @override
  String onboardingStepMark({required int step, required int total}) =>
      '$step / $total';
  @override
  String get continueLabel => 'Continue';
  @override
  String get enterEter => 'Enter Eter';

  @override
  String get welcomeTitle => 'Begin with what matters';
  @override
  String get welcomeIntro =>
      'A few words are enough. You can change or remove any of this later.';
  @override
  String get fieldWhatShouldEterCallYou => 'What should Eter call you?';
  @override
  String get fieldWhatWouldYouLikeMoreOf => 'What would you like more of?';
  @override
  String get hintWhatWouldYouLikeMoreOf =>
      'Steadier energy, deeper sleep, a clearer mind…';

  @override
  String get birthStepTitle => 'Your point of origin';
  @override
  String get birthStepIntro =>
      'Date supports health context and symbolic calculations. Place and exact '
      'time are optional; without them, Eter labels the chart provisional.';
  @override
  String get fieldBirthDate => 'Birth date';
  @override
  String get hintBirthDateFormat => 'YYYY-MM-DD';
  @override
  String get fieldCurrentWeightKg => 'Current weight in kilograms';
  @override
  String get fieldCurrentHeightCm => 'Current height in centimetres';
  @override
  String get headingBodyContext => 'BODY CONTEXT';
  @override
  String get sexFemale => 'Female';
  @override
  String get sexMale => 'Male';
  @override
  String get sexOther => 'Another / prefer not to say';
  @override
  String get fieldBirthPlaceOptional => 'Birth place — optional';
  @override
  String get hintCityOrRegion => 'City or region';
  @override
  String get exactBirthTimeLater =>
      'Exact birth time can be added later in the Sanctum.';
  @override
  String get errorEnterValidBirthDate =>
      'Enter a valid birth date as YYYY-MM-DD.';
  @override
  String get errorMinimumAge =>
      'Eter is currently available to people aged 16 and over.';
  @override
  String get errorEnterWeightRange =>
      'Enter your current weight between 20 and 500 kg.';
  @override
  String get errorEnterHeightRange =>
      'Enter your current height between 100 and 250 cm.';

  @override
  String get registerStepTitle => 'How Eter should speak';
  @override
  String get registerStepIntro =>
      'This sets the voice, not the facts. You can change it any time in the '
      'Sanctum.';
  @override
  String get registerGroundedOnboardingDetail =>
      'Daylight clarity at every hour. Plain, practical, unadorned.';
  @override
  String get registerBalancedOnboardingDetail =>
      'Changes with sunrise and sunset, as the day does.';
  @override
  String get registerImmersiveOnboardingDetail =>
      'The deeper night register, symbolic and unhurried.';

  @override
  String get languageStepTitle => 'What language should Eter speak?';
  @override
  String get languageStepIntro =>
      'Set from your phone to begin with. It changes every word, including '
      'what Aether writes, and you can change it any time in the Sanctum.';

  @override
  String get consentStepTitle => 'Choose what may leave this device';
  @override
  String get consentStepIntro =>
      'All of these are optional. Core journaling and local calculations still '
      'work if you decline.';
  @override
  String get consentAiTitle => 'AI guidance';
  @override
  String get consentAiDetail =>
      'Send selected health context to compose guidance.';
  @override
  String get consentJournalAiTitle => 'Journal-aware guidance';
  @override
  String get consentJournalAiDetail =>
      'Allow included journal prose to be sent for reflection.';
  @override
  String get consentCloudTitle => 'Cloud continuity';
  @override
  String get consentCloudDetail =>
      'Keep an encrypted account copy for a future phone.';
  @override
  String get allowMark => 'ALLOW';
  @override
  String get offMark => 'OFF';
  @override
  String consentSemantic({required String title, required bool allowed}) =>
      '$title, ${allowed ? 'allowed' : 'kept off'}';
  @override
  String get healthHistoryTitle => 'Health history';

  // ---------------------------------------------------------------- tutorial

  @override
  String get walkthroughJournal =>
      'This is the page. Write or speak whatever the day was — meals, '
      'movement, how it felt. There are no forms anywhere else; everything '
      'Eter knows about a day starts here.';
  @override
  String get walkthroughGuidance =>
      'The other side reads it back. One passage each morning, drawn from '
      'what you wrote, what your body recorded, and where the sky stands.';
  @override
  String get walkthroughDepths =>
      'Under the guidance sit three depths: the reading itself, the body’s '
      'measurements, and your chart. Tap any of the three to move between '
      'them — the day stays where it is.';
  @override
  String get walkthroughTwoDoors => 'TWO DOORS';
  @override
  String get walkthroughRail =>
      'The whole app is these two, side by side. Tap either word, or swipe '
      'between them.';
  @override
  String get walkthroughSanctum =>
      'Everything else lives behind this mark — what leaves the device, '
      'your language and register, your record, and the way out.';

  @override
  List<TutorialPassage> get tutorialPassages => const [
        TutorialPassage(
          eyebrow: 'ETER',
          lines: [
            'Eter reads your days and tells you what it notices.',
            'It is not a tracker with a companion bolted on. There are no '
                'streaks, no scores, and no rings to close — nothing here '
                'measures you against anyone, including yesterday’s you.',
          ],
        ),
        TutorialPassage(
          eyebrow: 'WHAT IT WORKS FROM',
          lines: [
            'Three things, and it says which is which.',
            'What you write. What your body recorded, if you connect it. And '
                'where the sky stood when you were born and where it stands '
                'today. A day you did not record is treated as absent, never '
                'as a zero.',
          ],
        ),
        TutorialPassage(
          eyebrow: 'WHERE IT STAYS',
          lines: [
            'On this device, unless you say otherwise.',
            'Nothing leaves without a consent you granted by name, each one '
                'separate and each one revocable. What you write can be kept '
                'from Aether entirely, page by page.',
          ],
        ),
        TutorialPassage(
          eyebrow: 'WHAT IT WILL NOT DO',
          lines: [
            'It does not diagnose, prescribe, or tell you what to do.',
            'Symbolism colours how a day is framed; it is never the reason '
                'for anything. The reason is always what was recorded — and '
                'every reading shows its own working.',
          ],
        ),
      ];

  // ---------------------------------------------------------------- body fat

  @override
  String get fieldBodyFatOptional => 'Body fat — optional';
  @override
  String get bodyFatNotGiven => 'Not given';
  @override
  String get bodyFatSemanticNotGiven => 'Body fat, optional, not given';
  @override
  String bodyFatSemantic(String formatted) => 'Body fat $formatted';
  @override
  String get bodyFatNote =>
      'Only if you know it. Eter never estimates this from your weight, and '
      'leaves it out of every calculation when it is absent.';

  @override
  String bodyRecordError(BodyRecordError error) => switch (error) {
        BodyRecordError.activityName =>
          'Name the activity in 1–80 characters.',
        BodyRecordError.activityDuration =>
          'Enter a duration between 1 and 1,440 minutes.',
        BodyRecordError.activityEnergy =>
          'Enter active energy between 1 and 10,000 kcal.',
        BodyRecordError.weightRange =>
          'Weight must be between 20 and 500 kg.',
        BodyRecordError.strengthNeedsExercise =>
          'Add one exercise with at least one set.',
        BodyRecordError.strengthReps =>
          'Each set holds between 1 and 500 reps.',
        BodyRecordError.strengthLoad =>
          'Load must be between 0 and 1,000 kg.',
        BodyRecordError.strengthNeedsBodyWeight =>
          'Record a body weight first; strength energy is estimated from it.',
      };

  // ---------------------------------------------------- birth context errors

  @override
  String birthContextError(BirthContextError error) => switch (error) {
        BirthContextError.birthDateInvalid => 'That is not a date the calendar has. Check the day and month.',
        BirthContextError.birthDateTooYoung => 'Eter is for people aged sixteen and over.',
        BirthContextError.placeNotLocated =>
          'That place could not be located. Try a city and country.',
        BirthContextError.profileUnavailable =>
          'The local profile is unavailable.',
        BirthContextError.choosePartOfDay =>
          'Choose which part of the day you were born in.',
        BirthContextError.addUtcOffset =>
          'Add the UTC offset at birth, so the time can be placed.',
        BirthContextError.placeNotLocatedNow =>
          'That place could not be located right now. Nothing changed.',
        BirthContextError.timeFormat =>
          'Enter birth time as HH:MM, or leave it blank.',
        BirthContextError.utcOffsetFormat =>
          'Enter the birth-place UTC offset like +01:00.',
        BirthContextError.utcOffsetRange =>
          'UTC offset must be between −14:00 and +14:00.',
      };

  // ----------------------------------------------------- symbolic vocabulary

  @override
  String elementName(Element element) => element.label;
  @override
  String elementMedallionSemantic(Element element) =>
      '${element.label} element';

  @override
  String signName(String canonical) => canonical;

  @override
  String bodyName(String canonical) => canonical;

  @override
  String aspectName(String canonical) => canonical;

  @override
  String moonPhaseName(String canonical) => canonical;

  @override
  String arcanaTitle(String slug) => switch (slug) {
        'the-fool' => 'The Fool',
        'the-magician' => 'The Magician',
        'the-high-priestess' => 'The High Priestess',
        'the-empress' => 'The Empress',
        'the-emperor' => 'The Emperor',
        'the-hierophant' => 'The Hierophant',
        'the-lovers' => 'The Lovers',
        'the-chariot' => 'The Chariot',
        'strength' => 'Strength',
        'the-hermit' => 'The Hermit',
        'wheel-of-fortune' => 'Wheel of Fortune',
        'justice' => 'Justice',
        'the-hanged-man' => 'The Hanged Man',
        'death' => 'Death',
        'temperance' => 'Temperance',
        'the-devil' => 'The Devil',
        'the-tower' => 'The Tower',
        'the-star' => 'The Star',
        'the-moon' => 'The Moon',
        'the-sun' => 'The Sun',
        'judgement' => 'Judgement',
        'the-world' => 'The World',
        _ => slug,
      };

  @override
  String matrixPositionLabel(MatrixPosition position) => position.label;
  @override
  String matrixPositionDetail(MatrixPosition position) => position.detail;
  @override
  String birthPeriodLabel(BirthTimePeriod period) => period.label;
  @override
  String birthPeriodDetail(BirthTimePeriod period) => period.detail;

  @override
  String get applyingWord => 'applying';
  @override
  String get separatingWord => 'separating';
  @override
  String get retrogradeWord => 'retrograde';

  // ------------------------------- locally composed prose (never the model)

  @override
  String patternSleepAfterLateActivity({required bool shorter}) =>
      'Sleep tended to be ${shorter ? 'shorter' : 'longer'} after late '
      'activity.';

  @override
  String seriesLabel(String canonical) => switch (canonical) {
        'steps' => 'your step count',
        'activeKcal' => 'how much you moved',
        'sleep' => 'how long you slept',
        'deep' => 'deep sleep',
        'rem' => 'REM sleep',
        'awake' => 'time awake in the night',
        'restingHr' => 'your resting heart rate',
        'hrv' => 'your heart-rate variability',
        'intake' => 'what you ate',
        'sessions' => 'training sessions',
        'mood' => 'your mood',
        'stress' => 'your stress',
        'recovery' => 'how recovered you felt',
        'meditation' => 'time spent in meditation',
        'weight' => 'your weight',
        _ => canonical,
      };

  @override
  String patternSweepSummary({
    required String fromKey,
    required String toKey,
    required bool lagged,
    required bool positive,
    required int percent,
    required int days,
  }) {
    final from = seriesLabel(fromKey);
    final to = seriesLabel(toKey);
    final direction = positive ? 'more' : 'less';
    final receipt = 'about $percent% of the variation, across $days days';
    return lagged
        ? 'On days after $from is higher, $to tends to be $direction '
            '($receipt).'
        : 'When $from is higher, $to tends to be $direction that same day '
            '($receipt).';
  }

  @override
  String retrospectiveHeadline({required bool complete}) => complete
      ? 'Your seven-day view'
      : 'Your partial seven-day view';
  @override
  String retrospectiveMovement({
    required int days,
    int? averageActiveKcal,
    int? averageSteps,
    int? stepDays,
  }) {
    final sentence = StringBuffer('Movement was recorded on $days of 7 days');
    if (averageActiveKcal != null) {
      sentence.write(
        ', averaging $averageActiveKcal active kcal on recorded days',
      );
    }
    if (averageSteps != null && stepDays != null) {
      sentence.write(
        '${averageActiveKcal == null ? ',' : ' and'} $averageSteps steps '
        'across $stepDays measured ${stepDays == 1 ? 'day' : 'days'}',
      );
    }
    return '$sentence.';
  }
  @override
  String retrospectiveSleep({
    required int nights,
    required String averageHours,
  }) =>
      'Sleep was available for $nights of 7 nights, averaging $averageHours '
      'hours.';
  @override
  String retrospectiveJournal(int entries) =>
      'You made $entries journal ${entries == 1 ? 'entry' : 'entries'} during '
      'this window.';
  @override
  String retrospectiveLifestyle({
    required int signals,
    required List<String> kinds,
  }) =>
      '$signals self-reported ${signals == 1 ? 'signal was' : 'signals were'} '
      'recorded across ${kinds.map(lifestyleKindName).join(', ')}.';
  @override
  String get retrospectiveCaveat =>
      'Missing days are omitted, not treated as zero.';

  @override
  String lifestyleKindName(String canonical) => switch (canonical) {
        'mood' => 'mood',
        'stress' => 'stress',
        'recovery' => 'recovery',
        'meditation' => 'meditation',
        'breathwork' => 'breathwork',
        _ => canonical,
      };

  // ------------------------------------------------------------- the long view

  @override
  String get headingLongView => 'THE LONG VIEW';
  @override
  String get headingLetter => 'A LETTER';
  @override
  String letterMonth(String month) => 'On $month';
  @override
  String get headingCorrespondence => 'A CORRESPONDENCE';
  @override
  String get correspondenceNote =>
      'One other person sees the single sentence Aether writes you each day, '
      'and you see theirs. Nothing measured, nothing you wrote, no health '
      'data — one sentence, and only today’s.';
  @override
  String get correspondenceNotPaired => 'Nobody sees anything.';
  @override
  String get correspondencePaired =>
      'One correspondence is open. Either of you can end it at any time, '
      'without the other agreeing.';
  @override
  String get correspondenceOffer => 'Offer a code';
  @override
  String get correspondenceAccept => 'Use a code';
  @override
  String get correspondenceEnd => 'End it';
  @override
  String correspondenceCodeIs(String code) => 'Your code is $code';
  @override
  String get correspondenceCodeNote =>
      'Read it to them. It works once, and only for a day.';
  @override
  String get fieldPairingCode => 'Their code';
  @override
  String get correspondenceNeedsAccount =>
      'A correspondence needs an account on both sides. Sign in above.';
  @override
  String get correspondenceCodeNotRecognised =>
      'That code has been used, or has expired.';
  @override
  String get correspondenceOwnCode => 'That is your own code.';
  @override
  String get correspondenceFailed =>
      'That did not go through. Nothing was changed.';
  @override
  String get correspondenceTheirDay => 'THEIR DAY';
  @override
  String get headingLocalImport => 'BRING A RECORD BACK';
  @override
  String get localImportNote =>
      'Read an Eter export back onto this device. Only onto a device with no '
      'history of its own — nothing here is ever overwritten.';
  @override
  String get importRecord => 'Choose a file';
  @override
  String localImportRestored(int records) => '$records records restored.';
  @override
  String localImportPartly(int records) =>
      '$records records restored. Part of that file was written by a newer '
      'Eter and could not be read.';
  @override
  String get localImportNotAnExport => 'That file is not an Eter export.';
  @override
  String get localImportNewerVersion =>
      'That export came from a newer Eter. Update this one first.';
  @override
  String get localImportDeviceHasHistory =>
      'This device already has history, so nothing was restored.';
  @override
  String get localImportFailed =>
      'That file could not be read. Nothing was changed.';
  @override
  String get headingEveningInvitation => 'AN EVENING INVITATION';
  @override
  String get eveningInvitationOffDetail =>
      'Eter never speaks first. Nothing arrives unless you open it.';
  @override
  String get eveningInvitationAllowedDetail =>
      'One quiet invitation to write, at your own sunset — or at eight, if '
      'Eter does not know where you are. Not if you have already written that '
      'day, and nothing else: no mornings, no streaks, no reminders to come '
      'back.';
  @override
  String get eveningInvitationNotPermitted =>
      'Your phone did not allow notifications, so nothing was turned on. You '
      'can grant them in your phone’s settings.';
  @override
  String get invitationTitle => 'The evening';
  @override
  String get invitationBody => 'Say how today went, if you feel like it.';
  @override
  String get longViewNote =>
      'Keep turning back in the Journal’s history and the day widens — a week, '
      'a month, a year. It is counted on this device, so it works offline and '
      'costs nothing.';
  @override
  String longViewSpanName(LongViewSpanName span) => switch (span) {
        LongViewSpanName.week => 'Week',
        LongViewSpanName.month => 'Month',
        LongViewSpanName.year => 'Year',
      };
  @override
  String longViewRecorded({required int recorded, required int total}) =>
      '$recorded of $total recorded.';
  @override
  String get longViewNothingRecorded =>
      'Nothing was recorded in this stretch of time.';
  @override
  String longViewMeasure(LongViewMeasure measure) => switch (measure) {
        LongViewMeasure.sleep => 'Sleep',
        LongViewMeasure.mood => 'Mood',
        LongViewMeasure.steps => 'Steps',
        LongViewMeasure.pages => 'Pages written',
      };
  @override
  String longViewSeriesSemantic({
    required String measure,
    required String cells,
    required int absent,
  }) =>
      absent == 0
          ? '$measure. $cells.'
          : '$measure. $cells. $absent not recorded.';
  @override
  String longViewCellSemantic({required String label, required String value}) =>
      '$label $value';
  @override
  String longViewCellAbsent(String label) => '$label not recorded';
}
