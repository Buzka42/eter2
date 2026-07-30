import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/health/foreground_refresh.dart';
import 'package:eter/core/health/health_hub.dart';
import 'package:flutter_test/flutter_test.dart';

/// A hub that records how often it was asked and answers with one minute of
/// movement, so a refresh is observable without a platform channel.
class _RecordingGateway implements HealthHubGateway {
  _RecordingGateway({this.authorized = true});

  final bool authorized;
  int reads = 0;

  @override
  String get vendor => 'test-hub';

  @override
  Future<bool> requestReadAccess() async => authorized;

  // Refreshing never writes; a resume that added to somebody's health record
  // would be doing something they did not ask for.
  @override
  Future<bool> requestWriteAccess() async =>
      throw UnsupportedError('a refresh must not write');

  @override
  Future<bool> write({
    required HubWritable metric,
    required double value,
    required DateTime at,
    required String recordId,
    String? label,
  }) async =>
      throw UnsupportedError('a refresh must not write');

  @override
  Future<List<HubSample>> read(DateTime start, DateTime end) async {
    reads += 1;
    return [
      HubSample(
        id: 'active-$reads',
        metric: HubMetric.activeEnergy,
        start: end.subtract(const Duration(minutes: 1)),
        end: end,
        value: 7,
        source: 'Test Watch',
      ),
    ];
  }
}

void main() {
  late AppDatabase db;
  late _RecordingGateway gateway;

  var clock = DateTime(2026, 7, 28, 9);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = _RecordingGateway();
    clock = DateTime(2026, 7, 28, 9);
  });

  tearDown(() => db.close());

  HealthForegroundRefresh subject() => HealthForegroundRefresh(
        database: db,
        gateway: gateway,
        now: () => clock,
      );

  Future<void> connect() => db.recordIntegrationSync(
        vendor: 'test-hub',
        status: 'connected',
        recordsToday: 1,
      );

  test('does nothing until a hub has been connected', () async {
    final refresh = subject();

    expect(await refresh.refreshIfDue(), isNull);
    expect(gateway.reads, 0);
  });

  test('refreshes once a hub is connected', () async {
    await connect();

    final records = await subject().refreshIfDue();

    expect(records, 1);
    expect(gateway.reads, 1);
  });

  test('debounces repeated resumes', () async {
    await connect();
    final refresh = subject();

    await refresh.refreshIfDue();
    clock = clock.add(const Duration(minutes: 3));
    await refresh.refreshIfDue();

    expect(gateway.reads, 1, reason: 'inside the minimum interval');

    clock = clock.add(const Duration(minutes: 11));
    await refresh.refreshIfDue();

    expect(gateway.reads, 2);
  });

  test('a disconnected hub imports nothing and is recorded as disconnected',
      () async {
    await connect();
    gateway = _RecordingGateway(authorized: false);

    expect(await subject().refreshIfDue(), isNull);

    final row = await db.loadIntegration('test-hub');
    expect(row?.status, 'disconnected');
  });

  test('a refresh writes through the canonical day summary', () async {
    // Resting burn is only derived when height is known, so the day summary
    // needs a real profile behind it.
    await db.saveProfile(
      ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'other',
        weightKg: 72,
        heightCm: const Value(178),
        units: 'metric',
      ),
    );
    await connect();

    await subject().refreshIfDue();

    final summary = await db.loadDaySummary('2026-07-28');
    expect(summary, isNotNull);
    expect(summary!.activeKcal, greaterThan(0));
  });
}
