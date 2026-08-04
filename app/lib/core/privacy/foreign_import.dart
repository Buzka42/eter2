/// Reading somebody else's app.
///
/// [LocalDataImporter] reads Eter's own snapshot: a versioned dump of every
/// table, written by this schema, restored into an empty device. This is the
/// other kind of import entirely, and almost every rule is different.
///
/// * **It does not need an empty device.** Somebody importing three years of
///   Daylio has usually been using Eter for a fortnight first — that is what
///   makes them go looking. Refusing them would make the feature useless in
///   the case it exists for.
/// * **So it must not double-write.** Import the same file twice, or two
///   overlapping exports, and the second pass must add only what is new. Every
///   record therefore carries a natural key and is matched against what is
///   already there.
/// * **It is lossy in one direction only.** A foreign format has fields Eter
///   has nowhere to put. Those are counted and named in the result rather than
///   dropped in silence, because "imported 1,412 entries" is a different
///   sentence from "imported 1,412 entries and ignored your medication log".
/// * **Nothing imported is sent anywhere.** Pages arrive with a status the
///   interpretation queue does not pick up. A person pressing *import* has not
///   asked to pay for a decade of their own notes to be read by a model, and
///   the queue would happily do exactly that.
library;

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../energy/energy.dart';

/// The status imported pages carry.
///
/// Not `pending`: that is the queue's word for "written just now and waiting
/// to be read", and `AutoInterpret` acts on it. An import of nine hundred old
/// pages would become nine hundred model calls nobody asked for.
const foreignImportStatus = 'imported';

/// One page of somebody's prose, with the moment it was written.
class ForeignJournalEntry {
  const ForeignJournalEntry({
    required this.at,
    required this.text,
    this.source = 'imported',
  });

  final DateTime at;
  final String text;
  final String source;
}

/// One self-report: a mood, an energy level, a rated night.
class ForeignLifestyleEntry {
  const ForeignLifestyleEntry({
    required this.at,
    required this.kind,
    this.value,
    this.durationMinutes,
    this.note,
    required this.source,
  });

  final DateTime at;

  /// `mood` | `stress` | `recovery` | `sleep` | `meditation` | `breathwork`,
  /// as `LifestyleEntries` defines them.
  final String kind;

  /// Null where the foreign app recorded something Eter cannot put a number
  /// on. A custom mood nobody can rank is absent, never a middling 3.
  final double? value;

  final double? durationMinutes;
  final String? note;
  final String source;
}

/// One weight reading.
class ForeignWeightEntry {
  const ForeignWeightEntry({
    required this.at,
    required this.kg,
    required this.source,
  });

  final DateTime at;
  final double kg;
  final String source;
}

/// One stretch of sleep, as the other app staged it.
class ForeignSleepSegment {
  const ForeignSleepSegment({
    required this.start,
    required this.end,
    required this.stage,
    required this.source,
  });

  final DateTime start;
  final DateTime end;

  /// `awake` | `light` | `deep` | `rem` | `unknown`, as `SleepSegments`
  /// defines them.
  final String stage;
  final String source;

