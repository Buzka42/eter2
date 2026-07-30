import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;

import 'core/account/account.dart';
import 'core/account/firebase_account_service.dart';
import 'core/aether/guidance_mode.dart';
import 'core/aether/guidance_contract.dart';
import 'core/ai/transport.dart';
import 'core/clock.dart';
import 'core/db/app_database.dart';
import 'core/diagnostics/crash_reporter.dart';
import 'core/diagnostics/firebase_crash_reporter.dart';
import 'core/journal/classification_contract.dart';
import 'core/journal/day_story.dart';
import 'core/profile/birth_context.dart';
import 'core/register.dart';
import 'core/symbolic/solar.dart';
import 'core/sync/background_sync.dart';
import 'core/sync/cloud_mirror.dart';
import 'core/sync/firestore_mirror.dart';
import 'core/sync/sync_service.dart';
import 'core/health/foreground_refresh.dart';
import 'core/i18n/language.dart';
import 'core/i18n/strings.dart';
import 'core/vessel/initial_readings.dart';
import 'core/vessel/positions_composer.dart';
import 'core/vessel/reading_composer.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/onboarding/tutorial.dart';
import 'features/shell/eter_shell.dart';

/// Bootstrap.
///
/// Opens the canonical local store and hands off to onboarding or the shell.
///
/// Prototype data is test-harness-only. A real fresh install must never wake
/// up as somebody else's profile or imply that health signals were measured.
/// Firebase initialisation, the auth gate and the health resume-sync wrapper
/// belong in this chain as those layers land.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // `DateFormat` ships with `en_US` alone until this runs; every other locale's
  // month and weekday names are absent, and asking for one throws. The Journal's
  // date is the first thing on the page, so this happens before anything can
  // render. Tests call it from `test/helpers/`.
  initializeDateFormatting();

  final database = AppDatabase();
  await database.runLocalRetention();

  // Accounts are optional, so their absence must not be fatal. A build with no
  // Firebase configuration — or a device that cannot reach Google Play
  // services — opens normally, keeps every record, and simply has no
  // "sign in to sync" to offer.
  // Nothing between here and `runApp` may be able to wait forever.
  //
  // It could, and it did: a fresh install disabled crash collection, which
  // awaited a Crashlytics task that never completed, and the app sat on its
  // splash screen. Optional infrastructure is not allowed to decide whether
  // the product opens, so every step below is bounded and every failure is
  // survivable — the app is fully usable with none of it.
  AccountService? accounts;
  CrashReporter reporter = const NoCrashReporter();
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    accounts = FirebaseAccountService();
    reporter = FirebaseCrashReporter();
    debugPrint('Eter: Firebase ready.');
  } catch (error) {
    debugPrint('Eter: accounts unavailable, continuing local-only: $error');
  }

  // Uncaught framework and platform errors reach the reporter, which drops
  // them unless collection is on. Both are also printed, because a swallowed
  // startup error is a blank screen with no explanation anywhere.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    previousOnError?.call(details);
    reporter.record(details.exception, details.stack, fatal: true);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Eter: uncaught $error\n$stack');
    reporter.record(error, stack, fatal: true);
    return true;
  };

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        accountServiceProvider.overrideWithValue(accounts),
        crashReporterProvider.overrideWithValue(reporter),
      ],
      child: const EterApp(),
    ),
  );

  // After the first frame, never before it. Crash collection is off until this
  // resolves, which is the safe direction to be wrong in.
  unawaited(
    CrashConsent(reporter)
        .apply(
          consentedAt: (await database.loadProfile())?.crashReportConsentAt,
        )
        .timeout(const Duration(seconds: 10))
        .catchError((Object error) {
      debugPrint('Eter: crash-report consent not applied: $error');
    }),
  );
}

/// The canonical store. Overridden at the root so tests and the background
/// isolate can supply their own; reading it without an override is a
/// programming error rather than a silent fallback to a second database.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('databaseProvider must be overridden'),
);

/// The account system, or null when this build has none.
///
/// Null is a supported, shipped state — Eter is local-first and an account
/// only ever adds recovery on a new phone. Every surface that reads this must
/// behave correctly when it is null, and tests read it null by default so that
/// stays true.
final accountServiceProvider = Provider<AccountService?>((ref) => null);

/// Crash reporting. A build with nothing to report to gets the no-op, which
/// is a shipped configuration rather than a degraded one.
final crashReporterProvider =
    Provider<CrashReporter>((ref) => const NoCrashReporter());

/// Who is signed in, if anyone. Null covers both "no account system" and
/// "signed out", because no surface needs to tell those apart.
final accountProvider = StreamProvider<EterAccount?>((ref) {
  final service = ref.watch(accountServiceProvider);
  return service == null ? Stream.value(null) : service.changes();
});

/// The cloud mirror, or null when this build has no account system.
final cloudMirrorProvider = Provider<CloudMirror?>((ref) {
  return ref.watch(accountServiceProvider) == null
      ? null
      : FirestoreCloudMirror();
});

