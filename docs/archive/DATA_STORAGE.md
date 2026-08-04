# Eter · what is stored, where, and for how long

Current as of 30 July 2026, schema 12. Supersedes
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
| `Profiles` (single row, id=1) | first name, DOB, sex, weight, height, body fat, units, guidance mode, start surface, `language`, **birth time / UTC offset / place / lat / lon**, **home place / lat / lon**, and five consent timestamps: `aiConsentAt`, `journalAiConsentAt`, `crashReportConsentAt`, `cloudSyncConsentAt`, `journalCloudSyncConsentAt` |

This is the only place birth time and coordinates exist. They never enter an
AI payload; they are used on-device by `NatalChartEngine` and as the
`inputHash` that keys cached readings.

### Birth place and home place are not the same column, and must not become one

`birth*` casts the chart. `home*` is where the person lives, and it is the only
thing the register's sunrise and sunset may be computed from.

Conflating them is not hypothetical — it shipped. `dayPhaseAt` was fed the birth
coordinates because they were the only ones stored, so anyone who had moved got a
register turning on a city they had left: born in Warsaw, living in Vancouver, and
the night register arrived mid-morning in the default mode, silently.

`registerCoordinates` (`core/symbolic/solar.dart`) resolves it. Home coordinates
win. With none, birth coordinates serve *only while the device's own UTC offset
agrees they are plausible* — a birth longitude implies a solar offset, and a phone
hours away from it proves the person is elsewhere. When they disagree it returns
null, the register falls back to a plain 07:00–19:00 clock, and the Sanctum asks.
No location permission, and no confident wrong answer. The tolerance is three
hours because Madrid keeps central European time on Greenwich's meridian and
Kashgar shares Beijing's offset five hours from its own sun; anything tighter
strands people who never moved.

Changing home place invalidates nothing composed. `updateHomePlace` is
deliberately *not* part of `updateBirthContext`, which clears readings belonging to
superseded chart hashes — moving house does not recast a chart.

### Measured record

| Table | Holds | Retention |
|---|---|---|
| `RawBuckets` | pre-dedup minute imports, per source | **90 days** (`pruneRawBuckets`) |
| `MinuteBuckets` | deduplicated winners + provenance | **400 days** (`pruneMinuteBuckets`) |
| `DaySummaries` | per-day totals | unbounded |
| `SleepSegments` | stages, keyed to `nightOf` | unbounded |
| `DailyVitals` | RHR, HRV, respiratory rate, temp delta, scores | unbounded |
| `ActivitySessions`, `StrengthWorkouts`, `LiveSessions` | sessions; live HR series | HR series **180 days** (`pruneLiveHeartRateSeries`) |
| `WeightEntries`, `NutritionEntries`, `LifestyleEntries` | manual and derived records; `mirrorId`, and `writtenBackAt` on the first two | unbounded |
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
  deletion, and the Sanctum now presents both as separately confirmed actions
  with different consequences. Its warning states which situation you are in:
  with an account copy still standing, wiping the device is not permanent and
  `RESTORE` would bring it back, so the copy says so instead of promising
  otherwise.
- `SyncService.withdraw` — the copy, then the account. **The order is
  load-bearing.** `firestore.rules` authorises every delete by
  `request.auth.uid`, so deleting the account first takes the only credential
  that can satisfy that rule and leaves the whole mirror standing under a uid
  nobody can present again: unreachable, and therefore permanently undeleted.
  A failed mirror clear leaves the account alone so a retry still has authority;
  a failed account delete leaves an already-empty mirror, which is the safe
  direction. Reached from the Sanctum's `DELETE ACCOUNT`, which both stores
  require to exist in-app.
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
`birthTimeMinutes`, `birthUtcOffsetMinutes`, `birthPlace`, `birthLatitude`,
`birthLongitude` and the three `home*` fields — the full identity set the AI
boundary deliberately excludes. Different boundary, different rules: the mirror is
the person's own backup.

