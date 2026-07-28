import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'major_arcana.dart';
import 'zodiac.dart';

/// The static half of the symbolic content.
///
/// Two layers, and the split is the point:
///
/// * **Here** — attributes. Keywords, correspondences, domains. Small, typed,
///   identical for everyone, and available with no network. This is what the
///   collapsed Vessel renders and what the offline fallback renders.
/// * **Not here** — the long-form interpretation, which is composed per user
///   against their actual chart by `VesselService` and cached under a birth
///   input hash. A Life Path 7 with Strength in that position gets a reading
///   about *their* chart, not a paragraph everyone else also receives.
///
/// Shipped as JSON rather than Dart so copy can be edited without touching
/// code. A test asserts every card, sign, life path, house and point has a
/// complete entry, and that the keys here match the enums and the chart
/// engine exactly.
class SymbolContent {
  const SymbolContent({
    required this.cards,
    required this.signs,
    required this.lifePaths,
    required this.houses,
    required this.points,
  });

  final Map<String, ArcanaAttributes> cards;
  final Map<String, SignAttributes> signs;
  final Map<int, LifePathAttributes> lifePaths;
  final Map<int, HouseAttributes> houses;
  final Map<String, PointAttributes> points;

  ArcanaAttributes? card(MajorArcana card) => cards[card.assetSlug];
  SignAttributes? sign(Zodiac sign) => signs[sign.name];
  LifePathAttributes? lifePath(int value) => lifePaths[value];
  HouseAttributes? house(int number) => houses[number];
  PointAttributes? point(String name) => points[name];

  static const _schemaVersion = 1;
  static SymbolContent? _rootBundleContent;

  static Future<SymbolContent> load({AssetBundle? bundle}) async {
    if (bundle == null && _rootBundleContent != null) {
      return _rootBundleContent!;
    }
    final b = bundle ?? rootBundle;
    Future<Map<String, Object?>> read(String name) async {
      final raw = await b.loadString('assets/content/$name.json');
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) {
        throw FormatException('$name.json is not an object');
      }
      if (json['schemaVersion'] != _schemaVersion) {
        throw FormatException(
          '$name.json declares schema ${json['schemaVersion']}, '
          'expected $_schemaVersion',
        );
      }
      return json;
    }

    List<Map<String, Object?>> rows(Map<String, Object?> json, String key) {
      final list = json[key];
      if (list is! List) throw FormatException('missing list "$key"');
      return list
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList(growable: false);
    }

    final arcanaJson = await read('arcana');
    final zodiacJson = await read('zodiac');
    final lifePathJson = await read('life_paths');
    final houseJson = await read('houses');
    final pointJson = await read('points');

    final content = SymbolContent(
      cards: {
        for (final row in rows(arcanaJson, 'cards'))
          _string(row, 'slug'): ArcanaAttributes.fromJson(row),
      },
      signs: {
        for (final row in rows(zodiacJson, 'signs'))
          _string(row, 'key'): SignAttributes.fromJson(row),
      },
      lifePaths: {
        for (final row in rows(lifePathJson, 'paths'))
          _int(row, 'value'): LifePathAttributes.fromJson(row),
      },
      houses: {
        for (final row in rows(houseJson, 'houses'))
          _int(row, 'number'): HouseAttributes.fromJson(row),
      },
      points: {
        for (final row in rows(pointJson, 'points'))
          _string(row, 'name'): PointAttributes.fromJson(row),
      },
    );
    if (bundle == null) _rootBundleContent = content;
    return content;
  }
}

class ArcanaAttributes {
  const ArcanaAttributes({
    required this.slug,
    required this.subtitle,
    required this.correspondence,
    required this.keywords,
  });

  final String slug;

  /// Death and The Devil keep their authentic names; the subtitle is where the
  /// positive reframing lives.
  final String subtitle;
  final String correspondence;
  final List<String> keywords;

  factory ArcanaAttributes.fromJson(Map<String, Object?> json) =>
      ArcanaAttributes(
        slug: _string(json, 'slug'),
        subtitle: _string(json, 'subtitle'),
        correspondence: _string(json, 'correspondence'),
        keywords: _keywords(json),
      );
}

class SignAttributes {
  const SignAttributes({
    required this.key,
    required this.modality,
    required this.ruler,
    required this.keywords,
  });

  final String key;
  final String modality;
  final String ruler;
  final List<String> keywords;

  factory SignAttributes.fromJson(Map<String, Object?> json) => SignAttributes(
        key: _string(json, 'key'),
        modality: _string(json, 'modality'),
        ruler: _string(json, 'ruler'),
        keywords: _keywords(json),
      );
}

class LifePathAttributes {
  const LifePathAttributes({
    required this.value,
    required this.title,
    required this.keywords,
    required this.master,
  });

  final int value;
  final String title;
  final List<String> keywords;
  final bool master;

  factory LifePathAttributes.fromJson(Map<String, Object?> json) =>
      LifePathAttributes(
        value: _int(json, 'value'),
        title: _string(json, 'title'),
        keywords: _keywords(json),
        master: json['master'] == true,
      );
}

class HouseAttributes {
  const HouseAttributes({
    required this.number,
    required this.title,
    required this.domain,
    required this.keywords,
  });

  final int number;
  final String title;
  final String domain;
  final List<String> keywords;

  factory HouseAttributes.fromJson(Map<String, Object?> json) =>
      HouseAttributes(
        number: _int(json, 'number'),
        title: _string(json, 'title'),
        domain: _string(json, 'domain'),
        keywords: _keywords(json),
      );
}

class PointAttributes {
  const PointAttributes({
    required this.name,
    required this.domain,
    required this.keywords,
  });

  /// Matches `ZodiacPosition.name` from `NatalChartEngine` exactly.
  final String name;
  final String domain;
  final List<String> keywords;

  factory PointAttributes.fromJson(Map<String, Object?> json) =>
      PointAttributes(
        name: _string(json, 'name'),
        domain: _string(json, 'domain'),
        keywords: _keywords(json),
      );
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('missing or empty "$key"');
  }
  return value.trim();
}

int _int(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('missing integer "$key"');
  return value;
}

/// Three to five, deliberately. Fewer reads thin under a card; more stops
/// being a glance and starts being prose, which is the other layer's job.
List<String> _keywords(Map<String, Object?> json) {
  final value = json['keywords'];
  if (value is! List || value.length < 3 || value.length > 5) {
    throw const FormatException('keywords must be a list of 3-5 entries');
  }
  return value.map((entry) {
    if (entry is! String || entry.trim().isEmpty) {
      throw const FormatException('keyword must be a non-empty string');
    }
    return entry.trim();
  }).toList(growable: false);
}
