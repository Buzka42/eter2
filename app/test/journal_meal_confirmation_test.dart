import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Confirming food where it was written.
///
/// Reviewing a derived estimate used to be possible only in the Body, which is
/// the wrong place: by the time somebody is looking at a balance they have left
/// the page, and what they can still remember is what was on the plate.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> addMeal({
    required int journalEntryId,
    required double kcal,
    bool confirmed = false,
  }) async {
    await db.into(db.nutritionEntries).insert(
          NutritionEntriesCompanion.insert(
            recordedAt: DateTime.utc(2026, 8, 4, 12),
            meal: 'Afternoon snack',
            kcal: kcal,
            source: const Value('journal'),
            confirmed: Value(confirmed),
            metadataJson:
                Value(jsonEncode({'journalEntryId': journalEntryId})),
          ),
        );
    final rows = await db.loadNutritionForJournalEntry(journalEntryId);
    return rows.last.id;
  }

  test('a page owns the rows it produced, and no others', () async {
    await addMeal(journalEntryId: 1, kcal: 320);
    await addMeal(journalEntryId: 2, kcal: 500);

    final mine = await db.loadNutritionForJournalEntry(1);
    expect(mine, hasLength(1));
    expect(mine.single.kcal, 320);
  });

  test('confirming counts it toward the day', () async {
    final id = await addMeal(journalEntryId: 1, kcal: 320);
    final before = await db.loadNutritionForJournalEntry(1);
    expect(before.single.confirmed, isFalse);

    await db.confirmNutritionEntry(id);
    final after = await db.loadNutritionForJournalEntry(1);
    expect(after.single.confirmed, isTrue);
  });

  test('confirming twice is not an error and changes nothing', () async {
    final id = await addMeal(journalEntryId: 1, kcal: 320);
    await db.confirmNutritionEntry(id);
    await db.confirmNutritionEntry(id);
    final rows = await db.loadNutritionForJournalEntry(1);
    expect(rows, hasLength(1));
    expect(rows.single.confirmed, isTrue);
  });

  test('confirming a row that is gone does nothing', () async {
    final id = await addMeal(journalEntryId: 1, kcal: 320);
    await db.deleteNutritionEntry(id);
    await db.confirmNutritionEntry(id);
    expect(await db.loadNutritionForJournalEntry(1), isEmpty);
  });

  test('deleting from the Body removes it from the page too', () async {
    // One row, two surfaces. There is no second copy to fall out of step.
    final id = await addMeal(journalEntryId: 1, kcal: 320);
    await db.deleteNutritionEntry(id);
    expect(await db.loadNutritionForJournalEntry(1), isEmpty);
  });

  test('reverting the page takes its meals with it', () async {
    // The direction that already held, pinned so it keeps holding: deleting
    // from the Journal has always deleted from the Body.
    final entry = await db.into(db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            createdAt: DateTime.utc(2026, 8, 4, 11),
            entryText: 'A page about lunch.',
            status: const Value('classified'),
          ),
        );
    await addMeal(journalEntryId: entry, kcal: 420, confirmed: true);
    expect(await db.loadNutritionForJournalEntry(entry), hasLength(1));

    await db.revertJournalEntryRows(entry);
    expect(await db.loadNutritionForJournalEntry(entry), isEmpty);
  });
}
