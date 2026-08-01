import 'package:flutter/foundation.dart';

import '../arcana/symbol_content.dart';
import '../db/app_database.dart';
import '../i18n/language.dart';
import '../i18n/strings.dart';
import '../symbolic/natal_chart.dart';
import 'chart_reading.dart';
import 'reading_composer.dart';

/// Writes the chart's reading, once, as soon as there is a chart worth reading.
///
/// The natal chart does not change, so neither does the reading of it. It is
/// composed the moment a birth time is saved rather than on demand, because
/// there is no longer anything to demand it *with*: the Vessel used to carry a
/// `COMPOSE READINGS` button and the owner asked for it to go. A symbolic
/// surface that greets you with "not composed yet" and no way to change that
/// has failed at the moment it mattered.
///
/// Two conditions, and both are refusals rather than delays:
///
/// * **No birth time, no reading.** The angles are most of what makes a
///   configuration particular. A chart cast at noon would be read once and
///   cached for life against angles nobody has.
/// * **No consent or no transport, nothing written.** Best-effort throughout.
///   Onboarding is never delayed, saving a birth time never fails because the
///   model was unreachable, and the Vessel retries the next time it is opened.
class InitialVesselReadings {
  const InitialVesselReadings({
    required this.database,
    required this.provider,
  });

  final AppDatabase database;
  final VesselReadingProvider? provider;

  /// True when a reading was actually written.
  Future<bool> composeIfPossible({required DateTime now}) async {
    final transport = provider;
    if (transport == null) return false;
    final profile = await database.loadProfile();
    if (profile == null || profile.aiConsentAt == null) return false;
    if (!chartReadingHasBirthTime(profile)) return false;

    try {
      // The reading is written once and kept for life, so it has to be written
      // in the language actually in force — not whichever one the asset cache
      // happened to hold. Same resolution the shell uses, so the two cannot
      // disagree.
      final language = AppLanguage.forProfile(profile.language);
      final request = buildChartReadingRequest(
        profile: profile,
        strings: EterStrings.forLanguage(language),
        content: await SymbolContent.load(language: language),
      );
      if (request == null) return false;

      final result = await VesselReadingComposer(
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
        request: request,
        now: now,
      );
      return result.movements.isNotEmpty;
    } catch (error) {
      // Never blocking — but silence here once cost an afternoon: the Vessel
      // stayed empty and nothing anywhere said why. Best-effort is about not
      // blocking the user, not about being untraceable.
      debugPrint('The chart reading did not compose: $error');
      return false;
    }
  }
}
