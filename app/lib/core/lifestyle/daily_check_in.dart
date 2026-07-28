import 'package:drift/drift.dart';

import '../clock.dart';
import '../db/app_database.dart';

/// The self-reported half of a day.
///
/// Placement is a settled product decision (28 July 2026): these belong in the
/// Journal's margin, beside the day's writing, and nowhere else. Body reads
/// them; it does not collect them. So this module owns the vocabulary and the
/// write rules, and the Journal owns only the marginal gesture.
///
/// Two shapes, deliberately not one:
///
/// * A **reading** — mood, stress, recovery — is the day's answer on a 1..5
///   scale. Answering again corrects the day rather than logging a second
///   opinion, so the write replaces.
/// * A **practice** — meditation, breathwork — is a session with a duration.
///   Two sittings are two sittings, so the write accumulates.
enum LifestyleReading {
  mood('mood', 'Mood'),
  stress('stress', 'Stress'),
  recovery('recovery', 'Recovery');

  const LifestyleReading(this.kind, this.label);

  /// The canonical `LifestyleEntries.kind` value.
  final String kind;
  final String label;

  /// The five marks, low to high, as the margin words them. Stress reads in
  /// the same direction as the others — 1 is the hard end of the day — so the
  /// scale never has to be explained twice.
  static const marks = ['Very low', 'Low', 'Even', 'High', 'Very high'];
}

enum LifestylePractice {
  meditation('meditation', 'Meditation'),
  breathwork('breathwork', 'Breathwork');

  const LifestylePractice(this.kind, this.label);

  final String kind;
  final String label;
}

class LifestyleCheckInService {
  const LifestyleCheckInService(this.database);

  final AppDatabase database;

  /// Records (or corrects) the day's reading. [day] is a local calendar day.
  Future<int> recordReading({
    required LifestyleReading reading,
    required int value,
    required DateTime day,
    required DateTime recordedAt,
  }) async {
    if (value < 1 || value > LifestyleReading.marks.length) {
      throw const LifestyleCheckInException(
        'A reading is one of the five marks.',
      );
    }
    final (dayStart, dayEnd) = eterDayBounds(day);
    return database.recordLifestyleReading(
      kind: reading.kind,
      value: value.toDouble(),
      recordedAt: recordedAt,
      dayStartUtc: dayStart,
      dayEndUtc: dayEnd,
    );
  }

  Future<int> recordPractice({
    required LifestylePractice practice,
    required double minutes,
    required DateTime recordedAt,
  }) async {
    if (!minutes.isFinite || minutes <= 0 || minutes > 600) {
      throw const LifestyleCheckInException(
        'A sitting is between 1 and 600 minutes.',
      );
    }
    return database.addLifestyleEntry(
      LifestyleEntriesCompanion.insert(
        recordedAt: recordedAt.toUtc(),
        kind: practice.kind,
        durationMinutes: Value(minutes),
      ),
    );
  }

  /// Taking a check-in back. The prose of the day is untouched.
  Future<void> remove(int entryId) => database.deleteLifestyleEntry(entryId);
}

class LifestyleCheckInException implements Exception {
  const LifestyleCheckInException(this.message);

  final String message;

  @override
  String toString() => message;
}
