import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/profile/birth_context.dart';
import 'package:eter/core/profile/birth_time.dart';
import 'package:eter/core/symbolic/natal_chart.dart';
import 'package:flutter_test/flutter_test.dart';

/// Three answers about the birth time, and the consequences of each.
///
/// The one that matters: a remembered part of the day produces a real chart
/// with a real ascendant, and every surface still has to treat that ascendant
/// as provisional. A stored minute is not the same as a known minute.
void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 3, 14),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
    ));
  });
  tearDown(() => database.close());

  BirthContextService service() => BirthContextService(
        database: database,
        resolver: _FixedResolver(),
      );

  group('what each answer stores', () {
    test('an exact time is stored to the minute', () async {
      await service().save(
        time: '06:45',
        utcOffset: '+01:00',
        place: 'Warsaw',
        precision: BirthTimePrecision.exact,
      );
      final profile = (await database.loadProfile())!;
      expect(profile.birthTimeMinutes, 6 * 60 + 45);
      expect(profile.birthTimePrecision, 'exact');
    });

    test('a remembered period stores the middle of its window', () async {
      await service().save(
        time: '',
        utcOffset: '+01:00',
        place: 'Warsaw',
        precision: BirthTimePrecision.approximate,
        period: BirthTimePeriod.morning,
      );
      final profile = (await database.loadProfile())!;
      expect(
        profile.birthTimeMinutes,
        BirthTimePeriod.morning.representativeMinutes,
      );
      expect(profile.birthTimePrecision, 'approximate');
    });

    test('the typed time is ignored when a period was chosen', () async {
      // The two can never disagree, because only one of them is read.
      await service().save(
        time: '23:59',
        utcOffset: '+01:00',
        place: 'Warsaw',
        precision: BirthTimePrecision.approximate,
        period: BirthTimePeriod.afternoon,
      );
      expect(
        (await database.loadProfile())!.birthTimeMinutes,
        BirthTimePeriod.afternoon.representativeMinutes,
      );
    });

    test('an unknown time stores nothing, whatever was typed', () async {
      await service().save(
        time: '06:45',
        utcOffset: '+01:00',
        place: 'Warsaw',
        precision: BirthTimePrecision.unknown,
      );
      final profile = (await database.loadProfile())!;
      expect(profile.birthTimeMinutes, isNull);
      expect(profile.birthTimePrecision, 'unknown');
    });

    test('choosing "roughly" without a period is refused', () async {
      await expectLater(
        service().save(
          time: '',
          utcOffset: '+01:00',
          place: 'Warsaw',
          precision: BirthTimePrecision.approximate,
        ),
        throwsA(isA<BirthContextException>()),
      );
    });
  });

  group('what each answer means downstream', () {
    test('only an exact time earns an angle stated plainly', () {
      expect(BirthTimePrecision.exact.supportsPreciseAngles, isTrue);
      expect(BirthTimePrecision.approximate.supportsPreciseAngles, isFalse);
      expect(BirthTimePrecision.unknown.supportsPreciseAngles, isFalse);
    });

    test('a stored minute is not the same as a known minute', () async {
      // The trap this whole feature had to avoid: an approximate time puts a
      // number in birthTimeMinutes, and anything checking "is it null" would
      // conclude the time is known.
      await service().save(
        time: '',
        utcOffset: '+01:00',
        place: 'Warsaw',
        precision: BirthTimePrecision.approximate,
        period: BirthTimePeriod.night,
      );
      final profile = (await database.loadProfile())!;
      expect(profile.birthTimeMinutes, isNotNull);
      expect(
        BirthTimePrecision.fromName(profile.birthTimePrecision)
            .supportsPreciseAngles,
        isFalse,
      );
    });

    test('precision changes the chart key, so readings are recomposed',
        () async {
      String hashFor(String precision) => natalInputHash(
            dob: DateTime(1990, 3, 14),
            birthTimeMinutes: 570,
            birthTimePrecision: precision,
            birthLatitude: 52.23,
            birthLongitude: 21.01,
          );
      // The same minute, differently known, is a different claim — and a
      // reading written under one must not be shown under the other.
      expect(hashFor('exact'), isNot(hashFor('approximate')));
    });

    test('an approximate time still produces a usable chart', () {
      final chart = NatalChartEngine().calculate(NatalInput(
        localDateTime: DateTime(
          1990,
          3,
          14,
          BirthTimePeriod.morning.representativeMinutes ~/ 60,
          BirthTimePeriod.morning.representativeMinutes % 60,
        ),
        utcOffsetMinutes: 60,
        latitude: 52.23,
        longitude: 21.01,
      ));
      // Provisional is not the same as absent: there is a real ascendant here
      // and the Vessel should show it, hedged.
      expect(chart.ascendant.sign, isNotEmpty);
      expect(chart.houseCusps, hasLength(12));
    });
  });

  group('the periods themselves', () {
    test('every period is a real window with a centre inside it', () {
      for (final period in BirthTimePeriod.values) {
        expect(period.windowMinutes, greaterThan(0), reason: period.name);
        expect(period.representativeMinutes, greaterThanOrEqualTo(0));
        expect(period.representativeMinutes, lessThan(24 * 60));
        expect(period.label, isNotEmpty);
        expect(period.detail, isNotEmpty);
      }
    });

    test('no two periods share a representative minute', () {
      final minutes =
          BirthTimePeriod.values.map((p) => p.representativeMinutes).toSet();
      // Otherwise the Sanctum could not tell which one was chosen last time.
      expect(minutes, hasLength(BirthTimePeriod.values.length));
    });

    test('a stored period is recognised when the editor reopens', () {
      for (final period in BirthTimePeriod.values) {
        expect(
          BirthTimePeriod.forMinutes(period.representativeMinutes),
          period,
        );
      }
      expect(BirthTimePeriod.forMinutes(null), isNull);
      expect(BirthTimePeriod.forMinutes(407), isNull);
    });
  });
}

class _FixedResolver implements BirthplaceResolver {
  @override
  Future<BirthplaceCoordinates> resolve(String place) async =>
      const BirthplaceCoordinates(latitude: 52.23, longitude: 21.01);
}
