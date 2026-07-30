import 'package:drift/drift.dart';

/// Drift schema v1.
///
/// Carried forward from the v1 tree's schema 18, minus the fitness-era
/// gamification the steering brief prohibits ("heavy gamification" is on the
/// avoid list): milestone counters and the flash they drove are gone.
///
/// Added: the precise wearable signals guidance actually needs (sleep stages,
/// resting heart rate, HRV, sessions), the onboarding intake, and the guidance
/// memory that makes the product worth renewing.
///
/// Sync convention: every table the user would expect to survive a phone swap
/// carries a nullable `syncedAt`. Null means "not yet pushed". Drift stays
/// canonical; Firestore is a mirror and never the calculation source.

@DataClassName('ProfileRow')
class Profiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  DateTimeColumn get dob => dateTime()();

  /// `female` | `male` | `other`.
  ///
  /// v1 emitted `unspecified` from Dart while firestore.rules only allowed
  /// `other`, so those users' profile mirrors were rejected and the error was
  /// swallowed. The names now agree; do not change one without the other.
  TextColumn get sex => text()();

  RealColumn get weightKg => real()();
  RealColumn get heightCm => real().nullable()();

  /// Optional body fat, 5–40% in 2.5-point steps. Null means unknown, which is
  /// the honest and common case — it is never estimated from weight and height.
  ///
  /// When present it improves two different things: resting burn is derived
  /// from lean mass (Katch-McArdle) rather than from body mass alone, and the
  /// guidance context can speak about composition instead of a single number.
  RealColumn get bodyFatPercent => real().nullable()();
  TextColumn get units => text()();
  TextColumn get firstName => text().nullable()();

  BoolColumn get hapticsEnabled =>
      boolean().withDefault(const Constant(true))();

  /// `grounded` | `balanced` | `immersive`. The setting, not the appearance —
  /// `balanced` resolves against real sunrise and sunset at run time.
  TextColumn get guidanceMode =>
      text().withDefault(const Constant('balanced'))();

  /// `journal` | `dashboard`. Which surface the app opens on.
  TextColumn get startSurface =>
      text().withDefault(const Constant('dashboard'))();

  /// `en` | `pl`. Which language Eter speaks — see `core/i18n/language.dart`.
  ///
  /// Nullable, and null means "nobody has chosen", which is a different fact
  /// from "chose English". An unchosen language follows the phone on every
  /// launch, so somebody who switches their OS to Polish is met in Polish; a
  /// chosen one is theirs and stops following anything. Defaulting the column to
  /// `'en'` would have quietly converted the first launch into a choice and
  /// stranded every Polish-speaking install in English.
  TextColumn get language => text().nullable()();

  /// Birth data. Nullable because only the date is required; the chart
  /// degrades gracefully without a time or place.
  IntColumn get birthTimeMinutes => integer().nullable()();

  /// `exact` | `approximate` | `unknown`. See `core/profile/birth_time.dart`.
  ///
  /// Distinguishes a time read off a record from a period someone remembers.
  /// Both produce an ascendant; only the first earns one stated without a
  /// hedge, because the ascendant crosses a sign roughly every two hours.
  TextColumn get birthTimePrecision =>
      text().withDefault(const Constant('unknown'))();
  IntColumn get birthUtcOffsetMinutes => integer().nullable()();
  TextColumn get birthPlace => text().nullable()();
  RealColumn get birthLatitude => real().nullable()();
  RealColumn get birthLongitude => real().nullable()();

  /// Where the person lives now, which is what the register actually turns on.
  ///
  /// Separate from the birth columns above and never a substitute for them: the
  /// chart is cast where you were born and cannot be recast, while sunrise and
  /// sunset are facts about where you are standing. Conflating the two made the
  /// night register arrive mid-morning for anyone who had moved — see
  /// `registerCoordinates` in `core/symbolic/solar.dart`.
  ///
  /// Null is the ordinary state and stays null for the majority who still live
  /// near where they were born; the resolver only needs this once the device's
  /// clock proves the birth coordinates cannot be current.
  TextColumn get homePlace => text().nullable()();
  RealColumn get homeLatitude => real().nullable()();
  RealColumn get homeLongitude => real().nullable()();

  /// When the user consented to AI processing, and to journal prose crossing
  /// the boundary specifically. Null means never — and with these null the
  /// guidance pipeline must not send prose. Separate fields because they are
  /// separate decisions and the second is the consequential one.
  DateTimeColumn get aiConsentAt => dateTime().nullable()();
  DateTimeColumn get journalAiConsentAt => dateTime().nullable()();

  /// When the user agreed to send crash reports. Null means never, which is
  /// the default and the shipped state until someone chooses otherwise.
  ///
  /// A crash report carries a stack trace, a device model and an OS version.
  /// It never carries a journal page, a measurement or an identifier Eter
  /// chose — see `core/diagnostics/crash_reporter.dart`, which is where that
  /// promise is kept rather than merely stated.
  DateTimeColumn get crashReportConsentAt => dateTime().nullable()();

  /// When the user consented to cloud sync. Null means local-only.
  ///
  /// This covers the measured record: weights, meals, sessions, sleep, day
  /// totals. It deliberately does not cover journal prose.
  DateTimeColumn get cloudSyncConsentAt => dateTime().nullable()();

  /// When the user consented to their journal prose leaving the device for
  /// the mirror specifically.
  ///
  /// Separate for the same reason [journalAiConsentAt] is separate from
  /// [aiConsentAt]: the pages are the most personal thing in the database and
  /// agreeing to keep a copy of your weights is not agreeing to keep a copy of
  /// what you wrote at 2am. A person can have full recovery of their body log
  /// and no copy of their journal anywhere but this phone.
  DateTimeColumn get journalCloudSyncConsentAt => dateTime().nullable()();

  TextColumn get connectedSourcesJson =>
      text().withDefault(const Constant('[]'))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DaySummaryRow')
