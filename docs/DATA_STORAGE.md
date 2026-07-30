# Eter · what is stored, where, and for how long

Current as of 30 July 2026, schema 9. Supersedes
`archive/14-data-models-firebase.md` and `archive/16-privacy-compliance.md`.

Principle: **the device is canonical.** Every surface reads local SQLite.
The cloud is a mirror written to when there is a connection and read from
exactly once — on a signed-in device with no history of its own.

---

## 1. Local store

Drift/SQLite at `<app documents>/eter.sqlite`, defined in
`core/db/tables.dart`, accessed only through `core/db/app_database.dart`.

### Identity and consent

| Table | Holds |
|---|---|
| `Profiles` (single row, id=1) | first name, DOB, sex, weight, height, body fat, units, guidance mode, start surface, `language`, **birth time / UTC offset / place / lat / lon**, and five consent timestamps: `aiConsentAt`, `journalAiConsentAt`, `crashReportConsentAt`, `cloudSyncConsentAt`, `journalCloudSyncConsentAt` |

This is the only place birth time and coordinates exist. They never enter an
AI payload; they are used on-device by `NatalChartEngine` and as the
`inputHash` that keys cached readings.

### Measured record

| Table | Holds | Retention |
|---|---|---|
| `RawBuckets` | pre-dedup minute imports, per source | **90 days** (`pruneRawBuckets`) |
| `MinuteBuckets` | deduplicated winners + provenance | unbounded |
| `DaySummaries` | per-day totals | unbounded |
| `SleepSegments` | stages, keyed to `nightOf` | unbounded |
| `DailyVitals` | RHR, HRV, respiratory rate, temp delta, scores | unbounded |
| `ActivitySessions`, `StrengthWorkouts`, `LiveSessions` | sessions; live HR series | HR series **180 days** (`pruneLiveHeartRateSeries`) |
| `WeightEntries`, `NutritionEntries`, `LifestyleEntries` | manual and derived records | unbounded |
| `Integrations`, `RememberedSensors` | device-local connection state | device-local |

`runLocalRetention()` runs every bounded prune. See §4.

### Written and generated content

| Table | Holds | Notes |
|---|---|---|
| `JournalEntries` | the person's prose, `status`, `excludedFromAi`, `extractionJson`, `model`, `appliedAt` | discarding blanks the text and sets `status: 'discarded'`; the row id is retained so nothing can be re-pointed at a different page |
| `JournalDayStories` | one story + digest per local date, `sourceFingerprint` | model output |
| `GuidanceHistory` | one row per dimension per composition, `contentJson`, `evidenceJson`, `contextFingerprint` | model output |
| `GuidanceRecalls` | one telegraphic note per local day, plus that day's action, `usedJournal`, replaced on recompose | model output; the fortnight guidance reads so it stops repeating itself |
| `VesselReadings` | one passage per position, keyed by `inputHash` | model output; `clearVesselReadingsExcept` drops readings for superseded charts |
| `TransitReadings` | one passage per (date, `inputHash`) | model output |
| `DailyCards` | the day's Arcana draw + reason | device arithmetic, no model |
| `PatternCandidates` | locally discovered correlations, `status` | dismissed patterns are never re-sent to a model |
| `Retrospectives`, `IntakeAnswers` | periodic summaries; onboarding answers | |

### Local controls

- `discardJournalEntry(id)` — blank one page.
- `pruneJournalProse(olderThanUtc)` — bulk-blank old prose, keeping derived
  facts. Exposed as **Sanctum → Old pages → Clear**, at one year.
- `revertJournalEntryRows(id)` — delete every record one entry produced.
- `resetPersonalization()` — clears guidance, its recall notes, patterns and
  retrospectives.
- `deleteAllLocalData()` — truncates every table. Distinct from account
  deletion, which must additionally clear the mirror.
- `LocalDataExporter` (`core/privacy/local_data_export.dart`) — writes a JSON
  snapshot of every table plus CSVs for the high-volume tables, no account and
  no network involved.

---

## 2. Cloud mirror

Firestore, under `users/{uid}/…`, behind the `CloudMirror` interface so the
sync rules are testable without a project. Requires `cloudSyncConsentAt` **and**
a confirmed email account (`account.canSync`).

**Mirrored:** `profile`, `weights`, `nutrition`, `lifestyle`, `sessions`,
`strength`, `days` — and `journal` only under the separate
`journalCloudSyncConsentAt`.

**Withheld, with the reason recorded in `SyncService.withheld`:**
`minuteBuckets`, `rawBuckets`, `guidanceHistory`, `guidanceRecalls`,
`vesselReadings`, `transitReadings`, `journalDayStories`, `integrations`.

