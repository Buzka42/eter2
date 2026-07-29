# Eter · what is stored, where, and for how long

Current as of 29 July 2026. Supersedes `archive/14-data-models-firebase.md`
and `archive/16-privacy-compliance.md`.

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
| `Profiles` (single row, id=1) | first name, DOB, sex, weight, height, body fat, units, guidance mode, start surface, **birth time / UTC offset / place / lat / lon**, and five consent timestamps: `aiConsentAt`, `journalAiConsentAt`, `crashReportConsentAt`, `cloudSyncConsentAt`, `journalCloudSyncConsentAt` |

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

`pruneNightly()` runs the two bounded prunes.

### Written and generated content

| Table | Holds | Notes |
|---|---|---|
| `JournalEntries` | the person's prose, `status`, `excludedFromAi`, `extractionJson`, `model`, `appliedAt` | discarding blanks the text and sets `status: 'discarded'`; the row id is retained so nothing can be re-pointed at a different page |
| `JournalDayStories` | one story + digest per local date, `sourceFingerprint` | model output |
| `GuidanceHistory` | one row per dimension per composition, `contentJson`, `evidenceJson`, `contextFingerprint` | model output, **unbounded** |
| `VesselReadings` | one passage per position, keyed by `inputHash` | model output; `clearVesselReadingsExcept` drops readings for superseded charts |
| `TransitReadings` | one passage per (date, `inputHash`) | model output, **unbounded** |
| `DailyCards` | the day's Arcana draw + reason | device arithmetic, no model |
| `PatternCandidates` | locally discovered correlations, `status` | dismissed patterns are never re-sent to a model |
| `Retrospectives`, `IntakeAnswers` | periodic summaries; onboarding answers | |

### Local controls

- `discardJournalEntry(id)` — blank one page.
- `pruneJournalProse(olderThanUtc)` — bulk-blank old prose, keeping derived
  facts. **Currently has no caller.**
- `revertJournalEntryRows(id)` — delete every record one entry produced.
- `resetPersonalization()` — clears guidance, patterns and retrospectives.
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
`minuteBuckets`, `rawBuckets`, `guidanceHistory`, `vesselReadings`,
`transitReadings`, `journalDayStories`, `integrations`.

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
| Account/row identifiers | ✔ | ✘ never | uid scoping only |

---

## 4. Known gaps

1. **No retention bound on `GuidanceHistory` or `TransitReadings`.** They grow
   for the life of the install.
2. **`pruneJournalProse` is unreachable** from any surface.
3. **A discarded journal entry keeps its cloud copy.** Local text is blanked
   and `syncedAt` nulled, but the mirrored document is only overwritten if the
   entry is pushed again — and a discarded entry is excluded from the push.
   The original prose survives until `deleteEverything`.
4. **`extractionJson` is retained indefinitely**, including after
   `revertJournalEntryRows` removes the records it produced.
5. **`deleteAllLocalData` does not touch the mirror**, by design — but the
   Sanctum must present both actions, or "delete everything" is not true.
6. **The export bundle is written to app documents** and is not encrypted;
   anything that can read the sandbox can read the export.