class DaySummaries extends Table {
  /// ISO `yyyy-MM-dd` in the user's local day, not UTC.
  TextColumn get date => text()();
  RealColumn get activeKcal => real().withDefault(const Constant(0))();
  RealColumn get basalKcal => real().withDefault(const Constant(0))();
  RealColumn get intakeKcal => real().nullable()();
  IntColumn get steps => integer().withDefault(const Constant(0))();
  IntColumn get sessionsCount => integer().withDefault(const Constant(0))();

  /// Set when a recomputation lowered the day's total, so the surface can say
  /// so rather than silently shrinking a number the user already read.
  BoolColumn get recalibrated => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// Raw imports, before deduplication. The natural key makes replay safe:
/// ingesting the same record twice cannot change a total.
@DataClassName('RawBucketRow')
class RawBuckets extends Table {
  DateTimeColumn get minuteUtc => dateTime()();
  TextColumn get source => text()();
  RealColumn get activeKcal => real()();
  IntColumn get steps => integer().nullable()();
  RealColumn get avgHr => real().nullable()();
  IntColumn get hrSampleCount => integer().withDefault(const Constant(0))();
  IntColumn get priority => integer()();
  TextColumn get externalId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {source, minuteUtc};
}

/// The deduplicated winners. Exactly one source owns each minute.
@DataClassName('MinuteBucketRow')
class MinuteBuckets extends Table {
  DateTimeColumn get minuteUtc => dateTime()();
  RealColumn get activeKcal => real()();
  IntColumn get steps => integer().nullable()();
  RealColumn get avgHr => real().nullable()();
  TextColumn get winningSource => text()();

  /// Human-readable, so the health surface can answer "why is my number X?"
  /// with "13:00-14:00 · Polar strap" instead of an argument.
  TextColumn get provenance => text()();

  @override
  Set<Column<Object>> get primaryKey => {minuteUtc};
}

@DataClassName('IntegrationRow')
class Integrations extends Table {
  TextColumn get vendor => text()();

