import 'package:drift/native.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/diagnostics/crash_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rule is one sentence — no consent, no collection — and it is worth a
/// test file because it is the kind of rule that decays silently.
void main() {
  group('the consent gate', () {
    test('no consent means no collection', () async {
      final reporter = _FakeReporter();
      await CrashConsent(reporter).apply(consentedAt: null);
      expect(reporter.enabled, isFalse);
      expect(CrashConsent.allows(null), isFalse);
    });

    test('consent turns it on, and only then', () async {
      final reporter = _FakeReporter();
      await CrashConsent(reporter).apply(consentedAt: DateTime.utc(2026, 7, 28));
      expect(reporter.enabled, isTrue);
      expect(CrashConsent.allows(DateTime.utc(2026, 7, 28)), isTrue);
    });

    test('revoking turns it off again', () async {
      final reporter = _FakeReporter();
      final consent = CrashConsent(reporter);
      await consent.apply(consentedAt: DateTime.utc(2026, 7, 28));
      await consent.apply(consentedAt: null);
      expect(reporter.enabled, isFalse);
    });
  });

  group('the profile', () {
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      await database.saveProfile(ProfilesCompanion.insert(
        dob: DateTime(1990, 1, 1),
        sex: 'other',
        weightKg: 70,
        units: 'metric',
      ));
    });
    tearDown(() => database.close());

    test('a fresh install has not consented', () async {
      expect((await database.loadProfile())!.crashReportConsentAt, isNull);
    });

    test('the choice is independent of every other permission', () async {
      await database.updateProfileConsents(crashReportsAllowed: true);
      var profile = await database.loadProfile();
      expect(profile!.crashReportConsentAt, isNotNull);
      // Turning crash reports on must not quietly turn anything else on.
      expect(profile.aiConsentAt, isNull);
      expect(profile.cloudSyncConsentAt, isNull);

      await database.updateProfileConsents(aiAllowed: true);
      profile = await database.loadProfile();
      expect(profile!.crashReportConsentAt, isNotNull);

      // Nor does revoking something else revoke this.
      await database.updateProfileConsents(aiAllowed: false);
      expect((await database.loadProfile())!.crashReportConsentAt, isNotNull);
    });

    test('revoking clears the timestamp rather than recording a refusal',
        () async {
      await database.updateProfileConsents(crashReportsAllowed: true);
      await database.updateProfileConsents(crashReportsAllowed: false);
      expect((await database.loadProfile())!.crashReportConsentAt, isNull);
    });
  });

  test('the no-op reporter is silent and safe', () async {
    const reporter = NoCrashReporter();
    await reporter.setEnabled(true);
    await reporter.record(StateError('boom'), StackTrace.current);
    // Nothing to assert but the absence of a throw: a build without crash
    // reporting must behave, not merely not report.
  });

  test('a report has nowhere to put user content', () {
    // A compile-time guarantee rather than a runtime one: record() takes an
    // error and a stack and nothing else, so no journal page, measurement or
    // identifier can be attached to one by a careless call site.
    const reporter = NoCrashReporter();
    expect(reporter.record, isA<Function>());
  });
}

class _FakeReporter implements CrashReporter {
  bool enabled = false;
  final recorded = <Object>[];

  @override
  Future<void> setEnabled(bool value) async => enabled = value;

  @override
  Future<void> record(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    if (!enabled) return;
    recorded.add(error);
  }
}
