import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'register.dart';
import 'tokens.dart';

/// True under `flutter test`, where video platform channels do not exist.
/// Media widgets fall back to their static masters, keeping goldens
/// deterministic and preventing dangling controller initializations.
bool eterRunningTests() =>
    !kIsWeb && Platform.environment['FLUTTER_TEST'] == 'true';

/// Cormorant Garamond = display/editorial voice · Inter = text & numerals.
/// The pairing replaces the original Marcellus/Manrope system with an
/// editorial-luxury register: wide-spaced serif moments, quiet grotesque
/// data. Numerals always render tabular so counters never jitter.
abstract final class EterTheme {
  static TextTheme _text(Color primary, Color secondary) {
    TextStyle cormorant(double size, double height, FontWeight w,
            {Color? color, double tracking = 0}) =>
        TextStyle(
          fontFamily: 'Cormorant Garamond',
          fontSize: size,
          height: height / size,
          fontWeight: w,
          color: color ?? primary,
          letterSpacing: tracking,
        );
    TextStyle inter(double size, double height, FontWeight w,
            {Color? color, double tracking = 0}) =>
        TextStyle(
          fontFamily: 'Inter',
          fontSize: size,
          height: height / size,
          fontWeight: w,
          color: color ?? primary,
          letterSpacing: tracking,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    return TextTheme(
      displayLarge: cormorant(46, 50, FontWeight.w300),
      displayMedium: cormorant(34, 40, FontWeight.w300),
      displaySmall: cormorant(28, 34, FontWeight.w400),
      headlineSmall: cormorant(24, 33, FontWeight.w400),
      titleLarge: cormorant(26, 31, FontWeight.w500),
      titleMedium: inter(15, 22, FontWeight.w600),
      titleSmall: inter(13, 18, FontWeight.w600),
      bodyLarge: inter(16, 26, FontWeight.w400),
      bodyMedium: inter(14, 22, FontWeight.w400),
      bodySmall: inter(12, 18, FontWeight.w400, color: secondary),
      labelLarge: inter(14, 20, FontWeight.w600, tracking: 0.4),
      labelMedium:
          inter(12, 16, FontWeight.w600, color: secondary, tracking: 1.1),
      labelSmall:
          inter(11, 15, FontWeight.w600, color: secondary, tracking: 1.6),
      // numeralHero 56/60 w800 — used for the daily kcal figure.
      headlineLarge: inter(56, 60, FontWeight.w800),
    );
  }

  static ThemeData day() => _base(
        brightness: Brightness.light,
        bg: EterColors.mist50,
        surface: EterColors.mist0,
        // Secondary is ink600, not ink400. ink400 was chosen against the old
        // near-white pale-morning plate; on the v4 sunny sky it is a blue-grey
        // on blue and eyebrows/captions disappeared entirely.
        text: _text(EterColors.ink900, EterColors.ink600),
      );

  static ThemeData night() => _base(
        brightness: Brightness.dark,
        bg: EterColors.night900,
        surface: EterColors.night700,
        text: _text(EterColors.nightText, EterColors.nightText2),
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required TextTheme text,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: EterColors.sky400,
        brightness: brightness,
        primary: EterColors.sky400,
        secondary: EterColors.aura500,
        surface: surface,
      ),
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: EterPageTransitionsBuilder(),
          TargetPlatform.iOS: EterPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: surface.withValues(
            alpha: brightness == Brightness.dark ? .94 : .98),
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: .96),
        indicatorColor: EterColors.aura500.withValues(alpha: .22),
        labelTextStyle: WidgetStatePropertyAll(
          text.labelSmall?.copyWith(
            color: brightness == Brightness.dark
                ? EterColors.nightText
                : EterColors.ink900,
          ),
        ),
      ),
    );
  }
}

/// Classical Air field shared by primary screens.
class SkyBackground extends StatefulWidget {
  const SkyBackground({super.key, required this.child});
  final Widget child;

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  Brightness? _loadedBrightness;
  Timer? _deferredLoad;

