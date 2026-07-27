import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';

/// The local `yyyy-MM-dd` day key the database contracts use.
String eterIsoDate(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';

/// Local start and end of the day containing [local].
(DateTime, DateTime) eterDayBounds(DateTime local) {
  final start = DateTime(local.year, local.month, local.day);
  return (start, start.add(const Duration(days: 1)));
}

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

    await db.recordDailyVitals(
      DailyVitalsCompanion.insert(
        date: today,
        source: 'fixture',
        restingHr: const Value(58),
        hrvMs: const Value(61),
      ),
    );

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
    }
  }
}