/// Pushing the record up and pulling it back. Null when there is nothing to
/// push it to, which every caller must handle: local-only is a real build.
final syncServiceProvider = Provider<SyncService?>((ref) {
  final mirror = ref.watch(cloudMirrorProvider);
  return mirror == null
      ? null
      : SyncService(database: ref.watch(databaseProvider), mirror: mirror);
});

/// The single network transport, or null when this build was compiled without
/// `ETER_AI_ENDPOINT`. Null is a supported, shipped configuration: the app is
/// complete without a model and every surface says so rather than pretending.
///
/// See `docs/AI_FLOW.md` §6 and `core/ai/transport.dart` for why the endpoint
/// belongs to the product owner and the model key never reaches this client.
final aiTransportProvider = Provider<EterAiTransport?>((ref) {
  final config = EterAiConfig.fromEnvironment();
  return config == null ? null : EterAiTransport(config: config);
});

/// Live interpretation transport. Absent without an endpoint; the Journal then
/// still exposes the explicit workflow and explains that state honestly.
final journalClassificationProvider =
    Provider<JournalClassificationProvider?>((ref) {
  final transport = ref.watch(aiTransportProvider);
  return transport == null
      ? null
      : TransportJournalClassificationProvider(transport);
});

/// Live Aether transport. The local trust boundary and UI remain functional
/// without it, but never imply that composition occurred.
final aetherTransportProvider = Provider<AetherProvider?>((ref) {
  final transport = ref.watch(aiTransportProvider);
  return transport == null ? null : TransportAetherProvider(transport);
});

final vesselReadingTransportProvider = Provider<VesselReadingProvider?>((ref) {
  final transport = ref.watch(aiTransportProvider);
  return transport == null ? null : TransportVesselReadingProvider(transport);
});

/// Transport for today's Positions — the moving half of the Vessel. The
/// contacts are always computed locally; only their prose needs this.
final positionsTransportProvider = Provider<PositionsProvider?>((ref) {
  final transport = ref.watch(aiTransportProvider);
  return transport == null ? null : TransportPositionsProvider(transport);
});

/// Transport for the Journal's daily story and its digest. Absent without an
/// endpoint; the Journal then shows the day's pages without a story rather
/// than pretending to have one.
final journalDayStoryProvider = Provider<JournalDayStoryProvider?>((ref) {
  final transport = ref.watch(aiTransportProvider);
  return transport == null ? null : TransportJournalDayStoryProvider(transport);
});
final birthplaceResolverProvider = Provider<BirthplaceResolver>(
  (ref) => PlatformBirthplaceResolver(),
);

/// Copies the record up on its own, so the mirror is not limited to what
/// somebody remembered to send from the Sanctum. Null with no mirror to push to.
///
/// Held in a provider so the debounce survives rebuilds; a fresh instance per
/// frame would push on every lifecycle event.
final backgroundSyncProvider = Provider<BackgroundSync?>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return sync == null ? null : BackgroundSync(sync: sync, now: ref.read(nowProvider));
});

/// Keeps connected health data current when the app is opened or resumed, so
/// the Body is not quietly stale until someone visits the Sanctum. Inert until
/// a hub is connected, and debounced; see `core/health/foreground_refresh.dart`
/// for why resume — not a background service — is the honest ceiling today.
final healthForegroundRefreshProvider = Provider<HealthForegroundRefresh>(
  (ref) => HealthForegroundRefresh(database: ref.watch(databaseProvider)),
);

class EterApp extends ConsumerStatefulWidget {
  const EterApp({super.key});

  @override
  ConsumerState<EterApp> createState() => _EterAppState();
}

class _EterAppState extends ConsumerState<EterApp> {
  Timer? _phaseTimer;
  DateTime? _scheduledBoundary;
  Stream<ProfileRow?>? _profileStream;
  Future<Map<String, IntakeAnswerRow>>? _intakeFuture;
  bool _onboardingCompletedNow = false;
  bool _tutorialCompletedNow = false;

  /// Once per run: the readings are written at intake, but intake is not the
  /// only moment they can become possible.
  bool _checkedInitialReadings = false;

  /// Composes the chart's passages if they are missing and can be written.
  ///
  /// The natural place for this is the end of onboarding, and that is where it
  /// first fires. But someone who declines AI during setup and allows it later
  /// in the Sanctum would otherwise never get them: the intake moment has
  /// passed and nothing would try again, leaving a Vessel that says "not
  /// composed yet" forever. So it is also attempted when the shell opens.
  ///
  /// Cheap to repeat — the composer only ever requests positions it does not
  /// already hold, so once the readings exist this writes nothing and calls
  /// no provider.
  void _ensureInitialReadings(AppDatabase db) {
    if (_checkedInitialReadings) return;
    _checkedInitialReadings = true;
    unawaited(
      InitialVesselReadings(
        database: db,
        provider: ref.read(vesselReadingTransportProvider),
      ).composeIfPossible(now: ref.read(nowProvider)()),
    );
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
  }

