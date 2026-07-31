import '../account/account.dart';
import '../arcana/matrix.dart';
import '../health/record_error.dart';
import '../arcana/zodiac.dart';
import '../profile/birth_context.dart';
import '../sync/cloud_mirror.dart';
import '../profile/birth_time.dart';
import 'language.dart';
import 'strings.dart';

/// Polski.
///
/// Addressed with `ty` throughout, and phrased to avoid grammatical gender
/// wherever Polish would otherwise force a choice the profile has no business
/// making — `Zapisano`, `Nie udało się`, `Można` rather than a participle that
/// has to agree with the reader. Where a sentence genuinely needs a person in
/// it, the second person singular carries it without gender.
///
/// The vocabulary is fixed here rather than improvised per surface:
///
/// * **Eter**, **Aether** — never translated. The product's name, and the name
///   of the thing that writes. Aether keeps the Greek spelling in both
///   languages so a Polish reader meets the same character an English one does.
/// * **Wgląd** — *guidance*, and also the right-hand destination. One word for
///   both, by the product owner's choice: the surface is the insight, and the
///   section within it is the pure form of it. See `docs/POLISH.md`.
/// * **Krąg** — *the Vessel*. **Zacisze** — *the Sanctum*. **Głębia** — the
///   disclosure. **Dziennik** — *the Journal*. None is the literal translation;
///   `docs/POLISH.md` records what each was chosen over and why.
/// * **Rejestr** — *register*, in the musical sense the English word carries
///   here, not a ledger.
///
/// Astrological and tarot names use the terms Polish practice actually uses
/// (`Ascendent`, `Medium Coeli`, `sekstyl`, `Koziorożec`, `Wisielec`), not
/// calques of the English.
class EterStringsPl extends EterStrings {
  const EterStringsPl();

  @override
  AppLanguage get language => AppLanguage.polish;

  // ------------------------------------------------------------------ common

  @override
  String get close => 'Zamknij';
  @override
  String get cancel => 'Anuluj';
  @override
  String get save => 'Zapisz';
  @override
  String get saving => 'Zapisuję';
  @override
  String get edit => 'Zmień';
  @override
  String get review => 'Przejrzyj';
  @override
  String get reviewing => 'Przeglądam ostatnie lokalne sygnały…';
  @override
  String get confirm => 'Potwierdź';
  @override
  String get delete => 'Usuń';
  @override
  String get deleteNow => 'Usuń teraz';
  @override
  String get keep => 'Zostaw';
  @override
  String get back => 'Wstecz';
  @override
  String get proceed => 'Sprawdź';
  @override
  String get next => 'Dalej';
  @override
  String get skip => 'Pomiń';
  @override
  String get begin => 'Zacznij';
  @override
  String get refresh => 'Odśwież';
  @override
  String get connect => 'Połącz';
  @override
  String get export => 'Eksportuj';
  @override
  String get copyPath => 'Kopiuj ścieżkę';
  @override
  String get prepare => 'Przygotuj';
  @override
  String get dismiss => 'Odrzuć';
  @override
  String get clear => 'Wyczyść';
  @override
  String get clearNow => 'Wyczyść teraz';
  @override
  String get reset => 'Od nowa';
  @override
  String get composing => 'Powstaje';
  @override
  String get off => 'Wyłączone';
  @override
  String get allowed => 'Dozwolone';

  // --------------------------------------------------------------- the shell

  @override
  String get destinationJournal => 'DZIENNIK';
  @override
  String get destinationDashboard => 'WGLĄD';
  @override
  String get sanctum => 'Zacisze';
  @override
  String get openSanctumSemantic => 'Otwórz Zacisze';

  // ----------------------------------------------------------- the dashboard

  @override
  String get guidanceNotComposedYet =>
      'Dzisiejszy wgląd jeszcze nie powstał.';
  @override
  String get composingTodaysGuidance => 'Dzisiejszy wgląd właśnie powstaje…';
  @override
  String get composeNow => 'Niech powstanie';
  @override
  String get guidanceComposed => 'Dzisiejszy wgląd jest gotowy.';
  @override
  String get guidanceAlreadyCurrent =>
      'Wgląd już odpowiada temu, co Eter wie o dzisiejszym dniu.';
  @override
  String get aetherNotConnected =>
      'Aether nie jest jeszcze podłączony w tej wersji.';
  @override
  String get enableAiBeforeComposing =>
      'Włącz wgląd AI w Zaciszu, zanim o niego poprosisz.';
  @override
  String get responseNotAcceptedSafely =>
      'Tej odpowiedzi nie dało się bezpiecznie przyjąć. Nic się nie zmieniło.';
  @override
  String get compositionUnavailable =>
      'Aether teraz nie odpowiada. Dotychczasowy wgląd zostaje.';

  @override
  String get lookDeeper => 'GŁĘBIA';
  @override
  String get sectionGuidance => 'WGLĄD';
  @override
  String get sectionBody => 'CIAŁO';
  @override
  String get sectionVessel => 'KRĄG';

  @override
  String guidanceDimension(String canonical) => switch (canonical) {
        'health' => 'ZDROWIE',
        'mind' => 'UMYSŁ',
        'spirit' => 'DUCH',
        'synthesis' => 'SYNTEZA',
        _ => canonical.toUpperCase(),
      };

  @override
  String evidenceFor(String dimension) => 'Podstawa dla: $dimension';

  @override
  String evidenceReceipt({
    required Object? n,
    required Object? window,
    required Object? coefficient,
    required Object? note,
  }) =>
      'n=$n · $window · współczynnik $coefficient\n'
      '$note To współwystępowanie, a nie dowód przyczyny.';

  @override
  String get evidenceUnknownCount => 'nieznane';
  @override
  String get evidenceWindowUnavailable => 'okno niedostępne';
  @override
  String get evidenceCoefficientUnavailable => 'niedostępny';
  @override
  String get evidenceUnreadable =>
      'Nie udało się odczytać zapisanych szczegółów podstawy.';

  // -------------------------------------------------------------------- body

  @override
  String get theBody => 'CIAŁO';
  @override
  String get bodyExpandsHint => 'rozwija szczegóły zdrowia';
  @override
  String factResting(int bpm) => 'puls spoczynkowy $bpm';
  @override
  String factSteps(String formattedSteps) => 'kroki: $formattedSteps';

  @override
  String get conclusionNothingRecorded =>
      'Dzisiaj nie zapisano jeszcze ani ruchu, ani jedzenia.';
  @override
  String get conclusionNothingEaten =>
      'Dzisiaj nie zapisano jeszcze nic zjedzonego.';
  @override
  String conclusionNoActivityYet(String eaten) =>
      'Zapisano $eaten kcal; ruchu jeszcze nie zanotowano.';
  @override
  String conclusionLevel({required String eaten, required String burned}) =>
      'Przyjęte i spalone są blisko równowagi — $eaten kcal zjedzone wobec '
      '$burned kcal spalonych.';
  @override
  String conclusionOver({required String eaten, required String burned}) =>
      'Dzisiaj trochę powyżej — $eaten kcal zjedzone wobec $burned kcal '
      'spalonych.';
  @override
  String conclusionUnder({required String eaten, required String burned}) =>
      'Dzisiaj trochę poniżej — $eaten kcal zjedzone wobec $burned kcal '
      'spalonych.';

  @override
  String get estimateWaitingBelow =>
      'Poniżej czeka jedno oszacowanie jedzenia. Nie wchodzi do bilansu, dopóki '
      'go nie potwierdzisz albo nie poprawisz.';
  @override
  String get headingFoodNotes => 'NOTATKI O JEDZENIU';
  @override
  String get headingRecoverySignals => 'SYGNAŁY REGENERACJI';
  @override
  String get noRecoverySignals =>
      'Dzisiaj nie ma żadnych sygnałów regeneracji z urządzenia.';
  @override
  String get headingRestingHeartRate => 'PULS SPOCZYNKOWY';
  @override
  String get headingHeartRateVariability => 'ZMIENNOŚĆ RYTMU SERCA';
  @override
  String get headingSleep => 'SEN';
  @override
  String get headingLastNight => 'OSTATNIA NOC';
  @override
  String get headingWeight => 'WAGA';
  @override
  String get headingActivityByTime => 'AKTYWNOŚĆ W CIĄGU DNIA';

  @override
  String get recoveryTrendUnavailable =>
      'Historyczny trend regeneracji nie jest jeszcze dostępny.';
  @override
  String get noSleepRecorded => 'Nie zapisano jeszcze żadnego snu.';
  @override
  String get lastNightNotStaged =>
      'Ostatnia noc nie została podzielona na fazy.';
  @override
  String get sleepHistoryNeedsTwoNights =>
      'Historia potrzebuje co najmniej dwóch zapisanych nocy.';
  @override
  String get weightNeedsTwoEntries =>
      'Trend wagi potrzebuje co najmniej dwóch wpisów.';
  @override
  String get activityByTimeUnavailable =>
      'Aktywność w ciągu dnia będzie dostępna, dopiero gdy podłączysz dane o '
      'ruchu z dokładnością do minuty.';

  @override
  String sleptSummary({
    required int hours,
    required int minutes,
    required String from,
    required String to,
  }) =>
      '${hours}h ${minutes}m snu · od $from do $to';

