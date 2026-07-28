import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/profile/birth_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late _Resolver resolver;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    resolver = _Resolver();
    await database.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 2),
        sex: 'other',
        weightKg: 70,
        heightCm: const Value(170),
        units: 'metric',
      ),
    );
  });

  tearDown(() => database.close());

  test('validates clock and offset formats without guessing', () {
    expect(BirthContextService.parseClockMinutes('07:35'), 455);
    expect(BirthContextService.parseUtcOffsetMinutes('-05:30'), -330);
    expect(
      () => BirthContextService.parseClockMinutes('25:00'),
      throwsA(isA<BirthContextException>()),
    );
    expect(
      () => BirthContextService.parseUtcOffsetMinutes('+14:30'),
      throwsA(isA<BirthContextException>()),
    );
  });

  test('resolves and saves a complete birth context atomically', () async {
    await BirthContextService(
      database: database,
      resolver: resolver,
    ).save(
      time: '06:45',
      utcOffset: '+01:00',
      place: 'Warsaw, Poland',
    );

    final profile = await database.loadProfile();
    expect(profile?.birthTimeMinutes, 405);
    expect(profile?.birthUtcOffsetMinutes, 60);
    expect(profile?.birthPlace, 'Warsaw, Poland');
    expect(profile?.birthLatitude, 52.2297);
    expect(profile?.birthLongitude, 21.0122);
    expect(resolver.queries, ['Warsaw, Poland']);
  });

  test('incomplete exact time and resolver failure change nothing', () async {
    await expectLater(
      BirthContextService(database: database, resolver: resolver).save(
        time: '06:45',
        utcOffset: '',
        place: 'Warsaw, Poland',
      ),
      throwsA(isA<BirthContextException>()),
    );
    resolver.fail = true;
    await expectLater(
      BirthContextService(database: database, resolver: resolver).save(
        time: '06:45',
        utcOffset: '+01:00',
        place: 'Unknown',
      ),
      throwsA(isA<BirthContextException>()),
    );

    final profile = await database.loadProfile();
    expect(profile?.birthTimeMinutes, isNull);
    expect(profile?.birthPlace, isNull);
  });

  test('changing chart inputs removes stale composed readings', () async {
    await database.saveVesselReading(
      VesselReadingsCompanion.insert(
        inputHash: 'old-chart',
        positionKey: 'sun',
        createdAt: DateTime.utc(2026, 7, 28),
        contentJson: '{"passage":"Old"}',
        model: 'test',
      ),
    );

    await BirthContextService(
      database: database,
      resolver: resolver,
    ).save(
      time: '06:45',
      utcOffset: '+01:00',
      place: 'Warsaw, Poland',
    );

    expect(
      await database.loadVesselReading(
        inputHash: 'old-chart',
        positionKey: 'sun',
      ),
      isNull,
    );
  });
}

class _Resolver implements BirthplaceResolver {
  bool fail = false;
  final queries = <String>[];

  @override
  Future<BirthplaceCoordinates> resolve(String place) async {
    queries.add(place);
    if (fail) throw StateError('offline');
    return const BirthplaceCoordinates(
      latitude: 52.2297,
      longitude: 21.0122,
    );
  }
}
