import 'package:flutter/widgets.dart';

import 'aether/guidance_mode.dart';

/// Which half of the day the surface is in.
///
/// Computed from real local sunrise and sunset against the user's birth (or
/// current) coordinates — see `core/symbolic/solar.dart`. Deliberately not a
/// clock hour: the app turning symbolic at *your* sunset, in *your* city, is
/// the point.
enum DayPhase { day, night }

/// How much ornament a surface is allowed to carry.
///
/// Guidance mode used to control only the wording of the daily reading, while
/// every surface decided its own ornament from `Theme.brightness`. That let
/// grounded mode still render gold dividers and a companion card, and let
/// immersive mode fall back to plain rules whenever the OS was in light mode.
/// The register makes it one decision, taken once at the root.
///
/// v2 collapses the register from three values to two. [GuidanceMode] keeps
/// all three names because that is the user's setting and what `firestore
/// .rules` validates, but what actually renders is only ever day or night:
///
/// * [GuidanceMode.grounded] — always [day].
/// * [GuidanceMode.immersive] — always [night].
/// * [GuidanceMode.balanced] — resolves by the sun. This is the default.
///
/// The old `balanced` register — a blended middle at 0.5 ornament — is gone.
/// A user on balanced still sees both halves of the product, sequenced rather
/// than blended: practical and light in the morning, symbolic and dark after
/// sunset. That reads as a better expression of "health information and
/// symbolic interpretation are both visible" than a permanent compromise
/// between them, and it means every pixel of ornament belongs to a register
/// that actually wanted it.
enum EterRegister {
  /// A plain instrument. Day sky, no gold, no ornament, no card, no motion.
  day,

  /// The full mystical register. Night sky, gold line-work, the Arcana card as
  /// the centre of the surface, ambient motion.
  night;

  /// Resolve the setting against the moment.
  ///
  /// Pure, so it can be tested against a fixed phase without a clock, a
  /// location, or an ephemeris.
  static EterRegister resolve(GuidanceMode mode, DayPhase phase) =>
      switch (mode) {
        GuidanceMode.grounded => EterRegister.day,
        GuidanceMode.immersive => EterRegister.night,
        GuidanceMode.balanced =>
          phase == DayPhase.day ? EterRegister.day : EterRegister.night,
      };

  /// Gold hairlines, star ornaments and engraved dividers.
  bool get showsOrnament => this == EterRegister.night;

  /// The Arcana card appears at all. Day shows the card only at launch and
  /// never again, so every in-app placement is suppressed.
  bool get showsCompanionCard => this == EterRegister.night;

  /// The Arcana card is the centre of the surface rather than a companion
  /// beside a heading — full width, revealable, the thing the eye lands on.
  bool get showsHeroCard => this == EterRegister.night;

  /// Ambient motion: the drifting air field, the twinkle, the slow reveal.
  ///
  /// There are 25 night card loops and no day loops. Under the automatic
  /// register that is a design rule rather than a gap: day is still, night
  /// moves. Do not commission day loops to "fix" it.
  bool get showsAmbientMotion => this == EterRegister.night;

  Brightness get brightness =>
      this == EterRegister.night ? Brightness.dark : Brightness.light;

  /// Roughly the "how mystical, 1–10" dial, for tuning opacities against a
  /// single number rather than scattering per-widget constants.
  double get ornamentIntensity =>
      this == EterRegister.night ? 0.7 : 0.2;

  static EterRegister of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<EterRegisterScope>();
    return scope?.register ?? EterRegister.day;
  }
}

/// How rich a given surface *wants* to be, independent of the user's setting.
///
/// The register alone could not express the chosen direction — minimal by
/// default, rich on moments — because that decision is per-surface, not
/// per-app: the Journal should stay plain even for someone who wants
/// immersion, and the arcana reveal should sing even for someone who wants
/// restraint. Pairing the two makes the register a *ceiling* rather than a
/// level: `day` means "even the ritual moments stay quiet", `night` means
/// "let them sing", and no setting can make an instrument ornate.
enum SurfaceIntent {
  /// Everyday instruments: the Journal, the figures, the charts, the Sanctum.
  /// Never ornamented, whatever the register.
  plain,

  /// Moments: the opening guidance, onboarding, the arcana reveal, the Vessel.
  /// Ornamented as far as the register permits.
  ritual,
}

/// The intent of the nearest enclosing surface. Defaults to
/// [SurfaceIntent.ritual] so that surfaces which have not been classified keep
/// their existing appearance rather than silently going plain.
SurfaceIntent surfaceIntentOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<SurfaceIntentScope>()?.intent ??
    SurfaceIntent.ritual;

/// Whether ornament may be drawn here: the register's permission capped by
/// what this surface actually wants. This is the resolver that replaces bare
/// `EterRegister.of(context).showsOrnament` checks.
bool showsOrnamentHere(BuildContext context) =>
    surfaceIntentOf(context) == SurfaceIntent.ritual &&
    EterRegister.of(context).showsOrnament;

/// Declares the intent of everything beneath it.
class SurfaceIntentScope extends InheritedWidget {
  const SurfaceIntentScope({
    super.key,
    required this.intent,
    required super.child,
  });

  final SurfaceIntent intent;

  @override
  bool updateShouldNotify(SurfaceIntentScope oldWidget) =>
      oldWidget.intent != intent;
}

/// Publishes the active [EterRegister] to the whole tree. Installed once, at
/// the root, from the profile's guidance mode resolved against the sun.
class EterRegisterScope extends InheritedWidget {
  const EterRegisterScope({
    super.key,
    required this.register,
    required super.child,
  });

  final EterRegister register;

  @override
  bool updateShouldNotify(EterRegisterScope oldWidget) =>
      oldWidget.register != register;
}
