/// Two people, each with a wholly private record, sharing one sentence a day.
///
/// The whole feature in one line: **the day's composed sentence, and nothing
/// else.** Nothing measured, nothing written, no health data, no counts, no
/// dates beyond the day it belongs to. It appears as one extra line beneath
/// today's guidance — not a screen, not a feed, and not a conversation.
///
/// This file is the part that decides what may leave. It is deliberately
/// separate from the transport, and deliberately paranoid: the boundary of a
/// sharing feature is the only thing in it worth writing twice, because every
/// other bug here shows you the wrong sentence and this one shows somebody
/// else your body.
library;

/// Refused, with a reason a person could be shown.
class CorrespondenceRefusal implements Exception {
  const CorrespondenceRefusal(this.reason);
  final String reason;

  @override
  String toString() => reason;
}

/// One day's sentence, as it crosses between two people.
///
/// There is no author field on purpose beyond the day and the words. The
/// gateway knows whose document it read; the payload does not need to carry an
/// identity, and a payload that carries one is a payload that can leak one.
class CorrespondenceLine {
  const CorrespondenceLine({required this.date, required this.sentence});

  /// Local `YYYY-MM-DD`, the day the sentence was composed for.
  final String date;

  /// The day's synthesis, as Aether wrote it.
  final String sentence;

  Map<String, Object?> toJson() => {'date': date, 'sentence': sentence};

  static CorrespondenceLine fromJson(Map<String, Object?> json) {
    final date = json['date'];
    final sentence = json['sentence'];
    if (date is! String || sentence is! String) {
      throw const CorrespondenceRefusal('That line is not a line.');
    }
    return CorrespondencePolicy.check(
      CorrespondenceLine(date: date, sentence: sentence),
    );
  }
}

/// What may cross, checked on the way out **and** on the way in.
///
/// Both directions, and that is not belt-and-braces. Outbound protects the
/// other person from this device; inbound protects this device from a
/// compromised peer, a stale document written by an older build, or a bug on
/// the other end. Neither check makes the other redundant.
abstract final class CorrespondencePolicy {
  /// One sentence of guidance. The synthesis dimension is bounded well under
  /// this by its own parser; the ceiling here is the wall, not the target.
  static const maxSentenceCharacters = 400;

  /// A numeral in the one field that is allowed to travel.
  ///
  /// **This catches digits and only digits, and that is worth stating plainly
  /// rather than describing it as catching measurements.** A real synthesis
  /// came back reading "rest settled near six hours and thirty-eight minutes" —
  /// a measurement, in words, which this would pass. Recognising spelled-out
  /// numbers reliably means a word list per language, and a word list is a
  /// thing that is always slightly out of date in exactly the place it matters.
  ///
  /// So the division is the one the whole product uses: **prevention in the
  /// prompt, defence here.** `EterPrompts` v7 forbids the synthesis from
  /// carrying a figure in digits *or* words, because it is the only line that
  /// can reach another person. This stays as the wall for the case the
  /// instruction stops landing, and refuses rather than trims — a sentence with
  /// the number taken out is still *about* the measurement.
  static final _carriesFigures = RegExp(r'\d');

  static CorrespondenceLine check(CorrespondenceLine line) {
    if (line.sentence.trim().isEmpty) {
      throw const CorrespondenceRefusal('There is no sentence to share.');
    }
    if (line.sentence.length > maxSentenceCharacters) {
      throw const CorrespondenceRefusal('That is longer than one sentence.');
    }
    if (!_isDate(line.date)) {
      throw const CorrespondenceRefusal('That line has no day.');
    }
    if (_carriesFigures.hasMatch(line.sentence)) {
      throw const CorrespondenceRefusal(
        'A shared line may not carry a measurement.',
      );
    }
    return line;
  }

  /// True when [line] may be shown, given today. A line from another day is
  /// not shown at all rather than shown with its date: the feature is one
  /// extra line beneath *today's* guidance, and yesterday's sentence sitting
  /// there unlabelled would read as today's.
  static bool isCurrent(CorrespondenceLine line, {required String today}) =>
      line.date == today;

  /// `DateTime.tryParse` is not a calendar check — it accepts `2026-02-31` and
  /// hands back the 3rd of March. The day has to be compared back.
  static bool _isDate(String value) {
    if (value.length != 10 || value[4] != '-' || value[7] != '-') return false;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return false;
    return value ==
        '${parsed.year.toString().padLeft(4, '0')}-'
            '${parsed.month.toString().padLeft(2, '0')}-'
            '${parsed.day.toString().padLeft(2, '0')}';
  }
}

/// A pairing invitation, as a code one person reads to another.
///
/// Short enough to say aloud, long enough that guessing is not a strategy:
/// eight characters from an alphabet of 32 is 2^40, against a Firestore rule
/// that only lets a signed-in caller read a code they can already name.
///
/// Ambiguous glyphs are out of the alphabet — `0`/`O` and `1`/`I`/`L` — because
/// this code's whole job is to survive being spoken over a kitchen table.
abstract final class PairingCode {
  static const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  static const length = 8;

  /// Normalises what somebody typed. Case, spaces and hyphens are not part of
  /// the code; a person copying one down will produce all three.
  ///
  /// Deliberately *not* clever about the excluded glyphs. `O` could be meant
  /// for `Q` or `D` as easily as anything, and a code that silently repairs
  /// itself into a different valid code is worse than one that says it is
  /// wrong — this is a bearer token, and the wrong one belongs to somebody.
  static String normalise(String typed) =>
      typed.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  static bool isWellFormed(String code) =>
      code.length == length &&
      code.split('').every((glyph) => alphabet.contains(glyph));
}
