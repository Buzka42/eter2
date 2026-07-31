# Eter · where the work stands, and what to do next

Written 30 July – 1 August 2026 across three long sessions on branch
`eter-audit-fixes`, the second of them with a real phone attached.
Read this first if you are picking the work up cold; then `DECISIONS.md` for what
the product owner has settled, then the specific document each task names.

**State of the tree:** nothing uncommitted. `flutter analyze` clean. **796 tests
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
- **The document picker opens unfiltered**, so a `.json` is selectable, and the
  export lands in the *shared* Downloads folder through MediaStore.
- **All six model calls, against the deployed endpoint**, plus guidance, the day
  story and interpretation composing on the phone itself.
- **Nutrition write-back**, the whole chain — see item 8.
- **The Long View's birth-date clamp.** Ninety taps of the earlier bead stop at
  the twelve months ending with the birth month; before the clamp, seventy-five
  reached 1981.

**Left on the phone**, deliberately, so it can be inspected or tidied: a debug
build carrying the endpoint defines, a test journal page dated 31 July with its
day story and two derived meals (one written to Health Connect), the evening
invitation switched **on**, and Health Connect write access granted for weight
and nutrition. Deleting the journal page removes the local rows but not the
Health Connect record, so tidy in that order.

Still unproven, and why:

| Thing | Blocked on |
|---|---|
| The invitation appearing | Next fires **1 August, 20:00**. The 31 July one fired on time and posted nothing — the icon name was wrong, and is fixed; see item 4 |
| `ic_notification` on the status bar | Same firing |
| The Letter arriving on a page | Needs five recall notes in a month; the device has one, and they accrue one a day |
| The Correspondence | Needs an account on both sides and the rules deployed |

---

## Start here

```bash
cd app
flutter test          # expect 796 pass, 9 skipped
flutter analyze       # expect clean
```

If either disagrees with those numbers, something in the working tree is wrong —
fix that before starting anything below.

---

## What the owner asked for after testing it

31 July, after a session with the app on a real phone. Seven items; all seven
are now done (the last four on 1 August, below). **Read this before the queue
below** — the queue is the original audit backlog, and this is what use
actually threw up.

### Done

- **The birth date types its own hyphens.** `core/profile/date_input.dart`. Not
  a picker, deliberately: a birth date is four digits somebody knows by heart,
  and a calendar widget means spinning back thirty years.
- **Onboarding asks for the birth time.** Precision, a self-punctuating clock
  field, or a part of the day — reusing the `BirthTimePrecision` machinery the
  Sanctum already had. The UTC offset is suggested from the phone rather than
  asked about.
- **Onboarding resolves the birth place.** It used to write `birthPlace` as a
  bare string and stop, which is why a real profile carried
  `birth_place = 'Warsaw'` with a null latitude — and why the register *and* the
  evening invitation both fell back to a clock hour for somebody who had said
  exactly where they were born. Bounded to four seconds; the Sanctum still
  resolves it later if the lookup fails.

### Done, 1 August (all seven now)

Decided and built in one session; `DECISIONS.md` 1 August carries the
reasoning for each choice. In brief:

- **Birth-place autocomplete** — `core/profile/place_suggestions.dart`.
  A `PlaceSuggester` interface separate from `BirthplaceResolver` (so the four
  test fakes stayed untouched), a debounced controller with latest-query-wins,
  and a suggestion list under the field in onboarding *and* the Sanctum.
  Owner chose single-locale: show whatever spelling the device geocoder
  returns, accept either on save. Candidates are named by reverse-geocoding
  each hit, capped at four. `test/place_suggestions_test.dart` drives the
  debounce, staleness and failure paths under `fake_async`.

  The rows have their **own** widget test, and they need one: the platform
  geocoder is the only real `PlaceSuggester` and it throws under a test
  binding, so nothing else in the suite renders a single suggestion. Writing
  it found two defects immediately — the rows were keyed on the label, so two
  Springfields in the same state threw `Duplicate keys found`, and they stood
  at 44 dp against the product's own 48 dp tap floor. Both fixed. If you add
  anything to that list, put it in `place_suggestions_widget_test.dart`,
  because no other test can see it.
