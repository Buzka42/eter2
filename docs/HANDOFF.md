# Eter · where the work stands, and what to do next

Written 30 July 2026, at the end of a long session on branch `eter-audit-fixes`.
Read this first if you are picking the work up cold; then `DECISIONS.md` for what
the product owner has settled, then the specific document each task names.

**State of the tree:** 20 commits ahead of `main`, nothing uncommitted.
`flutter analyze` clean. **681 tests pass, 7 skipped** — the seven are live-provider
tests that need a deployed endpoint. Release APK 80.1 MB. Schema is at **12**, and
all three migrations in this branch were verified on a real Android device with
real data.

---

## Start here

```bash
cd app
flutter test          # expect 681 pass, 7 skipped
flutter analyze       # expect clean
```

If either disagrees with those numbers, something in the working tree is wrong —
fix that before starting anything below.

---

## The queue, in dependency order

Nothing here is blocked on anything above it except where stated.

### 1 · Finish the Polish sentences · *no device, no decisions needed*

The **vocabulary** is settled and applied (`docs/POLISH.md`). The **sentences**
are not: roughly 380 of the 411 strings in `docs/TRANSLATIONS.md` are still
translated English rather than written Polish.

Two commits show the method. `80553c5` replaced four nouns that meant the wrong
thing; `4304b4a` replaced the *komponować* calque with **powstać** across nineteen
strings. Both followed the same two tests, which are in `POLISH.md`:

- **Read the Polish alone.** Cover the English column. If it only makes sense once
  you know what it was, it is not finished.
- **Ask whether the word belongs to the product or to software.** `EKSPORT`,
  `CIĄGŁOŚĆ`, `PULPIT` belong to an application. `GŁĘBIA`, `ZACISZE`, `KRĄG`,
  `WGLĄD` belong to this one.

Work in slices by surface, regenerate `TRANSLATIONS.md` with
`python tool/pair_translations.py`, re-record Polish goldens, commit per slice.

**Watch for:** no test reads Polish for sense, so a spliced or ungrammatical
sentence passes everything. One shipped mid-edit in this branch and was caught by
rereading, not by CI. Read every string you touch, out loud if it helps.

**Still open by name:** `EKSPORT LOKALNY` is software vocabulary. `WSKAZANIA` was
replaced by `WGLĄD` at the owner's request — see the note in `POLISH.md` about the
one word now doing two jobs, and change the *section* rather than the destination
if it grates in use.

### 2 · The Long View surface · *no device*

Half done. `ed52c47` committed `LongViewComposer` — day/week/month/year cells
folded from records already on the device, no model call, 12 tests pinning the rule
that a period nobody recorded is **absent, not zero**.

What remains is the surface:

- Reached by **extending the Journal's existing bead-and-thread date affordance** —
  keep turning back and the day widens to week, month, year. Not a new
  destination; see `DECISIONS.md`.
- Charts in the `EngravedBalance` `CustomPainter` idiom. **No charting package** —
  `UI_BRIEF.md` §7.2 explains what importing one costs.
- Recall notes as marginalia on day and week cells only. The composer already
  returns none for a month, deliberately.
- Add a named Sanctum entry for it, per `DECISIONS.md` — extension is the primary
  route, the Sanctum is the index so nothing lives only behind a gesture.

### 3 · The Letter · *no device*

Not started. A sixth model call, so it is the largest single piece here.

Once a month, one page composed **to** the person, second person, from the
fortnight of `GuidanceRecalls` plus the retrospective. It arrives **as a Journal
page** using the existing `EterArrival` reveal, and can be answered by writing
under it.

Follow the shape of the five existing calls exactly — `docs/AI_FLOW.md` is the
authority and where it and a code comment disagree, the code is wrong:

- an instruction and JSON Schema in `core/ai/prompts.dart`, with
  `EterPrompts.version` bumped
- a thin adapter in `core/ai/transport.dart`
- its own parser with explicit bounds, and `AetherSafetyPolicy` applied
- a cache key so the same month is not paid for twice
- the call name added to `CALLS` in `server/worker.js` with a temperature

**Do not** let it reach the model without `aiConsentAt`, and treat the recall notes
as the model's own words rather than the person's — `AI_FLOW.md` §1a.

### 4 · The evening invitation · *needs a device to verify delivery*