Rules of the road:

- A push marks `syncedAt` only after the write is acknowledged. A failed sync
  is a delay, never a loss.
- **Pushes happen on their own**, not only when somebody presses `SYNC NOW`.
  `BackgroundSync` fires on resume and on the app leaving — the latter being the
  moment worth catching, since it follows someone finishing a page. Debounced to
  one push per five minutes. Consent is re-checked by `push` itself rather than by
  the caller, so that rule lives in one place. A force-stopped app never delivers
  `paused`, so a page written and then force-closed reaches the cloud one session
  late; pushing at launch instead would put a network call on every cold start.
- Restore refuses on a device that already has history — merging two divergent
  health records has no correct answer.
- Restore does **not** restore consent, including cloud consent. A new phone asks
  again. This was untrue until 30 July 2026: `_restoreProfile` granted
  `cloudSyncConsentAt` on the line directly beneath a comment promising it did
  not, so a restore silently began copying a record to the mirror with nobody on
  that phone having agreed.
- **Documents are keyed on `mirrorId`, not the local row id.** A restore
  reassigns autoincrement ids, so id-keyed documents drifted: after a phone swap
  every push wrote beside the document it meant to replace. For the journal that
  mattered most — discarding a page pushes a blanked row *in order to* overwrite
  the prose, and the overwrite was landing on a document nobody had read, leaving
  the original page in the cloud permanently. `sessions`, `strength` and `days`
  were always safe; they carry stable string keys. `readAll` returns
  `MirrorEntry`, carrying the key, because it is not recoverable from the
  contents.
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

## 4. Retention, as of schema 12

`runLocalRetention()` bounds everything that is a cache or an interpretation
rather than a fact:

| What | Bound | Why it is not a fact |
|---|---|---|
| `RawBuckets` | 90 days | ingest staging; the winners survive |
| `MinuteBuckets` | 400 days | ingest detail; `DaySummaries` carries the result and is unbounded |
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

## 5. Writing back to the platform

Eter read fourteen kinds of health data and wrote none, which made it a good
citizen of nobody's phone: a weight typed here never appeared in Apple Health.
`core/health/write_back.dart` sends two things — weights, and **confirmed** meals.

**The origin filter is the whole design.** Only rows Eter originated go back;
anything read from the hub never does. Returning the platform's own data under
Eter's name survives one round trip and is then read back as a second, independent
measurement, so the day's intake would climb every time the app was opened and the
cause would be nearly invisible. `source` makes the filter possible, matched as a
prefix because the hub stamps the contributing app onto it — `healthConnect:garmin`
is still the hub.

Unconfirmed estimates are excluded too. A model's guess is kept out of Eter's own
totals until somebody confirms it; writing it into Apple Health would launder it
into a fact by moving it somewhere more authoritative.

`writtenBackAt` stops a row being offered twice, and each write carries a stable
`clientRecordId` so a repeat replaces rather than duplicates. No Eter-level consent
sits in front of this: the platform's own per-type permission dialog is the gate,
revocable in its own interface, exactly as it is for reading.

Nutrition goes through `Health.writeMeal`, not `writeHealthData`.
`DIETARY_ENERGY_CONSUMED` is Apple-only, and on Android `isDataTypeAvailable`
filtered it out *silently* — the permission sheet asked for Weight alone and
nutrition would have failed forever without saying why. Only a device showed that.

## 6. Still open

1. **The export bundle is written to app documents** and is not encrypted;
   anything that can read the sandbox can read the export. There is also still no
   import, so the versioned snapshot cannot be read back.
2. **`DaySummaries`, `SleepSegments` and `DailyVitals` are unbounded.** Deliberate
   — they are the record, and they are small.
3. **Nutrition write-back has never run against a real Health Connect.** Nine
   tests cover the rules; the device run stopped at the permission sheet.