  @override
  String windowDays(int days) => '$days ${_dni(days)}';

  @override
  String signalRestingHeartRate(int bpm) => 'puls spoczynkowy $bpm';
  @override
  String signalHrv(int ms) => 'HRV $ms ms';
  @override
  String signalRespiratoryRate(String perMinute) =>
      '$perMinute oddechów na minutę';

  @override
  String get trendRestingHeartRate => 'Trend pulsu spoczynkowego';
  @override
  String get trendHeartRateVariability => 'Trend zmienności rytmu serca';
  @override
  String get trendWeight => 'Trend wagi';
  @override
  String get unitBpm => 'ud./min';
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
      'OSZACOWANIE · $kcal KCAL · POZA SUMĄ';
  @override
  String get correctEstimateFirst =>
      'Popraw oszacowanie, zanim wejdzie do dzisiejszej sumy.';

  // ------------------------------------------------------------- instruments

  @override
  String get balanceEaten => 'Zjedzone';
  @override
  String get balanceBurned => 'Spalone';

  @override
  String trendSemantic({
    required String label,
    required int readings,
    required String latest,
    required String unit,
    required String low,
    required String high,
  }) =>
      '$label, $readings ${_odczyty(readings)}. Najnowszy: $latest $unit. '
      'Zakres od $low do $high $unit.';

  @override
  String trendDayCount(int days) => '$days ${_dni(days).toUpperCase()}';

  @override
  String sleepStageName(String canonical) => switch (canonical) {
        'deep' => 'Głęboki',
        'light' => 'Lekki',
        'rem' => 'REM',
        'awake' => 'Czuwanie',
        'unknown' => 'Bez faz',
        _ => canonical,
      };

  @override
  String sleepStageMinutes(String canonical, int minutes) =>
      '${sleepStageName(canonical).toUpperCase()} ${minutes}m';

  @override
  String sleepStagesSemantic(String stageSummary) => 'Fazy snu. $stageSummary.';

  @override
  String sleepStageSemanticEntry(String canonical, int minutes) =>
      '${sleepStageName(canonical)} $minutes ${_minuty(minutes)}';

  @override
  String sleepHistorySemantic({
    required int windowDays,
    required int nights,
    required String averageHours,
    required String nightSummary,
  }) =>
      'Historia snu z $windowDays ${_dniGen(windowDays)}, $nights '
      '${_nocy(nights)}. Średnio $averageHours godz. $nightSummary.';

  @override
  String sleepNightSemantic(int index, String stages) => 'Noc $index: $stages';

  @override
  String averageHoursMark(String hours) => '$hours h ŚR';

  @override
  String activityDaySemantic({
    required String totalKilocalories,
    required String detail,
  }) =>
      'Aktywność w ciągu dnia. Razem $totalKilocalories kilokalorii. $detail.';

  @override
  String activityHourSemantic({required String clock, required int kcal}) =>
      '$clock — $kcal kilokalorii';

  // ------------------------------------------------------------------ vessel

  @override
  String get theVessel => 'KRĄG';
  @override
  String get readingChartOnDevice =>
      'Czytam kosmogram zapisany na tym urządzeniu…';
  @override
  String get birthDetailsNeededForVessel =>
      'Krąg potrzebuje danych urodzenia, żeby można go było narysować.';

  @override
  String get headingYourCard => 'TWOJA KARTA';
  @override
  String sunCardSemantic(String cardTitle) =>
      '$cardTitle, twoja karta Słońca';
  @override
  String sunSitsIn(String? canonicalSign) => canonicalSign == null
      ? 'Twoje Słońce stoi we własnym znaku, i to wyznacza tę kartę. To się nie '
          'zmienia.'
      : 'Twoje Słońce stoi ${_wZnaku(canonicalSign)}, i to wyznacza tę kartę. '
          'To się nie zmienia.';
  @override
  String positionCardSemantic({
    required String cardTitle,
    required String positionLabel,
  }) =>
      '$cardTitle, $positionLabel';

  @override
  String get readDeeper => 'Czytaj głębiej';
  @override
  String get showLess => 'Pokaż mniej';
  @override
  String get composeReadings => 'Niech powstaną';
  @override
  String get personalReadingNotConnected =>
      'Osobiste odczytania nie są jeszcze podłączone w tej wersji.';
  @override
  String get everyReadingAlreadyComposed =>
      'Wszystkie osobiste odczytania dla tego kosmogramu już powstały.';
  @override
  String get missingReadingsComposed =>
      'Brakujące osobiste odczytania powstały.';
  @override
  String readingNotAccepted(String reason) =>
      'Nie udało się przyjąć odczytania: $reason. Nic się nie zmieniło.';
  @override
  String get compositionUnavailableCachedRemain =>
      'Aether teraz nie odpowiada. Zapisane odczytania zostają.';
  @override
  String get personalReadingNotComposedYet =>
      'To osobiste odczytanie jeszcze nie powstało. Słowa klucze są '
      'wbudowane w aplikację i mówią same za siebie.';

  @override
  String get approximateTimeAndPlace =>
      'Godzina i miejsce urodzenia są niepełne. Tymczasowo przyjęto południe i '
      'zerowe współrzędne; Ascendent nie jest wiarygodny.';
  @override
  String get approximateTime =>
      'Godzina urodzenia jest nieznana. Tymczasowo przyjęto południe; Ascendent '
      'nie jest wiarygodny.';
  @override
  String get approximatePlace =>
      'Miejsce urodzenia jest niepełne. Ascendent jest tymczasowy.';

  @override
  String get headingPositionsToday => 'POZYCJE NA DZIŚ';
  @override
  String positionsSummary({
    required String moonPhaseCanonical,
    required String moonSignCanonical,
    required String sunSignCanonical,
  }) =>
      'Księżyc w fazie ${_fazaGen(moonPhaseCanonical)} '
      '${_wZnaku(moonSignCanonical)}, Słońce ${_wZnaku(sunSignCanonical)}.';
  @override
  String get nothingCloseInTheSky =>
      'Nic na niebie nie stoi dziś blisko twojego kosmogramu.';
  // A readout rather than a sentence. Polish would need `natalny` to agree
  // with each body's gender (Mars natalny, Wenus natalna, Słońce natalne),
  // and this is a dense four-row table where a labelled reading is clearer
  // than forced prose anyway.
  @override
  String contactLine({
    required String transiting,
    required String aspect,
    required String natal,
  }) =>
      '$transiting · $aspect · natalny: $natal';
  @override
  String contactOrb({required String degrees, required bool applying}) =>
      '$degrees° ${applying ? applyingWord : separatingWord}';
  @override
  String get readToday => 'Przeczytaj dziś';
  @override
  String get readingToday => 'Czytam';
  @override
  String get todaysReadingNotConnected =>
      'Dzisiejsze odczytanie nie jest jeszcze podłączone w tej wersji. Pozycje '
      'poniżej są wyliczone na tym urządzeniu.';
  @override
  String get todaysReadingCouldNotBeWritten =>
      'Nie udało się zapisać dzisiejszego odczytania. Pozycje poniżej są bez '
      'zmian.';
  @override
  String get enableAiBeforeReadingToday =>
      'Włącz wgląd AI w Zaciszu, zanim przeczytasz dzisiejszy dzień.';

  @override
  String lifePathLabel(int value) => 'Droga życia $value';

  @override
  String positionDetail({
    required String signName,
    required String degrees,
    required bool retrograde,
  }) =>
      '$signName $degrees°${retrograde ? ' $retrogradeWord' : ''}';

  // ----------------------------------------------------------------- journal

  @override
  String get journalHistory => 'Historia';
  @override
  String get openJournalHistorySemantic => 'Otwórz historię dziennika';
  @override
  String get closeHistorySemantic => 'Zamknij historię';
  @override
  String get headingHistory => 'HISTORIA';
  @override
  String get headingTheDaySoFar => 'DZIEŃ DO TEJ PORY';
  @override
  String get writingFieldHint => 'Co domaga się twojej uwagi?';
  @override
  String get nothingWrittenOnThisPage => 'Na tej stronie nic nie zapisano.';
  @override
  String get thisPageIsClosed =>
      'Ta strona jest zamknięta. Pisać można na dzisiejszej.';
  @override
  String get previousJournalDay => 'Poprzedni dzień dziennika';
  @override
  String get nextJournalDay => 'Następny dzień dziennika';
  @override
  String get nextJournalDayUnavailable =>
      'Następny dzień dziennika jest niedostępny';