Decided and not built. One quiet local notification inviting a page, **off by
default**, scheduled on the **real sunset** `registerCoordinates` already
computes rather than a clock time.

Needs `POST_NOTIFICATIONS` back in the manifest — it was deliberately stripped —
a permission request, a consent column, and a notification package. No server.

### 5 · Import, and the prompt fixtures · *no device*

Two bounded robustness items from the audit that never got done.

**Import.** `LocalDataExporter` writes a versioned JSON snapshot and nothing can
read one back. The format is already versioned, so the restore path is small. The
more valuable version reads *other* apps — Daylio, Bearable, Apple Health XML.

**Prompt fixtures.** All five parsers are tested against hand-written JSON, never
against recorded real model output. Record good, malformed, unsafe and empty
responses per call. Needs the endpoint deployed to capture them.

### 6 · The home-screen widget · *needs a device, and a Mac for iOS*

Not started, and **not a short job**: native SwiftUI WidgetKit on iOS, Glance or
RemoteViews on Android, plus a shared read path out of the Drift store. Android
alone is several hours. There is no Mac in this environment, so the iOS half
cannot be built or verified here at all.

One sentence from today's synthesis, already sitting in `GuidanceHistory`.

### 7 · The Correspondence · *no device; needs new backend*

Last, because it is the only feature needing a server surface that does not exist:
pairing, a new Firestore collection, new security rules.

Two people, each with a wholly private record, sharing **only the day's composed
sentence** — nothing measured, nothing written, no health data. It appears as one
extra line beneath today's guidance. Pairing setup lives in the Sanctum.

### 8 · Verify nutrition write-back · *needs the phone*

`37b455f` built it and the device run stopped at the permission sheet — I did not
grant health-write access on the owner's behalf. Still unproven:

1. Grant `WRITE_WEIGHT` and `WRITE_NUTRITION` in Health Connect.
2. Sanctum → `WRITE BACK`.
3. Confirm a weight **and a confirmed meal** appear in Health Connect.
4. Tap again; confirm nothing duplicates (`clientRecordId` dedupe).

Nutrition goes through `Health.writeMeal`, which has never run against a real hub.
`DIETARY_ENERGY_CONSUMED` is Apple-only and was filtered out *silently* on
Android — that class of failure is why this needs a device and not an argument.

---

## Things that will bite you

**Golden tests are the honest reviewer.** They run every language at 320 dp and
200 % text, which is where translation breaks layouts. They caught a 112 px English
overflow and a 175 px Polish one on the same row, and they refused to tap when two
widgets ended up sharing a semantics label. When they fail, read the failure before
re-recording — twice in this branch the failure was a real defect, not a stale
image.

**Polish decides layout more often than English.** But not always: `DASHBOARD` is
nine letterspaced caps against `PULPIT`'s six, so the Sanctum mark collided in
*English* first. Render both.

**`flutter test --update-goldens` will happily bake in a bug.** If a capture throws
an overflow, updating records the yellow stripes as the new truth. Check the
failure reason.

**Schema migrations must be idempotent.** `_addColumnIfMissing` and the backfill
pattern in `app_database.dart` exist because a half-applied migration once left the
app unable to open. Follow that shape; never key on `from`.

**Consent is re-read, never cached.** Every path re-reads the profile so revoking
takes effect on the next pass. Do not add a cached flag.

**A record nobody made is absent, not zero.** This is the single rule most likely
to be violated by new code — averages, charts, summaries. v1 told somebody who had
not logged food that they were 828 kcal down. `long_view.dart` and
`sleep_totals.dart` both carry the rule in their doc comments.

---

## Owner-only, still outstanding

None of these can be done from the repo. `RELEASE.md` §2 is the full list; the ones
that block the most:

1. **Upload keystore** — create it early; losing it means losing the ability to
   update the listing.
2. **Deploy `server/worker.js`**, and **bind the rate limiter** in
   `wrangler.toml`. Without it the worker logs `limits=kv-approximate` and means
   it.
3. **Store subscription products** — `eter.monthly` $4.99, `eter.yearly` $39.99,
   **20 PLN/month in Poland** as a regional price, not a conversion.
4. **A public privacy-policy URL**, and the health-data declarations.
5. **Firestore rules deploy** — the live project's rules predate the mirror and
   would deny it.
6. **Rotate the development Gemini key** before any public build.
