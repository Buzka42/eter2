import 'package:drift/drift.dart' show Value;
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

  test('refreshes a replay-safe daily summary when body context is complete',
      () async {
    await _saveProfile(database);
    final service = HealthHubSyncService(
      database: database,
      gateway: _FakeGateway(samples: [
        _sample(HubMetric.activeEnergy, 12),
        _sample(HubMetric.steps, 30),
      ]),
    );

    final first = await service.sync(
      start: DateTime.utc(2026, 7, 28),
      end: DateTime.utc(2026, 7, 28, 12),
    );
    final second = await service.sync(
      start: DateTime.utc(2026, 7, 28),
      end: DateTime.utc(2026, 7, 28, 12),
    );
    final summary = await database.loadDaySummary('2026-07-28');

    expect(first.summariesUpdated, 1);
    expect(second.summariesUpdated, 1);
    expect(summary?.activeKcal, 12);
    expect(summary?.steps, 30);
    expect(summary?.basalKcal, greaterThan(0));
  });

  test('refreshes each imported day without treating today as a full day',
      () async {
    await _saveProfile(database);
    final service = HealthHubSyncService(
      database: database,
      gateway: _FakeGateway(samples: [
        _sampleAt(
          HubMetric.activeEnergy,
          20,
          DateTime.utc(2026, 7, 27, 10),
        ),
        _sampleAt(
          HubMetric.activeEnergy,
          10,
          DateTime.utc(2026, 7, 28, 10),
        ),
      ]),
    );

    final result = await service.sync(
      start: DateTime.utc(2026, 7, 27),
      end: DateTime.utc(2026, 7, 28, 12),
    );
    final yesterday = await database.loadDaySummary('2026-07-27');
    final today = await database.loadDaySummary('2026-07-28');

    expect(result.summariesUpdated, 2);
    expect(yesterday?.activeKcal, 20);
    expect(today?.activeKcal, 10);
    expect(yesterday!.basalKcal, greaterThan(today!.basalKcal));
  });

  test('does not fabricate basal totals when legacy height is missing',
      () async {
    await _saveProfile(database, includeHeight: false);
    final service = HealthHubSyncService(
      database: database,
      gateway: _FakeGateway(samples: [_sample(HubMetric.activeEnergy, 12)]),
    );

    final result = await service.sync(
      start: DateTime.utc(2026, 7, 28),
      end: DateTime.utc(2026, 7, 28, 12),
    );

    expect(result.summariesUpdated, 0);
    expect(await database.loadDaySummary('2026-07-28'), isNull);
  });

  test('marks a lower replayed activity total as recalibrated', () async {
    await _saveProfile(database);
    Future<void> sync(double activeEnergy) => HealthHubSyncService(
          database: database,
          gateway: _FakeGateway(
            samples: [_sample(HubMetric.activeEnergy, activeEnergy)],
          ),
        ).sync(
          start: DateTime.utc(2026, 7, 28),
          end: DateTime.utc(2026, 7, 28, 12),
        );

    await sync(30);
    await sync(10);
    final summary = await database.loadDaySummary('2026-07-28');

    expect(summary?.activeKcal, 10);
    expect(summary?.recalibrated, isTrue);
  });

  test('a night with stages does not also count its containing session',
      () async {
    // The real shape of a Garmin night as Health Connect stores it: the
    // session spans the whole sleep, and the stages break the same minutes
    // down. Counting both reported 8h21m of stages plus 8h25m of "unknown",
    // and doubled every average built on it.
    HubSample stage(String id, HubMetric metric, int fromMinute, int minutes) =>
        HubSample(
          id: id,
          metric: metric,
          start: DateTime.utc(2026, 7, 29, 0, 44).add(
            Duration(minutes: fromMinute),
          ),
          end: DateTime.utc(2026, 7, 29, 0, 44).add(
            Duration(minutes: fromMinute + minutes),
          ),
          value: minutes.toDouble(),
          source: 'Garmin',
        );

    final gateway = _FakeGateway(samples: [
      // The session: 00:44 to 09:09.
      stage('session', HubMetric.sleepUnknown, 0, 505),
      stage('light', HubMetric.sleepLight, 0, 296),
      stage('rem', HubMetric.sleepRem, 296, 165),
      stage('deep', HubMetric.sleepDeep, 461, 40),
      stage('awake', HubMetric.sleepAwake, 501, 4),
    ]);
    final service = HealthHubSyncService(database: database, gateway: gateway);
    await service.sync(
      start: DateTime.utc(2026, 7, 28),
      end: DateTime.utc(2026, 7, 30),
    );

    final sleep = await database.loadSleepForNights('2026-07-29', '2026-07-29');
    expect(
      sleep.map((row) => row.stage).toSet(),
      {'light', 'rem', 'deep', 'awake'},
      reason: 'the undifferentiated session must not survive beside stages',
    );
    final total = sleep.fold<int>(
      0,
      (sum, row) => sum + row.endUtc.difference(row.startUtc).inMinutes,
    );
    expect(total, 505);
  });

  test('a source that only reports a session still records the night',
      () async {
    // The other half of the same rule: a watch that says how long someone
    // slept and nothing more must not be discarded for lack of detail.
    final gateway = _FakeGateway(samples: [
      HubSample(
        id: 'session-only',
        metric: HubMetric.sleepUnknown,
        start: DateTime.utc(2026, 7, 29, 1),
        end: DateTime.utc(2026, 7, 29, 7),
        value: 360,
        source: 'Some watch',
      ),
    ]);
    final service = HealthHubSyncService(database: database, gateway: gateway);
    await service.sync(
      start: DateTime.utc(2026, 7, 28),
      end: DateTime.utc(2026, 7, 30),
    );

    final sleep = await database.loadSleepForNights('2026-07-29', '2026-07-29');
    expect(sleep, hasLength(1));
    expect(sleep.single.stage, 'unknown');
    expect(sleep.single.endUtc.difference(sleep.single.startUtc).inMinutes, 360);
  });

  test('a workout becomes a session, replayably', () async {
    // Every Garmin run used to arrive as minutes and never as a session,
    // because a workout carries a name rather than a number and the mapper
    // only understood numbers.
    final gateway = _FakeGateway(samples: [
      HubSample(
        id: 'run-1',
        metric: HubMetric.workout,
        start: DateTime.utc(2026, 7, 29, 6),
        end: DateTime.utc(2026, 7, 29, 6, 42),
        value: 410,
        source: 'Garmin',
        label: 'RUNNING',
      ),
    ]);
    final service = HealthHubSyncService(database: database, gateway: gateway);

    for (var i = 0; i < 2; i++) {
      await service.sync(
        start: DateTime.utc(2026, 7, 28),
        end: DateTime.utc(2026, 7, 30),
      );
    }

    final sessions = await database.loadSessions(
      DateTime.utc(2026, 7, 28),
      DateTime.utc(2026, 7, 30),
    );
    // Twice synced, once stored.
    expect(sessions, hasLength(1));
    expect(sessions.single.sport, 'RUNNING');
    expect(sessions.single.activeKcal, 410);
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

HubSample _sampleAt(HubMetric metric, double value, DateTime start) =>
    HubSample(
      id: '${metric.name}-$value-${start.toIso8601String()}',
      metric: metric,
      start: start,
      end: start.add(const Duration(minutes: 1)),
      value: value,
      source: 'Pixel Watch',
    );

Future<void> _saveProfile(
  AppDatabase database, {
  bool includeHeight = true,
}) =>
    database.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'female',
        weightKg: 65,
        heightCm: Value(includeHeight ? 168 : null),
        units: 'metric',
      ),
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

  @override
  Future<bool> requestWriteAccess() async => authorized;

  @override
  Future<bool> write({
    required HubWritable metric,
    required double value,
    required DateTime at,
    required String recordId,
    String? label,
  }) async =>
      throw UnsupportedError('reading must not write');
}
