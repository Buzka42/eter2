import '../aether/guidance_mode.dart';
import '../arcana/major_arcana.dart';
import '../arcana/matrix.dart';
import '../arcana/symbol_content.dart';
import '../arcana/zodiac.dart';
import '../db/app_database.dart';
import '../i18n/strings.dart';
import '../profile/birth_time.dart';
import '../symbolic/natal_chart.dart';
import '../symbolic/numerology.dart';
import 'reading_composer.dart';

/// The bodies the reading covers beyond the Sun, Moon and Ascendant.
///
/// The engine's own English names; the reading's keys are these, lowercased.
const chartReadingBodies = <String>[
  'Mercury',
  'Venus',
  'Mars',
  'Jupiter',
  'Saturn',
  'Uranus',
  'Neptune',
];

/// Whether this profile has said when it was born.
///
/// An approximate time counts — a remembered part of the day is still a
/// statement about the angles — but noon is not a time somebody gave, and a
/// reading of a chart cast at noon would cache for life against angles nobody
/// has.
bool chartReadingHasBirthTime(ProfileRow profile) =>
    profile.birthTimeMinutes != null && profile.birthUtcOffsetMinutes != null;

/// The whole configuration, in the order a reader meets it, as one request.
///
/// One definition, used by the composer that runs when a birth time is saved
/// *and* by the Vessel's own retry, so the reading that gets cached is always
/// about the positions the Vessel lists. Two builders would drift, and the
/// symptom would be a reading that discusses a placement the screen never
/// shows.
///
/// Returns null when there is no birth time. Nothing is composed then — see
/// [chartReadingHasBirthTime].
VesselReadingRequest? buildChartReadingRequest({
  required ProfileRow profile,
  required EterStrings strings,
  required SymbolContent content,
}) {
  if (!chartReadingHasBirthTime(profile)) return null;

  final minutes = profile.birthTimeMinutes ?? 12 * 60;
  final chart = NatalChartEngine().calculate(NatalInput(
    localDateTime: DateTime(
      profile.dob.year,
      profile.dob.month,
      profile.dob.day,
      minutes ~/ 60,
      minutes % 60,
    ),
    utcOffsetMinutes: profile.birthUtcOffsetMinutes ?? 0,
    latitude: profile.birthLatitude ?? 0,
    longitude: profile.birthLongitude ?? 0,
  ));

  final lifePath = calculateLifePath(profile.dob);
  final lifeCard = MajorArcana.forLifePath(lifePath);
  final lifeContent = content.lifePath(lifePath);
  if (lifeContent == null) return null;

  VesselReadingPosition forSign(
    String key,
    String bodyCanonical,
    ZodiacPosition point,
  ) {
    final sign = Zodiac.values.firstWhere((value) => value.label == point.sign);
    final card = MajorArcana.forZodiac(sign);
    return VesselReadingPosition(
      key: key,
      label: strings.bodyName(bodyCanonical),
      card: strings.arcanaTitle(card.assetSlug),
      keywords: content.card(card)?.keywords ?? const [],
      detail: strings.positionDetail(
        signName: strings.signName(point.sign),
        degrees: point.degreeInSign.toStringAsFixed(1),
        retrograde: point.retrograde,
      ),
    );
  }

  final approximateTime = !BirthTimePrecision.fromName(
        profile.birthTimePrecision,
      ).supportsPreciseAngles ||
      profile.birthUtcOffsetMinutes == null;
  final approximatePlace =
      profile.birthLatitude == null || profile.birthLongitude == null;

  return VesselReadingRequest(
    mode: switch (profile.guidanceMode) {
      'grounded' => GuidanceMode.grounded,
      'immersive' => GuidanceMode.immersive,
      _ => GuidanceMode.balanced,
    },
    positions: [
      VesselReadingPosition(
        key: 'lifePath',
        label: strings.lifePathLabel(lifePath),
        card: strings.arcanaTitle(lifeCard.assetSlug),
        keywords: lifeContent.keywords,
      ),
      forSign('sun', 'Sun', chart.sun),
      forSign('moon', 'Moon', chart.moon),
      forSign('ascendant', 'Ascendant', chart.ascendant),
      // The figure. Its places are ordinary positions, so they compose and
      // cache exactly as the others do.
      for (final entry in buildArcanaMatrix(profile.dob).inReadingOrder)
        VesselReadingPosition(
          key: entry.position.key,
          label: strings.matrixPositionLabel(entry.position),
          card: strings.arcanaTitle(entry.card.assetSlug),
          keywords: content.card(entry.card)?.keywords ?? const [],
        ),
      // The rest of the chart. Separate menus once, one list now.
      for (final name in chartReadingBodies)
        for (final point in chart.positions.where((p) => p.name == name))
          forSign(name.toLowerCase(), name, point),
    ],
    approximateTime: approximateTime,
    approximatePlace: approximatePlace,
  );
}
