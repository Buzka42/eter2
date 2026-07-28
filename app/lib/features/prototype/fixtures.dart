import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/db/app_database.dart';
import '../../core/energy/energy.dart' as energy;
import '../../core/arcana/major_arcana.dart';
import '../../core/symbolic/numerology.dart';

/// Fixture content for the defining prototype.
///
/// The Aether pipeline, the health hub and onboarding are not built yet; the
/// brief's answer is to read the table the data will land in and render
/// fixtures against the real contracts. Seeding is idempotent and only fills
/// empty tables, so a real pipeline outgrows it without a migration.
abstract final class PrototypeFixtures {
  static const profileLatitude = 51.5072;
  static const profileLongitude = -0.1276;

  static Future<void> seedIfEmpty(AppDatabase db, DateTime now) async {
    await _seedProfile(db);
    await _seedGuidance(db, now);
    await _seedBody(db, now);
    await _seedVessel(db, now);
  }

  static Future<void> _seedProfile(AppDatabase db) async {
    if (await db.loadProfile() != null) return;
    await db.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime.utc(1990, 4, 12),
        sex: 'other',
        weightKg: 71,
        units: 'metric',
        guidanceMode: const Value('balanced'),
        startSurface: const Value('dashboard'),
        birthPlace: const Value('London'),
        birthLatitude: const Value(profileLatitude),
        birthLongitude: const Value(profileLongitude),
      ),
    );
  }

  static Future<void> _seedGuidance(AppDatabase db, DateTime now) async {
    final today = eterIsoDate(now);
    if ((await db.loadGuidanceForDate(today)).isNotEmpty) return;
    await db.recordGuidance(
      GuidanceHistoryCompanion.insert(
        date: today,
        dimension: 'synthesis',
        generatedAt: now,
        // The content contract the pipeline will write: a primary passage and
        // an optional supporting one. Parse defensively — see DashboardPage.
        contentJson: jsonEncode(const {
          'passage':
              'Begin gently. Your body is asking for steadiness, not intensity.',
          'supporting':
              'A short walk after lunch may restore more than another hard effort.',
        }),
        contextFingerprint: 'prototype-fixture',
        source: 'local',
      ),
    );
    const dimensions = {
      'health':
          'Your recovery signals favour steadiness today. Choose movement that leaves some energy behind.',
      'mind':
          'Attention may come more easily in one protected stretch than through repeated small demands.',
      'spirit':
          'Let restraint be an active choice rather than an absence. A quieter pace can still be deliberate.',
    };
    for (final entry in dimensions.entries) {
      await db.recordGuidance(
        GuidanceHistoryCompanion.insert(
          date: today,
          dimension: entry.key,
          generatedAt: now,
          contentJson: jsonEncode({'passage': entry.value}),
          evidenceJson: entry.key == 'health'
              ? const Value(
                  '{"n":14,"window":"14 days","coefficient":0.42,'
                  '"note":"Resting heart rate and reported energy moved '
                  'together in this window."}',
                )
              : const Value.absent(),
          contextFingerprint: 'prototype-fixture-${entry.key}',
          source: 'local',
        ),
      );
    }
  }

  static Future<void> _seedBody(AppDatabase db, DateTime now) async {
    final today = eterIsoDate(now);
    final (dayStart, dayEnd) = eterDayBounds(now);

    if (await db.loadDaySummary(today) == null) {
      await db.recordDayTotal(
        date: today,
        activeKcal: 430,
        basalKcal: 1440,
        steps: 6230,
        sessionsCount: 0,
      );
    }

    if ((await db.loadMinuteBuckets(dayStart, dayEnd)).isEmpty) {
      const hourlyKcal = <double>[
        0,
        0,
        0,
        0,
        0,
        0,
        4,
        12,
        18,
        15,
        11,
        16,
        24,
        19,
        13,
        9,
        21,
        38,
        96,
        72,
        34,
        18,
        7,
        3,
      ];
      await db.ingestRawBuckets([
        for (var hour = 0; hour < 24; hour++)
          if (hourlyKcal[hour] > 0)
            energy.MinuteBucket(
              minuteUtc: dayStart.add(Duration(hours: hour)).toUtc(),
              activeKcal: hourlyKcal[hour],
              sourceId: 'fixture-hub',
              priority: energy.SourcePriority.hub,
              steps: (hourlyKcal[hour] * 12).round(),
            ),
      ]);
      await db.recomputeMinuteWinners(dayStart, dayEnd);
    }

    await db.recordDailyVitals(
      DailyVitalsCompanion.insert(
        date: today,
        source: 'fixture',
        restingHr: const Value(58),
        hrvMs: const Value(61),
      ),
    );

    final historyStart = now.subtract(const Duration(days: 13));
    final existingVitals = await db.loadVitalsRange(
      eterIsoDate(historyStart),
      today,
    );
    if (existingVitals.length <= 1) {
      for (var offset = 13; offset >= 1; offset--) {
        final day = now.subtract(Duration(days: offset));
        final wave = (offset % 5) - 2;
        await db.recordDailyVitals(
          DailyVitalsCompanion.insert(
            date: eterIsoDate(day),
            source: 'fixture',
            restingHr: Value(59 + wave * 0.8),
            hrvMs: Value(58 - wave * 2.1),
          ),
        );
      }
    }

    if ((await db.watchSleepForNight(today).first).isEmpty) {
      final sleepStart = DateTime.utc(2026, 7, 26, 22, 40);
      var cursor = sleepStart;
      final stages = <SleepSegmentsCompanion>[];
      for (final (stage, minutes) in const [
        ('light', 95),
        ('deep', 78),
        ('rem', 64),
        ('light', 142),
        ('awake', 18),
        ('rem', 51),
      ]) {
        final end = cursor.add(Duration(minutes: minutes));
        stages.add(
          SleepSegmentsCompanion.insert(
            startUtc: cursor,
            endUtc: end,
            stage: stage,
            source: 'fixture',
            priority: 1,
            nightOf: today,
          ),
        );
        cursor = end;
      }
      await db.replaceSleepForNight(
        nightOf: today,
        source: 'fixture',
        segments: stages,
      );
    }

    final sleepHistory = await db.loadSleepForNights(
      eterIsoDate(now.subtract(const Duration(days: 6))),
      today,
    );
    if ({for (final row in sleepHistory) row.nightOf}.length < 7) {
      for (var offset = 6; offset >= 1; offset--) {
        final night = now.subtract(Duration(days: offset));
        final nightOf = eterIsoDate(night);
        if (sleepHistory.any((row) => row.nightOf == nightOf)) continue;
        var cursor = DateTime.utc(
          night.year,
          night.month,
          night.day - 1,
          22,
          30 + offset,
        );
        final stages = <SleepSegmentsCompanion>[];
        for (final (stage, baseMinutes) in const [
          ('light', 102),
          ('deep', 72),
          ('rem', 61),
          ('light', 138),
          ('awake', 14),
          ('rem', 48),
        ]) {
          final minutes = baseMinutes + ((offset % 3) - 1) * 6;
          final end = cursor.add(Duration(minutes: minutes));
          stages.add(
            SleepSegmentsCompanion.insert(
              startUtc: cursor,
              endUtc: end,
              stage: stage,
              source: 'fixture',
              priority: 1,
              nightOf: nightOf,
            ),
          );
          cursor = end;
        }
        await db.replaceSleepForNight(
          nightOf: nightOf,
          source: 'fixture',
          segments: stages,
        );
      }
    }

    if ((await db.watchWeightEntries(limit: 30).first).isEmpty) {
      for (var offset = 28; offset >= 0; offset -= 4) {
        await db.addWeightEntry(
          kg: 71.8 - (28 - offset) * 0.018,
          source: 'fixture',
          recordedAt: now.subtract(Duration(days: offset)),
        );
      }
    }

    final existing = await db.watchNutritionForRange(dayStart, dayEnd).first;
    if (existing.isEmpty) {
      await db.addNutritionEntry(
        NutritionEntriesCompanion.insert(
          recordedAt: dayStart.add(const Duration(hours: 12, minutes: 40)),
          kcal: 1610,
          meal: 'The day’s meals',
          proteinG: const Value(88),
          carbsG: const Value(142),
          fatG: const Value(61),
        ),
      );
      await db.addNutritionEntry(
        NutritionEntriesCompanion.insert(
          recordedAt: dayStart.add(const Duration(hours: 15, minutes: 20)),
          kcal: 320,
          meal: 'Afternoon snack estimate',
          source: const Value('aether-estimate'),
          metadataJson: const Value('{"confidence":0.61}'),
          confirmed: const Value(false),
        ),
      );
    }
  }

  static Future<void> _seedVessel(AppDatabase db, DateTime now) async {
    final profile = await db.loadProfile();
    if (profile == null) return;
    final today = eterIsoDate(now);
    if (await db.loadDailyCard(today) == null) {
      final personalYear = calculatePersonalYear(profile.dob, now);
      final card = MajorArcana.forLifePath(personalYear);
      await db.recordDailyCard(
        DailyCardsCompanion.insert(
          date: today,
          arcanaSlug: card.assetSlug,
          reason: '${card.title} corresponds to personal year $personalYear, '
              'the deterministic cycle active for this date.',
          sourceJson: Value(
            jsonEncode({
              'selector': 'personalYear',
              'personalYear': personalYear,
              'dob': profile.dob.toIso8601String(),
              'date': today,
            }),
          ),
        ),
      );
    }

    final inputHash = [
      profile.dob.toIso8601String(),
      profile.birthTimeMinutes ?? 'unknown-time',
      profile.birthUtcOffsetMinutes ?? 'unknown-offset',
      profile.birthLatitude ?? 'unknown-latitude',
      profile.birthLongitude ?? 'unknown-longitude',
    ].join('|');
    if (await db.loadVesselReading(
          inputHash: inputHash,
          positionKey: 'lifePath',
        ) ==
        null) {
      final lifePath = calculateLifePath(profile.dob);
      await db.saveVesselReading(
        VesselReadingsCompanion.insert(
          inputHash: inputHash,
          positionKey: 'lifePath',
          createdAt: now,
          contentJson: jsonEncode({
            'passage': 'Life Path $lifePath describes the way persistence and '
                'adaptation may become a recurring personal theme. It is '
                'a reflective lens, not a prediction or instruction.',
          }),
          model: 'fixture',
        ),
      );
    }
  }
}