  @override
  String get listening => 'Słucham…';
  @override
  String get dictate => 'Dyktuj';
  @override
  String get stop => 'Stop';
  @override
  String get dictateSemantic => 'Dyktuj';
  @override
  String get stopDictationSemantic => 'Zatrzymaj dyktowanie';
  @override
  String get dictationNeedsMicrophone =>
      'Eter potrzebuje dostępu do mikrofonu, żeby przyjmować dyktowanie. Możesz '
      'go przyznać w ustawieniach telefonu.';
  @override
  String get dictationNothingHeard =>
      'Nic nie usłyszałem. Dotknij, żeby spróbować ponownie.';
  @override
  String get dictationNeedsConnection =>
      'Na tym telefonie dyktowanie potrzebuje połączenia. Nadal możesz pisać.';
  @override
  String get dictationStopped =>
      'Dyktowanie zatrzymane. Możesz dotknąć i spróbować ponownie albo pisać.';
  @override
  String get dictationNoRecogniser =>
      'Ten telefon nie ma rozpoznawania mowy, z którego Eter mógłby korzystać. '
      'Nadal możesz pisać.';
  @override
  String get dictationUnavailable => 'Dyktowanie jest teraz niedostępne.';
  @override
  String dictationLanguageUnavailable(String languageName) =>
      'Ten telefon nie ma zainstalowanego dyktowania dla języka $languageName. '
      'Możesz je dodać w ustawieniach telefonu albo pisać.';

  @override
  String get keptFromAether => 'Poza zasięgiem Aethera';
  @override
  String get allowAether => 'Udostępnij Aetherowi';
  @override
  String get keepLocal => 'Zatrzymaj lokalnie';
  @override
  String get allowAetherSemantic =>
      'Pozwól, żeby ten wpis trafił do wglądu Aethera';
  @override
  String get keepLocalSemantic =>
      'Zatrzymaj ten wpis poza wglądem Aethera';
  @override
  String get undoInterpretation => 'Cofnij interpretację';
  @override
  String get undoInterpretationSemantic =>
      'Usuń interpretację i zapisy z niej wynikające';
  @override
  String get deleteEntrySemantic =>
      'Usuń ten wpis dziennika i wszystko, co z niego wynikło';
  @override
  String get deleteEntryTitle => 'Usunąć ten wpis?';
  @override
  String get deleteEntryBody =>
      'Strona i wszystko, co z niej wynikło, zostaną usunięte z tego '
      'urządzenia. Tego nie można cofnąć.';
  @override
  String get fieldAddMissingDetail => 'Dopisz brakujący szczegół';
  @override
  String get addMoreDetailFirst => 'Najpierw dopisz trochę więcej szczegółów.';
  @override
  String get journalInterpretationNotConnected =>
      'Interpretacja dziennika nie jest jeszcze podłączona w tej wersji.';
  @override
  String get enableAiBeforeSendingEntry =>
      'Włącz wgląd AI w Zaciszu, zanim wyślesz ten wpis.';
  @override
  String get entryNotInterpretedSafely =>
      'Tego wpisu nie udało się bezpiecznie zinterpretować. Spróbuj ponownie.';
  @override
  String get interpretationUnavailable =>
      'Interpretacja jest teraz niedostępna. Nic się nie zmieniło.';
  @override
  String get interpretationAndDerivedRemoved =>
      'Interpretacja i wynikające z niej zapisy zostały usunięte.';
  @override
  String get tapToRevealImmediately => 'Dotknij, aby od razu odsłonić';

  @override
  String get aetherNeedsOneDetail =>
      'Aether potrzebuje jednego szczegółu, zanim cokolwiek zapisze.';
  @override
  String get entryWasInterpreted => 'Wpis został zinterpretowany.';
  @override
  String get entryWasInterpretedAndLogged =>
      'Wpis został zinterpretowany i zapisany.';
  @override
  String recordedItems(List<String> items) => switch (items.length) {
        1 => 'Zapisano ${items.first}.',
        _ => 'Zapisano ${items.take(items.length - 1).join(', ')} '
            'i ${items.last}.',
      };
  @override
  String get derivedWeight => 'wagę';
  @override
  String get derivedActivity => 'aktywność';
  @override
  String get derivedActivities => 'aktywności';
  @override
  String get derivedWorkout => 'trening';
  @override
  String get derivedFoodAwaitingReview =>
      'jedzenie czekające na sprawdzenie w Ciele';

  // ----------------------------------------------------------------- sanctum

  @override
  String get headingSanctum => 'ZACISZE';
  @override
  String get howEterMeetsYou => 'Jak Eter się z tobą spotyka';
  @override
  String get historyStaysOnThisDevice =>
      'Twoja historia zostaje na tym urządzeniu. Kopia w chmurze jest '
      'wyłączona.';
  @override
  String get cloudContinuityAllowed =>
      'Kopia w chmurze jest włączona. Możesz ją odwołać poniżej.';

  @override
  String get headingOpeningPage => 'STRONA OTWARCIA';
  @override
  String get choiceJournal => 'Dziennik';
  @override
  String get choiceDashboard => 'Wgląd';

  @override
  String get headingGuidanceRegister => 'REJESTR WGLĄDU';
  @override
  String get registerGrounded => 'Ugruntowany';
  @override
  String get registerBalanced => 'Zrównoważony';
  @override
  String get registerImmersive => 'Zanurzony';
  @override
  String get registerGroundedDetail => 'Jasność dnia o każdej godzinie.';
  @override
  String get registerBalancedDetail => 'Zmienia się ze wschodem i zachodem.';
  @override
  String get registerImmersiveDetail => 'Głębszy rejestr nocy.';

  @override
  String get headingLanguage => 'JĘZYK';
  @override
  String get languageDetail =>
      'Zmienia każde słowo, które mówi Eter, razem z tym, co pisze Aether. '
      'Fragmenty, które już powstały, zostają wyczyszczone, żeby nic nie zostało w '
      'języku, który właśnie opuszczasz.';
  @override
  String languageChanged(int clearedPassages) =>
      'Eter mówi teraz po polsku. Wyczyszczono $clearedPassages '
      '${_fragmenty(clearedPassages)} i zostaną napisane od nowa; twoje zapisy '
      'są nietknięte.';

  @override
  String get headingYourData => 'TWOJE DANE';
  @override
  String get permissionsAreIndependent =>
      'Każde pozwolenie jest niezależne i można je odwołać. Odwołanie AI '
      'wyłącza też wgląd czytający dziennik.';

  @override
  String get headingAiGuidance => 'WGLĄD AI';
  @override
  String get aiGuidanceOffDetail =>
      'Żaden kontekst zdrowotny nie opuszcza tego urządzenia na potrzeby AI.';
  @override
  String get aiGuidanceAllowedDetail =>
      'Wybrany kontekst może zostać wysłany, żeby wgląd mógł powstać.';
  @override
  String get headingJournalAwareGuidance => 'WGLĄD CZYTAJĄCY DZIENNIK';
  @override
  String get journalAwareOffDetail =>
      'Treść dziennika nigdy nie jest wysyłana.';
  @override
  String get journalAwareAllowedDetail =>
      'Wysłane mogą zostać tylko wpisy bez oznaczenia „Zatrzymaj lokalnie”.';
  @override
  String get headingCloudContinuity => 'KOPIA W CHMURZE';
  @override
  String get localOnly => 'Tylko lokalnie';
  @override
  String get cloudOffDetail =>
      'Nowe kopie nie powstają. Kopia, która już jest na twoim koncie, zostaje '
      'do momentu usunięcia konta.';
  @override
  String get cloudAllowedDetail =>
      'Kwalifikujące się dokumenty mogą trafiać na twoje konto, gdy '
      'synchronizacja jest połączona.';
  @override
  String get headingJournalInTheMirror => 'DZIENNIK W KOPII';
  @override
  String get staysHere => 'Zostaje tutaj';
  @override
  String get journalMirrorOffDetail =>
      'Twoje strony istnieją tylko na tym urządzeniu i przepadają razem z nim.';
  @override
  String get journalMirrorAllowedDetail =>
      'Strony też są kopiowane i wrócą na nowym telefonie.';
  @override
  String get headingCrashReports => 'RAPORTY AWARII';
  @override
  String get crashReportsOffDetail =>
      'Gdy Eter zawiedzie, nic nie jest wysyłane.';
  @override
  String get crashReportsAllowedDetail =>
      'Gdy Eter zawiedzie, wyślij błąd i model urządzenia. Nigdy twoich '
      'zapisów.';

  @override
  String get headingBirthContext => 'KONTEKST URODZENIA';
  @override
  String birthContextSummary({
    required String place,
    required String time,
    required String utcOffset,
  }) =>
      '$place · $time · UTC$utcOffset';
  @override
  String get locatedPlace => 'Znalezione miejsce';
  @override
  String get birthContextProvisional =>
      'Tymczasowy. Dopisz dokładną godzinę lokalną, jej przesunięcie UTC i '
      'miejsce, żeby kosmogram był pewniejszy.';
  @override
  String get headingHowWellIsTimeKnown => 'JAK DOKŁADNIE ZNASZ GODZINĘ';
  @override
  String get precisionExact => 'Co do minuty';
  @override
  String get precisionApproximate => 'W przybliżeniu';
  @override
  String get precisionUnknown => 'Wcale';
  @override
  String get precisionExactDetail =>
      'Z dokumentu. Ascendent podany wprost.';
  @override
  String get precisionApproximateDetail =>
      'Zapamiętana pora dnia. Kosmogram jest rysowany, a każdy kąt mówi, że '
      'jest tymczasowy.';
  @override
  String get precisionUnknownDetail =>
      'Kosmogram rysowany na południe — i tak też jest opisany.';
  @override
  String get headingWhichPartOfDay => 'KTÓRA PORA DNIA';
  @override
  String get fieldLocalBirthTime => 'Lokalna godzina urodzenia · HH:MM';
  @override
  String get fieldUtcOffsetAtBirth =>
      'Przesunięcie UTC przy urodzeniu · na przykład +01:00';
  @override
  String get fieldBirthCityAndCountry => 'Miasto i kraj urodzenia';
  @override
  String get placeLookupNote =>
      'Wyszukiwanie miejsca korzysta z geokodera urządzenia. Nazwa i '
      'współrzędne są zapisywane lokalnie.';
  @override
  String get offsetSuggestedFromPhone =>
      'Przesunięcie podpowiedziane ze strefy tego telefonu na tamtą datę, razem '
      'z czasem letnim. Popraw je, jeśli miejsce urodzenia było inne.';
  @override
  String get locatingBirthContext => 'Ustalam ten kontekst urodzenia…';
  @override
  String get birthContextSaved =>
      'Kontekst urodzenia zapisany na tym urządzeniu.';

