import 'package:flutter/animation.dart';

/// Design tokens — generated from spec/03-design-system.md.
/// Never hardcode colors/durations/sizes in feature code; import this.
abstract final class EterColors {
  // Day Sky
  static const mist0 = Color(0xFFFFFFFF);
  static const mist50 = Color(0xFFFAFCFE);
  static const sky100 = Color(0xFFEAF4FB);
  static const sky200 = Color(0xFFD6EAF7);
  static const sky300 = Color(0xFFA8D8F0);
  static const sky400 = Color(0xFF638FAE);
  static const sky500 = Color(0xFF477895);
  static const ink900 = Color(0xFF1C2B3A);
  static const ink600 = Color(0xFF4A6076);
  static const ink400 = Color(0xFF8AA0B4);
  // Gold
  static const aura300 = Color(0xFFE9CF9A);
  static const aura500 = Color(0xFFD4AF6A);
  static const aura700 = Color(0xFFA8843D);
  // Gild — highlight sweep and fine line-work on dark surfaces (v2 astral).
  static const aura200 = Color(0xFFF3E5BF);
  static const aura400 = Color(0xFFE3C284);
  static const gild = Color(0xFFF6E7B8);
  // Semantic
  static const success = Color(0xFF7BC49A);
  static const warn = Color(0xFFE8B36F);
  static const danger = Color(0xFFE08A8A);
  // Night Sky
  static const night900 = Color(0xFF0F1626);
  static const night800 = Color(0xFF16203A);
  static const night700 = Color(0xFF1F2C4A);
  static const nightText = Color(0xFFE9EFF7);
  static const nightText2 = Color(0xFFA9B8CC);
  static const nightText3 = Color(0xFF71809A);
  // Element accents (spec 03)
  static const elemAir = Color(0xFFC7DDF2);
  static const elemFire = Color(0xFFF0A987);
  static const elemWater = Color(0xFF93D5CF);
  static const elemEarth = Color(0xFFB9CCA8);
  // Element accents — deep variants for text/line use on Day Sky surfaces,
  // where the pale accents above do not meet contrast.
  static const elemAirDeep = Color(0xFF5E7F9D);
  static const elemFireDeep = Color(0xFFBC6B47);
  static const elemWaterDeep = Color(0xFF4C857F);
  static const elemEarthDeep = Color(0xFF71855B);
}

abstract final class EterMotion {
  /// cubic-bezier(0.22, 1.00, 0.36, 1.00) — default for all transitions.
  static const easeAir = Cubic(0.22, 1.0, 0.36, 1.0);
  static const durMicro = Duration(milliseconds: 180);
  static const durStandard = Duration(milliseconds: 320);
  static const durEmphasis = Duration(milliseconds: 600);
  static const durReveal = Duration(milliseconds: 900);

  /// Cadence of the guidance reveal — one sentence per beat. Slower than
  /// [durReveal] on purpose: this is a reading pace, not a transition.
  static const durSentence = Duration(milliseconds: 1200);
  static const listStagger = Duration(milliseconds: 40);
}

abstract final class EterSpace {
  static const double s4 = 4, s8 = 8, s12 = 12, s16 = 16;
  static const double s24 = 24, s32 = 32, s48 = 48, s64 = 64;
  static const double gutter = 24;

  /// Panels, inputs, dividers and scrims are square (radius 0) — sharp is the
  /// default, and no token is needed for it. Rounding is reserved for objects
  /// that are physically card-like: [rChip] for the arcana card and its art,
  /// [rSheet] for modal sheets.
  static const double rChip = 12, rSheet = 28;
}
