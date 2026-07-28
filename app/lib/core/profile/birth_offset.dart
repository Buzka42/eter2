/// Suggesting the UTC offset that was in force when someone was born.
///
/// Typing this by hand is the step people get wrong, and they get it wrong in
/// one specific way: they enter the offset their birthplace uses *now*.
/// Someone born in Warsaw in July 1990 was on +02:00, not the +01:00 the
/// country is usually labelled with — and an hour is half a sign of ascendant.
///
/// **This is a suggestion, not a determination**, and the interface says so.
/// Turning coordinates into a timezone needs the IANA boundary shapefile,
/// which is megabytes and which no Dart package publishes; so the zone here is
/// the *device's*, which is right for the common case of being born where you
/// still live and wrong for anyone who moved.
///
/// What it does get right, for any zone, is the historical rule. A local
/// `DateTime` carries the offset the platform's own timezone database says was
/// in force on that date — summer time and repealed legislation included —
/// which is the part a person cannot reasonably be expected to remember. That
/// is also why this needs no package: the platform already knows.
library;

abstract final class BirthOffset {
  /// The offset for [birthLocal] in the device's zone, or null if it cannot be
  /// determined.
  ///
  /// Never throws: without a suggestion the person types the offset
  /// themselves, exactly as before.
  static int? suggestMinutes(DateTime birthLocal) {
    try {
      // Constructed as a local wall-clock time, which is what a birth
      // certificate records — not an instant in UTC.
      final atBirth = DateTime(
        birthLocal.year,
        birthLocal.month,
        birthLocal.day,
        birthLocal.hour,
        birthLocal.minute,
      );
      final minutes = atBirth.timeZoneOffset.inMinutes;
      // Real offsets run from -12:00 to +14:00. Anything else means the
      // platform gave us something we should not put in a field.
      if (minutes < -12 * 60 || minutes > 14 * 60) return null;
      return minutes;
    } catch (_) {
      return null;
    }
  }

  /// `+01:00` / `-05:30`, the form the field expects.
  static String format(int minutes) {
    final sign = minutes < 0 ? '-' : '+';
    final absolute = minutes.abs();
    final hours = (absolute ~/ 60).toString().padLeft(2, '0');
    final rest = (absolute % 60).toString().padLeft(2, '0');
    return '$sign$hours:$rest';
  }
}
