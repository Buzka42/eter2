import 'dart:math';

import '../db/app_database.dart';

/// An opaque, random, per-install string, so the endpoint can meter one install
/// rather than everybody at once.
///
/// Why it exists is in `EterAiConfig.installId`. What matters here is what it is
/// made of, which is nothing:
///
/// * 128 bits from `Random.secure()`. Not derived from a device id, an
///   advertising id, an account, a name, a birth date or anything else about the
///   person — there is nothing in it to recover.
/// * Written once and then read. It changes on reinstall, and that is fine: it
///   identifies an install for the purpose of counting requests, not a person.
/// * Stored in `IntakeAnswers`, which `deleteAllLocalData` truncates. Erasing
///   local data therefore erases this too, and the next launch mints a new one.
///
/// Deliberately *not* a hardware identifier, which would have been less code and
/// far worse: those are stable across reinstalls, shared between apps, and in
/// several jurisdictions personal data on their own.
abstract final class EterInstallId {
  static const answerKey = 'ai_install_id';

  /// When this install first ran, which is when the trial starts.
  ///
  /// Written beside the install id and for the same reason: this is the earliest
  /// moment Eter has, and it is before there is a profile row to hang anything on.
  /// Deliberately *not* when onboarding finished — somebody who opens Eter, looks
  /// around and returns a week later has used a week, and a countdown that
  /// disagreed with the calendar would be the kind of thing people notice.
  static const firstLaunchKey = 'first_launch_at';

  /// The id for this install, minting one on first use.
  ///
  /// Read through [AppDatabase] rather than a preferences plugin so it lives in
  /// the store that already has a delete-everything path, and so no dependency
  /// is added for sixteen bytes.
  static Future<String> ensure(AppDatabase database) async {
    final existing = (await database.loadIntakeAnswers())[answerKey]?.value;
    if (existing != null && existing.isNotEmpty) return existing;
    final minted = _mint();
    await database.saveIntakeAnswer(
      key: answerKey,
      value: minted,
      // Not something the person told Eter, and nothing the prompt builder may
      // ever weigh. `optional` keeps it out of the intake tiers' meaning.
      tier: 'optional',
    );
    return minted;
  }

  /// When this install first ran, recording it if nobody has.
  static Future<DateTime> firstLaunch(
    AppDatabase database, {
    required DateTime now,
  }) async {
    final stored = (await database.loadIntakeAnswers())[firstLaunchKey]?.value;
    final parsed = stored == null ? null : DateTime.tryParse(stored);
    if (parsed != null) return parsed;
    final at = now.toUtc();
    await database.saveIntakeAnswer(
      key: firstLaunchKey,
      value: at.toIso8601String(),
      tier: 'optional',
    );
    return at;
  }

  static String _mint() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
