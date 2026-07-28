import 'dart:convert';

import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/retrospectives/local_weekly_retrospective.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('prepares a factual complete-week review from canonical records',
      () async {
    for (var offset = 1; offset <= 7; offset++) {
      final day = DateTime(2026, 7, 29).subtract(Duration(days: offset));
      final date = _date(day);
      await database.recordDayTotal(
        date: date,
        activeKcal: 200 + offset * 10,
        basalKcal: 1500,
        steps: 6000 + offset * 100,
        sessionsCount: 1,
      );
    }
    await database.addJournalEntry(
      JournalEntriesCompanion.insert(
        createdAt: DateTime.utc(2026, 7, 27, 9),
        entryText: 'A private reflection.',
      ),
    );

    final result = await LocalWeeklyRetrospective(database).prepare(
      now: DateTime(2026, 7, 29, 12),
    );
    final rows = await database.loadRetrospectives();
    final content = jsonDecode(rows.single.contentJson) as Map<String, dynamic>;
    final evidence =
        jsonDecode(rows.single.evidenceJson!) as Map<String, dynamic>;

    expect(result?.id, 'weekly-2026-07-28');
    expect(rows.single.model, 'local-factual-v1');
    expect(content['headline'], 'Your seven-day view');
    expect(
      (content['passages'] as List).join(' '),
      allOf(contains('averaging 240 active kcal'), contains('1 journal entry')),
    );
    expect(content['caveat'], contains('not treated as zero'));
    expect(evidence['daySummaryN'], 7);
    expect(evidence['journalEntryN'], 1);
  });

  test('re-preparing the same window updates one cached review', () async {
    await database.recordDayTotal(
      date: '2026-07-28',
      activeKcal: 250,
      basalKcal: 1500,
      steps: 7000,
      sessionsCount: 1,
    );
    final builder = LocalWeeklyRetrospective(database);
    await builder.prepare(now: DateTime(2026, 7, 29, 10));
    await builder.prepare(now: DateTime(2026, 7, 29, 11));

    final rows = await database.loadRetrospectives();
    expect(rows, hasLength(1));
    expect(rows.single.generatedAt, DateTime(2026, 7, 29, 11).toUtc());
  });

  test('writes nothing when the complete window has no local history',
      () async {
    final result = await LocalWeeklyRetrospective(database).prepare(
      now: DateTime(2026, 7, 29, 12),
    );

    expect(result, isNull);
    expect(await database.loadRetrospectives(), isEmpty);
  });
}

String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
