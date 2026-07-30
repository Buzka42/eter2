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
/// * **Wskazania** — *guidance*. Chosen over `prowadzenie` because the whole
///   visual language of this app is engraved instruments, and `wskazania` is
///   what an instrument gives you: a reading, not advice.
/// * **Naczynie** — *the Vessel*. **Sanktuarium** — *the Sanctum*.
///   **Dziennik** — *the Journal*. **Pulpit** — *the Dashboard*.
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
  String get reset => 'Zeruj';
  @override
  String get composing => 'Komponuję';
  @override
  String get off => 'Wyłączone';
  @override
  String get allowed => 'Dozwolone';

  // --------------------------------------------------------------- the shell

  @override
  String get destinationJournal => 'DZIENNIK';
  @override
  String get destinationDashboard => 'PULPIT';
  @override
  String get sanctum => 'Sanktuarium';
  @override
  String get openSanctumSemantic => 'Otwórz Sanktuarium';

  // ----------------------------------------------------------- the dashboard

  @override
  String get guidanceNotComposedYet =>
      'Dzisiejsze wskazania nie zostały jeszcze skomponowane.';
  @override
  String get composingTodaysGuidance => 'Komponuję dzisiejsze wskazania…';
  @override
  String get composeNow => 'Skomponuj teraz';
  @override
  String get guidanceComposed => 'Dzisiejsze wskazania są gotowe.';
  @override
  String get guidanceAlreadyCurrent =>
      'Wskazania są już aktualne dla tego, co Eter wie o dzisiejszym dniu.';
  @override
  String get aetherNotConnected =>
      'Kompozycja Aether nie jest jeszcze podłączona w tej wersji.';
  @override
  String get enableAiBeforeComposing =>
      'Włącz wskazania AI w Sanktuarium, zanim zaczniesz komponować.';
  @override
  String get responseNotAcceptedSafely =>
      'Odpowiedzi nie można było bezpiecznie przyjąć. Nic się nie zmieniło.';
  @override
  String get compositionUnavailable =>
      'Kompozycja jest teraz niedostępna. Dotychczasowe wskazania zostają.';

  @override
  String get lookDeeper => 'ZAJRZYJ GŁĘBIEJ';
  @override
  String get sectionGuidance => 'WSKAZANIA';
  @override
  String get sectionBody => 'CIAŁO';
  @override
  String get sectionVessel => 'NACZYNIE';

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
      'Poniżej czeka jedno oszacowanie jedzenia. Nie wchodzi do wagi, dopóki '
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
      'OSZACOWANIE · $kcal KCAL · NIE LICZONE';
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
  String get theVessel => 'NACZYNIE';
  @override
  String get readingChartOnDevice =>
      'Czytam kosmogram zapisany na tym urządzeniu…';
  @override
  String get birthDetailsNeededForVessel =>
      'Naczynie potrzebuje danych urodzenia, żeby można je było narysować.';

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
  String get composeReadings => 'Skomponuj odczytania';
  @override
  String get personalReadingNotConnected =>
      'Kompozycja osobistych odczytań nie jest jeszcze podłączona w tej wersji.';
  @override
  String get everyReadingAlreadyComposed =>
      'Wszystkie osobiste odczytania dla tego kosmogramu są już skomponowane.';
  @override
  String get missingReadingsComposed =>
      'Brakujące osobiste odczytania zostały skomponowane.';
  @override
  String readingNotAccepted(String reason) =>
      'Nie udało się przyjąć odczytania: $reason. Nic się nie zmieniło.';
  @override
  String get compositionUnavailableCachedRemain =>
      'Kompozycja jest teraz niedostępna. Zapisane odczytania zostają.';
  @override
  String get personalReadingNotComposedYet =>
      'To osobiste odczytanie nie zostało jeszcze skomponowane. Słowa klucze są '
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
  @override
  String contactLine({
    required String transiting,
    required String aspect,
    required String natal,
  }) =>
      // A readout rather than a sentence. Polish would need `natalny` to agree
      // with each body's gender (Mars natalny, Wenus natalna, Słońce natalne),
      // and this is a dense four-row table where a labelled reading is clearer
      // than forced prose anyway.
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
      'Włącz wskazania AI w Sanktuarium, zanim przeczytasz dzisiejszy dzień.';

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
  String get keptFromAether => 'Poza zasięgiem Aether';
  @override
  String get allowAether => 'Udostępnij Aether';
  @override
  String get keepLocal => 'Zatrzymaj lokalnie';
  @override
  String get allowAetherSemantic =>
      'Pozwól, aby ten wpis trafił do wskazań Aether';
  @override
  String get keepLocalSemantic =>
      'Zatrzymaj ten wpis poza wskazaniami Aether';
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
      'Włącz wskazania AI w Sanktuarium, zanim wyślesz ten wpis.';
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
  String get headingSanctum => 'SANKTUARIUM';
  @override
  String get howEterMeetsYou => 'Jak Eter się z tobą spotyka';
  @override
  String get historyStaysOnThisDevice =>
      'Twoja historia zostaje na tym urządzeniu. Kopia w chmurze jest '
      'wyłączona.';
  @override
  String get cloudContinuityAllowed =>
      'Ciągłość w chmurze jest dozwolona. Możesz ją odwołać poniżej.';

  @override
  String get headingOpeningPage => 'STRONA OTWARCIA';
  @override
  String get choiceJournal => 'Dziennik';
  @override
  String get choiceDashboard => 'Pulpit';

  @override
  String get headingGuidanceRegister => 'REJESTR WSKAZAŃ';
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
      'Skomponowane fragmenty zostają wyczyszczone, żeby nic nie zostało w '
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
      'wyłącza też wskazania czytające dziennik.';

  @override
  String get headingAiGuidance => 'WSKAZANIA AI';
  @override
  String get aiGuidanceOffDetail =>
      'Żaden kontekst zdrowotny nie opuszcza tego urządzenia na potrzeby AI.';
  @override
  String get aiGuidanceAllowedDetail =>
      'Wybrany kontekst może zostać wysłany, żeby skomponować wskazania.';
  @override
  String get headingJournalAwareGuidance => 'WSKAZANIA CZYTAJĄCE DZIENNIK';
  @override
  String get journalAwareOffDetail =>
      'Treść dziennika nigdy nie jest wysyłana.';
  @override
  String get journalAwareAllowedDetail =>
      'Wysłane mogą zostać tylko wpisy bez oznaczenia „Zatrzymaj lokalnie”.';
  @override
  String get headingCloudContinuity => 'CIĄGŁOŚĆ W CHMURZE';
  @override
  String get localOnly => 'Tylko lokalnie';
  @override
  String get cloudOffDetail =>
      'Nowe kopie nie powstają. Kopia, która już jest na Twoim koncie, zostaje '
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
      'Kosmogram rysowany na południe — i tak to nazywa.';
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
      'z czasem letnim. Popraw je, jeśli urodziłaś się lub urodziłeś gdzie '
      'indziej.';
  @override
  String get locatingBirthContext => 'Ustalam ten kontekst urodzenia…';
  @override
  String get birthContextSaved =>
      'Kontekst urodzenia zapisany na tym urządzeniu.';

  @override
  String get headingAetherMemory => 'PAMIĘĆ AETHER';
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
      'To usuwa skomponowane wskazania, wyuczone wzorce i skróty. Twój dziennik '
      'i historia zdrowia zostają.';
  @override
  String get aetherMemoryAlreadyEmpty => 'Pamięć Aether była już pusta.';
  @override
  String get aetherMemoryCleared =>
      'Pamięć Aether wyczyszczona z tego urządzenia.';
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
      'wpisy, które z niej powstały, zostają.';
  @override
  String get pruneProseWarning =>
      'To czyści treść stron dziennika starszych niż rok. Posiłki, treningi i '
      'wpisy z nich wynikające zostają.';
  @override
  String get noPagesOlderThanAYear => 'Żadna strona nie jest starsza niż rok.';
  @override
  String clearedPageText(int pages) =>
      'Wyczyszczono treść $pages ${_stron(pages)}.';

  @override
  String get headingDeleteFromThisDevice => 'USUŃ Z TEGO URZĄDZENIA';
  @override
  String get deleteLocalIntro =>
      'Usuń każdy lokalny zapis Eteru i wróć do wprowadzenia.';
  @override
  String get deleteLocalWarning =>
      'To trwale usuwa lokalny profil, dziennik, historię zdrowia i wyliczone '
      'odczytania. Nic z tego nie da się potem odzyskać.';
  @override
  String get deleteLocalWarningCopyRemains =>
      'To usuwa z tego urządzenia lokalny profil, dziennik, historię zdrowia i '
      'wyliczone odczytania. Kopia na Twoim koncie zostaje, a Przywróć wróciłoby '
      'z nią — usuń konto poniżej, żeby usunąć i ją.';

  @override
  String get headingHealthHistory => 'HISTORIA ZDROWIA';
  @override
  String get healthConnectedReconnect =>
      'Połączone. Połącz ponownie, żeby wczytać ostatnie 30 dni; nakładające '
      'się źródła są rozstrzygane co minutę.';
  @override
  String get healthOffer =>
      'Czytaj wybrane sygnały ruchu, snu i regeneracji z magazynu zdrowia '
      'twojego telefonu.';
  @override
  String get healthOnboardingOffer =>
      'Czytaj ruch, sen i regenerację z magazynu zdrowia twojego telefonu, żeby '
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
      'się później w Sanktuarium.';
  @override
  String get healthCouldNotBeRead =>
      'Nie udało się odczytać danych zdrowotnych. Dotychczasowa historia jest '
      'bez zmian.';
  @override
  String get healthCouldNotBeReadOnboarding =>
      'Nie udało się odczytać danych zdrowotnych. Możesz spróbować później w '
      'Sanktuarium.';

  @override
  String get headingLocalExport => 'EKSPORT LOKALNY';
  @override
  String get localExportNote =>
      'Przygotuj pełny zrzut JSON oraz pliki ruchu i sesji wygodne dla arkusza '
      'kalkulacyjnego. Nic nie jest wysyłane.';
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
      'jest lepsza niż krótki splot, którego nie zapamiętasz.';
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
  String get iHaveConfirmed => 'Potwierdziłem';
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
      'Usuń konto i kopię Twojego zapisu, którą pod nim trzyma.';
  @override
  String get deleteAccountWarning =>
      'To usuwa kopię na koncie, a potem samo konto. Wszystko na tym urządzeniu '
      'zostaje i działa dalej — usunięcie konta to wycofanie się z kopii, a nie '
      'prośba, żeby Eter o Tobie zapomniał.';
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
          'Ciągłość w chmurze jest wyłączona.',
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
  String get fieldWhatWouldYouLikeMoreOf => 'Czego chciałabyś lub chciałbyś '
      'więcej?';
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
      'Dokładną godzinę urodzenia można dopisać później w Sanktuarium.';
  @override
  String get errorEnterValidBirthDate =>
      'Podaj prawidłową datę urodzenia w formacie RRRR-MM-DD.';
  @override
  String get errorMinimumAge =>
      'Eter jest obecnie dostępny dla osób w wieku 16 lat i starszych.';
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
      'Sanktuarium.';
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
      'Sanktuarium.';

  @override
  String get consentStepTitle => 'Wybierz, co może opuścić to urządzenie';
  @override
  String get consentStepIntro =>
      'Wszystko to jest opcjonalne. Prowadzenie dziennika i lokalne wyliczenia '
      'działają nawet wtedy, gdy odmówisz.';
  @override
  String get consentAiTitle => 'Wskazania AI';
  @override
  String get consentAiDetail =>
      'Wysyłaj wybrany kontekst zdrowotny, żeby skomponować wskazania.';
  @override
  String get consentJournalAiTitle => 'Wskazania czytające dziennik';
  @override
  String get consentJournalAiDetail =>
      'Pozwól wysyłać dołączoną treść dziennika do refleksji.';
  @override
  String get consentCloudTitle => 'Ciągłość w chmurze';
  @override
  String get consentCloudDetail =>
      'Trzymaj zaszyfrowaną kopię na koncie na potrzeby przyszłego telefonu.';
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
                'dzień, biorą się z tego, co napisałaś lub napisałeś. Każdą '
                'stronę można zinterpretować, a każdą można też całkowicie '
                'zatrzymać poza zasięgiem Aether.',
          ],
        ),
        TutorialPassage(
          eyebrow: 'PULPIT',
          lines: [
            'Druga strona tej samej przestrzeni odczytuje to, co znalazła.',
            'Wskazania przychodzą same każdego dnia. Zajrzyj głębiej po ciało '
                'albo po Naczynie — twój kosmogram, twoją Drogę życia i to, '
                'jak dzisiejsze niebo stoi wobec nich.',
          ],
        ),
        TutorialPassage(
          eyebrow: 'SANKTUARIUM',
          lines: [
            'Dotknij sygnatury ETER na górze, żeby je otworzyć.',
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
          'Wybierz porę dnia, w której się urodziłaś lub urodziłeś.',
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
        MatrixPosition.given => 'Dane',
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
          'Sam dzień — poszczególny fakt przybycia.',
        MatrixPosition.inherited =>
          'Miesiąc — pora roku, którą życie dostaje, zanim cokolwiek wybierze.',
        MatrixPosition.era =>
          'Rok — pogoda czasu, nie człowieka.',
        MatrixPosition.turning =>
          'Gdzie ten rok stał we własnym cyklu, kiedy człowiek się zaczął.',
        MatrixPosition.meeting =>
          'Dzień i miesiąc razem — poszczególne spotykające swoją porę roku.',
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
        BirthTimePeriod.afternoon => 'Około południe – 17',
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

  @override
  String seriesLabel(String canonical) => switch (canonical) {
        'steps' => 'twoja liczba kroków',
        'activeKcal' => 'ile się ruszałaś lub ruszałeś',
        'sleep' => 'jak długo spałaś lub spałeś',
        'deep' => 'sen głęboki',
        'rem' => 'sen REM',
        'awake' => 'czas czuwania w nocy',
        'restingHr' => 'twój puls spoczynkowy',
        'hrv' => 'twoja zmienność rytmu serca',
        'intake' => 'to, co jadłaś lub jadłeś',
        'sessions' => 'sesje treningowe',
        'mood' => 'twój nastrój',
        'stress' => 'twój stres',
        'recovery' => 'jak zregenerowana lub zregenerowany się czułaś lub '
            'czułeś',
        'meditation' => 'czas spędzony na medytacji',
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
    final direction = positive ? 'wyższe' : 'niższe';
    final receipt = 'około $percent% zmienności, na przestrzeni $days '
        '${_dniGen(days)}';
    return lagged
        ? 'W dniach po tym, jak $from jest wyższe, $to bywa $direction '
            '($receipt).'
        : 'Kiedy $from jest wyższe, $to bywa $direction tego samego dnia '
            '($receipt).';
  }

  @override
  String retrospectiveHeadline({required bool complete}) => complete
      ? 'Twój skrót siedmiu dni'
      : 'Twój częściowy skrót siedmiu dni';
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
      'Sen był dostępny dla $nights z 7 nocy, średnio $averageHours godz.';
  @override
  String retrospectiveJournal(int entries) =>
      'W tym okresie zrobiono $entries ${_wpisy(entries)} w dzienniku.';
  @override
  String retrospectiveLifestyle({
    required int signals,
    required List<String> kinds,
  }) =>
      'Zapisano $signals ${_sygnaly(signals)} zgłoszone samodzielnie, w '
      'kategoriach: ${kinds.map(lifestyleKindName).join(', ')}.';
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
  static String _sygnaly(int n) =>
      _plural(n, one: 'sygnał', few: 'sygnały', many: 'sygnałów');
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
        one: 'skomponowany fragment',
        few: 'skomponowane fragmenty',
        many: 'skomponowanych fragmentów',
      );
}