- **Astrogram "go deeper"** — a `THE CHART` / `KOSMOGRAM` action under the
  wheel opens per-planet passages (Mercury through Neptune) composed through
  the **same** `VesselReadingComposer`, same `inputHash` cache, same
  `VesselReadings` table — not a seventh call. `AI_FLOW.md`'s call table notes
  it, and `shell_test.dart` asserts both the seven bodies and that composing
  them asks for *only* them. The label is a bare noun because the action row
  at 320 dp × 200 % has room for about nine characters; the verb forms
  overflowed in both languages. **Not yet composed against the live
  endpoint** — the fixture provider is what these tests exercise, so the first
  real run should be read for sense the way v6's letter was.
- **Cards — and why only some of them animated.** Every reading card was
  already an `EterArcanaPlate` asking for its night loop, so "animate
  everywhere" was true in the code and false on the phone. The reason is
  arithmetic: with the readings *and* the new chart panel open the Vessel puts
  **eighteen plates in one column**, each allocating a hardware video decoder,
  and a mid-range phone has nowhere near eighteen. Past the limit
  `initialize()` fails, the plate keeps its still art, and an arbitrary
  subset animates — different every build. That is exactly the reported
  symptom.

  So `core/arcana/loop_budget.dart` caps concurrent loops at six, and
  `ArcanaCardMedia` now only holds a decoder while it is **on or near the
  screen** (240 dp margin), handing it back when scrolled away. The plate you
  are looking at is the one that moves. The still art is still mandatory
  underneath, so a refused slot costs nothing but motion.

  Secondary cards take the Sun card's clamp **at night outside the grounded
  register**; day and grounded keep the 132 dp thumbnail.

  **This is the one change in this batch that a device has to confirm.**
  `eterRunningTests()` disables the video plugin outright, so the budget is
  unit-tested (`test/arcana_loop_budget_test.dart`) and the visibility half
  is not testable here at all. On the phone, at night, in the balanced or
  immersive register: open the Vessel, `Read deeper`, and scroll the whole
  column — every card should be moving by the time you have looked at it for
  a moment, and none should stutter.
- **Sanctum, by frequency** (owner's pick over by-consequence and
  collapsible): opening page, language, register, evening invitation on top;
  birth context, where-you-live, consents, and the rest below the hairline.
- **Guidance depths slide horizontally** (owner approved): `LOOK DEEPER`
  opens a persistent glyph row — the three depths stay visible, the open one
  in full ink — and the chosen section slides in beneath by tap. Tap, not
  swipe: the shell's pager owns the horizontal gesture. Glyphs are drawn
  placeholders in `core/icons.dart` (`EterSectionMark`); the owner may
  replace them with generated art, which touches only the painters. The
  label stays beside every mark — non-negotiable 7 forbids an unexplained
  symbol and nothing has taught these yet.

  The sections also stopped printing their own name: the row *is* the
  heading now, and `GUIDANCE` appearing twice two lines apart read as a bug.
  Each of the three takes `showHeading: false` from the Dashboard and keeps
  only its actions. Three tests in `shell_test.dart` cover it — the row
  surviving an opening, crossing from the Body to the Vessel without
  collapsing, and the name not being printed twice.

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
member whose comment sits between `@override` and the signature. **That is not a
hypothetical**: `chartGoDeeper` was added on 1 August with its note in exactly
that position and vanished from `TRANSLATIONS.md` silently, so nobody would have
reviewed either language. Put the comment *above* the annotation, and check the
string count moved after regenerating — it is printed on the last line.

**Left deliberately:** *rosnący garb* for a waxing gibbous moon. It is transparent
but it is not what Polish astronomy says, and every alternative reads worse inside
`Księżyc w fazie …`. A decision, not an oversight.

### 2 · The Long View surface · *done, and rendered on a phone*

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

- **The axis stops at the date of birth.** Owner's decision, and the right one:
  the months before your first record are still months you lived and did not
  spend with Eter, and the axis saying so is true; before you were born it is not
  your time at all. Without the floor, seventy-five taps reached **1981**,
  because each tap is a whole year once the span widens.

**Rendered on a phone**, all three spans, and two defects came out of it:

- A week nobody wrote in drew seven one-pixel stubs — pages is the only measure
  with a real zero, and the bar floor applied to it, putting marks a pixel away
  from the open ticks that mean something else. A zero draws nothing now.
- `Year · August 1992 – July 1993` is thirty characters and was ellipsised before
  the second year could be read. Abbreviated months on that span.

**Not done:** no golden covers a widened sheet. The panel is behind fourteen taps
of a bead and the capture harness drives the shell, not the sheet.

### 3 · The Letter · *built, and run against the real model*

