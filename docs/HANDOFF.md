# Eter · where the work stands, and what to do next

Written 30 July 2026, at the end of a long session on branch `eter-audit-fixes`.
Read this first if you are picking the work up cold; then `DECISIONS.md` for what
the product owner has settled, then the specific document each task names.

**State of the tree:** nothing uncommitted. `flutter analyze` clean. **766 tests
pass, 9 skipped** — the skips are the live-provider suite, which needs the
endpoint token, and one manual test that needs an export file. The live suite
*has* been run and passes; see item 3. Schema is at **15**, and the upgrade
**12 → 15 was run on a real device with 3.3 MB of real data**: nothing lost,
`letters` created, both new profile columns added, and neither new consent
inherited.

## What the phone has and has not proved

Verified on a Blade V 5G, Android 14, against the owner's own record:

- **Schema 12 → 15 in place.** Row counts before and after in the commit.
- **The Android build.** Three things failed on the first device build that no
  test could see — core library desugaring, `file_picker` under AGP 9, and a
  Kotlin/Java target mismatch. All fixed; release build clean at 82.5 MB.
- **The evening invitation schedules.** One `RTC_WAKEUP` alarm, at the right
  hour, through the plugin's receiver. Refusing the OS prompt leaves the control
  reading **Off** and stores nothing; allowing it stores the consent with its
  offset.
- **The export/import round trip, at real scale.** A 4.8 MB snapshot with every
  table restored whole into an empty database — see
  `test/manual/real_export_round_trip_test.dart`, which is the strongest test in
  the repository and is skipped by default because the file is somebody's record.
- **The document picker opens unfiltered**, so a `.json` is selectable.
- **Write-back dedupe.** A second `WRITE BACK` says "Nothing new to write."

Still unproven, and why:

| Thing | Blocked on |
|---|---|
| The invitation actually appearing | It fires at the scheduled hour; nobody has watched one land |
| `ic_notification` on the status bar | Same — it compiles, it has not been seen |
| **Nutrition write-back** | See below. Not permissions |
| The Letter arriving on a page | Needs five recall notes in a month; see item 3 |
| The Correspondence | Needs an account on both sides and the rules deployed |

---

## Start here

```bash
cd app
flutter test          # expect 766 pass, 9 skipped
flutter analyze       # expect clean
```

If either disagrees with those numbers, something in the working tree is wrong —
fix that before starting anything below.

---

## The queue, in dependency order

Nothing here is blocked on anything above it except where stated.

### 1 · The Polish sentences · *done, and read once more if you like*

All fifteen sections of `docs/TRANSLATIONS.md` were read against the two tests in
`POLISH.md`, in six slices, and everything that failed one was rewritten. What was
actually wrong, in descending order of how badly it read:

- **Gender agreement in assembled sentences.** The sweep summary put one fixed
  adjective ending after fifteen nouns of two genders, and fed it clauses where a
  noun belongs. The retrospective left a participle in the wrong case above four.
  `POLISH.md` now has a section on both shapes.
- **Gendered verbs addressing the reader** — *chciałabyś lub chciałbyś*, and
  *Potwierdziłem* on a button. There are none left in the file; the grep that
  finds them is in that same section.
- **Vocabulary the lexicon had already retired**, still in place: `SANKTUARIUM`
  titled the Sanctum, `Pulpit` was an opening page, `CIĄGŁOŚĆ` was a consent, and
  *komponować* survived in three strings.
- **Words that mean something else here** — the food estimate stayed out of *the
  weight*, and the first matrix cell was called *Dane*.
- **Aether now declines**, because it is a name. See `POLISH.md`.

`EKSPORT LOKALNY` was kept and `POLISH.md` records why: the native word is *kopia*
and the cloud section owns it. `WGLĄD` still does two jobs; leave it until use
says otherwise, and change the *section* rather than the destination.

**Watch for:** no test reads Polish for sense, so a spliced or ungrammatical
sentence passes everything. Read every string you touch, out loud if it helps.
`python tool/pair_translations.py` regenerates the pairing — and note it drops any
member whose comment sits between `@override` and the signature.

**Left deliberately:** *rosnący garb* for a waxing gibbous moon. It is transparent
but it is not what Polish astronomy says, and every alternative reads worse inside
`Księżyc w fazie …`. A decision, not an oversight.

### 2 · The Long View surface · *built; wants a look on a real device*

`LongViewSource` loads a window, `EngravedLongView` draws it, and the History
sheet widens on its own as you turn back. No charting package, no model call, no
new destination.

