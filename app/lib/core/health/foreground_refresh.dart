import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../db/app_database.dart';
import 'health_hub.dart';
import 'platform_health_gateway.dart';

/// Keeps the Body's numbers current without asking the user to ask.
///
/// Before this, health data moved only when someone opened the Sanctum and
/// pressed `Refresh Health`. That made the Dashboard quietly stale: a morning
/// walk recorded by the watch did not exist in Eter until the user went
/// looking for a settings action.
///
/// The honest ceiling on freshness, and why this is the shape it is:
///
/// * **Health Connect has no push.** Android exposes changes tokens that you
///   poll; the platform floor for background polling is 15 minutes. So
///   genuinely live background sync is a separate slice needing WorkManager
///   (Android) and native `enableBackgroundDelivery` (iOS) — see
///   `docs/ROADMAP.md`.
/// * **What the user actually experiences** is the number they see when they
///   open the app. Syncing on resume closes almost the whole perceived gap at
///   no battery cost and with no new dependency.
///
/// Rules this keeps:
///
/// * Never on a platform without a hub, and never before the user has
///   connected one — a sync request would surface a permission prompt the user
///   did not ask for.
/// * Debounced: at most one sync per [minimumInterval], however often the app
///   is resumed.
/// * Silent both ways. A refresh that finds nothing changes nothing, and a
///   failure is recorded by the sync service as a failed integration rather
///   than thrown at someone who was just opening their journal.
/// * A short window. Resume asks for today and yesterday, not thirty days;
///   the deep read stays the Sanctum's explicit action.
class HealthForegroundRefresh {
  HealthForegroundRefresh({
    required this.database,
    HealthHubGateway? gateway,
    this.minimumInterval = const Duration(minutes: 10),
    DateTime Function()? now,
  })  : _gateway = gateway,
        _now = now ?? DateTime.now;

  final AppDatabase database;
  final HealthHubGateway? _gateway;
  final Duration minimumInterval;
  final DateTime Function() _now;

  DateTime? _lastAttempt;
  bool _running = false;

  /// True when a hub exists and the user has already connected it. A refresh
  /// is never the thing that first asks for health permission.
  Future<bool> shouldRefresh() async {
    if (!(Platform.isAndroid || Platform.isIOS) && _gateway == null) {
      return false;
    }
    final last = _lastAttempt;
    if (last != null && _now().difference(last) < minimumInterval) return false;
    final hub = await database.loadIntegration(
      (_gateway ?? PlatformHealthGateway()).vendor,
    );
    return hub?.status == 'connected';
  }

  /// Syncs the recent window if it is due. Returns the number of records read,
  /// or null when the refresh was skipped or failed quietly.
  Future<int?> refreshIfDue() async {
    if (_running) return null;
    if (!await shouldRefresh()) return null;
    _running = true;
    _lastAttempt = _now();
    try {
      final now = _now();
      final result = await HealthHubSyncService(
        database: database,
        gateway: _gateway ?? PlatformHealthGateway(),
      ).sync(
        start: DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 1)),
        end: now,
      );
      return result.authorized ? result.records : null;
    } catch (_) {
      // The sync service has already recorded the failure against the
      // integration. A background refresh must never interrupt reading.
      return null;
    } finally {
      _running = false;
    }
  }
}

/// Runs [refresh] when the app returns to the foreground.
///
/// Mounted once, by the shell. It holds no UI of its own and rebuilds nothing:
/// the Body's streams are already reactive, so a sync that writes shows up on
/// its own.
class HealthRefreshOnResume extends StatefulWidget {
  const HealthRefreshOnResume({
    super.key,
    required this.refresh,
    required this.child,
  });

  final HealthForegroundRefresh refresh;
  final Widget child;

  @override
  State<HealthRefreshOnResume> createState() => _HealthRefreshOnResumeState();
}

class _HealthRefreshOnResumeState extends State<HealthRefreshOnResume>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The first frame is a resume too: the app was just opened.
    unawaited(widget.refresh.refreshIfDue());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.refresh.refreshIfDue());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
