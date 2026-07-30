import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/health/health_hub.dart';
import 'package:eter/core/health/write_back.dart';
import 'package:flutter_test/flutter_test.dart';

/// Writing Eter's own records into the platform's health store.
///
/// Almost all of this is about one rule. Only rows Eter *originated* go back;
/// anything read from the hub never does. Returning the platform's own data to it
/// under Eter's name survives one round trip and is then read back as a second,
/// independent measurement — so the day's intake would climb every time somebody
/// opened the app, forever, and the cause would be almost impossible to see.
void main() {
  late AppDatabase database;
  late _RecordingGateway gateway;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    gateway = _RecordingGateway();
  });
  tearDown(() => database.close());

  HealthWriteBack subject() =>
      HealthWriteBack(database: database, gateway: gateway);

  Future<void> weight(double kg, {required String source}) =>
      database.into(database.weightEntries).insert(
            WeightEntriesCompanion.insert(
              recordedAt: DateTime.utc(2026, 7, 30, 8),
              kg: kg,
              source: Value(source),
            ),
          );

  Future<void> meal(
    double kcal, {
    String source = 'manual',
    bool confirmed = true,
  }) =>
      database.into(database.nutritionEntries).insert(
            NutritionEntriesCompanion.insert(
              recordedAt: DateTime.utc(2026, 7, 30, 12),
              kcal: kcal,
              meal: 'lunch',
              source: Value(source),
              confirmed: Value(confirmed),
            ),
          );

  test('a typed weight is written back', () async {
    await weight(81.4, source: 'manual');
    expect(await subject().run(), 1);
    expect(gateway.written.single.value, 81.4);
    expect(gateway.written.single.metric, HubWritable.weight);
  });

  test('a weight read from the hub is never written back', () async {
    await weight(81.4, source: 'healthConnect:garmin');
    expect(await subject().run(), 0);
    expect(gateway.written, isEmpty);
  });

  test('every vendor behind the hub is still the hub', () async {
    // The source carries the contributing app, so the filter has to match on
    // the prefix rather than on a fixed set of strings it would have to keep up
    // with forever.
    await weight(80, source: 'healthConnect:samsung');
    await weight(79, source: 'appleHealth');
    expect(await subject().run(), 0);
    expect(gateway.written, isEmpty);
  });

  test('an unconfirmed estimate is not made official', () async {
    // A model's guess at a meal is excluded from Eter's own totals until
    // somebody confirms it. Writing it into Apple Health would be laundering it
    // into a fact by moving it somewhere more authoritative.
    await meal(600, confirmed: false);
    expect(await subject().run(), 0);
    expect(gateway.written, isEmpty);
  });

  test('a confirmed meal is written back', () async {
    await meal(600);
    expect(await subject().run(), 1);
    expect(gateway.written.single.metric, HubWritable.dietaryEnergy);
  });

  test('running twice writes nothing the second time', () async {
    await weight(81.4, source: 'manual');
    await meal(600);
    expect(await subject().run(), 2);
    expect(await subject().run(), 0);
    expect(gateway.written, hasLength(2));
  });

  test('a refused write is retried rather than marked done', () async {
    await weight(81.4, source: 'manual');
    gateway.accept = false;
    expect(await subject().run(), 0);

    final row = (await database.select(database.weightEntries).get()).single;
    expect(row.writtenBackAt, isNull);

    gateway.accept = true;
    expect(await subject().run(), 1);
  });

  test('no write permission means nothing is attempted', () async {
    await weight(81.4, source: 'manual');
    gateway.permitted = false;
    expect(await subject().run(), 0);
    expect(gateway.written, isEmpty);
  });

  test('each row carries a stable key, so a rewrite replaces it', () async {
    await weight(81.4, source: 'manual');
    await subject().run();
    // Health Connect deduplicates on `clientRecordId`. The row id is the natural
    // key and is the reason a repeat write cannot duplicate a record.
    expect(gateway.written.single.recordId, 'eter-weight-1');
  });
}

class _RecordingGateway implements HealthHubGateway {
  final List<_Written> written = [];
  bool permitted = true;
  bool accept = true;

  @override
  String get vendor => 'healthConnect';

  @override
  Future<bool> requestWriteAccess() async => permitted;

  @override
  Future<bool> write({
    required HubWritable metric,
    required double value,
    required DateTime at,
    required String recordId,
    String? label,
  }) async {
    if (!accept) return false;
    written.add(_Written(metric: metric, value: value, recordId: recordId));
    return true;
  }

  @override
  Future<bool> requestReadAccess() async =>
      throw UnsupportedError('writing must not read');

  @override
  Future<List<HubSample>> read(DateTime start, DateTime end) async =>
      throw UnsupportedError('writing must not read');
}

class _Written {
  const _Written({
    required this.metric,
    required this.value,
    required this.recordId,
  });

  final HubWritable metric;
  final double value;
  final String recordId;
}