  @override
  String get headingAetherMemory => 'PAMIĘĆ AETHERA';
  @override
  String get onlyStructuredPatternsRetained =>
      'Zachowywane są tylko uporządkowane wzorce. Lokalne współwystępowania nie '
      'są traktowane jako przyczyny.';
  @override
  String get headingWeekInView => 'TYDZIEŃ W SKRÓCIE';
  @override
  String get noWeeklyViewPrepared =>
      'Nie przygotowano jeszcze tygodniowego skrótu.';
  @override
  String get headingLocalPatterns => 'LOKALNE WZORCE';
  @override
  String get noActivePatterns => 'Brak aktywnych wzorców.';

  @override
  String patternReceipt({
    required int confidencePercent,
    required Object? observations,
    required String? window,
    required num? coefficientMinutes,
  }) {
    final parts = <String>['pewność $confidencePercent%'];
    if (observations != null) {
      final count = observations is num ? observations.round() : null;
      parts.add(
        count == null
            ? 'obserwacje: $observations'
            : '$count ${_obserwacje(count)}',
      );
    }
    if (window != null) parts.add(window);
    if (coefficientMinutes != null) {
      final sign = coefficientMinutes > 0 ? '+' : '';
      parts.add('różnica $sign${coefficientMinutes.round()} min');
    }
    return '${parts.join(' · ')} · $correlationNotCause';
  }

  @override
  String get correlationNotCause => 'współwystępowanie, nie przyczyna';
  @override
  String patternSemantic({
    required String summary,
    required String receipt,
  }) =>
      '$summary. $receipt.';
  @override
  String get notEnoughConsistentEvidence =>
      'Jeszcze za mało spójnych lokalnych przesłanek.';
  @override
  String patternsRefreshed({
    required int patterns,
    required int observations,
  }) =>
      'Odświeżono $patterns ${_wzorce(patterns)} na podstawie $observations '
      '${_obserwacjiGen(observations)}.';
  @override
  String get preparingSevenDayView =>
      'Przygotowuję rzeczowy skrót siedmiu dni…';
  @override
  String get notEnoughHistoryForWeekly =>
      'Za mało lokalnej historii na tygodniowy skrót.';
  @override
  String get sevenDayViewPrepared =>
      'Skrót siedmiu dni przygotowany na tym urządzeniu.';
  @override
  String get patternDismissed =>
      'Wzorzec odrzucony. Aether go nie użyje.';
  @override
  String get resetPersonalizationWarning =>
      'To usuwa wgląd, który już powstał, wyuczone wzorce i skróty. Twój '
      'dziennik i historia zdrowia zostają.';
  @override
  String get aetherMemoryAlreadyEmpty => 'Pamięć Aethera była już pusta.';
  @override
  String get aetherMemoryCleared =>
      'Pamięć Aethera wyczyszczona z tego urządzenia.';
  @override
  String retrospectiveSemantic({
    required String headline,
    required String passages,
    required String caveat,
    required String window,
  }) =>
      '$headline. $passages $caveat Okno: $window.';
  @override
  String retrospectiveWindow({required String from, required String to}) =>
      'od $from do $to';

  @override
  String get headingOldPages => 'STARE STRONY';
  @override
  String get oldPagesNote =>
      'Treść dziennika starszą niż rok można wyczyścić, a posiłki, treningi i '
      'wpisy samopoczucia, które z niej powstały, zostają.';
  @override
  String get pruneProseWarning =>
      'To czyści treść stron dziennika starszych niż rok. Posiłki, treningi i '
      'wpisy samopoczucia, które z nich wynikły, zostają.';
  @override
  String get noPagesOlderThanAYear => 'Żadna strona nie jest starsza niż rok.';
  @override
  String clearedPageText(int pages) =>
      'Wyczyszczono treść $pages ${_stron(pages)}.';

  @override
  String get headingWhereYouLive => 'GDZIE MIESZKASZ';
  @override
  String get whereYouLiveNote =>
      'Eter przełącza się o twoim zachodzie słońca. Miejsce urodzenia ustala '
      'kosmogram i nigdy się nie zmienia; to ustala horyzont.';
  @override
  String get whereYouLivePrompt =>
      'Twój zegar nie zgadza się z miejscem urodzenia, więc Eter używa zwykłych '
      'godzin zamiast twojego prawdziwego zachodu słońca. Podaj miasto, w '
      'którym mieszkasz, a znów będzie się przełączał ze słońcem.';
  @override
  String get fieldHomePlace => 'Miasto';
  @override
  String homePlaceSaved(String place) =>
      'Rejestr przełącza się teraz ze słońcem w tym miejscu: $place.';
  @override
  String get homePlaceForgotten =>
      'Zapomniane. Eter znów czyta słońce z twojego miejsca urodzenia, jeśli '
      'może.';
  @override
  String get usingBirthPlaceForNow =>
      'Eter czyta słońce z twojego miejsca urodzenia. Ustaw to, jeśli '
      'mieszkasz gdzie indziej.';

  @override
  String get headingDeleteFromThisDevice => 'USUŃ Z TEGO URZĄDZENIA';
  @override
  String get deleteLocalIntro =>
      'Usuń każdy lokalny zapis Eteru i wróć do wprowadzenia.';
  @override
  String get deleteLocalWarning =>
      'To trwale usuwa lokalny profil, dziennik, historię zdrowia i wyliczone '
      'odczyty. Nic z tego nie da się potem odzyskać.';
  @override
  String get deleteLocalWarningCopyRemains =>
      'To usuwa z tego urządzenia lokalny profil, dziennik, historię zdrowia i '
      'wyliczone odczyty. Kopia na twoim koncie zostaje i „Odtwórz” sprowadzi '
      'ją z powrotem — usuń konto poniżej, żeby usunąć i ją.';

  @override
  String get headingHealthHistory => 'HISTORIA ZDROWIA';
  @override
  String get healthConnectedReconnect =>
      'Połączone. Połącz ponownie, żeby wczytać ostatnie 30 dni; gdy źródła się '
      'nakładają, zostaje jedno na każdą minutę.';
  @override
  String get healthOffer =>
      'Czytaj wybrane sygnały ruchu, snu i regeneracji z zapisu zdrowia w '
      'twoim telefonie.';
  @override
  String get healthOnboardingOffer =>
      'Czytaj ruch, sen i regenerację z zapisu zdrowia w twoim telefonie, żeby '
      'Ciało miało co pokazać od pierwszej chwili.';
  @override
  String get healthUnsupportedPlatform =>
      'Połączenie ze zdrowiem jest dostępne na iPhonie i Androidzie.';
  @override
  String healthRecordsRead(int records) =>
      'Wczytano $records ${_zapisy(records)} zdrowia. Eter zachował jedno '
      'źródło na minutę.';
  @override
  String get healthAccessNotGranted =>
      'Dostęp nie został przyznany. Nie zaimportowano żadnych wartości '
      'zdrowotnych.';
  @override
  String get healthAccessNotGrantedOnboarding =>
      'Dostęp nie został przyznany. Nic nie zaimportowano, a połączyć możesz '
      'się później w Zaciszu.';
  @override
  // "Zapisz zwrotnie" is the precise phrase and overflowed the control by 24 px
  // at 320 dp with 200% text. The note below carries the precision; the button
  // only has to name the action.
  String get writeBack => 'Odeślij';
  @override
  String get writeBackNote =>
      'Wysyła wagi i potwierdzone posiłki do zapisu zdrowia w telefonie. Tylko '
      'to, co wpisujesz tutaj — nigdy nic, co Eter stamtąd odczytał.';
  @override
  String healthWroteBack(int records) =>
      'Zapisano $records ${_zapisy(records)}.';
  @override
  String get healthNothingToWriteBack =>
      'Nie ma nic nowego do zapisania. Wszystkie twoje wpisy już tam są.';
  @override
  String get healthCouldNotWriteBack =>
      'Nie udało się nic zapisać w telefonie. Nic nie zostało zmienione.';
  @override
  String get healthCouldNotBeRead =>
      'Nie udało się odczytać danych zdrowotnych. Dotychczasowa historia jest '
      'bez zmian.';
  @override
  String get healthCouldNotBeReadOnboarding =>
      'Nie udało się odczytać danych zdrowotnych. Możesz spróbować później w '
      'Zaciszu.';