  /// `connected` | `disconnected` | `reauthNeeded` | `error`.
  TextColumn get status => text()();
  DateTimeColumn get lastAttempt => dateTime().nullable()();
  DateTimeColumn get lastSync => dateTime().nullable()();

  /// Health Connect differential-sync token. v1 plumbed this end to end and
  /// then discarded it in the hub, so every sync was a full re-read; the v2
  /// hub must actually use it.
  TextColumn get changesToken => text().nullable()();
  IntColumn get recordsToday => integer().withDefault(const Constant(0))();
  TextColumn get diagnosticsJson => text().withDefault(const Constant('{}'))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {vendor};
}

// ---------------------------------------------------------------------------
// Precise wearable signals. New in v2 -- guidance that claims to read sleep or
// recovery needs somewhere to read it from.
// ---------------------------------------------------------------------------

/// One stage of one sleep period.
///
/// Stored as segments rather than a nightly total so the charts can show the
/// shape of a night and guidance can say something about its structure.
@DataClassName('SleepSegmentRow')
class SleepSegments extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startUtc => dateTime()();
  DateTimeColumn get endUtc => dateTime()();

  /// `awake` | `light` | `deep` | `rem` | `unknown`. Hubs frequently report
  /// only `unknown`; the charts must render that honestly rather than
  /// inventing a distribution.
  TextColumn get stage => text()();
  TextColumn get source => text()();
  IntColumn get priority => integer()();

  /// The night this segment belongs to, as a local `yyyy-MM-dd`. A sleep
  /// period crossing midnight belongs to the morning it ends on.
  TextColumn get nightOf => text()();
  TextColumn get externalId => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

/// Once-a-day physiological readings a wearable produces.
@DataClassName('DailyVitalsRow')
class DailyVitals extends Table {
  TextColumn get date => text()();
  RealColumn get restingHr => real().nullable()();
  RealColumn get hrvMs => real().nullable()();
  RealColumn get respiratoryRate => real().nullable()();
  RealColumn get bodyTemperatureDelta => real().nullable()();

  /// Vendor-computed scores. Kept separate from the raw signals because they
  /// are opinions, not measurements, and guidance should say which it is using.
  RealColumn get sleepScore => real().nullable()();
  RealColumn get readinessScore => real().nullable()();
  TextColumn get source => text()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// A discrete activity with a start and an end.
///
/// A session claims its whole minute range at its priority; lower-priority
/// minutes inside that range are discarded rather than summed.
@DataClassName('ActivitySessionRow')
class ActivitySessions extends Table {
  TextColumn get id => text()();
  TextColumn get sport => text().nullable()();
  DateTimeColumn get startUtc => dateTime()();
  DateTimeColumn get endUtc => dateTime()();
  RealColumn get activeKcal => real().nullable()();
  RealColumn get avgHr => real().nullable()();
  RealColumn get maxHr => real().nullable()();
  IntColumn get steps => integer().nullable()();
  TextColumn get source => text()();
  IntColumn get priority => integer()();
  TextColumn get externalId => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Logged and derived records.
// ---------------------------------------------------------------------------

@DataClassName('StrengthWorkoutRow')
class StrengthWorkouts extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  RealColumn get bodyWeightKgAtTime => real()();
  TextColumn get exercisesJson => text()();
  RealColumn get fallbackKcal => real()();
  RealColumn get finalKcal => real()();
  TextColumn get method => text().withDefault(const Constant('fallback'))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('WeightEntryRow')
class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get kg => real()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// The key this row occupies in the mirror, once it has one.
  ///
  /// Null until the row is first pushed, and then never changes. It exists
  /// because [id] cannot do this job across a phone swap: mirror documents used
  /// to be keyed on the local autoincrement id, and a restore reassigns those,
  /// so every subsequent push wrote to a *different* document than the one it
  /// meant to replace. See `SyncService.mirrorKeyFor`.
  TextColumn get mirrorId => text().nullable()();
}

@DataClassName('NutritionEntryRow')
class NutritionEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get kcal => real()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get carbsG => real().nullable()();
  RealColumn get fatG => real().nullable()();
  TextColumn get meal => text()();
  TextColumn get source => text().withDefault(const Constant('eter'))();

