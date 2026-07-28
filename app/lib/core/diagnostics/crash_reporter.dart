/// Knowing that Eter broke, without learning anything else about the person.
///
/// The decision, recorded: **Eter reports crashes, and only with permission.**
///
/// Shipping with no crash signal at all is flying blind — a bug that only
/// happens on one manufacturer's keyboard is invisible until someone writes an
/// angry review, and by then it has been happening for weeks. But a health
/// journal is the wrong app to switch on automatic telemetry, and the product
/// has said in three other places that data leaves the device only when asked.
/// So it is a fourth independent permission: off on install, off after a
/// restore, revocable, and worth nothing to anyone if declined.
///
/// What a report may contain: the exception, the stack trace, the device model
/// and the OS version. What it may never contain: a journal page, a
/// measurement, a birth date, an email address, or any identifier Eter chose.
/// The rule is enforced in [CrashReporter.record] rather than merely promised
/// here — nothing in this app hands user content to a reporter, and the
/// interface gives it nowhere to go.
library;

/// The reporter the app talks to.
///
/// An interface so the gating can be tested with no SDK, no network and no
/// project — and so a build with no Firebase simply has no reporter, which is
/// a supported configuration rather than a broken one.
abstract interface class CrashReporter {
  /// Turns collection on or off. Called whenever consent changes, and once at
  /// startup with whatever the profile says.
  Future<void> setEnabled(bool enabled);

  /// Records an error. Does nothing at all when collection is off.
  ///
  /// Deliberately takes no message, no context map and no user id: there is no
  /// parameter here through which a journal page could reach a server.
  Future<void> record(Object error, StackTrace? stack, {bool fatal = false});
}

/// The reporter for a build with nothing to report to.
///
/// Not a fallback that silently swallows — the app genuinely has no crash
/// reporting in this configuration, and that is the honest state to be in.
class NoCrashReporter implements CrashReporter {
  const NoCrashReporter();

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> record(Object error, StackTrace? stack, {bool fatal = false}) async {}
}

/// Decides whether anything is collected, from the profile alone.
///
/// Kept separate from the reporter so the rule — no consent, no collection —
/// is testable without any SDK, and so there is exactly one place that
/// decides it.
class CrashConsent {
  const CrashConsent(this.reporter);

  final CrashReporter reporter;

  /// Applies the person's current answer. Call at startup and on every change.
  Future<void> apply({required DateTime? consentedAt}) =>
      reporter.setEnabled(consentedAt != null);

  /// True when a report may be sent at all.
  static bool allows(DateTime? consentedAt) => consentedAt != null;
}
