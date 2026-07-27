/// Eter energy engine — pure functions, zero Flutter imports.
/// Specs: 05 (RMR), 07 (Keytel), 08 (MET fallback), 11 (dedup).
library;

enum Sex { female, male, other }

// ---------------------------------------------------------------------------
// RMR — Mifflin-St Jeor (spec 05)
// ---------------------------------------------------------------------------

/// kcal/day. male: 10kg + 6.25cm − 5age + 5 · female: −161 · unspecified: mean.
double rmrKcalPerDay({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int age,
}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return switch (sex) {
    Sex.male => base + 5,
    Sex.female => base - 161,
    Sex.other => base + (5 - 161) / 2,
  };
}

double rmrPerMin(double rmrPerDay) => rmrPerDay / 1440;

/// Everything the body has spent so far today: resting burn accrued since
/// midnight plus logged activity.
///
/// One definition on purpose. "Burned" used to mean activity alone on the
/// dashboard figure and resting-plus-activity on the Scales, so the same word
/// labelled 0 and 828 on a single scroll (§4 C2).
double burnedSoFarToday({
  required double restingKcalPerMin,
  required double activeKcal,
  required DateTime now,
}) =>
    restingKcalPerMin * (now.hour * 60 + now.minute) + activeKcal;

// ---------------------------------------------------------------------------
// Home burn state (spec 06)
// ---------------------------------------------------------------------------

double burnRatePerMin({
  required double trailingFiveMinuteActiveKcal,
  required double restingKcalPerMin,
}) =>
    trailingFiveMinuteActiveKcal / 5 + restingKcalPerMin;

double pulseThreshold({
  required double restingKcalPerMin,
  double multiplier = 1.5,
}) =>
    restingKcalPerMin * multiplier;

bool shouldPulse({
  required double trailingFiveMinuteActiveKcal,
  required double restingKcalPerMin,
  double multiplier = 1.5,
}) =>
    burnRatePerMin(
      trailingFiveMinuteActiveKcal: trailingFiveMinuteActiveKcal,
      restingKcalPerMin: restingKcalPerMin,
    ) >=
    pulseThreshold(
      restingKcalPerMin: restingKcalPerMin,
      multiplier: multiplier,
    );

double cloudFill({required double activeKcal, required double activeGoal}) {
  if (activeGoal <= 0) return 0;
  return (activeKcal / activeGoal).clamp(0, 1.25);
}

// ---------------------------------------------------------------------------
// Keytel (2005) HR -> kcal/min (spec 07)
// ---------------------------------------------------------------------------

/// kcal/min from heart rate. Formula yields kJ/min; divided by 4.184.
double keytelKcalPerMin({
  required Sex sex,
  required double hr,
  required double weightKg,
  required int age,
}) {
  final male =
      (-55.0969 + 0.6309 * hr + 0.1988 * weightKg + 0.2017 * age) / 4.184;
  final female =
      (-20.4022 + 0.4472 * hr - 0.1263 * weightKg + 0.0740 * age) / 4.184;
  return switch (sex) {
    Sex.male => male,
    Sex.female => female,
    Sex.other => (male + female) / 2,
  };
}

/// Session integration floor (spec 07): below HR 90 the regression
/// under-reads — clamp to 1.2 × resting rate while a session is active.
double sessionKcalPerMin({
  required Sex sex,
  required double hr,
  required double weightKg,
  required int age,
  required double restingKcalPerMin,
}) {
  final k = keytelKcalPerMin(sex: sex, hr: hr, weightKg: weightKg, age: age);
  return hr < 90
      ? (k > 1.2 * restingKcalPerMin ? k : 1.2 * restingKcalPerMin)
      : k;
}

/// HRmax — Tanaka (spec 07). Zones Z1..Z5 at 50/60/70/80/90% of HRmax.
double hrMaxTanaka(int age) => 208 - 0.7 * age;

/// 0 = below Z1, 1..5 = zone.
int hrZone(double hr, double hrMax) {
  final pct = hr / hrMax;
  if (pct < 0.50) return 0;
  if (pct < 0.60) return 1;
  if (pct < 0.70) return 2;
  if (pct < 0.80) return 3;
  if (pct < 0.90) return 4;
  return 5;
}