  /// Carries `journalEntryId` when this row was derived from a journal entry,
  /// which is what makes per-item correction and undo possible.
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();

  /// An estimate the user has not yet confirmed. The brief is explicit that AI
  /// food estimates "remain editable and require confirmation before being
  /// saved" -- unconfirmed rows must not count toward any total.
  BoolColumn get confirmed => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// See `WeightEntries.mirrorId`.
  TextColumn get mirrorId => text().nullable()();
}

@DataClassName('LiveSessionRow')
class LiveSessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  TextColumn get sourceId => text()();
  TextColumn get hrSeriesJson => text()();
  RealColumn get finalKcal => real()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RememberedSensorRow')
class RememberedSensors extends Table {
  TextColumn get deviceId => text()();
  TextColumn get name => text()();
  BoolColumn get paired => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastConnected => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

/// Self-reported mood, stress, recovery and practice.
@DataClassName('LifestyleEntryRow')
class LifestyleEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get recordedAt => dateTime()();

  /// `mood` | `stress` | `recovery` | `sleep` | `meditation` | `breathwork`.
  TextColumn get kind => text()();
  RealColumn get value => real().nullable()();
  RealColumn get durationMinutes => real().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('self-report'))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// See [WeightEntries.mirrorId].
  TextColumn get mirrorId => text().nullable()();
}

/// One local day, as the day's own pages tell it.
///
/// Two things at once, produced by a single pass over everything written that
/// day:
///
/// * [story] — a few sentences of continuous prose the Journal always shows.
///   It is the day read back to the person, not advice.
/// * [digestJson] — the same day compressed into the few structured points
///   guidance actually needs (movement, food, mood, sleep, notable events).
///   Guidance sends this instead of the raw prose, which is what keeps the
///   request small however much someone writes.
///
/// Regenerated whenever the day's entries change, so [entryCount] and
/// [sourceFingerprint] record what it was made from.
@DataClassName('JournalDayStoryRow')
class JournalDayStories extends Table {
  /// Local `YYYY-MM-DD`.
  TextColumn get date => text()();
  DateTimeColumn get generatedAt => dateTime()();
  TextColumn get story => text()();
  TextColumn get digestJson => text().withDefault(const Constant('{}'))();
  IntColumn get entryCount => integer().withDefault(const Constant(0))();

  /// Hash of the prose this was derived from. An unchanged fingerprint means
  /// the story is current and no provider call is needed.
  TextColumn get sourceFingerprint => text()();
  TextColumn get model => text().withDefault(const Constant('provider'))();

  /// Which `EterPrompts.version` composed this. Null on rows written before
  /// the column existed — an honest "we no longer know" rather than a guess.
  IntColumn get promptVersion => integer().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// Today's sky against the natal chart, and what was written about it.
///
/// The contacts themselves are arithmetic and recomputed freely; this table
/// caches the *prose*, which costs a provider call. Keyed by day and by the
/// chart it was read against, so changing birth context retires old readings
/// rather than editing them.
@DataClassName('TransitReadingRow')
class TransitReadings extends Table {
  TextColumn get date => text()();

  /// The same local chart hash the Vessel's readings use.
  TextColumn get inputHash => text()();
  DateTimeColumn get generatedAt => dateTime()();

  /// The computed contacts, kept so a reading can be inspected against what it
  /// was written from.
  TextColumn get contactsJson => text()();
  TextColumn get passage => text()();
  TextColumn get model => text().withDefault(const Constant('provider'))();