`core/aether/letter.dart`, schema 13's `Letters` table, `letter` in `CALLS` at
0.7, and `EterPrompts.version` now at 7. `AI_FLOW.md` now documents six calls.

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
`EterPrompts.version` was raised because of it; it is **7** in
`core/ai/prompts.dart` today. See the version note for what changed.

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

### 8 · Nutrition write-back · *done, and it was broken*

Proven on the phone, end to end and by the route the product intends: a journal
page about food → interpretation → two unconfirmed estimates in the Body →
confirm one → `WRITE BACK` → *"[Health Connect] Meal was successfully added!"*
The surface said "1 record written", the estimate left unconfirmed beside it was
correctly not sent, and a second tap wrote nothing.

Getting there found two real defects, both of the kind only a device produces:

- **`writeMeal` passed a zero-length interval.** Health Connect's nutrition
  record is an interval and rejects `startTime == endTime` — *"startTime must be
  before endTime"*. The plugin catches it, returns false, the write-back skips
  the row. Meals get one minute now: not a guess at how long somebody ate, the
  smallest interval the platform will accept for something Eter holds as an
  instant.
- **Every unhappy path said the same reassuring thing.** `run()` returned an
  `int`, so access refused, every record rejected, and nothing to do all
  collapsed into zero and produced *"Nothing new to write. Everything you
  entered is already there."* The second sentence was false while a confirmed
  meal sat unwritten. It returns `HealthWriteBackResult` now and the Sanctum
  distinguishes four outcomes.

**Left on the phone:** a test journal page dated 31 July, its day story, two
derived meals (one confirmed and written to Health Connect), and the Health
Connect record itself. Deleting the page removes the local rows through
`revertJournalEntryRows` but *not* the Health Connect record, so tidy in that
order if you want it gone.

---

## Things that will bite you

**Golden tests are the honest reviewer.** They run every language at 320 dp and
200 % text, which is where translation breaks layouts. They caught a 112 px English
overflow and a 175 px Polish one on the same row, and they refused to tap when two
widgets ended up sharing a semantics label. When they fail, read the failure before
re-recording — **four** times in this branch the failure was a real defect, not a
stale image. Two of the four were on 1 August: `Go deeper into the chart` ran 181 px
past the action row in Polish and 9.4 px past it in English, which is how that
button ended up a short noun in both languages. The action row at 320 dp × 200 %
has room for roughly nine characters; budget for that before writing a verb.

**An overflow fails `--update-goldens` too**, which is the behaviour you want:
the capture throws before it is written, so a bad layout cannot be recorded as
truth. It also means a red run under `--update-goldens` is worth reading rather
than re-running.

**A widget test with no teardown hangs for ten minutes and then says
`TimeoutException`**, with a stack pointing at `dart:isolate`. It is almost
always the tree never being disposed: `eterTestDatabase()` leaves Drift a
zero-duration close timer, and `closeShell` in `shell_test.dart` is what flushes
it. Put new shell-level tests in that file rather than standing up a second
harness — one was written on 1 August and hung until it moved.

**A surface behind a platform plugin is a surface no test renders.**
`eterRunningTests()` disables video outright and the geocoder throws under the
test binding, so the Arcana loops and the birth-place suggestion rows are both
invisible to the whole suite — they pass every run without ever being drawn.
Give anything in that position its own test with a fake, and drive the widget
directly rather than through the surface that owns it. Doing that for the
suggestion rows found a `Duplicate keys found` crash and a 44 dp tap target on
the first run.

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

1. **Bind the rate limiter.** Both bindings are still commented out in
   `server/wrangler.toml`, so the deployed worker has no per-install cap of any
   kind — not even the KV fallback whose weakness it logs as
   `limits=kv-approximate`. Google's free tier is the only ceiling, on an
   endpoint anybody holding the client token can reach. This moved to the top of
   the list the moment the endpoint went live.
2. **Upload keystore** — create it early; losing it means losing the ability to
   update the listing.
3. **Redeploy `server/worker.js` whenever it changes.** It is deployed and
   current as of 31 July, but it drifted three commits behind once already and
   the symptom was `400 Unknown call: letter` with nothing wrong in the
   repository. `test/worker_contract_test.dart` catches the half that lives
   here; only `npx wrangler deploy` catches the other half.
4. **Store subscription products** — `eter.monthly` $4.99, `eter.yearly` $39.99,
   **20 PLN/month in Poland** as a regional price, not a conversion.
5. **A public privacy-policy URL**, and the health-data declarations.
6. **Firestore rules deploy** — the live project's rules predate the mirror and
   would deny it.
7. **Rotate the development Gemini key** before any public build.
