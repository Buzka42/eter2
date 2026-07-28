import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'crash_reporter.dart';

/// The only file in the app that knows Crashlytics exists.
///
/// It is deliberately thin, and the things it does *not* do are the point:
/// it sets no user identifier, attaches no custom keys, and logs no
/// breadcrumbs. Crashlytics will happily carry all three, which is exactly why
/// the temptation has to be refused in one place rather than resisted in
/// twenty.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    if (!enabled) {
      // Anything captured before the switch was thrown must not survive it.
      await _crashlytics.deleteUnsentReports();
    }
  }

  @override
  Future<void> record(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) =>
      _crashlytics.recordError(error, stack, fatal: fatal);
}
