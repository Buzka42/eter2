/// How well the birth time is actually known.
///
/// Eter used to offer two answers — a time to the minute, or nothing — and
/// almost nobody has either. People know they were born "in the morning", or
/// "just after midnight", because that is what gets retold. Forcing that into
/// an exact field produces a false ascendant stated with total confidence;
/// forcing it into "unknown" throws away real information and defaults the
/// chart to noon.
///
/// So there are three answers, and the difference between them is carried
/// everywhere the chart goes. An approximate time still yields an ascendant —
/// it is simply one the surfaces are required to hedge, exactly as they
/// already hedge an unknown one.
library;

enum BirthTimePrecision {
  /// Known to the minute, from a record rather than a memory.
  exact,

  /// A period of the day, chosen from [BirthTimePeriod].
  approximate,

  /// Not known at all. The chart is computed for noon and every
  /// time-dependent reading says so.
  unknown;

  static BirthTimePrecision fromName(String? name) => switch (name) {
        'exact' => BirthTimePrecision.exact,
        'approximate' => BirthTimePrecision.approximate,
        _ => BirthTimePrecision.unknown,
      };

  /// True when the ascendant and the houses may be stated plainly.
  ///
  /// Only an exact time earns that. The ascendant moves roughly a degree every
  /// four minutes, so a three-hour window is most of a sign — which is worth
  /// showing, and not worth asserting.
  bool get supportsPreciseAngles => this == BirthTimePrecision.exact;
}

/// A period of the day someone might actually remember being born in.
///
/// The representative minute is the middle of the window, which is the least
/// wrong single value: it is never more than half the window from the truth.
enum BirthTimePeriod {
  smallHours('Small hours', 'Around 1–4am', 150, 180),
  earlyMorning('Early morning', 'Around 4–7am', 330, 180),
  morning('Morning', 'Around 7am–noon', 570, 300),
  afternoon('Afternoon', 'Around noon–5pm', 870, 300),
  evening('Evening', 'Around 5–9pm', 1140, 240),
  night('Night', 'Around 9pm–1am', 1350, 240);

  const BirthTimePeriod(
    this.label,
    this.detail,
    this.representativeMinutes,
    this.windowMinutes,
  );

  final String label;
  final String detail;

  /// Minutes after local midnight, at the centre of the window.
  final int representativeMinutes;

  /// How wide the window is, which is what makes the hedge honest.
  final int windowMinutes;

  static BirthTimePeriod? forMinutes(int? minutes) {
    if (minutes == null) return null;
    for (final period in values) {
      if (period.representativeMinutes == minutes) return period;
    }
    return null;
  }
}