The parts worth knowing before changing any of it:

- **There is no zoom control, on purpose.** `longViewSpanFor` turns
  distance-from-today into a scale — under a fortnight a day, then week, month,
  year — and the beads step by whatever scale you are on. A zoom button would
  have been the menu `DECISIONS.md` rejected.
- **An unrecorded period is an open tick below the baseline**, not a bar of no
  height. That is the absent-not-zero rule made visible, and it is the one thing
  in the painter that must not be "simplified". Pages written is the exception
  and draws a real zero: Eter knows for certain that nothing was written.
- **Marginalia only on a week.** Thirty recall notes is a wall of text, which is
  the same reason `LongViewComposer` returns none for a month cell.
- A week ends on the anchor day; a year is the twelve months ending with the
  anchor's month. Both are in `long_view_source.dart` with the reasoning.

**Rendered on a device**, all three spans: `Week · 11 Jul – 17 Jul` with the
peak day in strong ink, and an empty `Year · July 1981 – June 1982` saying
"0 of 12 recorded. Nothing was recorded in this stretch of time." One defect came
out of that and is fixed — a week nobody wrote in drew seven one-pixel stubs,
because pages is the one measure with a real zero and the bar floor applied to it.

**Not done:** no golden covers a widened sheet. The panel is behind fourteen taps
of a bead and the capture harness drives the shell, not the sheet.

**A decision you may want to make.** The axis has no floor. Seventy-five taps of
the earlier bead reached **1981** — once you are in year mode each tap is a whole
year, which is the acceleration working as designed, but it means you can wander
decades into a record that starts in 2026 and read empty window after empty
window. Clamping at the earliest record is cheap and probably right; leaving it
open is defensible if the axis is meant to be time rather than your time. It is a
product question, so it is not built.

### 3 · The Letter · *built; never run against a real model*

`core/aether/letter.dart`, schema 13's `Letters` table, `letter` in `CALLS` at
0.7, and `EterPrompts.version` at 5. `AI_FLOW.md` now documents six calls.

- **The cache key is the month.** One request per person per month, and a month
  already written is never composed again. There is a test for that specifically,
  because a monthly page that quietly re-bills is the worst kind of cost.
- **Below five recall notes Eter does not ask at all.** The instruction already
  keeps a thin month short; this is the floor below which the request is not
  worth making, since paying a model to say "there is not much here yet" is
  worse than not writing.
- Recalls that saw the journal stop travelling when `journalAiConsentAt` is
  withdrawn, so revoking cannot leave last month's pages reaching the model
  laundered through Eter's own prose.
- It arrives on the Journal page where Aether's prose always stands, scrolls
  rather than shrinking to fit, and is answered by the writing field below.
  Composition is attempted when the Journal opens — the only moment Eter has,
  since there is no background poll — and is best-effort.
- `Letters` has **no retention expiry**, deliberately. `AI_FLOW.md` §6 says why.

**Proven against the deployed endpoint.** `https://eter-ai.eter-ai.workers.dev`
is live and current, and all eight live-smoke cases pass — prompt built on the
device, transport, worker, model, and each contract's own parser over the answer:

```bash
flutter test test/manual/live_smoke_test.dart   --dart-define=ETER_LIVE_SMOKE=true   --dart-define=ETER_AI_ENDPOINT=https://eter-ai.eter-ai.workers.dev   --dart-define=ETER_AI_TOKEN=<the client token>
```

**And reading the answer found what passing it could not.** The first real
letter opened *"We watched the third short night"* — Eter as an institution
observing somebody. It also recited the retrospective's figures in a row and
called a month with twenty-two recorded days thin. All three parsed perfectly.
`EterPrompts.version` is 6 because of it; see the version note for what changed.

**Still not exercised end to end in the app:** `LetterComposer` needs five
recall notes in a month before it will ask, and this device has none — recalls
accumulate one per day as guidance composes. Either compose for five days or
lower `minimumRecalls` temporarily to watch a letter arrive on a Journal page.

**One live thing still wrong.** Both rate-limiter bindings are commented out in
`wrangler.toml`, so the worker has no per-install cap of any kind — not even the
KV fallback whose weakness it logs as `limits=kv-approximate`. Google's free tier
is the only ceiling, on an endpoint reachable by anyone holding the token.
`RELEASE.md` §2.2.

### 4 · The evening invitation · *built; delivery unverified*

`core/invitation/` is the feature, split so the rule is testable and only the
platform call is not. Schema 14 carries the consent, null on upgrade. The
Sanctum has the toggle, beside the other consents rather than in a preferences
list — it is the only one that is not about data leaving the device, and what it
grants is the right to interrupt.

