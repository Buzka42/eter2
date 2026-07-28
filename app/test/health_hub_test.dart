import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/health/health_hub.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('permission denial records disconnected and imports no zeroes',
      () async {
    final service = HealthHubSyncService(
      database: database,
      gateway: _FakeGateway(authorized: false),
    );

    final result = await service.sync(
      start: DateTime.utc(2026, 7, 28),
      end: DateTime.utc(2026, 7, 29),
    );

    expect(result.authorized, isFalse);
    expect(
      await database.loadMinuteBuckets(
        DateTime.utc(2026, 7, 28),
        DateTime.utc(2026, 7, 29),
      ),
      isEmpty,
    );
    expect((await database.loadIntegration('healthConnect'))!.status,
        'disconnected');
  });

  test('maps energy, steps and heart rate into one canonical minute', () async {
    final gateway = _FakeGateway(samples: [
      _sample(HubMetric.activeEnergy, 12),
      _sample(HubMetric.steps, 30),
      _sample(HubMetric.heartRate, 120),
    ]);
    final service = HealthHubSyncService(database: database, gateway: gateway);

    await service.sync(
      start: DateTime.utc(2026, 7, 28, 10),
      end: DateTime.utc(2026, 7, 28, 11),
    );
    await database.recomputeMinuteWinners(
      DateTime.utc(2026, 7, 28, 10),
      DateTime.utc(2026, 7, 28, 11),
    );
    final rows = await database.loadMinuteBuckets(
      DateTime.utc(2026, 7, 28, 10),
      DateTime.utc(2026, 7, 28, 11),
    );

    expect(rows, hasLength(1));
    expect(rows.single.activeKcal, 12);
    expect(rows.single.steps, 30);
    expect(rows.single.avgHr, 120);
    expect(rows.single.winningSource, 'healthConnect:Pixel Watch');
  });

  test('sleep is replay-safe and belongs to the morning it ends', () async {
    final gateway = _FakeGateway(samples: [
      HubSample(
        id: 'sleep-1',
        metric: HubMetric.sleepDeep,
        start: DateTime.utc(2026, 7, 27, 23),
        end: DateTime.utc(2026, 7, 28, 1),
        value: 120,
        source: 'Pixel Watch',
      ),
    ]);
    final service = HealthHubSyncService(database: database, gateway: gateway);

    for (var i = 0; i < 2; i++) {
      await service.sync(
        start: DateTime.utc(2026, 7, 27),
        end: DateTime.utc(2026, 7, 29),
      );
    }
    final sleep = await database.loadSleepForNights('2026-07-28', '2026-07-28');

    expect(sleep, hasLength(1));
    expect(sleep.single.stage, 'deep');
    expect(sleep.single.externalId, 'sleep-1');
  });

  test('daily vitals average repeated measurements without inventing signals',
      () async {
    final gateway = _FakeGateway(samples: [
      _sample(HubMetric.restingHeartRate, 60),
      _sample(HubMetric.restingHeartRate, 64),
      _sample(HubMetric.hrv, 42),
    ]);
    final service = HealthHubSyncService(database: database, gateway: gateway);

    await service.sync(
      start: DateTime.utc(2026, 7, 28),
      end: DateTime.utc(2026, 7, 29),
    );
    final row =
        (await database.loadVitalsRange('2026-07-28', '2026-07-28')).single;

    expect(row.restingHr, 62);
    expect(row.hrvMs, 42);
    expect(row.respiratoryRate, isNull);
  });
}

HubSample _sample(HubMetric metric, double value) => HubSample(
      id: '${metric.name}-$value',
      metric: metric,
      start: DateTime.utc(2026, 7, 28, 10),
      end: DateTime.utc(2026, 7, 28, 10, 1),
      value: value,
      source: 'Pixel Watch',
    );

class _FakeGateway implements HealthHubGateway {
  _FakeGateway({
    this.authorized = true,
    this.samples = const [],
  });

  final bool authorized;
  final List<HubSample> samples;

  @override
  String get vendor => 'healthConnect';

  @override
  Future<List<HubSample>> read(DateTime start, DateTime end) async => samples;

  @override
  Future<bool> requestReadAccess() async => authorized;
}
