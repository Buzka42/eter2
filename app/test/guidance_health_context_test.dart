import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/aether/context_assembler.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Health that exists on the device has to reach the guidance request.
///
/// The Dashboard said movement and sleep were absent while the Body was
/// showing a resting heart rate and a week of sleep on the same screen. That
/// is either a broken assembler or a stale composition, and the two are worth
/// telling apart: one is a bug, the other is a cached answer that predates the
/// data. These tests remove the first possibility.
void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 3, 14),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
      heightCm: const Value(175),
      aiConsentAt: Value(DateTime.utc(2026, 7, 20)),
    ));
  });
  tearDown(() => database.close());

  final now = DateTime(2026, 7, 28, 20);

  Future<void> seedDay(
    int day, {
    int steps = 8000,
    double activeKcal = 420,
    double restingHr = 46,
    int sleepMinutes = 380,
  }) async {
    final date = '2026-07-${day.toString().padLeft(2, '0')}';
    await database.recordDayTotal(
      date: date,
      activeKcal: activeKcal,
      basalKcal: 1500,
      steps: steps,
      sessionsCount: 0,
    );
    await database.recordDailyVitals(
      DailyVitalsCompanion.insert(
        date: date,
        source: 'healthConnect',
        restingHr: Value(restingHr),
        hrvMs: const Value(62),
      ),
    );
    await database.replaceSleepForNight(
      nightOf: date,
      source: 'healthConnect',
      segments: [
        SleepSegmentsCompanion.insert(
          nightOf: date,
          stage: 'deep',
          startUtc: DateTime.utc(2026, 7, day, 1),
          endUtc: DateTime.utc(2026, 7, day, 1).add(
            Duration(minutes: sleepMinutes),
          ),
          source: 'healthConnect',
          priority: 3,
        ),
      ],
    );
  }

  test('a week of recorded days all reach the request', () async {
    for (var day = 22; day <= 28; day++) {
      await seedDay(day);
    }

    final request =
        await AetherContextAssembler(database: database).assemble(now: now);

    expect(request.health, hasLength(7));
    expect(request.health.first.steps, isNotNull);
    expect(request.health.first.restingHeartRate, 46);
    expect(request.health.first.sleepMinutes, 380);
  });

  test('health connected only today still travels', () async {
    // The case that prompted this: the hub was connected after the fact, so
    // there is exactly one day of records and six of nothing.
    await seedDay(28);

    final request =
        await AetherContextAssembler(database: database).assemble(now: now);

    expect(request.health, hasLength(1));
    expect(request.health.single.localDate, '2026-07-28');
    expect(request.health.single.restingHeartRate, 46);
    expect(request.health.single.sleepMinutes, 380);
  });

  test('days with nothing recorded are omitted, not zero-filled', () async {
    await seedDay(27);
    await seedDay(28);

    final request =
        await AetherContextAssembler(database: database).assemble(now: now);

    // A gap is information. Sending a zero would be a claim that someone took
    // no steps, which is a different and false statement.
    expect(request.health, hasLength(2));
    expect(
      request.health.map((day) => day.localDate),
      ['2026-07-27', '2026-07-28'],
    );
  });

  test('the payload the model receives actually carries the numbers',
      () async {
    await seedDay(28, steps: 9240, restingHr: 54, sleepMinutes: 407);

    final request =
        await AetherContextAssembler(database: database).assemble(now: now);
    final encoded = jsonEncode(request.toJson());

    expect(encoded, contains('9240'));
    expect(encoded, contains('54'));
    expect(encoded, contains('407'));
  });

  test('adding health changes the fingerprint, so nothing stays cached',
      () async {
    // This is what makes REFRESH able to notice. If the fingerprint did not
    // move when the records did, a composition written before the hub was
    // connected would be returned forever.
    final before =
        await AetherContextAssembler(database: database).assemble(now: now);

    await seedDay(28);
    final after =
        await AetherContextAssembler(database: database).assemble(now: now);

    expect(after.contextFingerprint, isNot(before.contextFingerprint));
  });

  test('sleep alone is enough to make a day worth sending', () async {
    // A watch that syncs sleep but no steps still has something to say.
    await database.replaceSleepForNight(
      nightOf: '2026-07-28',
      source: 'healthConnect',
      segments: [
        SleepSegmentsCompanion.insert(
          nightOf: '2026-07-28',
          stage: 'light',
          startUtc: DateTime.utc(2026, 7, 28, 1),
          endUtc: DateTime.utc(2026, 7, 28, 7),
          source: 'healthConnect',
          priority: 3,
        ),
      ],
    );

    final request =
        await AetherContextAssembler(database: database).assemble(now: now);

    expect(request.health, hasLength(1));
    expect(request.health.single.sleepMinutes, 360);
    expect(request.health.single.steps, isNull);
  });
}