- Half an hour **after** the real sunset. At sunset the register turns, and a
  notification on the same minute reads as the app announcing its own theme.
- Somebody who already wrote today is moved to tomorrow. An invitation, not a
  reminder.
- Above the Arctic Circle it degrades to 20:00 rather than falling silent for a
  season — the same way the register degrades with no horizon to read.
- Granting asks the OS first and stores nothing if refused.
- `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED` are back in the manifest,
  each with a comment saying why.

**What the phone proved:** the sheet appears once per attempt; refusing leaves
the control reading OFF and stores nothing; allowing stores the consent with its
UTC offset intact; and exactly one `RTC_WAKEUP` alarm is registered against the
plugin's receiver.

**Still to watch, none of which a test can:**

1. One notification that evening, silent and low-importance, and **only one**.
2. Write a page during the day; that evening must stay silent.
3. Turn it off; anything pending must disappear immediately.
4. Reboot mid-afternoon; that evening's invitation must survive.

**And the thing the device changed about the design.** The profile carries
`birth_place = 'Warsaw'` and **no coordinates**, so `registerCoordinates` returns
null and the invitation is scheduled at the flat fallback hour — the alarm landed
at 20:00, not at sunset. That branch was named `polarFallbackHour` and documented
as an Arctic edge case; it is the ordinary path for anyone whose place was typed
and never geocoded. Renamed, documented, and the Sanctum copy now says "at your
own sunset — or at eight, if Eter does not know where you are" rather than
promising a sunset it may not have.

**The icon was wrong and is fixed.** It was scheduled against
`@mipmap/ic_launcher`, which is adaptive and full-colour, and Android draws a
small icon as an alpha mask — it would have rendered as a white blob.
`res/drawable/ic_notification.xml` is the mark reduced to what survives at 24dp:
the arc and the plumb. It compiles into the APK; nobody has seen it on a status
bar yet.

### 5 · Import · *done*, and the prompt fixtures · *blocked on the endpoint*

**Import is built.** `core/privacy/local_data_import.dart`, reached from the
Sanctum under `BRING A RECORD BACK`, directly beneath the export it undoes.

- It only fills an empty device, the same promise cloud Restore makes.
  "Empty" **excludes the profile row** — a new phone has one by the time anybody
  reaches the Sanctum, and counting it would make the feature refuse in exactly
  the case it exists for.
- A snapshot from a newer schema is refused outright; anything else unreadable is
  *reported* — how many records came back, and that part of the file did not.
- The insert is raw SQL. Drift's `validateIntegrity` is written for rows the app
  is composing; a restore is putting back bytes this same schema wrote.

**Still worth doing, and not started:** reading *other* apps — Daylio, Bearable,
Apple Health XML. That is the version that gets somebody to switch, and it is a
different job: those are foreign shapes, not Eter's own snapshot.

**Verified on the device.** The picker opens unfiltered, as intended — Android's
document picker filters by MIME type and would hide a `.json` the file manager
reports as `application/octet-stream`, which is most of them.

**The export now lands in the phone's Downloads folder**, which is the owner's
decision and fixes the thing that made the feature untryable: it used to be
written to the application documents directory, invisible to every file manager
and every document picker, so you could export your record and then hand it to
nothing — including Eter's own restore.

Two attempts, and the first was wrong. `getDownloadsDirectory()` on Android is
the **app-specific** external Downloads, and `Android/data` is hidden from the
picker on Android 11+; browsing to it on the device showed `Android/` containing
only `media/`. So it publishes through **MediaStore** instead, which needs no
permission at all on API 29+ — see `MainActivity.kt`. Writing to
`/storage/emulated/0/Download` directly would need `MANAGE_EXTERNAL_STORAGE`,
permission to read every file on the phone, which this product must never ask
for.

There are two copies by design: the bundle in storage the app owns, which always
exists and needs no platform support, and the published copy a person can reach.
Publishing catches every failure on purpose — an export that succeeded must not
report failure because a convenience did not.

**Not yet seen on screen:** the published copy actually appearing in Downloads.
Built, installed, and the cable dropped before the tap.

**Prompt fixtures — done, and they earned their keep immediately.**
`test/fixtures/live/` holds one recorded response per call and
`live_fixtures_test.dart` replays them through the real parsers with no network.
Their inputs are invented, so nothing in them is anybody's record.

