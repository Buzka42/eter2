import 'package:flutter/foundation.dart';

import '../aether/guidance_mode.dart';
import '../arcana/major_arcana.dart';
import '../arcana/matrix.dart';
import '../arcana/symbol_content.dart';
import '../arcana/zodiac.dart';
import '../profile/birth_time.dart';
import '../db/app_database.dart';
import '../i18n/language.dart';
import '../i18n/strings.dart';
import '../symbolic/natal_chart.dart';
import '../symbolic/numerology.dart';
import 'reading_composer.dart';

/// Writes the chart's readings once, when the account is created.
///
/// The natal chart does not change, so neither do the passages about it. They
/// are composed at intake rather than on demand so the Vessel is already whole
/// the first time it is opened — a symbolic surface that greets a new user with
/// four "not composed yet" lines has failed at exactly the moment it mattered.
///
/// Everything here is best-effort by design. No consent, no transport, no
/// birth date the engine accepts — all of them mean the same thing: nothing is
/// written, onboarding is not delayed, and the Vessel's explicit
/// `COMPOSE READINGS` remains exactly as it was.
class InitialVesselReadings {
  const InitialVesselReadings({
    required this.database,
    required this.provider,
  });

  final AppDatabase database;
  final VesselReadingProvider? provider;

  /// True when passages were actually written.
  Future<bool> composeIfPossible({required DateTime now}) async {
    final transport = provider;
    if (transport == null) return false;
    final profile = await database.loadProfile();
    if (profile == null || profile.aiConsentAt == null) return false;

    try {
      // The chart's passages are written once and cached for life, so they have
      // to be written in the language that is actually in force — not in
      // whichever one the asset cache happened to hold. Same resolution the
      // shell uses, so the two cannot disagree.
      final language = AppLanguage.forProfile(profile.language);
      final strings = EterStrings.forLanguage(language);
      final content = await SymbolContent.load(language: language);
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
      if (lifeContent == null) return false;

      VesselReadingPosition forSign(
        String key,
        String bodyCanonical,
        ZodiacPosition point,
      ) {
        final label = strings.bodyName(bodyCanonical);
        final sign =
            Zodiac.values.firstWhere((value) => value.label == point.sign);
        final card = MajorArcana.forZodiac(sign);
        return VesselReadingPosition(
          key: key,
          label: label,
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
          profile.birthTimeMinutes == null ||
          profile.birthUtcOffsetMinutes == null;
      final approximatePlace =
          profile.birthLatitude == null || profile.birthLongitude == null;

      await VesselReadingComposer(
        database: database,
        provider: transport,
      ).compose(
        inputHash: natalInputHash(
          dob: profile.dob,
          birthTimeMinutes: profile.birthTimeMinutes,
          birthTimePrecision: profile.birthTimePrecision,
          birthUtcOffsetMinutes: profile.birthUtcOffsetMinutes,
          birthLatitude: profile.birthLatitude,
          birthLongitude: profile.birthLongitude,
        ),
        request: VesselReadingRequest(
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
            // An unreliable ascendant still gets a passage: the reliability
            // flags travel with the request and the prose is required to say
            // so. What it must never do is arrive silently certain.
            forSign('ascendant', 'Ascendant', chart.ascendant),
            // The figure. Its positions are ordinary reading positions, so
            // they compose, cache and retire exactly as the others do — the
            // matrix needed no machinery of its own.
            for (final entry in buildArcanaMatrix(profile.dob).inReadingOrder)
              VesselReadingPosition(
                key: entry.position.key,
                label: entry.position.label,
                card: entry.card.title,
                keywords: content.card(entry.card)?.keywords ?? const [],
                detail: entry.position.detail,
              ),
          ],
          approximateTime: approximateTime,
          approximatePlace: approximatePlace,
        ),
        now: now,
      );
      return true;
    } catch (error) {
      // Intake is never blocked by the symbolic half failing — but silence
      // here once cost an afternoon: the Vessel stayed empty and nothing
      // anywhere said why. Best-effort is about not blocking the user, not
      // about being untraceable.
      debugPrint('Initial vessel readings did not compose: $error');
      return false;
    }
  }
}
