import 'package:flutter/material.dart';

import '../tokens.dart';

/// Zodiac → Major Arcana (Golden Dawn correspondence) — spec 05.
enum Element { fire, earth, air, water }

extension ElementX on Element {
  Color get accent => switch (this) {
        Element.air => EterColors.elemAir,
        Element.fire => EterColors.elemFire,
        Element.water => EterColors.elemWater,
        Element.earth => EterColors.elemEarth,
      };

  /// Contrast-safe variant for text and fine line-work on Day Sky surfaces.
  Color get accentDeep => switch (this) {
        Element.air => EterColors.elemAirDeep,
        Element.fire => EterColors.elemFireDeep,
        Element.water => EterColors.elemWaterDeep,
        Element.earth => EterColors.elemEarthDeep,
      };

  /// Resolves the readable variant for the current brightness.
  Color accentFor(Brightness brightness) =>
      brightness == Brightness.dark ? accent : accentDeep;
  String get label => switch (this) {
        Element.air => 'Air',
        Element.fire => 'Fire',
        Element.water => 'Water',
        Element.earth => 'Earth',
      };

  /// Commissioned gold line-work medallion master
  /// (STATIC_ASSET_REQUESTS.md §B, 1024x1024, transparent background).
  String get medallionAsset => 'assets/art/elem-$name.png';
}

enum Zodiac {
  aries('Aries', Element.fire, 'The Emperor', 'IV', 'Card of Command'),
  taurus('Taurus', Element.earth, 'The Hierophant', 'V', 'Card of Foundations'),
  gemini('Gemini', Element.air, 'The Lovers', 'VI', 'Card of Union'),
  cancer('Cancer', Element.water, 'The Chariot', 'VII', 'Card of Momentum'),
  leo('Leo', Element.fire, 'Strength', 'VIII', 'Card of Inner Fire'),
  virgo('Virgo', Element.earth, 'The Hermit', 'IX', 'Card of Focus'),
  libra('Libra', Element.air, 'Justice', 'XI', 'Card of Balance'),
  scorpio('Scorpio', Element.water, 'Death', 'XIII', 'Card of Transformation'),
  sagittarius('Sagittarius', Element.fire, 'Temperance', 'XIV', 'Card of Flow'),
  capricorn('Capricorn', Element.earth, 'The Devil', 'XV', 'Card of Ambition'),
  aquarius('Aquarius', Element.air, 'The Star', 'XVII', 'Card of Hope'),
  pisces('Pisces', Element.water, 'The Moon', 'XVIII', 'Card of Intuition');

  const Zodiac(
      this.label, this.element, this.arcana, this.numeral, this.subtitle);
  final String label;
  final Element element;
  final String arcana;
  final String numeral;
  final String subtitle;

  /// Tropical date ranges (spec 05 table). Boundaries tested in zodiac_test.
  static Zodiac fromDate(DateTime dob) {
    final m = dob.month, d = dob.day;
    return switch ((m, d)) {
      (3, >= 21) || (4, <= 19) => aries,
      (4, _) || (5, <= 20) => taurus,
      (5, _) || (6, <= 20) => gemini,
      (6, _) || (7, <= 22) => cancer,
      (7, _) || (8, <= 22) => leo,
      (8, _) || (9, <= 22) => virgo,
      (9, _) || (10, <= 22) => libra,
      (10, _) || (11, <= 21) => scorpio,
      (11, _) || (12, <= 21) => sagittarius,
      (12, _) || (1, <= 19) => capricorn,
      (1, _) || (2, <= 18) => aquarius,
      _ => pisces,
    };
  }

  String get assetSlug => switch (this) {
        aries => 'the-emperor',
        taurus => 'the-hierophant',
        gemini => 'the-lovers',
        cancer => 'the-chariot',
        leo => 'strength',
        virgo => 'the-hermit',
        libra => 'justice',
        scorpio => 'death',
        sagittarius => 'temperance',
        capricorn => 'the-devil',
        aquarius => 'the-star',
        pisces => 'the-moon',
      };

  /// Theme-matched production collection. Naming is data-driven so artwork
  /// remains swappable without reveal-widget changes (spec 05).
  String cardAssetFor(Brightness brightness) =>
      'assets/art/cards/$assetSlug-${brightness == Brightness.dark ? 'dark' : 'light'}.webp';

  String get cardAsset => cardAssetFor(Brightness.dark);
}
