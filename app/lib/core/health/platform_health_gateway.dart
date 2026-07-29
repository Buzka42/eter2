import 'package:health/health.dart';

import 'health_hub.dart';

class PlatformHealthGateway implements HealthHubGateway {
  PlatformHealthGateway({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const _types = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_UNKNOWN,
    // The session itself, not only its stages. A source that writes a sleep
    // session without a stage breakdown -- which some watches and some sync
    // paths do -- otherwise reaches Eter as nothing at all, and the night
    // looks unslept rather than unstaged.
    HealthDataType.SLEEP_SESSION,
    // Workouts. Never requested before, which is why a phone full of Garmin
    // runs reported zero sessions: Eter was reading the minutes a workout
    // produced without ever learning that a workout had happened.
    HealthDataType.WORKOUT,
  ];

  @override
  String get vendor => _health.platformType == HealthPlatformType.appleHealth
      ? 'appleHealth'
      : 'healthConnect';

  @override
  Future<bool> requestReadAccess() async {
    await _configure();
    final available =
        _types.where(_health.isDataTypeAvailable).toList(growable: false);
    return _health.requestAuthorization(
      available,
      permissions: List.filled(available.length, HealthDataAccess.READ),
    );
  }

  @override
  Future<List<HubSample>> read(DateTime start, DateTime end) async {
    await _configure();
    final available =
        _types.where(_health.isDataTypeAvailable).toList(growable: false);
    final points = await _health.getHealthDataFromTypes(
      types: available,
      startTime: start,
      endTime: end,
    );
    return points.map(_map).whereType<HubSample>().toList(growable: false);
  }

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  HubSample? _map(HealthDataPoint point) {
    final value = point.value;
    // A workout is an event with a name, not a number, so it does not survive
    // the numeric path below — which is why every Garmin run reached Eter as
    // minutes and never as a session.
    if (value is WorkoutHealthValue) {
      return HubSample(
        id: point.uuid,
        metric: HubMetric.workout,
        start: point.dateFrom.toUtc(),
        end: point.dateTo.toUtc(),
        value: (value.totalEnergyBurned ?? 0).toDouble(),
        source: point.sourceName,
        label: value.workoutActivityType.name,
      );
    }
    if (value is! NumericHealthValue) return null;
    final metric = switch (point.type) {
      HealthDataType.ACTIVE_ENERGY_BURNED => HubMetric.activeEnergy,
      HealthDataType.STEPS => HubMetric.steps,
      HealthDataType.HEART_RATE => HubMetric.heartRate,
      HealthDataType.RESTING_HEART_RATE => HubMetric.restingHeartRate,
      HealthDataType.HEART_RATE_VARIABILITY_RMSSD ||
      HealthDataType.HEART_RATE_VARIABILITY_SDNN =>
        HubMetric.hrv,
      HealthDataType.RESPIRATORY_RATE => HubMetric.respiratoryRate,
      HealthDataType.SLEEP_AWAKE => HubMetric.sleepAwake,
      HealthDataType.SLEEP_LIGHT => HubMetric.sleepLight,
      HealthDataType.SLEEP_DEEP => HubMetric.sleepDeep,
      HealthDataType.SLEEP_REM => HubMetric.sleepRem,
      HealthDataType.SLEEP_UNKNOWN ||
      // A session with no stages is time asleep of an unknown kind, which is
      // exactly what `sleepUnknown` means. Stages, when they exist, arrive as
      // their own samples and are preferred.
      HealthDataType.SLEEP_SESSION =>
        HubMetric.sleepUnknown,
      _ => null,
    };
    if (metric == null) return null;
    return HubSample(
      id: point.uuid,
      metric: metric,
      start: point.dateFrom.toUtc(),
      end: point.dateTo.toUtc(),
      value: value.numericValue.toDouble(),
      source: point.sourceName.isEmpty ? point.sourceId : point.sourceName,
    );
  }
}