  @override
  String get headingLocalExport => 'EKSPORT LOKALNY';
  @override
  String get localExportNote =>
      'Przygotuj pełny zrzut JSON oraz pliki ruchu i sesji do otwarcia w '
      'arkuszu. Nic nie jest wysyłane.';
  @override
  String get localExportReady =>
      'Pliki JSON i CSV są gotowe na tym urządzeniu. Dane konta w chmurze nie '
      'są w nich zawarte.';
  @override
  String get localExportFailed =>
      'Nie udało się teraz przygotować lokalnego eksportu.';
  @override
  String get exportFolderCopied =>
      'Ścieżka folderu eksportu skopiowana.';

  // ----------------------------------------------------------------- account

  @override
  String get headingAether => 'AETHER';
  @override
  String aetherTrialDaysLeft(int days) => switch (days) {
        1 => 'Został jeden dzień okresu próbnego.',
        _ => 'Zostało $days ${_dni(days)} okresu próbnego.',
      };
  @override
  String get aetherTrialEndsToday =>
      'Twój okres próbny kończy się dzisiaj.';
  @override
  String get aetherTrialExplainsItself =>
      'Trzydzieści dni, bo Aether potrzebuje około trzech tygodni twoich '
      'zapisów, żeby powiedzieć ci o tobie coś, czego jeszcze nie wiesz.';
  @override
  String get aetherLapsed =>
      'Okres próbny się skończył, więc Aether już nie pisze.';
  @override
  String get aetherSubscribed => 'Aether pisze.';
  @override
  String get aetherUnconfigured =>
      'Ta wersja nie ma dokąd wysłać pytania, więc nic w niej nie powstanie. '
      'Nic z tego, co masz, na tym nie traci.';
  @override
  String get aetherRecordKeepsWorking =>
      'Wszystko, co napisane i zapisane, zostaje i działa dalej — dziennik, '
      'historia zdrowia, wykresy, twój kosmogram. Zatrzymuje się samo '
      'powstawanie.';
  @override
  String subscribeMonthly(String price) => 'Subskrybuj · $price miesięcznie';
  @override
  String subscribeYearly(String price) => 'Subskrybuj · $price rocznie';
  @override
  String get launchPriceWillRise =>
      'To cena startowa i wzrośnie. Subskrypcja teraz jej nie zamraża — wolimy '
      'to powiedzieć, niż zaskoczyć cię później. Rok kupiony teraz to rok w tej '
      'cenie.';
  @override
  String get restorePurchases => 'Przywróć zakup';
  @override
  String get billingNotOnThisBuild =>
      'Ta wersja nie może jeszcze przyjąć płatności.';
  @override
  String get headingAccount => 'KONTO';
  @override
  String get buildHasNoAccountSystem =>
      'Ta wersja nie ma systemu kont. Wszystko działa; nic nie jest '
      'archiwizowane.';
  @override
  String get historyNeedsNoAccount =>
      'Twoja historia jest na tym urządzeniu i nie potrzebuje konta. Zaloguj '
      'się tylko wtedy, gdy chcesz ją odzyskać po zmianie telefonu.';
  @override
  String get fieldEmail => 'E-mail';
  @override
  String get fieldPassword => 'Hasło';
  @override
  String get fieldNewPassword => 'Nowe hasło';
  @override
  String passwordMinimum(int characters) =>
      'Co najmniej $characters ${_znaki(characters)}. Fraza, którą zapamiętasz, '
      'jest lepsza niż krótka plątanina, której nie zapamiętasz.';
  @override
  String get createAccount => 'Utwórz konto';
  @override
  String get signIn => 'Zaloguj się';
  @override
  String get iHaveAnAccount => 'Mam już konto';
  @override
  String get createOne => 'Utwórz konto';
  @override
  String get continueWithGoogle => 'Kontynuuj z Google';
  @override
  String get forgottenPassword => 'Nie pamiętam hasła';
  @override
  String get resetLinkOnItsWay =>
      'Jeśli ten adres ma konto, link do zmiany hasła jest już w drodze.';
  @override
  String confirmationLinkSent(String email) =>
      'Sprawdź $email — jest tam link potwierdzający. Twoja historia zostaje '
      'tutaj, dopóki go nie otworzysz.';
  @override
  String get signedIn => 'Zalogowano';
  @override
  String get historyCanBeRestored =>
      'Twoją historię można odtworzyć na nowym telefonie.';
  @override
  String get confirmEmailToEnable =>
      'Potwierdź e-mail, żeby to włączyć. Do tego czasu nic nie opuszcza tego '
      'urządzenia.';
  @override
  String get resendLink => 'Wyślij link ponownie';
  @override
  String get iHaveConfirmed => 'Już potwierdzone';
  @override
  String get verificationSent =>
      'Wysłano. Może minąć chwila, zanim dotrze.';
  @override
  String get notConfirmedYet =>
      'Jeszcze nie potwierdzone. Otwórz link z wiadomości i spróbuj ponownie.';
  @override
  String get syncNow => 'Synchronizuj';
  @override
  String get restore => 'Odtwórz';
  @override
  String get restoreOnlyFillsEmptyDevice =>
      'Odtwarzanie zapełnia tylko urządzenie bez własnej historii — nigdy nie '
      'nadpisze tego, co już tu jest.';
  @override
  String get signOut => 'Wyloguj się';
  @override
  String get signedOutNothingRemoved =>
      'Wylogowano. Wszystko na tym urządzeniu nadal tu jest.';

  @override
  String get headingDeleteAccount => 'USUŃ KONTO';
  @override
  String get deleteAccount => 'USUŃ KONTO';
  @override
  String get deleteAccountIntro =>
      'Usuń konto i kopię twojego zapisu, którą pod nim trzyma.';
  @override
  String get deleteAccountWarning =>
      'To usuwa kopię na koncie, a potem samo konto. Wszystko na tym urządzeniu '
      'zostaje i działa dalej — usunięcie konta to wycofanie się z kopii, a nie '
      'prośba, żeby Eter o tobie zapomniał.';
  @override
  String get accountDeletedRecordKept =>
      'Konto usunięte razem z kopią. Twój zapis nadal jest na tym urządzeniu.';
  @override
  String get somethingWentWrong =>
      'Coś poszło nie tak. Nic nie zostało zmienione.';

  @override
  String get syncNotAvailableOnBuild =>
      'Synchronizacja nie jest dostępna w tej wersji.';
  @override
  String get everythingAlreadyCopied => 'Wszystko było już skopiowane.';
  @override
  String copiedRecords(int records) =>
      'Skopiowano $records ${_zapisy(records)}.';
  @override
  String get journalStayedOnThisDevice =>
      'Twój dziennik został na tym urządzeniu.';
  @override
  String get nothingInAccountToRestore =>
      'Na twoim koncie nie było nic do odtworzenia.';
  @override
  String restoredRecords(int records) =>
      'Odtworzono $records ${_zapisy(records)}.';
  @override
  String syncRefusal(SyncRefusal refusal) => switch (refusal) {
        SyncRefusal.nothingToSync =>
          'Nie ma jeszcze nic do synchronizacji.',
        SyncRefusal.confirmEmailBeforeCopying =>
          'Potwierdź e-mail, zanim cokolwiek zostanie skopiowane.',
        SyncRefusal.cloudContinuityOff =>
          'Kopia w chmurze jest wyłączona.',
        SyncRefusal.confirmEmailFirst => 'Najpierw potwierdź e-mail.',
        SyncRefusal.deviceAlreadyHasHistory =>
          'To urządzenie ma już historię, więc nic nie zostało odtworzone.',
      };

  @override
  String accountFailure(AccountFailure failure) => switch (failure) {
        AccountFailure.invalidEmail => 'To nie wygląda na adres e-mail.',
        AccountFailure.weakPassword =>
          'Wybierz hasło o długości co najmniej ośmiu znaków.',
        AccountFailure.emailInUse =>
          'Ten adres jest już zarejestrowany. Zaloguj się albo zmień hasło.',
        // Identyczne celowo — patrz opis `accountFailure`.
        AccountFailure.wrongPassword ||
        AccountFailure.noSuchAccount =>
          'Ten e-mail i hasło do siebie nie pasują.',
        AccountFailure.cancelled => 'Logowanie zostało anulowane.',
        AccountFailure.network =>
          'Brak połączenia. Eter działa bez sieci; synchronizacja poczeka.',
        AccountFailure.tooManyAttempts =>
          'Za dużo prób. Spróbuj ponownie za kilka minut.',
        AccountFailure.notVerified =>
          'Najpierw potwierdź e-mail — poszukaj linku, który wysłaliśmy.',
        AccountFailure.requiresRecentLogin =>
          'Zaloguj się ponownie, a potem poproś jeszcze raz. Nic nie zostało '
              'usunięte.',
        AccountFailure.unknown =>
          'Logowanie się nie udało. Nic nie zostało zmienione.',
      };

  // -------------------------------------------------------------- onboarding

  @override
  String onboardingStepSemantic({required int step, required int total}) =>
      'Krok wprowadzenia $step z $total';
  @override
  String onboardingStepMark({required int step, required int total}) =>
      '$step / $total';
  @override
  String get continueLabel => 'Dalej';
  @override
  String get enterEter => 'Wejdź do Eteru';

