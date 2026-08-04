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

/// kcal/day from lean mass — Katch-McArdle.
///
/// Preferred over Mifflin-St Jeor whenever body fat is actually known, because
/// it reads the tissue that does the spending rather than total mass and sex.
/// It is never used with a guessed composition: Eter does not estimate body
/// fat, so an absent value falls back to [rmrKcalPerDay] rather than to an
/// invented one.
double rmrKcalPerDayFromLeanMass({
  required double weightKg,
  required double bodyFatPercent,
}) {
  final leanKg = weightKg * (1 - bodyFatPercent / 100);
  return 370 + 21.6 * leanKg;
}

/// The best resting estimate the recorded facts support.
double restingKcalPerDay({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int age,
  double? bodyFatPercent,
}) =>
    bodyFatPercent == null
        ? rmrKcalPerDay(
            sex: sex,
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
          )
        : rmrKcalPerDayFromLeanMass(
            weightKg: weightKg,
            bodyFatPercent: bodyFatPercent,
          );

double rmrPerMin(double rmrPerDay) => rmrPerDay / 1440;

/// Walking energy, from steps, for the case where a source counts steps and
/// reports no calories at all.
///
/// **Why this exists.** Health Connect on a real phone delivered 22,720 steps
/// across three days and **zero** active energy: the step counter is the
/// handset's own, and nothing on that phone writes `ActiveCaloriesBurned`. The
/// day's burn was therefore resting alone, and somebody who had walked ten
/// thousand steps was told the same number as somebody who had not moved.
///
/// **Why it is not a violation of absent-not-zero.** The rule is that a
/// measurement nobody made must not be invented. This invents nothing: the
/// steps are measured, and this is the arithmetic that turns a measured
/// distance into the energy it costs. What would break the rule is the
/// opposite — reporting zero for a day that plainly had movement in it, which
/// is what was happening.
///
/// **The model, and what it is not.** Stride from height (Bassett: 0.415 of
/// standing height for men, 0.413 for women), and **net** walking cost of
/// about half a kilocalorie per kilogram per kilometre. Net, not gross,
/// because resting burn is already counted for every minute of the day and
/// gross would charge those minutes twice.
///
/// It is an estimate of walking. It does not know about hills, running, or a
/// bag of shopping, and it is deliberately conservative: understating movement
/// is a smaller lie than overstating it, in a product whose whole argument is
/// that it will not flatter anybody.
double activeKcalFromSteps({
  required int steps,
  required double weightKg,
  required double heightCm,
  required Sex sex,
}) {
  if (steps <= 0 || weightKg <= 0 || heightCm <= 0) return 0;
  final strideMetres = heightCm * (sex == Sex.female ? 0.413 : 0.415) / 100;
  final kilometres = steps * strideMetres / 1000;
  return kilometres * weightKg * netWalkKcalPerKgPerKm;
}

/// Net cost of walking a kilometre, per kilogram of body, above resting.
///
/// Gross is about 1.0; half of that is the part resting burn has not already
/// accounted for.
const netWalkKcalPerKgPerKm = 0.5;

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
///
/// The index is stored in the database, so a value may be **appended** and
/// never inserted or reordered: renumbering these would silently re-rank every
/// row already written.
enum SourcePriority {
  liveStrap,
  liveWatchSession,
  manualStrength,
  vendorDirect,
  hub,
  phoneSensors,

  /// A file somebody exported from another app and imported here.
  ///
  /// Last on purpose, and it is not a judgement about the other app. A file is
  /// a snapshot of what was true when it was written: it cannot be corrected,
  /// it may overlap a live source by months, and where the two disagree about
  /// a night the live one was measured on this device and this one was typed
  /// into a different one. Being outranked by everything is exactly right.
  importedFile,
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
