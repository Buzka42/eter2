import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/aether/guidance_mode.dart';
import 'core/aether/guidance_contract.dart';
import 'core/ai/transport.dart';
import 'core/clock.dart';
import 'core/db/app_database.dart';
import 'core/journal/classification_contract.dart';
import 'core/journal/day_story.dart';
import 'core/profile/birth_context.dart';
import 'core/register.dart';
import 'core/symbolic/solar.dart';
import 'core/health/foreground_refresh.dart';
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
  final database = AppDatabase();
  await database.runLocalRetention();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const EterApp(),
    ),
  );
}

/// The canonical store. Overridden at the root so tests and the background
/// isolate can supply their own; reading it without an override is a
/// programming error rather than a silent fallback to a second database.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('databaseProvider must be overridden'),
);

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

final vesselReadingTransportProvider =
    Provider<VesselReadingProvider?>((ref) {
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

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
  }

  /// The register turns at the user's real horizon. Schedule the one rebuild
  /// that matters — the next sunrise or sunset — rather than polling. Called
  /// from build, so it is idempotent on the boundary instant.
  void _schedulePhaseChange(ProfileRow? profile) {
    final lat = profile?.birthLatitude;
    final lng = profile?.birthLongitude;
    if (lat == null || lng == null) {
      _phaseTimer?.cancel();
      _scheduledBoundary = null;
      return;
    }
    final now = ref.read(nowProvider)();
    final next = nextPhaseChangeAfter(
      instant: now,
      latitude: lat,
      longitude: lng,
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
        final phase = dayPhaseAt(
          instant: ref.watch(nowProvider)(),
          latitude: profile?.birthLatitude,
          longitude: profile?.birthLongitude,
        );
        final register = EterRegister.resolve(mode, phase);
        final night = register == EterRegister.night;
        final intakeFuture = _intakeFuture ??= db.loadIntakeAnswers();
        return MaterialApp(
          title: 'Eter',
          debugShowCheckedModeBanner: false,
          theme: EterTheme.day(),
          darkTheme: EterTheme.night(),
          themeMode: night ? ThemeMode.dark : ThemeMode.light,
          home: EterRegisterScope(
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
                      unawaited(
                        InitialVesselReadings(
                          database: db,
                          provider: ref.read(vesselReadingTransportProvider),
                        ).composeIfPossible(now: ref.read(nowProvider)()),
                      );
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
                return HealthRefreshOnResume(
                  refresh: ref.watch(healthForegroundRefreshProvider),
                  child: EterShell(startSurface: profile.startSurface),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
