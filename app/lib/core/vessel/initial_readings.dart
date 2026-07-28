import 'package:flutter/foundation.dart';

import '../aether/guidance_mode.dart';
import '../arcana/major_arcana.dart';
import '../arcana/symbol_content.dart';
import '../arcana/zodiac.dart';
import '../db/app_database.dart';
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
      final content = await SymbolContent.load();
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
        String label,
        ZodiacPosition point,
      ) {
        final sign =
            Zodiac.values.firstWhere((value) => value.label == point.sign);
        final card = MajorArcana.forZodiac(sign);
        return VesselReadingPosition(
          key: key,
          label: label,
          card: card.title,
          keywords: content.card(card)?.keywords ?? const [],
          detail: '${point.sign} ${point.degreeInSign.toStringAsFixed(1)}°',
        );
      }

      final approximateTime = profile.birthTimeMinutes == null ||
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
              label: 'Life Path $lifePath',
              card: lifeCard.title,
              keywords: lifeContent.keywords,
            ),
            forSign('sun', 'Sun', chart.sun),
            forSign('moon', 'Moon', chart.moon),
            // An unreliable ascendant still gets a passage: the reliability
            // flags travel with the request and the prose is required to say
            // so. What it must never do is arrive silently certain.
            forSign('ascendant', 'Ascendant', chart.ascendant),
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