  /// Where this device should read the sun from, or null to fall back to the
  /// clock. The rule itself is in `core/symbolic/solar.dart`; this only supplies
  /// the device's current offset, which is the one input that cannot be pure.
  ({double latitude, double longitude})? _registerCoordinates(
    ProfileRow? profile,
  ) =>
      registerCoordinates(
        homeLatitude: profile?.homeLatitude,
        homeLongitude: profile?.homeLongitude,
        birthLatitude: profile?.birthLatitude,
        birthLongitude: profile?.birthLongitude,
        utcOffset: ref.read(nowProvider)().timeZoneOffset,
      );

  /// The register turns at the user's real horizon. Schedule the one rebuild
  /// that matters — the next sunrise or sunset — rather than polling. Called
  /// from build, so it is idempotent on the boundary instant.
  void _schedulePhaseChange(ProfileRow? profile) {
    final at = _registerCoordinates(profile);
    if (at == null) {
      _phaseTimer?.cancel();
      _scheduledBoundary = null;
      return;
    }
    final now = ref.read(nowProvider)();
    final next = nextPhaseChangeAfter(
      instant: now,
      latitude: at.latitude,
      longitude: at.longitude,
    );
    if (next == _scheduledBoundary) return;
    _phaseTimer?.cancel();
    _scheduledBoundary = next;
    if (next == null) return;
    final delay = next.difference(now.toUtc());
    if (delay.isNegative) return;
    _phaseTimer = Timer(delay + const Duration(seconds: 1), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    // Cached: a fresh watchProfile() per build would resubscribe the
    // StreamBuilder on every register flip.
    final profileStream = _profileStream ??= db.watchProfile();
    return StreamBuilder<ProfileRow?>(
      stream: profileStream,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        _schedulePhaseChange(profile);
        final mode = switch (profile?.guidanceMode) {
          'grounded' => GuidanceMode.grounded,
          'immersive' => GuidanceMode.immersive,
          _ => GuidanceMode.balanced,
        };
        final at = _registerCoordinates(profile);
        final phase = dayPhaseAt(
          instant: ref.watch(nowProvider)(),
          latitude: at?.latitude,
          longitude: at?.longitude,
        );
        final register = EterRegister.resolve(mode, phase);
        final night = register == EterRegister.night;
        final intakeFuture = _intakeFuture ??= db.loadIntakeAnswers();
        // A stored choice is the person's and is obeyed; a null column means
        // nobody has chosen, and then the phone decides. Resolved here, once, so
        // every surface below reads one answer — including onboarding, which
        // runs before there is a profile row to hold one.
        final language = AppLanguage.forProfile(profile?.language);
        return MaterialApp(
          title: 'Eter',
          debugShowCheckedModeBanner: false,
          theme: EterTheme.day(),
          darkTheme: EterTheme.night(),
          themeMode: night ? ThemeMode.dark : ThemeMode.light,
          // The framework's own strings — the selection toolbar, the scrollbar's
          // semantics — follow Eter rather than the device, so a Polish app does
          // not offer an English "Paste".
          locale: language.locale,
          supportedLocales: [
            for (final value in AppLanguage.values) value.locale,
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: EterStringsScope(
            strings: EterStrings.forLanguage(language),
            child: EterRegisterScope(
              register: register,
              child: FutureBuilder<Map<String, IntakeAnswerRow>>(
                future: intakeFuture,
                builder: (context, intake) {
                  if (!intake.hasData) return const SizedBox.shrink();
                  final complete = _onboardingCompletedNow ||
                      intake.data?['onboarding_complete']?.value == 'true';
                  if (profile == null || !complete) {
                    return OnboardingFlow(
                      database: db,
                      profile: profile,
                      onComplete: () {
                        setState(() => _onboardingCompletedNow = true);
                        // The chart is fixed for life, so its passages are
                        // written once, here, rather than on demand — the
                        // Vessel should already be whole the first time it is
                        // opened. Best-effort and unawaited: no consent, no
                        // transport or a provider failure all mean the same
                        // thing, and none of them may delay the first screen.
                        _ensureInitialReadings(db);
                      },
                    );
                  }
                  // The first minute, once. A sparse interface is the kind most
                  // often misread, so the four passages that say where things
                  // are come between intake and the shell — and never again.
                  final tutorialDone = _tutorialCompletedNow ||
                      intake.data?[EterTutorial.answerKey]?.value == 'true';
                  if (!tutorialDone) {
                    return EterTutorial(
                      database: db,
                      onFinished: () =>
                          setState(() => _tutorialCompletedNow = true),
                    );
                  }
                  _ensureInitialReadings(db);
                  return HealthRefreshOnResume(
                    refresh: ref.watch(healthForegroundRefreshProvider),
                    child: SyncOnLifecycle(
                      sync: ref.watch(backgroundSyncProvider),
                      account: () => ref.read(accountProvider).value,
                      child: EterShell(startSurface: profile.startSurface),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
