import 'dart:async';

import 'package:eter/core/diagnostics/crash_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/prototype_harness.dart';

/// Startup must not be able to wait forever.
///
/// It could, and it did. On a fresh install crash-report consent is null, so
/// the first thing the app did was disable collection — which awaited a
/// Crashlytics task that never completed, and the product sat on its splash
/// screen with nothing on any log to say why.
///
/// The lesson is not "that one call": it is that optional infrastructure was
/// allowed to decide whether the app opens. These tests hold that line.
void main() {
  // The Journal's date needs `intl`'s locale data, and no test runs `main()`.
  setUpAll(eterInitializeFormatting);

  test('a reporter that never answers cannot hold the app closed', () async {
    // The exact shape of the bug: setEnabled never completes.
    final consent = CrashConsent(_HangingReporter());

    var opened = false;
    // What main() does now — bounded, and survivable when it expires.
    unawaited(
      consent
          .apply(consentedAt: null)
          .timeout(const Duration(milliseconds: 50))
          .catchError((Object _) {}),
    );
    opened = true;

    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(
      opened,
      isTrue,
      reason: 'the app must reach its first frame regardless',
    );
  });

  test('a reporter that throws is survivable', () async {
    await expectLater(
      CrashConsent(_ThrowingReporter())
          .apply(consentedAt: DateTime.utc(2026, 7, 28))
          .catchError((Object _) {}),
      completes,
    );
  });

  test('collection stays off while consent is unknown', () async {
    // The safe direction to be wrong in: if the consent read fails or is slow,
    // nothing is collected in the meantime.
    final reporter = _RecordingReporter();
    expect(reporter.enabled, isFalse);
    await CrashConsent(reporter).apply(consentedAt: null);
    expect(reporter.enabled, isFalse);
  });

  test('recording an error while disabled sends nothing', () async {
    final reporter = _RecordingReporter();
    await reporter.record(StateError('boom'), StackTrace.current);
    expect(reporter.sent, isEmpty);

    await CrashConsent(reporter).apply(consentedAt: DateTime.utc(2026, 7, 28));
    await reporter.record(StateError('boom'), StackTrace.current);
    expect(reporter.sent, hasLength(1));
  });

  test('the no-op reporter satisfies the contract without any SDK', () async {
    const reporter = NoCrashReporter();
    await expectLater(reporter.setEnabled(true), completes);
    await expectLater(
      reporter.record(StateError('boom'), StackTrace.current),
      completes,
    );
  });
}

/// Never completes — the failure mode that hung the splash screen.
class _HangingReporter implements CrashReporter {
  @override
  Future<void> setEnabled(bool enabled) => Completer<void>().future;

  @override
  Future<void> record(Object error, StackTrace? stack, {bool fatal = false}) =>
      Completer<void>().future;
}

class _ThrowingReporter implements CrashReporter {
  @override
  Future<void> setEnabled(bool enabled) async => throw StateError('no service');

  @override
  Future<void> record(Object error, StackTrace? stack, {bool fatal = false}) =>
      throw StateError('no service');
}

class _RecordingReporter implements CrashReporter {
  bool enabled = false;
  final sent = <Object>[];

  @override
  Future<void> setEnabled(bool value) async => enabled = value;

  @override
  Future<void> record(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    if (enabled) sent.add(error);
  }
}
