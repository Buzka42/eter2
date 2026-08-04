import 'dart:convert';

import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/features/dashboard/dashboard_page.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which composition of a day the Dashboard shows.
///
/// Found on a phone, not here. `AGAIN` in the Sanctum says it composes "the
/// whole day, not one section", and it does — four new rows every time. But
/// the surface put the new synthesis above the *old* health, mind and spirit,
/// because the map that collected the dimensions was a comprehension:
///
/// ```dart
/// {for (final row in rows) row.dimension: row}
/// ```
///
/// The rows arrive newest first and a later entry overwrites an earlier one,
/// so that map ended up holding the oldest composition of the day. Reading the
/// device's own database showed four rows at the new prompt version sitting
/// unread underneath three that were two versions old.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<void> compose({
    required String label,
    required DateTime at,
  }) async {
    for (final dimension in const ['synthesis', 'health', 'mind', 'spirit']) {
      await database.recordGuidance(
        GuidanceHistoryCompanion.insert(
          date: '2026-08-04',
          dimension: dimension,
          generatedAt: at,
          contentJson: jsonEncode({'passage': '$label $dimension'}),
          contextFingerprint: label,
          source: 'provider',
        ),
      );
    }
  }

  test('every dimension shows the newest composition of the day', () async {
    await compose(label: 'older', at: DateTime.utc(2026, 8, 4, 9));
    await compose(label: 'newer', at: DateTime.utc(2026, 8, 4, 20));

    // Exactly what the surface reads: the database's own ordering.
    final rows = await database.loadGuidanceForDate('2026-08-04');
    final newest = eterNewestByDimension(rows);

    for (final dimension in const ['synthesis', 'health', 'mind', 'spirit']) {
      expect(
        newest[dimension]!.contentJson,
        contains('newer $dimension'),
        reason: '$dimension is showing an older composition',
      );
    }
  });

  test('the synthesis and the three dimensions never disagree', () async {
    // The shape of the bug: the synthesis was selected by one rule and the
    // dimensions by another, so a recompose updated the top of the surface and
    // not the rest of it.
    await compose(label: 'older', at: DateTime.utc(2026, 8, 4, 9));
    await compose(label: 'newer', at: DateTime.utc(2026, 8, 4, 20));

    final rows = await database.loadGuidanceForDate('2026-08-04');
    final newest = eterNewestByDimension(rows);
    final synthesisTheOtherWay =
        rows.where((row) => row.dimension == 'synthesis').first;

    expect(newest['synthesis']!.id, synthesisTheOtherWay.id);
  });

  test('one composition is not disturbed by having only one', () async {
    await compose(label: 'only', at: DateTime.utc(2026, 8, 4, 9));
    final newest =
        eterNewestByDimension(await database.loadGuidanceForDate('2026-08-04'));
    expect(newest, hasLength(4));
  });

  test('an empty day selects nothing rather than throwing', () {
    expect(eterNewestByDimension(const []), isEmpty);
  });
}