  /// See [JournalDayStories.promptVersion].
  IntColumn get promptVersion => integer().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {date, inputHash};
}

// ---------------------------------------------------------------------------
// The journal.
// ---------------------------------------------------------------------------

/// An entry as the user wrote or spoke it, plus whatever Aether made of it.
///
/// The prose is the source of truth for what was said; the extraction is a
/// derived interpretation the user can correct. Both are kept so a correction
/// can re-derive rather than guess.
///
/// v1 guaranteed this text never left the device. v2 does not: with consent it
/// reaches the model and syncs to Firestore. [excludedFromAi] is the user's
/// fine-grained control over that and the brief requires it.
@DataClassName('JournalEntryRow')
class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();

  /// `text` is also Drift's column builder, so the Dart getter differs. The
  /// persisted column stays exactly `text`.
  TextColumn get entryText => text().named('text')();

  /// `typed` | `spoken`. Spoken entries carry transcription error the user may
  /// want to fix.
  TextColumn get source => text().withDefault(const Constant('typed'))();

  /// `pending` | `classified` | `needsDetail` | `failed` | `discarded`.
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get extractionJson => text().nullable()();
  TextColumn get model => text().nullable()();

  /// See [JournalDayStories.promptVersion].
  IntColumn get promptVersion => integer().nullable()();

  /// Set once the derived rows exist, so a retry cannot double-log the same
  /// meal into NutritionEntries.
  DateTimeColumn get appliedAt => dateTime().nullable()();

  /// The user has excluded this entry from AI processing. Guidance must not
  /// see it, in prose or in summary. Classification is still allowed, because
  /// that is what the user explicitly asked for when they wrote it.
  BoolColumn get excludedFromAi =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// See [WeightEntries.mirrorId]. This is the column that matters most: a
  /// discarded page is pushed as a blanked row so it overwrites the prose in
  /// the mirror, and without a stable key that overwrite landed on a new
  /// document and left the original page in the cloud permanently.
  TextColumn get mirrorId => text().nullable()();
}

// ---------------------------------------------------------------------------
// Guidance, memory and the symbolic layer.
// ---------------------------------------------------------------------------

/// Every composition Aether has produced, not just the latest.
///
/// This replaces v1's single-row GuidanceCache and it is the retention
/// mechanic. Without history, guidance repeats itself and has no way to say
/// "last Tuesday you wrote that you were dreading the week."
@DataClassName('GuidanceHistoryRow')
class GuidanceHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Local `yyyy-MM-dd`.
  TextColumn get date => text()();

  /// `synthesis` | `health` | `mind` | `spirit`. The collapsed surface renders
  /// the synthesis; expanding shows the three dimensions.
  TextColumn get dimension => text()();
  DateTimeColumn get generatedAt => dateTime()();
  TextColumn get contentJson => text()();

  /// The receipts behind any claim resting on data: n, window, coefficient.
  /// Null when the passage made no empirical claim.
  TextColumn get evidenceJson => text().nullable()();

  /// Detects whether the inputs actually changed, so a recomposition is only
  /// requested when there is something new to say.
  TextColumn get contextFingerprint => text()();

  /// The model, or `local` for the offline composition. The surface tells the
  /// user which they are reading.
  TextColumn get source => text()();

  /// See [JournalDayStories.promptVersion].
  IntColumn get promptVersion => integer().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

/// What Aether said on a day, compressed to the substance of it.
///
/// Guidance was composing every morning as though it had never spoken to this
/// person. It could repeat yesterday's observation word for word, contradict
/// what it said on Tuesday, and re-offer a walk that had been declined four
/// times — and the 365 days of [GuidanceHistory] sitting beside it were only
/// ever read as a cache, keyed by fingerprint.
///
/// So each composition also writes one telegraphic line here, and the next
/// fortnight of them travels with the request. Telegraphic on purpose: the
/// prose is already in [GuidanceHistory] and sending fourteen days of it would
/// cost more of the budget than the records the day is actually about. What is
/// wanted is the thread, not the writing.
///
/// One row per local day, replaced when the day is recomposed. Fourteen rows
/// is the whole of what guidance ever reads.
@DataClassName('GuidanceRecallRow')
class GuidanceRecalls extends Table {
  /// Local `yyyy-MM-dd`.
  TextColumn get date => text()();
  DateTimeColumn get generatedAt => dateTime()();

