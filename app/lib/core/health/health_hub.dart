import 'package:drift/drift.dart';

import '../clock.dart';
import '../db/app_database.dart';
import '../energy/energy.dart' as energy;
import 'daily_activity_summary.dart';

enum HubMetric {
  activeEnergy,
  steps,
  heartRate,
  restingHeartRate,
  hrv,
  respiratoryRate,
  sleepAwake,
  sleepLight,
  sleepDeep,
  sleepRem,
  sleepUnknown,

  /// A workout the watch recorded as an event, rather than the minutes it
  /// produced. Both matter and they are not the same: the minutes say a body
  /// moved, the workout says a person decided to train.
  workout,
}

class HubSample {
  const HubSample({
    required this.id,
    required this.metric,
    required this.start,
    required this.end,
    required this.value,
    required this.source,
    this.label,
  });

  final String id;
  final HubMetric metric;
  final DateTime start;
  final DateTime end;
  final double value;
  final String source;

  /// What the sample calls itself, when that is more than its metric — a
  /// workout's sport, for instance. Null for everything measured in units.
  final String? label;
}

abstract interface class HealthHubGateway {
  String get vendor;
  Future<bool> requestReadAccess();
  Future<List<HubSample>> read(DateTime start, DateTime end);
}

class HealthHubSyncResult {
  const HealthHubSyncResult({
    required this.authorized,
    required this.records,
    this.summariesUpdated = 0,
  });
  final bool authorized;
  final int records;
  final int summariesUpdated;
}

/// Maps platform health records into Eter's canonical, replay-safe store.
class HealthHubSyncService {
  const HealthHubSyncService({
    required this.database,
    required this.gateway,
  });

  final AppDatabase database;
  final HealthHubGateway gateway;