  /// The night a segment belongs to is the local date it *ended* on, which is
  /// the rule the live pipeline already uses. Sleep crosses midnight, so the
  /// date it started on is the wrong answer for almost every night there is.
  String get nightOf {
    final local = end.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

/// One day's vitals, as far as the file knew them.
class ForeignDailyVital {
  const ForeignDailyVital({
    required this.date,
    required this.source,
    this.restingHr,
    this.hrvMs,
    this.respiratoryRate,
  });

  /// Local `YYYY-MM-DD`.
  final String date;
  final String source;
  final double? restingHr;
  final double? hrvMs;
  final double? respiratoryRate;

  bool get isEmpty =>
      restingHr == null && hrvMs == null && respiratoryRate == null;
}

/// Everything one foreign file turned out to hold.
class ForeignRecords {
  const ForeignRecords({
    this.journal = const [],
    this.lifestyle = const [],
    this.weight = const [],
    this.sleep = const [],
    this.vitals = const [],
    this.ignored = const {},
    this.unreadableRows = 0,
  });

  final List<ForeignJournalEntry> journal;
  final List<ForeignLifestyleEntry> lifestyle;
  final List<ForeignWeightEntry> weight;
  final List<ForeignSleepSegment> sleep;
  final List<ForeignDailyVital> vitals;

  /// What the file carried that Eter has nowhere to keep, and how much of it —
  /// `{'Medication': 212}`. Named rather than counted in one lump: a person
  /// deciding whether to keep the other app installed needs to know *what*
  /// did not come across.
  final Map<String, int> ignored;

  /// Rows that could not be read at all — a date that was not a date, a row
  /// with nothing in the columns that matter.
  final int unreadableRows;

  bool get isEmpty =>
      journal.isEmpty &&
      lifestyle.isEmpty &&
      weight.isEmpty &&
      sleep.isEmpty &&
      vitals.isEmpty;
}

/// What an import did, in enough detail to be told to somebody.
class ForeignImportResult {
  const ForeignImportResult({
    required this.source,
    required this.journalWritten,
    required this.lifestyleWritten,
    required this.weightWritten,
    this.sleepNightsWritten = 0,
    this.vitalDaysWritten = 0,
    this.vitalDaysLeftAlone = 0,
    required this.duplicatesSkipped,
    required this.ignored,
    required this.unreadableRows,
    this.earliest,
    this.latest,
  });

  /// The app this came from, as the importer names itself.
  final String source;

  final int journalWritten;
  final int lifestyleWritten;
  final int weightWritten;

  /// Nights of sleep written. Counted in nights rather than segments because
  /// a night is what a person recognises; eleven segments is a fact about the
  /// watch.
  final int sleepNightsWritten;

  final int vitalDaysWritten;

  /// Days whose vitals were already here and were left as they were.
  ///
  /// `DailyVitals` holds one row per date whatever measured it, so a file
  /// cannot be merged into a day the device already knows about — and the file
  /// is the one that must give way. Reported rather than silent: it is the
  /// answer to "why does last March still look empty".
  final int vitalDaysLeftAlone;

  /// Records that were already here. The number that makes importing the same
  /// file twice a safe thing to do rather than a thing to warn about.
  final int duplicatesSkipped;

  final Map<String, int> ignored;
  final int unreadableRows;

  /// The span the file covered, which is the one fact that tells somebody at a
  /// glance whether they exported what they meant to.
  final DateTime? earliest;
  final DateTime? latest;

  int get written =>
      journalWritten +
      lifestyleWritten +
      weightWritten +
      sleepNightsWritten +
      vitalDaysWritten;

  bool get isPartial => ignored.isNotEmpty || unreadableRows > 0;
}

/// Recognises a file and turns it into records. One per foreign app.
abstract interface class ForeignImportSource {
  /// Shown to the person: `Daylio`.
  String get name;

  /// Whether this reader recognises the file. Cheap, and it must be certain —
  /// two readers claiming the same file is worse than none.
  bool canRead(String content);

  ForeignRecords read(String content);
}

/// Writes foreign records into the record, once each.
class ForeignImporter {
  const ForeignImporter(this.database);

  final AppDatabase database;

  /// Reads [content] with whichever of [sources] recognises it.
  ///
  /// Returns null when none does, which the surface reports as "this is not a
  /// file Eter knows how to read" rather than as a failure — being handed a
  /// PDF is a mistake, not an error.
  Future<ForeignImportResult?> importContent(
    String content, {
    required List<ForeignImportSource> sources,
  }) async {
    for (final source in sources) {
      if (!source.canRead(content)) continue;
      return write(source.name, source.read(content));
    }
    return null;
  }

  /// Writes what a reader produced, skipping anything already here.
  ///
  /// The whole thing is one transaction. A half-written import is the state
  /// nobody can reason about: the second attempt would see some of the first
  /// and the person would have no way to tell what they now hold.
  Future<ForeignImportResult> write(
    String source,
    ForeignRecords records,
  ) async {
    var journalWritten = 0;
    var lifestyleWritten = 0;
    var weightWritten = 0;
    var sleepNights = 0;
    var vitalDays = 0;
    var vitalDaysLeftAlone = 0;
    var duplicates = 0;
    DateTime? earliest;
    DateTime? latest;

    void span(DateTime at) {
      if (earliest == null || at.isBefore(earliest!)) earliest = at;
      if (latest == null || at.isAfter(latest!)) latest = at;
    }

    await database.transaction(() async {
      for (final entry in records.journal) {
        span(entry.at);
        // The natural key: the same words at the same minute are the same
        // page. Text as well as time, because two exports of the same diary
        // agree on both, and because a person who genuinely wrote twice in one
        // minute wrote two different things.
        final existing = await database
            .customSelect(
              'SELECT 1 FROM journal_entries '
              'WHERE created_at = ? AND text = ? LIMIT 1',
              variables: [
                Variable<DateTime>(entry.at),
                Variable<String>(entry.text),
              ],
              readsFrom: {database.journalEntries},
            )
            .get();
        if (existing.isNotEmpty) {
          duplicates++;
          continue;
        }
        await database.into(database.journalEntries).insert(
              JournalEntriesCompanion.insert(
                createdAt: entry.at,
                entryText: entry.text,
                source: Value(entry.source),
                status: const Value(foreignImportStatus),
              ),
            );
        journalWritten++;
      }

      for (final entry in records.lifestyle) {
        span(entry.at);
        // One reading of one kind at one moment. A file that carries both a
        // mood and an energy level for the same minute is two records, and
        // both belong here.
        final existing = await database
            .customSelect(
              'SELECT 1 FROM lifestyle_entries '
              'WHERE recorded_at = ? AND kind = ? LIMIT 1',
              variables: [
                Variable<DateTime>(entry.at),
                Variable<String>(entry.kind),
              ],
              readsFrom: {database.lifestyleEntries},
            )
            .get();
        if (existing.isNotEmpty) {
          duplicates++;
          continue;
        }
        await database.into(database.lifestyleEntries).insert(
              LifestyleEntriesCompanion.insert(
                recordedAt: entry.at,
                kind: entry.kind,
                value: Value(entry.value),
                durationMinutes: Value(entry.durationMinutes),
                note: Value(entry.note),
                source: Value(entry.source),
              ),
            );
        lifestyleWritten++;
      }

      for (final entry in records.weight) {
        span(entry.at);
        final existing = await database
            .customSelect(
              'SELECT 1 FROM weight_entries WHERE recorded_at = ? LIMIT 1',
              variables: [Variable<DateTime>(entry.at)],
              readsFrom: {database.weightEntries},
            )
            .get();
        if (existing.isNotEmpty) {
          duplicates++;
          continue;
        }
        await database.into(database.weightEntries).insert(
              WeightEntriesCompanion.insert(
                recordedAt: entry.at,
                kg: entry.kg,
                source: Value(entry.source),
              ),
            );
        weightWritten++;
      }

      // Sleep goes in a night at a time, through the same call the live
      // pipeline uses. It replaces this source's segments for that night and
      // touches no other source's, which is what makes importing the same file
      // twice leave one night rather than two overlapping copies of it.
      final byNight = <(String, String), List<ForeignSleepSegment>>{};
      for (final segment in records.sleep) {
        span(segment.end);
        byNight
            .putIfAbsent((segment.nightOf, segment.source), () => [])
            .add(segment);
      }
      for (final entry in byNight.entries) {
        final (night, source) = entry.key;
        // The same rule the hub follows: a source that gives both a whole
        // undifferentiated night *and* its stages has described the same
        // minutes twice, and keeping both doubles every total built on it.
        final staged =
            entry.value.where((one) => one.stage != 'unknown').toList();
        final segments = staged.isEmpty ? entry.value : staged;
        await database.replaceSleepForNight(
          nightOf: night,
          source: source,
          segments: [
            for (final segment in segments)
              SleepSegmentsCompanion.insert(
                startUtc: segment.start.toUtc(),
                endUtc: segment.end.toUtc(),
                stage: segment.stage,
                source: segment.source,
                priority: SourcePriority.importedFile.index,
                nightOf: night,
              ),
          ],
        );
        sleepNights++;
      }

      for (final vital in records.vitals) {
        if (vital.isEmpty) continue;
        // One row per date, whatever measured it — so a file cannot be merged
        // into a day the device already knows about, and the file is the one
        // that gives way. It is a snapshot of what another phone thought;
        // whatever is here was measured on this one.
        final existing = await database
            .customSelect(
              'SELECT 1 FROM daily_vitals WHERE date = ? LIMIT 1',
              variables: [Variable<String>(vital.date)],
              readsFrom: {database.dailyVitals},
            )
            .get();
        if (existing.isNotEmpty) {
          vitalDaysLeftAlone++;
          continue;
        }
        await database.into(database.dailyVitals).insert(
              DailyVitalsCompanion.insert(
                date: vital.date,
                restingHr: Value(vital.restingHr),
                hrvMs: Value(vital.hrvMs),
                respiratoryRate: Value(vital.respiratoryRate),
                source: vital.source,
              ),
            );
        vitalDays++;
      }
    });

    return ForeignImportResult(
      source: source,
      journalWritten: journalWritten,
      lifestyleWritten: lifestyleWritten,
      weightWritten: weightWritten,
      sleepNightsWritten: sleepNights,
      vitalDaysWritten: vitalDays,
      vitalDaysLeftAlone: vitalDaysLeftAlone,
      duplicatesSkipped: duplicates,
      ignored: records.ignored,
      unreadableRows: records.unreadableRows,
      earliest: earliest,
      latest: latest,
    );
  }
}
