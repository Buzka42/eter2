import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:eter/core/health/record_error.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/health/manual_weight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'other',
        weightKg: 70,
        heightCm: const Value(175),
        units: 'metric',
      ),
    );
  });

  tearDown(() => db.close());

  test('manual weight updates history and current profile atomically',
      () async {
    final at = DateTime(2026, 7, 28, 8);

    await ManualWeightService(db).record(kg: 71.4, recordedAt: at);

    final rows = await db.watchWeightEntries().first;
    final profile = await db.loadProfile();
    expect(rows, hasLength(1));
    expect(rows.single.kg, 71.4);
    expect(rows.single.source, 'manual');
    expect(rows.single.recordedAt, at.toUtc());
    expect(profile?.weightKg, 71.4);
  });

  test('implausible manual weight changes nothing', () async {
    expect(
      () => ManualWeightService(db).record(kg: 10),
      // Its own type, not a bare FormatException: the caller that reports this
      // has to tell a rejected weight from a malformed payload.
      throwsA(isA<ManualWeightException>().having(
        (error) => error.error,
        'error',
        BodyRecordError.weightRange,
      )),
    );

    expect(await db.watchWeightEntries().first, isEmpty);
    expect((await db.loadProfile())?.weightKg, 70);
  });
}