  @override
  String get welcomeTitle => 'Zacznij od tego, co ważne';
  @override
  String get welcomeIntro =>
      'Kilka słów wystarczy. Każdą z tych rzeczy możesz później zmienić albo '
      'usunąć.';
  @override
  String get fieldWhatShouldEterCallYou => 'Jak Eter ma cię nazywać?';
  @override
  String get fieldWhatWouldYouLikeMoreOf => 'Czego chcesz więcej?';
  @override
  String get hintWhatWouldYouLikeMoreOf =>
      'Spokojniejszej energii, głębszego snu, jaśniejszej głowy…';

  @override
  String get birthStepTitle => 'Twój punkt wyjścia';
  @override
  String get birthStepIntro =>
      'Data zasila kontekst zdrowotny i wyliczenia symboliczne. Miejsce i '
      'dokładna godzina są opcjonalne; bez nich Eter oznacza kosmogram jako '
      'tymczasowy.';
  @override
  String get fieldBirthDate => 'Data urodzenia';
  @override
  String get hintBirthDateFormat => 'RRRR-MM-DD';
  @override
  String get fieldCurrentWeightKg => 'Obecna waga w kilogramach';
  @override
  String get fieldCurrentHeightCm => 'Obecny wzrost w centymetrach';
  @override
  String get headingBodyContext => 'KONTEKST CIAŁA';
  @override
  String get sexFemale => 'Kobieta';
  @override
  String get sexMale => 'Mężczyzna';
  @override
  String get sexOther => 'Inaczej / wolę nie mówić';
  @override
  String get fieldBirthPlaceOptional => 'Miejsce urodzenia — opcjonalnie';
  @override
  String get hintCityOrRegion => 'Miasto lub region';
  @override
  String get exactBirthTimeLater =>
      'Dokładną godzinę urodzenia można dopisać później w Zaciszu.';
  @override
  String get errorEnterValidBirthDate =>
      'Podaj prawidłową datę urodzenia w formacie RRRR-MM-DD.';
  @override
  String get errorMinimumAge =>
      'Eter jest na razie dostępny dla osób od 16. roku życia.';
  @override
  String get errorEnterWeightRange =>
      'Podaj obecną wagę pomiędzy 20 a 500 kg.';
  @override
  String get errorEnterHeightRange =>
      'Podaj obecny wzrost pomiędzy 100 a 250 cm.';

  @override
  String get registerStepTitle => 'Jak Eter ma mówić';
  @override
  String get registerStepIntro =>
      'To ustawia głos, nie fakty. Możesz to zmienić w każdej chwili w '
      'Zaciszu.';
  @override
  String get registerGroundedOnboardingDetail =>
      'Jasność dnia o każdej godzinie. Prosto, praktycznie, bez ozdób.';
  @override
  String get registerBalancedOnboardingDetail =>
      'Zmienia się ze wschodem i zachodem słońca, tak jak dzień.';
  @override
  String get registerImmersiveOnboardingDetail =>
      'Głębszy rejestr nocy, symboliczny i niespieszny.';

  @override
  String get languageStepTitle => 'W jakim języku ma mówić Eter?';
  @override
  String get languageStepIntro =>
      'Na początek ustawiony według twojego telefonu. Zmienia każde słowo, '
      'razem z tym, co pisze Aether, i możesz go zmienić w każdej chwili w '
      'Zaciszu.';

  @override
  String get consentStepTitle => 'Wybierz, co może opuścić to urządzenie';
  @override
  String get consentStepIntro =>
      'Wszystko to jest opcjonalne. Prowadzenie dziennika i lokalne wyliczenia '
      'działają nawet wtedy, gdy odmówisz.';
  @override
  String get consentAiTitle => 'Wgląd AI';
  @override
  String get consentAiDetail =>
      'Wysyłaj wybrany kontekst zdrowotny, żeby wgląd mógł powstać.';
  @override
  String get consentJournalAiTitle => 'Wgląd czytający dziennik';
  @override
  String get consentJournalAiDetail =>
      'Pozwól wysyłać dołączoną treść dziennika, żeby Aether mógł ją '
      'przemyśleć.';
  @override
  String get consentCloudTitle => 'Kopia w chmurze';
  @override
  String get consentCloudDetail =>
      'Trzymaj zaszyfrowaną kopię na koncie, na przyszły telefon.';
  @override
  String get allowMark => 'POZWÓL';
  @override
  String get offMark => 'WYŁ.';
  @override
  String consentSemantic({required String title, required bool allowed}) =>
      '$title, ${allowed ? 'dozwolone' : 'wyłączone'}';
  @override
  String get healthHistoryTitle => 'Historia zdrowia';

  // ---------------------------------------------------------------- tutorial

  @override
  List<TutorialPassage> get tutorialPassages => const [
        TutorialPassage(
          eyebrow: 'ETER',
          lines: [
            'Eter czyta twoje dni i mówi ci, co zauważa.',
            'Wszystko trzyma na tym urządzeniu, dopóki nie powiesz inaczej, i '
                'nigdy cię nie ocenia.',
          ],
        ),
        TutorialPassage(
          eyebrow: 'DZIENNIK',
          lines: [
            'Wszystko, co zapisujesz, piszesz albo mówisz tutaj.',
            'Nigdzie indziej nie ma formularzy: posiłki, ruch i to, jak minął '
                'dzień, biorą się z tego, co piszesz. Każdą '
                'stronę można zinterpretować, a każdą można też całkowicie '
                'zatrzymać poza zasięgiem Aethera.',
          ],
        ),
        TutorialPassage(
          eyebrow: 'WGLĄD',
          lines: [
            'Druga strona tej samej przestrzeni odczytuje to, co znalazła.',
            'Wgląd przychodzi sam każdego dnia. Otwórz głębię po ciało '
                'albo po Krąg — twój kosmogram, twoją Drogę życia i to, '
                'jak dzisiejsze niebo stoi wobec nich.',
          ],
        ),
        TutorialPassage(
          showsSanctumMark: true,
          eyebrow: 'ZACISZE',
          lines: [
            'Ten znak, na górze każdego ekranu, je otwiera.',
            'Ustawienia, twoje dane urodzenia, połączenie ze zdrowiem i każde '
                'pozwolenie — każde niezależne, każde odwołalne, i sposób, żeby '
                'zabrać to wszystko z powrotem.',
          ],
        ),
      ];

  // ---------------------------------------------------------------- body fat

  @override
  String get fieldBodyFatOptional => 'Tkanka tłuszczowa — opcjonalnie';
  @override
  String get bodyFatNotGiven => 'Nie podano';
  @override
  String get bodyFatSemanticNotGiven =>
      'Tkanka tłuszczowa, opcjonalna, nie podano';
  @override
  String bodyFatSemantic(String formatted) => 'Tkanka tłuszczowa $formatted';
  @override
  String get bodyFatNote =>
      'Tylko jeśli ją znasz. Eter nigdy jej nie szacuje z twojej wagi i pomija '
      'ją w każdym wyliczeniu, gdy jej nie ma.';

  @override
  String bodyRecordError(BodyRecordError error) => switch (error) {
        BodyRecordError.activityName =>
          'Nazwij aktywność w 1–80 znakach.',
        BodyRecordError.activityDuration =>
          'Podaj czas trwania pomiędzy 1 a 1440 minut.',
        BodyRecordError.activityEnergy =>
          'Podaj energię aktywności pomiędzy 1 a 10 000 kcal.',
        BodyRecordError.weightRange =>
          'Waga musi być pomiędzy 20 a 500 kg.',
        BodyRecordError.strengthNeedsExercise =>
          'Dodaj jedno ćwiczenie z przynajmniej jedną serią.',
        BodyRecordError.strengthReps =>
          'Każda seria mieści od 1 do 500 powtórzeń.',
        BodyRecordError.strengthLoad =>
          'Obciążenie musi być pomiędzy 0 a 1000 kg.',
        BodyRecordError.strengthNeedsBodyWeight =>
          'Najpierw zapisz masę ciała; energia treningu siłowego jest z niej '
              'wyliczana.',
      };

  // ---------------------------------------------------- birth context errors

  @override
  String birthContextError(BirthContextError error) => switch (error) {
        BirthContextError.placeNotLocated =>
          'Nie udało się znaleźć tego miejsca. Spróbuj podać miasto i kraj.',
        BirthContextError.profileUnavailable =>
          'Lokalny profil jest niedostępny.',
        BirthContextError.choosePartOfDay =>
          'Wybierz porę dnia twoich narodzin.',
        BirthContextError.addUtcOffset =>
          'Dopisz przesunięcie UTC przy urodzeniu, żeby dało się umieścić '
              'godzinę.',
        BirthContextError.placeNotLocatedNow =>
          'Nie udało się teraz znaleźć tego miejsca. Nic się nie zmieniło.',
        BirthContextError.timeFormat =>
          'Podaj godzinę urodzenia jako HH:MM albo zostaw pole puste.',
        BirthContextError.utcOffsetFormat =>
          'Podaj przesunięcie UTC miejsca urodzenia w postaci +01:00.',
        BirthContextError.utcOffsetRange =>
          'Przesunięcie UTC musi być pomiędzy −14:00 a +14:00.',
      };

