import 'package:drift/native.dart';
import 'package:eter/core/clock.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/lifestyle/daily_check_in.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LifestyleCheckInService service;

  final day = DateTime(2026, 7, 28);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = LifestyleCheckInService(db);
  });

  tearDown(() => db.close());

  Future<List<LifestyleEntryRow>> rowsFor(DateTime local) {
    final (start, end) = eterDayBounds(local);
    return db.loadLifestyleRange(start, end);
  }

  test('a reading is the day\'s answer and answering again corrects it',
      () async {
    await service.recordReading(
      reading: LifestyleReading.mood,
      value: 2,
      day: day,
      recordedAt: DateTime(2026, 7, 28, 9),
    );
    await service.recordReading(
      reading: LifestyleReading.mood,
      value: 4,
      day: day,
      recordedAt: DateTime(2026, 7, 28, 21),
    );

    final rows = await rowsFor(day);
    expect(rows, hasLength(1));
    expect(rows.single.kind, 'mood');
    expect(rows.single.value, 4);
  });

  test('correcting one reading leaves the day\'s other readings alone',
      () async {
    await service.recordReading(
      reading: LifestyleReading.stress,
      value: 2,
      day: day,
      recordedAt: DateTime(2026, 7, 28, 9),
    );
    await service.recordReading(
      reading: LifestyleReading.mood,
      value: 3,
      day: day,
      recordedAt: DateTime(2026, 7, 28, 10),
    );
    await service.recordReading(
      reading: LifestyleReading.mood,
      value: 5,
      day: day,
      recordedAt: DateTime(2026, 7, 28, 11),
    );

    final rows = await rowsFor(day);
    expect(rows.map((row) => row.kind).toSet(), {'stress', 'mood'});
    expect(rows.firstWhere((row) => row.kind == 'stress').value, 2);
    expect(rows.firstWhere((row) => row.kind == 'mood').value, 5);
  });

  test('yesterday\'s answer survives today\'s', () async {
    final yesterday = DateTime(2026, 7, 27);
    await service.recordReading(
      reading: LifestyleReading.recovery,
      value: 1,
      day: yesterday,
      recordedAt: DateTime(2026, 7, 27, 20),
    );
    await service.recordReading(
      reading: LifestyleReading.recovery,
      value: 5,
      day: day,
      recordedAt: DateTime(2026, 7, 28, 8),
    );

    expect((await rowsFor(yesterday)).single.value, 1);
    expect((await rowsFor(day)).single.value, 5);
  });

  test('practice sittings accumulate rather than replace', () async {
    await service.recordPractice(
      practice: LifestylePractice.meditation,
      minutes: 12,
      recordedAt: DateTime(2026, 7, 28, 7),
    );
    await service.recordPractice(
      practice: LifestylePractice.meditation,
      minutes: 20,
      recordedAt: DateTime(2026, 7, 28, 19),
    );

    final rows = await rowsFor(day);
    expect(rows, hasLength(2));
    expect(
      rows.fold<double>(0, (sum, row) => sum + (row.durationMinutes ?? 0)),
      32,
    );
  });

  test('an implausible check-in writes nothing', () async {
    await expectLater(
      service.recordReading(
        reading: LifestyleReading.mood,
        value: 9,
        day: day,
        recordedAt: DateTime(2026, 7, 28, 9),
      ),
      throwsA(isA<LifestyleCheckInException>()),
    );
    await expectLater(
      service.recordPractice(
        practice: LifestylePractice.breathwork,
        minutes: 0,
        recordedAt: DateTime(2026, 7, 28, 9),
      ),
      throwsA(isA<LifestyleCheckInException>()),
    );

    expect(await rowsFor(day), isEmpty);
  });

  test('a check-in can be taken back', () async {
    final id = await service.recordPractice(
      practice: LifestylePractice.breathwork,
      minutes: 6,
      recordedAt: DateTime(2026, 7, 28, 9),
    );

    await service.remove(id);

    expect(await rowsFor(day), isEmpty);
  });
}