Two of those checks are about drift rather than shape, and are the reason the
directory is worth its weight: **the letter must never say "we" again**, and the
**synthesis must carry no digit** — `CorrespondencePolicy` refuses a shared line
containing one, which is an assumption about what the model writes that only
recorded output can test.

Re-record after changing a prompt, and *read* what comes back. A fixture that
parses is not a fixture that reads well; that is the whole lesson of v6.

### 6 · The home-screen widget · *needs a device, and a Mac for iOS*

Not started, and **not a short job**: native SwiftUI WidgetKit on iOS, Glance or
RemoteViews on Android, plus a shared read path out of the Drift store. Android
alone is several hours. There is no Mac in this environment, so the iOS half
cannot be built or verified here at all.

One sentence from today's synthesis, already sitting in `GuidanceHistory`.

### 7 · The Correspondence · *built; the rules are not deployed*

`core/correspondence/` — the policy, the pairing, and the Firestore gateway.
`firestore.rules` carries the server half and **validates**, but has never run
against the live project.

The parts that are load-bearing rather than incidental:

- **`CorrespondencePolicy` runs on the way out and again on the way in.**
  Neither makes the other redundant: outbound protects them from this device,
  inbound protects this device from a compromised peer or a stale document. It
  refuses any sentence containing a digit — Eter's synthesis never quotes a
  figure, so a digit means something upstream changed, and trimming it would
  leave a sentence still *about* the measurement.
- **The rule is the third check**, and the only one an attacker cannot skip by
  not running our client. A line document may hold exactly `date` and
  `sentence`. Membership can never change. `list` on invitations is denied, so
  the code's length actually buys something.
- **Leaving is unilateral on both sides**, in the rules as well as the client.
- Schema 15 stores the pair id and **nothing about the other person** — no name,
  no address, no history of their lines. Today's line is read, shown, not kept.
- The Polish label is `DZIEŃ OBOK`. Eter does not know who the other person is,
  so `JEJ`/`JEGO` is out.

**What is not done, and needs two accounts and a deployed project:**

1. `firebase deploy --only firestore:rules`. The live project's rules predate
   all of this and will deny every path here — see `RELEASE.md` §2.5.
2. Pair two real accounts end to end: offer, read the code aloud, redeem.
3. Confirm the code is dead after one use, and after 24 hours.
4. Confirm a **non-member** is refused on `correspondences/{pairId}` and on a
   line document. This is the one that matters; everything else is convenience.
5. End it from each side in turn and confirm the other side notices and forgets.

**Not built, deliberately:** any notification that a line arrived. It appears
when you next look, which is the whole register of the feature.

### 8 · Verify nutrition write-back · *half proved, and blocked on something else*

The device run answered most of this and moved the blocker somewhere unexpected.

**Weights: done.** Both rows on the device carry `writtenBackAt`, so weight
write-back has succeeded against a real hub. Health Connect's permission sheet
now offers only *Nutrition*, which is how you can tell `WRITE_WEIGHT` was already
granted and used.

**Dedupe: done.** A second `WRITE BACK` reports "Nothing new to write."

**Nutrition: still unproven, and not because of permissions** — those are granted
now. `nutrition_entries` is **empty**, so `Health.writeMeal` has nothing to send
and cannot be reached.

And the reason it is empty is not a bug. **The Dashboard reads; the Journal
writes** — the product rule of 28 July 2026, stated at the top of
`body_section.dart`, which removed every capture control the Body used to carry.
So the only way a meal enters Eter is by writing a page and letting
interpretation derive one, and that needs the guidance endpoint.

`ManualMealService` still exists, still records a confirmed meal, and still has
its own tests — the class comment on `BodySection` says explicitly that the write
services were kept when their surfaces went. But it has **no caller anywhere in
`lib/`**, which makes it the only path that could produce a meal offline and the
only path nothing can reach.

That leaves a decision rather than a task, and it is the owner's:

- **Deploy the endpoint**, write a page about a meal, confirm the estimate, then
  `WRITE BACK`. This is the intended route and needs nothing new built.
- **Or give `ManualMealService` a surface anyway** — which contradicts the
  product rule above, so it wants a line in `DECISIONS.md` rather than a quiet
  widget. There is a real argument for it: without one, a person with no network
  cannot record eating at all, and the Body's balance is half-blind.

Do not add the surface without deciding that second point out loud. Whichever
way it goes, `Health.writeMeal` stays untested until a confirmed meal exists, and
`DIETARY_ENERGY_CONSUMED` being Apple-only and *silently* filtered on Android is
still the failure to watch for.

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