So: **no model output is ever mirrored.** The cloud holds the record, not the
readings composed from it.

Note that the mirrored `profile` document *does* carry `firstName`, `dob`,
`birthTimeMinutes`, `birthUtcOffsetMinutes`, `birthPlace`, `birthLatitude` and
`birthLongitude` — the full identity set the AI boundary deliberately excludes.
Different boundary, different rules: the mirror is the person's own backup.

Rules of the road:

- A push marks `syncedAt` only after the write is acknowledged. A failed sync
  is a delay, never a loss.
- Restore refuses on a device that already has history — merging two divergent
  health records has no correct answer.
- Restore does **not** restore consent. A new phone asks again.
- `forget(userId)` / `deleteEverything` walks all eight subcollections, because
  Firestore does not delete subcollections with their parent.

`firestore.rules` enforces ownership server-side (`request.auth.uid == userId`),
caps documents at 40 keys and text fields at 20 000 characters, and denies
every path not explicitly named.

---

## 3. What crosses which boundary

| | Device | AI endpoint | Cloud mirror |
|---|---|---|---|
| Name, DOB, birth time, coordinates | ✔ | ✘ never | ✔ under cloud consent |
| Derived age, sun/moon sign, Life Path | ✔ | ✔ under AI consent | derived, not stored |
| Measured health records | ✔ | ✔ 7-day window, under AI consent | ✔ under cloud consent |
| Raw/minute buckets | ✔ | ✘ | ✘ |
| Journal prose | ✔ | ✔ under *journal* AI consent, bounded | ✔ under *journal* cloud consent |
| Journal digests | ✔ | ✔ under journal AI consent | ✘ |
| Model output (guidance, stories, readings) | ✔ | ✘ | ✘ |
| Aether's own recall notes | ✔ | ✔ 14 days, under AI consent; journal-derived notes need journal consent | ✘ |
| Account/row identifiers | ✔ | ✘ never | uid scoping only |

---

## 4. Retention, as of schema 9

`runLocalRetention()` bounds everything that is a cache or an interpretation
rather than a fact:

| What | Bound | Why it is not a fact |
|---|---|---|
| `RawBuckets` | 90 days | ingest staging; the winners survive |
| `LiveSessions.hrSeriesJson` | 180 days | the session aggregate survives |
| `GuidanceHistory` | 365 days | composed from the record, recomposable from it |
| `GuidanceRecalls` | 60 days | a summary of prose that has itself expired; only 14 are ever read |
| `TransitReadings` | 90 days | a passage about one day's sky |
| `JournalEntries.extractionJson` | 90 days | the model's reading; the records it produced stay |

Discarding a journal entry now also removes the cloud copy: the blanked row is
pushed and overwrites the mirrored prose, and restore skips tombstones. Model
output is still never mirrored at all.

`revertJournalEntryRows` clears `extractionJson` with the rows it produced.
The Sanctum exposes **Old pages → Clear**, which runs `pruneJournalProse` over
anything older than a year behind a second confirmation.

### Changing language discards composed prose

`Profile.language` is `en` | `pl` | null, and null means *nobody has chosen* —
that install follows the phone on every launch, so moving the OS to Polish is
met in Polish. A stored code is the person's and stops following anything.

`chooseLanguage()` writes the code and then deletes `GuidanceHistory`,
`GuidanceRecalls`, `VesselReadings`, `TransitReadings`, `JournalDayStories` and
`Retrospectives`. This is not tidiness: every composer keys its cache on a
fingerprint of its *inputs*, none of which change when the language does, so a
Polish Dashboard would open on an English paragraph that every composer
considered current and would never replace. Clearing is what makes the switch
take effect.

Nothing measured moves. Journal pages, weights, meals, sleep, day totals,
consents and the whole symbolic chart are untouched, and learned patterns
survive because a pattern stores structured evidence and is *worded at display
time* rather than kept as a sentence. The count of discarded rows is returned so
the Sanctum can say what actually happened.

## 5. Still open

1. **`deleteAllLocalData` does not touch the mirror**, by design — but the
   Sanctum must present both actions, or "delete everything" is not true.
2. **The export bundle is written to app documents** and is not encrypted;
   anything that can read the sandbox can read the export.
3. **Most measured tables are unbounded** (`MinuteBuckets`, `DaySummaries`,
   `SleepSegments`, `DailyVitals`). That is deliberate — they are the record —
   but `MinuteBuckets` is 1,440 rows a day and nothing prunes it.
