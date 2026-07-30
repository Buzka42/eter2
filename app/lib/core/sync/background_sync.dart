import 'dart:async';

import 'package:flutter/widgets.dart';

import '../account/account.dart';
import 'cloud_mirror.dart';
import 'sync_service.dart';

/// Copies the record up without being asked to.
///
/// `SyncService.push` had exactly one caller: the Sanctum's `SYNC NOW` button.
/// So the mirror only ever contained what someone had remembered to send, and
/// "survives a phone swap" quietly depended on a settings visit. A person who
/// signed in, allowed cloud continuity during setup and never opened the Sanctum
/// again had an empty mirror and every reason to believe otherwise — which is
/// the worst kind of backup, the sort that is discovered missing at the moment
/// it is needed.
///
/// The same shape as `HealthForegroundRefresh`, for the same reasons, with one
/// difference: this also runs when the app is *leaving*. That is the moment
/// worth catching, because it is immediately after someone has finished writing.
///
/// Leaving is safe to push from even though the process may die mid-flight.
/// Rows are marked `syncedAt` only once the write is acknowledged, so a push cut
/// short leaves them exactly as they were and they go again next time. A failed
/// sync is a delay, never a loss.
class BackgroundSync {
  BackgroundSync({
    required this.sync,
    this.minimumInterval = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Null on a build with no mirror, which is a shipped configuration.
  final SyncService? sync;

  /// At most one push per interval, however often the app is opened and closed.
  final Duration minimumInterval;

  final DateTime Function() _now;

  DateTime? _lastAttempt;
  bool _running = false;

  /// Pushes if anything is due, and reports nothing to anybody.
  ///
  /// Consent is deliberately *not* checked here. `SyncService.push` re-reads the
  /// profile on every call and refuses on its own, so there is one place that
  /// decision lives rather than two that have to agree forever. The refusal
  /// comes back as a [SyncOutcome] and is dropped: a person opening their
  /// journal has not asked about sync and should not be told about it.
  Future<SyncOutcome?> pushIfDue(EterAccount? account) async {
    final service = sync;
    if (service == null || account == null || !account.canSync) return null;
    if (_running) return null;
    final last = _lastAttempt;
    if (last != null && _now().difference(last) < minimumInterval) return null;
    _running = true;
    _lastAttempt = _now();
    try {
      return await service.push(account);
    } catch (_) {
      // `push` reports failure in its return value rather than throwing, so
      // reaching here means something unforeseen. It still must not surface.
      return null;
    } finally {
      _running = false;
    }
  }
}

/// Mounted once by the shell. Holds no UI and rebuilds nothing.
///
/// Takes its collaborators as parameters rather than reading providers, like
/// `HealthRefreshOnResume` does — `core/` has no business importing `main.dart`,
/// and it keeps this testable by pumping it with a fake.
///
/// [account] is a callback, not a value: who is signed in arrives
/// asynchronously and can change while this is mounted, and the push has to use
/// whoever is signed in at the moment it fires.
class SyncOnLifecycle extends StatefulWidget {
  const SyncOnLifecycle({
    super.key,
    required this.sync,
    required this.account,
    required this.child,
  });

  /// Null on a build with no mirror.
  final BackgroundSync? sync;
  final EterAccount? Function() account;
  final Widget child;

  @override
  State<SyncOnLifecycle> createState() => _SyncOnLifecycleState();
}

class _SyncOnLifecycleState extends State<SyncOnLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resumed catches anything changed since the app was last open; paused and
    // detached catch the page just written, which is the moment that matters
    // most. All three share one debounce.
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(widget.sync?.pushIfDue(widget.account()));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