  // ----------------------------------------------------- symbolic vocabulary

  @override
  String elementName(Element element) => switch (element) {
        Element.air => 'Powietrze',
        Element.fire => 'Ogień',
        Element.water => 'Woda',
        Element.earth => 'Ziemia',
      };
  @override
  String elementMedallionSemantic(Element element) =>
      'Żywioł: ${elementName(element)}';

  @override
  String signName(String canonical) => switch (canonical) {
        'Aries' => 'Baran',
        'Taurus' => 'Byk',
        'Gemini' => 'Bliźnięta',
        'Cancer' => 'Rak',
        'Leo' => 'Lew',
        'Virgo' => 'Panna',
        'Libra' => 'Waga',
        'Scorpio' => 'Skorpion',
        'Sagittarius' => 'Strzelec',
        'Capricorn' => 'Koziorożec',
        'Aquarius' => 'Wodnik',
        'Pisces' => 'Ryby',
        _ => canonical,
      };

  /// The locative, for "the Moon in …". Polish cannot build this from
  /// [signName] — `Ryby` becomes `Rybach`, `Bliźnięta` becomes `Bliźniętach` —
  /// so the twelve forms are written out.
  String _wZnaku(String canonical) => switch (canonical) {
        'Aries' => 'w Baranie',
        'Taurus' => 'w Byku',
        'Gemini' => 'w Bliźniętach',
        'Cancer' => 'w Raku',
        'Leo' => 'w Lwie',
        'Virgo' => 'w Pannie',
        'Libra' => 'w Wadze',
        'Scorpio' => 'w Skorpionie',
        'Sagittarius' => 'w Strzelcu',
        'Capricorn' => 'w Koziorożcu',
        'Aquarius' => 'w Wodniku',
        'Pisces' => 'w Rybach',
        _ => 'w znaku ${signName(canonical)}',
      };

  /// The genitive, for "in the phase of …".
  String _fazaGen(String canonical) => switch (canonical) {
        'new' => 'nowiu',
        'waxing crescent' => 'rosnącego sierpa',
        'first quarter' => 'pierwszej kwadry',
        'waxing gibbous' => 'rosnącego garbu',
        'full' => 'pełni',
        'waning gibbous' => 'ubywającego garbu',
        'last quarter' => 'ostatniej kwadry',
        'waning crescent' => 'ubywającego sierpa',
        _ => moonPhaseName(canonical),
      };

  @override
  String bodyName(String canonical) => switch (canonical) {
        'Sun' => 'Słońce',
        'Moon' => 'Księżyc',
        'Mercury' => 'Merkury',
        'Venus' => 'Wenus',
        'Mars' => 'Mars',
        'Jupiter' => 'Jowisz',
        'Saturn' => 'Saturn',
        'Uranus' => 'Uran',
        'Neptune' => 'Neptun',
        'Pluto' => 'Pluton',
        'Ascendant' => 'Ascendent',
        'Midheaven' => 'Medium Coeli',
        _ => canonical,
      };

  @override
  String aspectName(String canonical) => switch (canonical) {
        'conjunction' => 'koniunkcja',
        'sextile' => 'sekstyl',
        'square' => 'kwadratura',
        'trine' => 'trygon',
        'opposition' => 'opozycja',
        _ => canonical,
      };

  @override
  String moonPhaseName(String canonical) => switch (canonical) {
        'new' => 'nów',
        'waxing crescent' => 'rosnący sierp',
        'first quarter' => 'pierwsza kwadra',
        'waxing gibbous' => 'rosnący garb',
        'full' => 'pełnia',
        'waning gibbous' => 'ubywający garb',
        'last quarter' => 'ostatnia kwadra',
        'waning crescent' => 'ubywający sierp',
        _ => canonical,
      };

  @override
  String arcanaTitle(String slug) => switch (slug) {
        'the-fool' => 'Głupiec',
        'the-magician' => 'Mag',
        'the-high-priestess' => 'Kapłanka',
        'the-empress' => 'Cesarzowa',
        'the-emperor' => 'Cesarz',
        'the-hierophant' => 'Kapłan',
        'the-lovers' => 'Kochankowie',
        'the-chariot' => 'Rydwan',
        'strength' => 'Siła',
        'the-hermit' => 'Pustelnik',
        'wheel-of-fortune' => 'Koło Fortuny',
        'justice' => 'Sprawiedliwość',
        'the-hanged-man' => 'Wisielec',
        'death' => 'Śmierć',
        'temperance' => 'Umiarkowanie',
        'the-devil' => 'Diabeł',
        'the-tower' => 'Wieża',
        'the-star' => 'Gwiazda',
        'the-moon' => 'Księżyc',
        'the-sun' => 'Słońce',
        'judgement' => 'Sąd Ostateczny',
        'the-world' => 'Świat',
        _ => slug,
      };

  @override
  String matrixPositionLabel(MatrixPosition position) => switch (position) {
        // Not `Dane`, which is the word the Sanctum uses for *data*.
        MatrixPosition.given => 'Zastane',
        MatrixPosition.inherited => 'Odziedziczone',
        MatrixPosition.era => 'Epoka',
        MatrixPosition.turning => 'Zwrot',
        MatrixPosition.meeting => 'Spotkanie',
        MatrixPosition.longThread => 'Długa nić',
        MatrixPosition.centre => 'Środek',
      };

  @override
  String matrixPositionDetail(MatrixPosition position) => switch (position) {
        MatrixPosition.given =>
          'Sam dzień — konkretny fakt przyjścia na świat.',
        MatrixPosition.inherited =>
          'Miesiąc — pora roku, którą życie dostaje, zanim cokolwiek wybierze.',
        MatrixPosition.era =>
          'Rok — pogoda czasu, nie człowieka.',
        MatrixPosition.turning =>
          'Gdzie ten rok stał we własnym cyklu, gdy zaczynał się człowiek.',
        MatrixPosition.meeting =>
          'Dzień i miesiąc razem — to, co konkretne, spotyka swoją porę roku.',
        MatrixPosition.longThread =>
          'Dzień i rok razem — ta część, która biegnie przez całą długość.',
        MatrixPosition.centre =>
          'Wszystko zsumowane. Ta sama karta, do której dochodzi Droga życia, '
              'osiągnięta z drugiej strony.',
      };

  @override
  String birthPeriodLabel(BirthTimePeriod period) => switch (period) {
        BirthTimePeriod.smallHours => 'Głucha noc',
        BirthTimePeriod.earlyMorning => 'Wczesny ranek',
        BirthTimePeriod.morning => 'Rano',
        BirthTimePeriod.afternoon => 'Popołudnie',
        BirthTimePeriod.evening => 'Wieczór',
        BirthTimePeriod.night => 'Noc',
      };

  @override
  String birthPeriodDetail(BirthTimePeriod period) => switch (period) {
        BirthTimePeriod.smallHours => 'Około 1–4 w nocy',
        BirthTimePeriod.earlyMorning => 'Około 4–7 rano',
        BirthTimePeriod.morning => 'Około 7 rano – południe',
        BirthTimePeriod.afternoon => 'Około południa – 17',
        BirthTimePeriod.evening => 'Około 17–21',
        BirthTimePeriod.night => 'Około 21–1',
      };

  @override
  String get applyingWord => 'zbliża się';
  @override
  String get separatingWord => 'rozchodzi się';
  @override
  String get retrogradeWord => 'retrogradacja';

  // ------------------------------- locally composed prose (never the model)

  @override
  String patternSleepAfterLateActivity({required bool shorter}) =>
      'Po późnej aktywności sen bywał ${shorter ? 'krótszy' : 'dłuższy'}.';

  // Every name here is a noun phrase in the nominative, never a clause. The
  // sweep sentence puts one of these in front of an adjective, and English can
  // write "when how long you slept is higher" where Polish cannot: the phrase
  // has to be something that can *be* higher, and it has to have a gender for
  // the adjective to agree with. See `_seriesRodzaj`.
  @override
  String seriesLabel(String canonical) => switch (canonical) {
        'steps' => 'twoja liczba kroków',
        'activeKcal' => 'twoja aktywność',
        'sleep' => 'długość twojego snu',
        'deep' => 'sen głęboki',
        'rem' => 'sen REM',
        'awake' => 'czas czuwania w nocy',
        'restingHr' => 'twój puls spoczynkowy',
        'hrv' => 'twoja zmienność rytmu serca',
        'intake' => 'ilość jedzenia',
        'sessions' => 'liczba sesji treningowych',
        'mood' => 'twój nastrój',
        'stress' => 'twój stres',
        'recovery' => 'twoja regeneracja',
        'meditation' => 'czas medytacji',
        'weight' => 'twoja waga',
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
    final higher = _stopien(_seriesRodzaj(fromKey), higher: true);
    final direction = _stopien(_seriesRodzaj(toKey), higher: positive);
    final receipt = 'około $percent% zmienności, na przestrzeni $days '
        '${_dniGen(days)}';
    return lagged
        ? 'W dniach po tym, gdy $from jest $higher, $to bywa $direction '
            '($receipt).'
        : 'Kiedy $from jest $higher, $to bywa $direction tego samego dnia '
            '($receipt).';
  }