  Future<HealthHubSyncResult> sync({
    required DateTime start,
    required DateTime end,
  }) async {
    final authorized = await gateway.requestReadAccess();
    if (!authorized) {
      await database.recordIntegrationFailure(
        vendor: gateway.vendor,
        status: 'disconnected',
        error: 'Health permission was not granted',
      );
      return const HealthHubSyncResult(authorized: false, records: 0);
    }

    try {
      final samples = await gateway.read(start.toUtc(), end.toUtc());
      await _writeMinuteBuckets(samples);
      await database.recomputeMinuteWinners(start.toUtc(), end.toUtc());
      final summariesUpdated =
          await DailyActivitySummaryService(database).refresh(start, end);
      await _writeSleep(samples);
      await _writeSessions(samples);
      await _writeVitals(samples);
      await database.recordIntegrationSync(
        vendor: gateway.vendor,
        status: 'connected',
        recordsToday: samples.length,
        diagnostics: {'windowStart': start.toUtc().toIso8601String()},
      );
      return HealthHubSyncResult(
        authorized: true,
        records: samples.length,
        summariesUpdated: summariesUpdated,
      );
    } catch (error) {
      await database.recordIntegrationFailure(
        vendor: gateway.vendor,
        status: 'error',
        error: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> _writeMinuteBuckets(List<HubSample> samples) async {
    final buckets = <(String, DateTime), _MinuteAccumulator>{};
    for (final sample in samples.where((item) =>
        item.metric == HubMetric.activeEnergy ||
        item.metric == HubMetric.steps ||
        item.metric == HubMetric.heartRate)) {
      final minutes = _minutes(sample.start, sample.end);
      if (minutes.isEmpty) continue;
      for (final minute in minutes) {
        final key = (sample.source, minute);
        final bucket = buckets.putIfAbsent(key, _MinuteAccumulator.new);
        switch (sample.metric) {
          case HubMetric.activeEnergy:
            bucket.activeKcal += sample.value / minutes.length;
          case HubMetric.steps:
            bucket.steps += sample.value / minutes.length;
          case HubMetric.heartRate:
            bucket.hrTotal += sample.value;
            bucket.hrSamples += 1;
          default:
            break;
        }
      }
    }
    await database.ingestRawBuckets(buckets.entries.map((entry) {
      final ((source, minute), value) = (entry.key, entry.value);
      return energy.MinuteBucket(
        minuteUtc: minute,
        activeKcal: value.activeKcal,
        sourceId: '${gateway.vendor}:$source',
        priority: energy.SourcePriority.hub,
        steps: value.steps.round(),
        avgHr: value.hrSamples == 0 ? null : value.hrTotal / value.hrSamples,
        hrSampleCount: value.hrSamples,
      );
    }));
  }

  /// Workouts, as sessions rather than as scattered minutes.
  ///
  /// Written through the same table a manually logged activity uses, so a
  /// Garmin run and a run typed into the Journal are the same kind of thing
  /// and count once each.
  Future<void> _writeSessions(List<HubSample> samples) async {
    for (final sample in samples.where((s) => s.metric == HubMetric.workout)) {
      await database.upsertActivitySession(
        ActivitySessionsCompanion.insert(
          // The hub's own id, so re-reading the same workout replaces it
          // rather than adding a second one.
          id: '${gateway.vendor}:${sample.id}',
          startUtc: sample.start.toUtc(),
          endUtc: sample.end.toUtc(),
          source: '${gateway.vendor}:${sample.source}',
          priority: energy.SourcePriority.hub.index,
          sport: Value(sample.label),
          activeKcal: Value(sample.value > 0 ? sample.value : null),
          externalId: Value(sample.id),
        ),
      );
    }
  }

  Future<void> _writeSleep(List<HubSample> samples) async {
    final sleep = samples.where((item) => _sleepStage(item.metric) != null);
    final groups = <(String, String), List<HubSample>>{};
    for (final sample in sleep) {
      final night = eterIsoDate(sample.end.toLocal());
      groups.putIfAbsent((night, sample.source), () => []).add(sample);
    }
    for (final entry in groups.entries) {
      final (night, source) = entry.key;
      // A session and its own stages describe the same minutes.
      //
      // Health Connect stores the night as a session that *contains* the
      // stages, so a source that provides both hands us the whole night twice
      // — once broken down, once as a single undifferentiated block. Keeping
      // both put an "unknown 505m" beside a light/deep/REM breakdown summing
      // to the same 505, and doubled every average built on it.
      //
      // The stages win when they exist. The session is the fallback for a
      // source that only ever says how long someone slept.
      final staged = entry.value
          .where((sample) => _sleepStage(sample.metric) != 'unknown')
          .toList();
      final segments = staged.isEmpty ? entry.value : staged;
      await database.replaceSleepForNight(
        nightOf: night,
        source: '${gateway.vendor}:$source',
        segments: segments.map(
          (sample) => SleepSegmentsCompanion.insert(
            startUtc: sample.start.toUtc(),
            endUtc: sample.end.toUtc(),
            stage: _sleepStage(sample.metric)!,
            source: '${gateway.vendor}:$source',
            priority: energy.SourcePriority.hub.index,
            nightOf: night,
            externalId: Value(sample.id),
          ),
        ),
      );
    }
  }

  Future<void> _writeVitals(List<HubSample> samples) async {
    final groups = <String, List<HubSample>>{};
    for (final sample in samples.where((item) => {
          HubMetric.restingHeartRate,
          HubMetric.hrv,
          HubMetric.respiratoryRate,
        }.contains(item.metric))) {
      groups
          .putIfAbsent(eterIsoDate(sample.end.toLocal()), () => [])
          .add(sample);
    }
    for (final entry in groups.entries) {
      double? average(HubMetric metric) {
        final values = entry.value
            .where((item) => item.metric == metric)
            .map((item) => item.value)
            .toList();
        return values.isEmpty
            ? null
            : values.reduce((a, b) => a + b) / values.length;
      }

      await database.recordDailyVitals(DailyVitalsCompanion.insert(
        date: entry.key,
        restingHr: Value(average(HubMetric.restingHeartRate)),
        hrvMs: Value(average(HubMetric.hrv)),
        respiratoryRate: Value(average(HubMetric.respiratoryRate)),
        source: gateway.vendor,
      ));
    }
  }

  List<DateTime> _minutes(DateTime start, DateTime end) {
    final first = start.toUtc();
    final cursor = DateTime.utc(
      first.year,
      first.month,
      first.day,
      first.hour,
      first.minute,
    );
    final limit = end.toUtc().isAfter(first)
        ? end.toUtc()
        : first.add(const Duration(minutes: 1));
    return [
      for (var value = cursor;
          value.isBefore(limit);
          value = value.add(const Duration(minutes: 1)))
        value,
    ];
  }

  String? _sleepStage(HubMetric metric) => switch (metric) {
        HubMetric.sleepAwake => 'awake',
        HubMetric.sleepLight => 'light',
        HubMetric.sleepDeep => 'deep',
        HubMetric.sleepRem => 'rem',
        HubMetric.sleepUnknown => 'unknown',
        _ => null,
      };
}

class _MinuteAccumulator {
  double activeKcal = 0;
  double steps = 0;
  double hrTotal = 0;
  int hrSamples = 0;
}