// ---------------------------------------------------------------------------
// MET fallback for strength (spec 08)
// ---------------------------------------------------------------------------

enum SetTechnique { normal, superset, dropSet, restPause, eccentric }

double techniqueFactor(SetTechnique t) => switch (t) {
      SetTechnique.normal => 1.00,
      SetTechnique.superset => 1.15,
      SetTechnique.dropSet => 1.12,
      SetTechnique.restPause => 1.10,
      SetTechnique.eccentric => 1.08,
    };

double metKcalPerMin({required double met, required double weightKg}) =>
    met * 3.5 * weightKg / 200;

/// One exercise's fallback kcal (spec 08 formula, EPOC applied at workout
/// level by [applyEpoc]).
///
/// activeMinutes = (sets × avgSecPerSet + Σrest × 0.35) / 60
/// avgSecPerSet  = reps × (3 + eccentricExtraSec)
double exerciseFallbackKcal({
  required double metHint,
  required double weightKg,
  required int sets,
  required int repsPerSet,
  required double restSecPerGap, // rest after each set except the last
  double eccentricExtraSecPerRep = 0,
  SetTechnique technique = SetTechnique.normal,
}) {
  final workSec = sets * repsPerSet * (3 + eccentricExtraSecPerRep);
  final restSec = (sets - 1) * restSecPerGap * 0.35;
  final activeMin = (workSec + restSec) / 60;
  return metKcalPerMin(met: metHint, weightKg: weightKg) *
      activeMin *
      techniqueFactor(technique);
}

/// EPOC: +7% at workout level (spec 08).
double applyEpoc(double workoutKcal) => workoutKcal * 1.07;

/// Blend rule (spec 12): ≥70% HR coverage → 0.6×HR + 0.4×AI.
double blendFinalKcal({
  required double? keytelSessionKcal,
  required double? aiKcal,
  required double fallbackKcal,
  required double hrCoveragePct,
}) {
  if (keytelSessionKcal != null && aiKcal != null && hrCoveragePct >= 70) {
    return 0.6 * keytelSessionKcal + 0.4 * aiKcal;
  }
  return aiKcal ?? fallbackKcal;
}

// ---------------------------------------------------------------------------
// Deduplication (spec 11) — per minute bucket, exactly one source wins.
// ---------------------------------------------------------------------------

/// Priority high→low. Lower index wins.
enum SourcePriority {
  liveStrap,
  liveWatchSession,
  manualStrength,
  vendorDirect,
  hub,
  phoneSensors,
}

class MinuteBucket {
  const MinuteBucket({
    required this.minuteUtc,
    required this.activeKcal,
    required this.sourceId,
    required this.priority,
    this.hrSampleCount = 0,
    this.steps,
    this.avgHr,
  });
  final DateTime minuteUtc;
  final double activeKcal;
  final String sourceId;
  final SourcePriority priority;
  final int hrSampleCount;
  final int? steps;
  final double? avgHr;
}

/// Resolve raw buckets to one winner per minute.
/// Tie at same priority: higher HR sample density wins; still tied →
/// alphabetically stable sourceId (never "higher kcal" — prevents inflation).
Map<DateTime, MinuteBucket> dedupe(Iterable<MinuteBucket> raw) {
  final winners = <DateTime, MinuteBucket>{};
  for (final b in raw) {
    final cur = winners[b.minuteUtc];
    if (cur == null) {
      winners[b.minuteUtc] = b;
      continue;
    }
    final byPriority = b.priority.index.compareTo(cur.priority.index);
    if (byPriority < 0) {
      winners[b.minuteUtc] = b;
    } else if (byPriority == 0) {
      if (b.hrSampleCount > cur.hrSampleCount ||
          (b.hrSampleCount == cur.hrSampleCount &&
              b.sourceId.compareTo(cur.sourceId) < 0)) {
        winners[b.minuteUtc] = b;
      }
    }
  }
  return winners;
}

double dailyTotalKcal(Map<DateTime, MinuteBucket> winners) =>
    winners.values.fold(0.0, (sum, b) => sum + b.activeKcal);