  /// A very slow parallax drift across the plate.
  ///
  /// Both skies were dead still: the night astrophotograph and the day cloud
  /// are single bitmaps, so nothing moved unless the air-field video happened
  /// to be loaded. A 3% oversample panned over three minutes gives the sky the
  /// sense of turning overhead without any new asset, any decode, or any
  /// motion fast enough to read as an animation.
  AnimationController? _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 180),
    );
  }

  static const double _driftOversample = 1.03;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (eterRunningTests()) return;
    // Grounded is a still, plain daylight surface. Loading and looping a video
    // for a register whose whole point is the absence of ambient motion costs
    // a decode, a texture and battery for nothing visible.
    if (!EterRegister.of(context).showsAmbientMotion) {
      _deferredLoad?.cancel();
      _controller?.dispose();
      _controller = null;
      _loadedBrightness = null;
      return;
    }
    final brightness = Theme.of(context).brightness;
    if (_loadedBrightness != brightness) {
      _loadedBrightness = brightness;
      _deferredLoad?.cancel();
      // Paint the static master first. Media initialization on a cold Android
      // process is expensive and must never hold the launch experience hostage.
      _deferredLoad = Timer(const Duration(milliseconds: 900), () {
        if (mounted) _load(brightness);
      });
    }
  }

  Future<void> _load(Brightness brightness) async {
    final previous = _controller;
    _controller = null;
    await previous?.dispose();
    final suffix = brightness == Brightness.dark ? 'dark' : 'light';
    final controller = VideoPlayerController.asset(
      'assets/art/animations/air-field-$suffix.mp4',
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted && identical(_controller, controller)) setState(() {});
    } catch (_) {
      await controller.dispose();
      if (identical(_controller, controller)) _controller = null;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _deferredLoad?.cancel();
    _drift?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final controller = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        _DriftingPlate(
          drift: reduceMotion ? null : _drift,
          oversample: _driftOversample,
          child: Image.asset(
            // Night Sky is the v3 astrophotography plate: the delivered master
            // is a real long exposure, but it shipped crushed to near-black, so
            // the galactic band was invisible and a procedural StarField painted
            // symbolic four-armed sparkles on top to compensate. v3 applies the
            // astro stretch and reframes to phone aspect so the band survives the
            // cover crop, and the symbolic overlay is gone
            // (tools/grade_night_sky.py).
            //
            // Day Sky is the v5 plate: v4 fixed the colour (v3 had desaturated
            // the master to flat neutral grey) and v5 fixes the character, which
            // was a perfectly smooth ramp with no light direction and visible
            // 8-bit banding. It composites real photographic cumulus low in the
            // frame and dithers the whole plate (tools/compose_day_sky.py).
            'assets/art/bg-air-${night ? 'dark-v3' : 'light-v5'}.webp',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
        if (!reduceMotion && (controller?.value.isInitialized ?? false))
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: EterMotion.durEmphasis,
            curve: EterMotion.easeAir,
            builder: (context, opacity, child) => Opacity(
              opacity: opacity,
              child: child,
            ),
            child: RepaintBoundary(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller!.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
        // A scrim, not a wash. The previous values put up to 48% of night800
        // over the plate, which is what flattened a real star field into a
        // gradient; both graded plates already carry their own vertical ramp,
        // so this only has to seat text at the bottom of the frame.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.55, 1.0],
              colors: night
                  ? [
                      Colors.transparent,
                      EterColors.night900.withValues(alpha: .10),
                      EterColors.night900.withValues(alpha: .30),
                    ]
                  : [
                      Colors.transparent,
                      EterColors.mist50.withValues(alpha: .06),
                      EterColors.mist50.withValues(alpha: .16),
                    ],
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// Oversamples a background plate and pans it on a very long cycle, so the sky
/// is never completely still. The drift is a triangle wave — out and back —
/// because a sawtooth would snap at the loop point.
class _DriftingPlate extends StatelessWidget {
  const _DriftingPlate({
    required this.drift,
    required this.oversample,
    required this.child,
  });

  final AnimationController? drift;
  final double oversample;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final drift = this.drift;
    if (drift == null) return child;
    // Started here rather than in initState so Reduce Motion, which removes
    // this widget entirely, also stops the ticker.
    if (!drift.isAnimating) drift.repeat(reverse: true);
    return AnimatedBuilder(
      animation: drift,
      child: child,
      builder: (context, child) {
        final t = Curves.easeInOutSine.transform(drift.value) - 0.5;
        final slack = (oversample - 1) / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scaleByDouble(oversample, oversample, 1, 1)
            ..translateByDouble(t * slack * 260, t * slack * 130, 0, 1),
          child: child,
        );
      },
    );
  }
}

/// Eter's "gust" route transition: mist-like lift, fade and a restrained blur.
class EterPageTransitionsBuilder extends PageTransitionsBuilder {
  const EterPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return FadeTransition(opacity: animation, child: child);
    }
    final curved = CurvedAnimation(
      parent: animation,
      curve: EterMotion.easeAir,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .025),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