  @override
  String retrospectiveHeadline({required bool complete}) =>
      complete ? 'Twoje siedem dni' : 'Twoje niepełne siedem dni';
  @override
  String retrospectiveMovement({
    required int days,
    required int averageActiveKcal,
    int? averageSteps,
    int? stepDays,
  }) {
    final sentence = StringBuffer(
      'Ruch zapisano w $days z 7 dni, średnio $averageActiveKcal kcal '
      'aktywności w zapisanych dniach',
    );
    if (averageSteps != null && stepDays != null) {
      sentence.write(
        ' oraz $averageSteps kroków w $stepDays zmierzonych '
        '${_dniGen(stepDays)}',
      );
    }
    return '$sentence.';
  }
  @override
  String retrospectiveSleep({
    required int nights,
    required String averageHours,
  }) =>
      'Sen zapisano w $nights z 7 nocy, średnio $averageHours godz.';
  @override
  String retrospectiveJournal(int entries) =>
      'W tym okresie zapisano w dzienniku $entries ${_wpisy(entries)}.';
  @override
  String retrospectiveLifestyle({
    required int signals,
    required List<String> kinds,
  }) =>
      'Zapisano $signals ${_zgloszoneSygnaly(signals)} w kategoriach: '
      '${kinds.map(lifestyleKindName).join(', ')}.';
  @override
  String get retrospectiveCaveat =>
      'Brakujące dni są pomijane, a nie traktowane jako zero.';

  @override
  String lifestyleKindName(String canonical) => switch (canonical) {
        'mood' => 'nastrój',
        'stress' => 'stres',
        'recovery' => 'regeneracja',
        'meditation' => 'medytacja',
        'breathwork' => 'praca z oddechem',
        _ => canonical,
      };

  // ------------------------------------------------------------- the long view

  @override
  String get headingLongView => 'Z ODDALI';
  @override
  String get headingLetter => 'LIST';
  @override
  String letterMonth(String month) => 'O miesiącu: $month';
  @override
  String get headingLocalImport => 'PRZYWRÓĆ ZAPIS';
  @override
  String get localImportNote =>
      'Wczytaj eksport Eteru z powrotem na to urządzenie. Tylko na urządzenie '
      'bez własnej historii — nic tutaj nie zostanie nadpisane.';
  @override
  String get importRecord => 'Wybierz plik';
  @override
  String localImportRestored(int records) =>
      'Przywrócono $records ${_zapisy(records)}.';
  @override
  String localImportPartly(int records) =>
      'Przywrócono $records ${_zapisy(records)}. Część tego pliku napisał '
      'nowszy Eter i nie dało się jej odczytać.';
  @override
  String get localImportNotAnExport => 'To nie jest eksport Eteru.';
  @override
  String get localImportNewerVersion =>
      'Ten eksport pochodzi z nowszego Eteru. Najpierw zaktualizuj ten.';
  @override
  String get localImportDeviceHasHistory =>
      'To urządzenie ma już historię, więc nic nie zostało przywrócone.';
  @override
  String get localImportFailed =>
      'Nie udało się odczytać tego pliku. Nic nie zostało zmienione.';
  @override
  String get headingEveningInvitation => 'WIECZORNE ZAPROSZENIE';
  @override
  String get eveningInvitationOffDetail =>
      'Eter nigdy nie odzywa się pierwszy. Nic nie przyjdzie, dopóki go nie '
      'otworzysz.';
  @override
  String get eveningInvitationAllowedDetail =>
      'Jedno ciche zaproszenie do pisania, o twoim zachodzie słońca. Nie w '
      'dniu, w którym już piszesz, i nic poza tym — żadnych poranków, serii '
      'ani przypomnień, żeby wrócić.';
  @override
  String get eveningInvitationNotPermitted =>
      'Telefon nie zgodził się na powiadomienia, więc nic nie zostało '
      'włączone. Możesz je włączyć w ustawieniach telefonu.';
  @override
  String get invitationTitle => 'Wieczór';
  @override
  String get invitationBody => 'Strona, jeśli masz ochotę.';
  @override
  String get longViewNote =>
      'Cofaj się w historii dziennika, a dzień się poszerzy — do tygodnia, '
      'miesiąca, roku. Wszystko liczy się na tym urządzeniu, więc działa bez '
      'sieci i nic nie kosztuje.';
  @override
  String longViewSpanName(LongViewSpanName span) => switch (span) {
        LongViewSpanName.week => 'Tydzień',
        LongViewSpanName.month => 'Miesiąc',
        LongViewSpanName.year => 'Rok',
      };
  // "Zapisane: 4 z 7" rather than a counted noun. The cells are days in one
  // span and months in another, and a fraction does not have to name them.
  @override
  String longViewRecorded({required int recorded, required int total}) =>
      'Zapisane: $recorded z $total.';
  @override
  String get longViewNothingRecorded => 'W tym czasie nic nie zapisano.';
  @override
  String longViewMeasure(LongViewMeasure measure) => switch (measure) {
        LongViewMeasure.sleep => 'Sen',
        LongViewMeasure.mood => 'Nastrój',
        LongViewMeasure.steps => 'Kroki',
        LongViewMeasure.pages => 'Napisane strony',
      };
  @override
  String longViewSeriesSemantic({
    required String measure,
    required String cells,
    required int absent,
  }) =>
      absent == 0
          ? '$measure. $cells.'
          : '$measure. $cells. Nie zapisano: $absent.';
  @override
  String longViewCellSemantic({required String label, required String value}) =>
      '$label $value';
  @override
  String longViewCellAbsent(String label) => '$label — nie zapisano';

  // ------------------------------------------------------------------ plural
  //
  // Polish has three plural forms, not two: one for 1, one for 2–4, and one for
  // 5+ — with the ordinary trap that 12–14 and every teen take the many form
  // while 22–24 take the few form. `intl`'s plural rules would give the right
  // *category*, but the noun still has to be written out per case, so the forms
  // are tabulated here and the rule is applied once.

  /// `few` for 2–4 (excluding the teens), `many` otherwise. [one] is only used
  /// for exactly 1.
  static String _plural(
    int count, {
    required String one,
    required String few,
    required String many,
  }) {
    if (count == 1) return one;
    final lastTwo = count.abs() % 100;
    final last = count.abs() % 10;
    if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) return few;
    return many;
  }

  /// The gender of the noun [seriesLabel] returns — `'ż'`, `'n'` or masculine
  /// by default. Only needed because an adjective follows it.
  static String _seriesRodzaj(String canonical) => switch (canonical) {
        'steps' ||
        'activeKcal' ||
        'sleep' ||
        'hrv' ||
        'intake' ||
        'sessions' ||
        'recovery' ||
        'weight' =>
          'ż',
        _ => 'm',
      };

  /// *wyższy / wyższa / wyższe*, and the same for *niższy*.
  static String _stopien(String rodzaj, {required bool higher}) {
    final stem = higher ? 'wyższ' : 'niższ';
    return switch (rodzaj) {
      'ż' => '${stem}a',
      'n' => '${stem}e',
      _ => '${stem}y',
    };
  }

  static String _dni(int n) => _plural(n, one: 'dzień', few: 'dni', many: 'dni');
  static String _dniGen(int n) =>
      _plural(n, one: 'dnia', few: 'dni', many: 'dni');
  static String _nocy(int n) =>
      _plural(n, one: 'nocy', few: 'nocy', many: 'nocy');
  static String _minuty(int n) =>
      _plural(n, one: 'minuta', few: 'minuty', many: 'minut');
  static String _odczyty(int n) =>
      _plural(n, one: 'odczyt', few: 'odczyty', many: 'odczytów');
  static String _zapisy(int n) =>
      _plural(n, one: 'zapis', few: 'zapisy', many: 'zapisów');
  static String _stron(int n) =>
      _plural(n, one: 'strony', few: 'stron', many: 'stron');
  static String _wpisy(int n) =>
      _plural(n, one: 'wpis', few: 'wpisy', many: 'wpisów');
  /// The adjective is tabulated with the noun on purpose: it agrees with the
  /// case the numeral forces, so `5 samodzielnie zgłoszonych sygnałów` and
  /// `2 samodzielnie zgłoszone sygnały` differ in both words, not one.
  static String _zgloszoneSygnaly(int n) => _plural(
        n,
        one: 'samodzielnie zgłoszony sygnał',
        few: 'samodzielnie zgłoszone sygnały',
        many: 'samodzielnie zgłoszonych sygnałów',
      );
  static String _wzorce(int n) =>
      _plural(n, one: 'wzorzec', few: 'wzorce', many: 'wzorców');
  static String _obserwacje(int n) =>
      _plural(n, one: 'obserwacja', few: 'obserwacje', many: 'obserwacji');
  static String _obserwacjiGen(int n) =>
      _plural(n, one: 'obserwacji', few: 'obserwacji', many: 'obserwacji');
  static String _znaki(int n) =>
      _plural(n, one: 'znak', few: 'znaki', many: 'znaków');
  static String _fragmenty(int n) => _plural(
        n,
        one: 'fragment',
        few: 'fragmenty',
        many: 'fragmentów',
      );
}
