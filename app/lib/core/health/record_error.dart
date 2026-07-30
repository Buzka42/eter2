/// Why a record derived from a journal page could not be written.
///
/// A code, for the same reason `BirthContextError` is one: these are thrown deep
/// in the write services — which validate a number and have no idea who is
/// reading — and they surface at the top of the Journal, in whatever language
/// Eter is speaking. A `const` English sentence thrown from
/// `ManualActivityService` cannot be both.
///
/// Every value here is a *bound being exceeded*, never a diagnosis. The bounds
/// themselves live with the service that enforces them; this only names which
/// one was hit, and `EterStrings.bodyRecordError` says it.
enum BodyRecordError {
  /// The activity name was empty or longer than 80 characters.
  activityName,

  /// Duration outside 1–1,440 minutes.
  activityDuration,

  /// Active energy outside 1–10,000 kcal.
  activityEnergy,

  /// Weight outside 20–500 kg.
  weightRange,

  /// A workout with no exercise carrying at least one set.
  strengthNeedsExercise,

  /// A set outside 1–500 reps.
  strengthReps,

  /// A load outside 0–1,000 kg.
  strengthLoad,

  /// Strength energy is derived from body weight, and there is none on file.
  strengthNeedsBodyWeight,
}