  /// The substance of that day's synthesis, in as few words as carry it.
  TextColumn get note => text()();

  /// The action that day offered, so tomorrow does not offer it again.
  TextColumn get action => text().nullable()();

  /// Whether the composition this came from could see journal material.
  ///
  /// A note written while journal consent was on may paraphrase a page. If that
  /// consent is later withdrawn, the note must stop travelling with it —
  /// otherwise revoking would leave last week's pages still reaching the model,
  /// laundered through Eter's own prose.
  BoolColumn get usedJournal =>
      boolean().withDefault(const Constant(false))();

  /// Which `EterPrompts.version` wrote it.
  IntColumn get promptVersion => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// A long-form interpretation, composed once against this user's chart.
///
/// Keyed by `(inputHash, positionKey)` so each position is composed at most
/// once, ever. `inputHash` is the deterministic hash of the birth inputs; a
/// user who corrects their birth time gets fresh readings rather than stale
/// ones about a chart that is no longer theirs.
@DataClassName('VesselReadingRow')
class VesselReadings extends Table {
  TextColumn get inputHash => text()();

  /// `lifePath` | `sun` | `moon` | `ascendant` | `house.7` | `card.strength`.
  TextColumn get positionKey => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get contentJson => text()();
  TextColumn get model => text()();

  /// See [JournalDayStories.promptVersion].
  IntColumn get promptVersion => integer().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {inputHash, positionKey};
}

/// The day's card, chosen by the application with a stated reason.
///
/// The brief is explicit: "The AI may interpret the selected card, but the
/// application should retain control over how the card is chosen." Storing the
/// reason is what makes that inspectable rather than a claim.
@DataClassName('DailyCardRow')
class DailyCards extends Table {
  TextColumn get date => text()();
  TextColumn get arcanaSlug => text()();

  /// Why this card, in the app's own words. Shown when the user asks.
  TextColumn get reason => text()();

  /// The inputs the selection weighed: transits, personal year, recent
  /// signals, previous cards. Inspectable, per the brief's requirement that
  /// personalization be structured rather than opaque.
  TextColumn get sourceJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// A deterministic correlation, computed locally and marked non-causal.
///
/// Feeds the evidence chips. The brief requires these be inspectable and
/// dismissible, which is what `status` is for.
@DataClassName('PatternCandidateRow')
class PatternCandidates extends Table {
  TextColumn get key => text()();
  DateTimeColumn get computedAt => dateTime()();
  TextColumn get summary => text()();
  TextColumn get evidenceJson => text()();
  RealColumn get confidence => real()();

  /// `active` | `dismissed`. A dismissed pattern must not reach the model.
  TextColumn get status => text().withDefault(const Constant('active'))();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// The periodic review: what you wrote against what your body did.
@DataClassName('RetrospectiveRow')
class Retrospectives extends Table {
  TextColumn get id => text()();

  /// `weekly` | `monthly` | `biannual`.
  TextColumn get kind => text()();
  TextColumn get periodStart => text()();
  TextColumn get periodEnd => text()();
  DateTimeColumn get generatedAt => dateTime()();
  TextColumn get contentJson => text()();
  TextColumn get evidenceJson => text().nullable()();
  TextColumn get model => text()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The onboarding intake, key/value so it extends without a migration.
///
/// Deliberately not columns: the question set will change, and a schema
/// migration per question is how intake stops being revisable.
@DataClassName('IntakeAnswerRow')
class IntakeAnswers extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  /// `essential` | `valuable` | `optional`. Mirrors the onboarding grading, so
  /// the prompt builder can weight what it includes and the Sanctum can show
  /// the user what they chose to give.
  TextColumn get tier => text().withDefault(const Constant('optional'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
