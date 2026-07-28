import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/aether/guidance_mode.dart';
import 'core/clock.dart';
import 'core/db/app_database.dart';
import 'core/register.dart';
import 'core/symbolic/solar.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_flow.dart';
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
                    onComplete: () =>
                        setState(() => _onboardingCompletedNow = true),
                  );
                }
                return EterShell(startSurface: profile.startSurface);
              },
            ),
          ),
        );
      },
    );
  }
}
