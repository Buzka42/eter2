import 'dart:convert';

import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/patterns/local_pattern_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  Future<void> addNight({
    required DateTime morning,
    required int sleepingMinutes,
    required bool lateActivity,
  }) async {
    final nightOf = _date(morning);
    final start = DateTime.utc(
      morning.year,
      morning.month,
      morning.day - 1,
      22,
    );
    await database.replaceSleepForNight(
      nightOf: nightOf,
      source: 'hub',
      segments: [
        SleepSegmentsCompanion.insert(
          startUtc: start,
          endUtc: start.add(Duration(minutes: sleepingMinutes)),
          stage: 'unknown',
          source: 'hub',
          priority: 4,
          nightOf: nightOf,
        ),
      ],
    );
    if (lateActivity) {
      final sessionStart = DateTime.utc(
        morning.year,
        morning.month,
        morning.day - 1,
        20,
      );
      await database.upsertActivitySession(
        ActivitySessionsCompanion.insert(
          id: 'late-$nightOf',
          startUtc: sessionStart,
          endUtc: sessionStart.add(const Duration(minutes: 45)),
          source: 'manual',
          priority: 2,
        ),
      );
    }
  }

  test('discovers an inspectable non-causal late-activity correlation',
      () async {
    for (var offset = 1; offset <= 6; offset++) {
      await addNight(
        morning: DateTime(2026, 7, 29).subtract(Duration(days: offset)),
        sleepingMinutes: offset <= 3 ? 360 : 450,
        lateActivity: offset <= 3,
      );
    }

    final result = await LocalPatternDiscovery(database).review(
      now: DateTime(2026, 7, 29, 12),
    );
    final rows = await database.loadActivePatterns();
    final evidence =
        jsonDecode(rows.single.evidenceJson) as Map<String, dynamic>;

    expect(result.activePatterns, 1);
    expect(result.observations, 6);
    expect(rows.single.summary, contains('shorter after late activity'));
    expect(evidence['n'], 6);
    expect(evidence['coefficient'], -90);
    expect(evidence['caveat'], 'correlation, not cause');
  });

  test('a review never revives a pattern the user dismissed', () async {
    for (var offset = 1; offset <= 6; offset++) {
      await addNight(
        morning: DateTime(2026, 7, 29).subtract(Duration(days: offset)),
        sleepingMinutes: offset <= 3 ? 360 : 450,
        lateActivity: offset <= 3,
      );
    }
    final discovery = LocalPatternDiscovery(database);
    await discovery.review(now: DateTime(2026, 7, 29, 12));
    await database.dismissPattern(
      LocalPatternDiscovery.sleepAfterLateActivityKey,
    );

    final result = await discovery.review(now: DateTime(2026, 7, 29, 13));

    expect(result.activePatterns, 0);
    expect(await database.loadActivePatterns(), isEmpty);
  });

  test('weak or sparse evidence does not leave an active pattern', () async {
    await database.upsertPattern(
      PatternCandidatesCompanion.insert(
        key: LocalPatternDiscovery.sleepAfterLateActivityKey,
        computedAt: DateTime.utc(2026, 7, 1),
        summary: 'Stale pattern',
        evidenceJson: '{}',
        confidence: .5,
      ),
    );
    await addNight(
      morning: DateTime(2026, 7, 28),
      sleepingMinutes: 420,
      lateActivity: true,
    );

    final result = await LocalPatternDiscovery(database).review(
      now: DateTime(2026, 7, 29, 12),
    );

    expect(result.activePatterns, 0);
    expect(await database.loadActivePatterns(), isEmpty);
  });
}

String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
