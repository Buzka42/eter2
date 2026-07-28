import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import 'classification_contract.dart';
import 'classifier.dart';

/// Interpreting every page that is kept, rather than every page that is asked
/// about.
///
/// Interpretation used to be a button on each entry. In practice a person
/// writes a page and moves on, so the records the page contained arrived only
/// if they remembered to come back and press something — which made the Body
/// look empty for reasons that had nothing to do with their day.
///
/// So the rule inverted: **what is kept is read; what is deleted is not.**
/// Deleting is now the deliberate act, and it is the one a person actually
/// wants to be deliberate about.
///
/// What did *not* change is the boundary. AI consent is still required and is
/// re-read on every pass, `KEEP LOCAL` still holds an entry back, and an entry
/// already applied is never sent twice. Nothing here loosens what may leave
/// the device; it only stops asking permission twice for the same decision.
class JournalAutoInterpreter {
  const JournalAutoInterpreter({
    required this.database,
    required this.provider,
    this.maxPerPass = 5,
  });

  final AppDatabase database;
  final JournalClassificationProvider? provider;

  /// A ceiling per pass, so opening a day with a backlog cannot fire twenty
  /// model calls at once. The rest are picked up on the next pass.
  final int maxPerPass;

  /// Interprets what is pending in [start]–[end], oldest first.
  ///
  /// Returns how many entries were read. Best-effort by design: a failure on
  /// one page must not stop the next, and none of it may block the surface
  /// that called it.
  Future<int> run({required DateTime start, required DateTime end}) async {
    final transport = provider;
    if (transport == null) return 0;

    final profile = await database.loadProfile();
    if (profile?.aiConsentAt == null) return 0;

    final entries = await database.loadJournalForRange(start, end);
    final pending = [
      for (final entry in entries)
        if (_isPending(entry)) entry,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    var read = 0;
    for (final entry in pending.take(maxPerPass)) {
      try {
        await JournalClassifier(
          database: database,
          provider: transport,
        ).classify(entry.id);
        read += 1;
      } catch (error) {
        // One unreadable page does not stop the others, and does not surface
        // as an error: nothing was asked for, so nothing failed in front of
        // anyone. The entry stays pending and is tried again next time.
        debugPrint('Eter: entry ${entry.id} not interpreted: $error');
      }
    }
    return read;
  }

  /// Worth sending: written, kept, not held back, and not already read.
  ///
  /// `needsDetail` is deliberately excluded. The model asked a question about
  /// that page and nobody has answered it; asking again unprompted would spend
  /// a call to receive the same question.
  bool _isPending(JournalEntryRow entry) =>
      entry.status == 'pending' &&
      entry.appliedAt == null &&
      !entry.excludedFromAi &&
      entry.entryText.trim().isNotEmpty;
}
