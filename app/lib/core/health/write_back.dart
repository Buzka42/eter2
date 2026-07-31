import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'health_hub.dart';

/// Puts what Eter knows back into the platform's own record.
///
/// Eter read fourteen kinds of health data and wrote none, which made it a good
/// citizen of nobody's phone: a weight typed here never appeared in Apple Health,
/// so a person using Eter alongside anything else kept two records that disagreed.
///
/// **The rule that keeps this safe is the origin filter.** Only rows Eter
/// originated are written back — a weight somebody typed, a meal it estimated
/// from a page and they confirmed. Anything read *from* the hub is never returned
/// to it. Handing the platform its own data under Eter's name would survive one
/// round trip and then be read back as a second, independent measurement, and the
/// day's intake would climb every time somebody opened the app.
///
/// `WeightEntries.source` and `NutritionEntries.source` are what make that
/// filter possible: the ingest path stamps `healthConnect:*` or `appleHealth`,
/// and everything else came from here.
class HealthWriteBack {
  const HealthWriteBack({
    required this.database,
    required this.gateway,
  });

  final AppDatabase database;
  final HealthHubGateway gateway;

  /// Sources that mean "this came from the platform, do not send it back".
  ///
  /// Matched as a prefix because the hub stamps the contributing app onto the
  /// source — `healthConnect:garmin`, `healthConnect:samsung` — and every one of
  /// them is still the platform's own record.
  static const _foreign = ['healthConnect', 'appleHealth'];

  static bool _isOurs(String source) =>
      !_foreign.any((prefix) => source.startsWith(prefix));

  /// Writes everything eligible that has not been written yet.
  ///
  /// Idempotent: each row goes under a stable `clientRecordId`, so running
  /// this twice replaces rather than duplicates, and `writtenBackAt` stops it
  /// re-offering work.
  ///
  /// Returns what happened rather than just a count. It used to return an
  /// `int`, and every unhappy path collapsed into zero: access refused, every
  /// record rejected by the platform, and genuinely nothing to do all produced
  /// the same "Nothing new to write. Everything you entered is already there."
  /// The second sentence of that was simply false while a confirmed meal sat
  /// unwritten, which is the failure mode this whole feature most needed not
  /// to have.
  Future<HealthWriteBackResult> run() async {
    if (!await gateway.requestWriteAccess()) {
      return const HealthWriteBackResult(accessRefused: true);
    }
    final weights = await _weights();
    final meals = await _nutrition();
    return HealthWriteBackResult(
      written: weights.written + meals.written,
      offered: weights.offered + meals.offered,
    );
  }

  Future<HealthWriteBackResult> _weights() async {
    final rows = await (database.select(database.weightEntries)
          ..where((row) => row.writtenBackAt.isNull()))
        .get();
    final ours = rows.where((row) => _isOurs(row.source)).toList();
    var written = 0;
    for (final row in ours) {
      final accepted = await gateway.write(
        metric: HubWritable.weight,
        value: row.kg,
        at: row.recordedAt,
        recordId: 'eter-weight-${row.id}',
      );
      if (!accepted) continue;
      await (database.update(database.weightEntries)
            ..where((item) => item.id.equals(row.id)))
          .write(
        WeightEntriesCompanion(writtenBackAt: Value(DateTime.now().toUtc())),
      );
      written += 1;
    }
    return HealthWriteBackResult(written: written, offered: ours.length);
  }

  Future<HealthWriteBackResult> _nutrition() async {
    final rows = await (database.select(database.nutritionEntries)
          ..where((row) => row.writtenBackAt.isNull() & row.confirmed))
        .get();
    final ours = rows.where((row) => _isOurs(row.source)).toList();
    var written = 0;
    for (final row in ours) {
      final accepted = await gateway.write(
        metric: HubWritable.dietaryEnergy,
        value: row.kcal,
        at: row.recordedAt,
        recordId: 'eter-meal-${row.id}',
        label: row.meal,
      );
      if (!accepted) continue;
      await (database.update(database.nutritionEntries)
            ..where((item) => item.id.equals(row.id)))
          .write(
        NutritionEntriesCompanion(writtenBackAt: Value(DateTime.now().toUtc())),
      );
      written += 1;
    }
    return HealthWriteBackResult(written: written, offered: ours.length);
  }
}

/// What a write-back actually did.
///
/// [offered] is how many rows were eligible; [written] is how many the platform
/// accepted. They differ when the platform refuses a record, which it does
/// silently as far as the caller is concerned — and a surface that cannot tell
/// the difference will tell somebody everything they entered is already there
/// while it is not.
class HealthWriteBackResult {
  const HealthWriteBackResult({
    this.written = 0,
    this.offered = 0,
    this.accessRefused = false,
  });

  final int written;
  final int offered;

  /// The person, or the platform, said no to write access. Nothing was tried.
  final bool accessRefused;

  /// Eligible rows the platform would not take. Not an exception — the write
  /// simply did not happen, and saying so is the whole point of this class.
  int get refused => offered - written;

  bool get isNothingToDo => !accessRefused && offered == 0;
}
