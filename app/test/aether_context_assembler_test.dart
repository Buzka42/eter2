import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/aether/context_assembler.dart';
import 'package:eter/core/aether/request_contract.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/energy/energy.dart' as energy;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  final now = DateTime(2026, 7, 28, 12);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime(1990, 8, 2),
        sex: 'other',
        weightKg: 70,
        units: 'metric',
        firstName: const Value('Private name'),
        birthPlace: const Value('Private place'),
        birthLatitude: const Value(51.5),
        birthLongitude: const Value(-0.1),
      ),
    );
  });
  tearDown(() => database.close());

  test('refuses to assemble before current AI consent', () async {
    await expectLater(
      AetherContextAssembler(database: database).assemble(now: now),
      throwsA(isA<AetherConsentException>()),
    );
  });

  test('assembles real bounded signals without profile identity', () async {
    await database.updateProfileConsents(aiAllowed: true);
    await database.recordDayTotal(
      date: '2026-07-28',
      activeKcal: 420,
      basalKcal: 1100,
      steps: 7600,
      sessionsCount: 1,
    );
    await database.recordDailyVitals(
      DailyVitalsCompanion.insert(
        date: '2026-07-28',
        restingHr: const Value(59),
        hrvMs: const Value(44),
        source: 'healthConnect',
      ),
    );
    await database.replaceSleepForNight(
      nightOf: '2026-07-28',
      source: 'healthConnect',
      segments: [
        SleepSegmentsCompanion.insert(
          startUtc: DateTime.utc(2026, 7, 27, 22),
          endUtc: DateTime.utc(2026, 7, 28, 6),
          stage: 'unknown',
          source: 'healthConnect',
          priority: energy.SourcePriority.hub.index,
          nightOf: '2026-07-28',
        ),
      ],
    );

    final request =
        await AetherContextAssembler(database: database).assemble(now: now);
    final encoded = jsonEncode(request.toJson());

    expect(request.ageYears, 35);
    expect(request.health.single.steps, 7600);
    expect(request.health.single.sleepMinutes, 480);
    expect(encoded, isNot(contains('Private name')));
    expect(encoded, isNot(contains('Private place')));
    expect(encoded, isNot(contains('51.5')));
    expect(encoded, isNot(contains('1990-08-02')));
    expect(encoded, isNot(contains('healthConnect')));
  });

  test('journal prose requires its consent and respects entry exclusion',
      () async {
    await database.updateProfileConsents(aiAllowed: true);
    for (final entry in [
      ('Allowed reflection', false),
      ('Withheld reflection', true),
    ]) {
      await database.addJournalEntry(
        JournalEntriesCompanion.insert(
          createdAt: DateTime.utc(2026, 7, 28, 9),
          entryText: entry.$1,
          excludedFromAi: Value(entry.$2),
        ),
      );
    }
    final assembler = AetherContextAssembler(database: database);

    expect((await assembler.assemble(now: now)).journal, isEmpty);

    await database.updateProfileConsents(journalAiAllowed: true);
    final request = await assembler.assemble(now: now);
    final encoded = jsonEncode(request.toJson());
    expect(encoded, contains('Allowed reflection'));
    expect(encoded, isNot(contains('Withheld reflection')));
  });

  test('window excludes older health and journal records', () async {
    await database.updateProfileConsents(journalAiAllowed: true);
    await database.recordDayTotal(
      date: '2026-07-20',
      activeKcal: 999,
      basalKcal: 1000,
      steps: 99999,
      sessionsCount: 0,
    );
    await database.addJournalEntry(
      JournalEntriesCompanion.insert(
        createdAt: DateTime.utc(2026, 7, 20),
        entryText: 'Old prose',
      ),
    );

    final request =
        await AetherContextAssembler(database: database).assemble(now: now);
    expect(request.health, isEmpty);
    expect(request.journal, isEmpty);
  });
}
