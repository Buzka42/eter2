# Eter · where the work stands

**Start here if you are picking this up cold.** Then `PRODUCT.md` for what Eter
is and what has already been decided; `ENGINEERING.md` for how the model layer,
the storage and the endpoint work; `LANGUAGE.md` before touching a word of
Polish; `RELEASE.md` for what only the owner can unblock.

Written across six sessions, 30 July – 5 August 2026, on branch
`eter-audit-fixes` and now on `main`. Three of those sessions had a real phone
attached, and the last one is the reason most of this document exists: a device
found nine things in an evening that nothing in the repository could.

---

## The state of it, in four lines

- **1028 tests pass, 14 skipped.** `flutter analyze` is clean (four `info`s that
  predate this work). A debug APK builds and runs.
- **Every feature asked for is written.** What is left is device time, reading,
  and owner-only work.
- **The endpoint is live** and all six calls have been run against it, in both
  languages, with the answers read rather than assumed.
- **Nothing is uncommitted.**

## The five things worth doing next

1. **The three evening-invitation checks**, each of which needs a real evening:
   write during the day → that evening must stay silent; turn it off → anything
   pending must disappear; reboot mid-afternoon → that evening must survive.
2. **Bind the rate limiter.** `server/wrangler.toml` still has both bindings
   commented out, so the deployed worker has no per-install cap at all. This
   session alone made about sixty calls to it. `RELEASE.md` §2.
3. **Read a real export** from Daylio, Bearable or Apple Health. The importers
   work and are well tested, but no real file from any of the three has been
   read — Daylio's columns are exact, Bearable's value formats are inferred.
4. **The iOS half of the widget**, which does not exist and needs a Mac.
5. **Deploy the Firestore rules**, without which the Correspondence cannot be
   proven at all.


---

## Start here

```bash
cd app
flutter test          # expect 1028 pass, 14 skipped
flutter analyze       # expect clean
```

If either disagrees with those numbers, something in the working tree is wrong —
fix that before starting anything below.

The device work is driven over `adb`, and everything in this document that says
"seen on the phone" was seen that way: `flutter build apk --debug` with the
endpoint defines, `adb install -r`, then `adb exec-out screencap -p` to look and
`adb exec-out run-as com.eterhealth.eter cat app_flutter/eter.sqlite` to read the
record itself. The last of those is how three separate faults were actually
diagnosed — the screen tells you something is wrong, the database tells you what.

---

## What a phone found, 4–5 August

A device was attached for the last session and found nine things nothing in this
repository could. Two of them had been wrong for months.

### What the phone corrected

1. **"Twice the size" never meant the font.** The instruction of 3 August was
   read as font size and `displayMedium` went to 68 pt. Ten minutes on a real
   screen ended it — four words filled the phone. It meant twice the *length*.
   Type is back at the theme's size; the synthesis is three sentences and the
   three dimensions four to six. **Widening the ceiling alone did nothing**: a
   model asked for "up to six" wrote two, and the length had to be required.
2. **Guidance broke a word in half** — *tętno spocz / ynkowe*. Flutter does not
   hyphenate, and a word wider than its line is broken wherever the engine runs
   out of room, with no overflow and so no error. `core/type_fitting.dart` sets
   the passage against its own longest word.
3. **`EterArrival` ignored the reader's font size** — a bare `RichText` does not
   scale. The one passage this product exists to deliver was the only prose in
   the app that did not respect the system setting.
4. **Recomposing a day only half worked.** `AGAIN` writes four rows; the surface
   showed the new synthesis above the *old* health, mind and spirit, because a
   map comprehension over newest-first rows keeps the oldest.
   `eterNewestByDimension` is a named function so the comprehension cannot come
   back, and its test fails against the old code.
5. **Every modal route was in English.** `EterStringsScope` was installed as
   `MaterialApp.home` — and `home` is a *route*, so anything pushed on top of it
   inherits nothing. The Journal's History sheet came up HISTORY / CLOSE /
   "Tuesday 4 August" on a Polish phone. It is on `builder` now, which wraps
   every route. `modal_language_test.dart` keeps the old shape as a test so the
   reason cannot be undone by accident.
6. **The burn figure was resting alone.** Health Connect gave 22,720 steps
   across three days and zero active kilocalories — the step counter is the
   handset's and nothing on it writes `ActiveCaloriesBurned`. Steps become
   energy now where nothing measured any, **per minute** so a logged session
   never costs the day its walking and never double-counts its own steps. On
   the owner's data 4 August went from 2,031 to 2,385.
7. **The model was estimating training energy for nobody.** It now receives
   weight, height, body fat, age and sex — owner's decision, and a change to
   what crosses the boundary. Live: *"Easy run along the river, 30 min,
   310 kcal — assumed an easy pace for 30 minutes for 88 kg at 10% fat."*
8. **A planet does not stand against itself.** A reading said "the approaching
   configuration between Jupiter and Jupiter". That is a return.
9. **The widget went blank after an install** — which is what a store update
   would do to everyone who had one. The activity refreshes it on open.

### What the phone proved

- **The Vessel's six parts**, drawn for the first time: the wheel with its house
  band, ASC and MC in their own lane, the Moon leading at full width, twelve
  house cards, the figure with its passages. **The loop budget holds on the
  longer column** — 4 decoders held mid-scroll, 3 after a long one, cap 6.
- **The home-screen widget, end to end.** Placed on a launcher, showing today's
  sentence. **Speak** opens Eter on the Journal already listening; **Write**
  opens it with the keyboard up (`mIsInputViewShown=true`). Owner's decision to
  add the two controls; the file argues the opposite case and says so.
- **Reading another app's export, on a device.** A Daylio file pushed to
  Downloads, picked through the real unfiltered picker: *"Przeniesiono 10
  zapisów z Daylio."* Read it again: *"Wszystko z tego pliku (Daylio) już tu
  było."*
- **Guidance at four sentences a dimension**, using the room for what it was
  meant for: *"Rejestr snu oraz tętna spoczynkowego milczy"* — it states the
  silence rather than filling it.

### Still not proven

- The three invitation checks a test cannot do: write during the day → that
  evening stays silent; turn it off → anything pending disappears; reboot →
  that evening survives.
- Bearable and Apple Health on a device. No real export from any of the three
  has ever been read; Daylio's columns are exact, Bearable's value formats are
  inferred.
- The iOS widget. It does not exist and cannot be built without a Mac.

---

---

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
- **Loops no longer steal audio focus** (1 August). Verified by relaunching
  with a cleared logcat: the video pipeline is active and
  `requestAudioFocus` appears **zero** times, where the build before it logged
  one on every launch.
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
| The Letter arriving on a page | Needs five recall notes in a month; the device has one, and they accrue one a day |
| The Correspondence | Needs an account on both sides and the rules deployed |

**On 3 August the invitation consent was found switched _off_**, not on as this
document said — so nothing was scheduled and nothing could have fired. Turned
back on with the owner's agreement, and the alarm landed at **20:54**, which is
the real sunset plus thirty rather than the flat 20:00 fallback. That is worth
noticing on its own: the fallback fired last time because the profile carried
`birth_place = 'Warsaw'` with no coordinates, and it no longer does.

---

---

## Things that will bite you

**A pinned `SliverPersistentHeader` is not a way to keep a row on screen.** It
was the obvious answer for the depths row and it failed twice. A pinned header
must declare its height *before* it is laid out, and that row wraps to two lines
at 390 dp and three at 200 % text — the first guess overflowed a plain phone by
37 px. Measuring it and feeding the height back fixed that and not the second
problem, which is fatal: **a sliver is only built while it is within the
viewport**, so once the guidance passage doubled and filled the screen, the row
stopped existing until it had been scrolled to. `cacheExtent` did not save it.
The row lives outside the scroll now, and that is why guidance lost the first
glance.

**`flutter test` is a debug build.** Anything gated on `kDebugMode` alone
appears in every test and every golden — the two Sanctum probes cost fourteen
failures before they were also gated on `!eterRunningTests()`.

**A test that sleeps a fixed number of milliseconds against an async call will
fail on a busy machine and pass on yours.** `shell_test.dart` already has
`waitForWidget`; use it. One flat 30 ms delay in the weekly-view test was found
this way.

**Two Sanctum controls were reading `DateTime.now()` instead of the injected
clock**, so against a pinned fixture their seven-day window walked off the seeded
data and the test began failing when the host clock crossed midnight, with nobody
touching it. Everything in this product takes `nowProvider`. If something reads
a window backwards from *now*, check which clock it is asking.

**An example in a prompt can come back in the answer.** A real Polish reading
contained *"ten układ tends to ask for harmonizowanie energii"* — five English
words lifted from an instruction that quoted that phrase as the way to hedge.
`languageFor` now says once, for every call, that quoted examples are shapes and
never wording. If you add an example, assume it can be copied verbatim.

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

**The prototype fixture has no birth time, so no golden drew a chart's
angles.** `ascendantReliable` is false for that profile, which means every
shell capture in the suite shows the Vessel's wheel with no cusps and neither
angle named — the half of the surface with nothing in it. The `ASC` and `MC`
letters were drawn at `0.995 × outer` and centred there, which put them
*inside* the sign ring (six pixels of overlap with the sign glyphs) and about
nine pixels past the widget's own edge, so the container decided whether you
read `ASC` or `AS`. It fired on every chart from anybody who told Eter their
birth time — which is to say, on the owner's chart and not on any test's.
The letters now have a lane outside the rim and the wheel gives it up;
`test/golden/chart_wheel_golden_test.dart` is the capture that draws houses,
and it exists so this gap does not reopen.

**A silent video still takes audio focus.** Both loops — the shell's ambient
field and the Arcana plates — are muted with `setVolume(0)`, but `video_player`
manages audio focus by default, so starting one *paused whatever the person was
listening to*. The field loop starts with the shell, which meant opening Eter at
all stopped your music. Nothing in the repository could see it; it was one line
in logcat on launch — `requestAudioFocus() … CONTENT_TYPE_MOVIE …
callingPack=com.eterhealth.eter`. Both sites now pass
`VideoPlayerOptions(mixWithOthers: true)`. If a third video is ever added, it
needs the same option, and the check is: launch, then
`adb logcat -d | grep requestAudioFocus` — it must find nothing.

**A scope on `MaterialApp.home` is a scope no pushed route can see.** `home` is
a route, and a modal sheet or dialog is its *sibling* rather than its child, so
it inherits nothing. `EterStringsScope` sat there, and `EterStrings.of`
documents its own fallback as English — so the Journal's History sheet came up
HISTORY / CLOSE / "Tuesday 4 August" on a Polish phone, silently, for as long as
the sheet has existed. It is on `builder` now, which wraps every route the
Navigator shows. No test could see it because a widget test pumps a sheet under
whatever scope it likes; `modal_language_test.dart` pushes one the way the app
does, and keeps the old shape as a test of its own.

**Flutter does not hyphenate, and a broken word is not an overflow.** A word
wider than its line is broken wherever the engine runs out of room — no hyphen,
no error, because nothing overflowed. Real Polish guidance at 68 pt read "tętno
spocz / ynkowe" and every golden was clean, because the word came from the model
rather than from a fixture. `core/type_fitting.dart` sizes a passage against its
own longest word, and holds back a logical pixel: fitting a word to *exactly*
the line width still breaks it.

**`RichText` does not scale with the reader's setting.** `Text` does; `RichText`
is not a `Text`. `EterArrival` is built of `RichText`, so the product's most
important passage was the only prose in the app that ignored the system font
size — in both directions, and a phone set to 85 % rendered it at 100 % while
every measurement of it assumed otherwise.

**A map comprehension keeps the last of each key.** `{for (final row in rows)
row.dimension: row}` over rows that arrive *newest first* keeps the **oldest** of
each dimension. That is how recomposing a day updated the synthesis and left
health, mind and spirit showing the earlier reasoning. If a list is ordered and
you want the first of each key, write the loop.

**A surface below the fold is a surface no capture draws.** A `ListView` builds
nothing it cannot see, and the Sanctum's goldens photograph what is on screen —
so the export/import panel at the bottom of that scroll had never been laid out
by anything in the suite. `Choose a file` had been overflowing its row by 110 px
at 320 dp with text doubled since the day it was written, in front of people and
nowhere else. `EterAction` lets a label wrap now, and
`sanctum_export_panel_test.dart` renders the panel directly. If you add anything
to that panel, it is the only place that will see it.

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

---

## The queue, in dependency order

Nothing here is blocked on anything above it except where stated.

### 1 · The Polish sentences · *done, and read once more if you like*

All fifteen sections of `docs/TRANSLATIONS.md` were read against the two tests in
`LANGUAGE.md`, in six slices, and everything that failed one was rewritten. What was
actually wrong, in descending order of how badly it read:

- **Gender agreement in assembled sentences.** The sweep summary put one fixed
  adjective ending after fifteen nouns of two genders, and fed it clauses where a
  noun belongs. The retrospective left a participle in the wrong case above four.
  `LANGUAGE.md` now has a section on both shapes.
- **Gendered verbs addressing the reader** — *chciałabyś lub chciałbyś*, and
  *Potwierdziłem* on a button. There are none left in the file; the grep that
  finds them is in that same section.
- **Vocabulary the lexicon had already retired**, still in place: `SANKTUARIUM`
  titled the Sanctum, `Pulpit` was an opening page, `CIĄGŁOŚĆ` was a consent, and
  *komponować* survived in three strings.
- **Words that mean something else here** — the food estimate stayed out of *the
  weight*, and the first matrix cell was called *Dane*.
- **Aether now declines**, because it is a name. See `LANGUAGE.md`.

`EKSPORT LOKALNY` was kept and `LANGUAGE.md` records why: the native word is *kopia*
and the cloud section owns it. `WGLĄD` still does two jobs; leave it until use
says otherwise, and change the *section* rather than the destination.

**Watch for:** no test reads Polish for sense, so a spliced or ungrammatical
sentence passes everything. **And the model's own Polish was recorded for the
first time on 4 August** — see item 2 at the top. It was choosing a grammatical
gender for the reader, and a different one for itself, on every call. **And it is not only the strings** — the model's own
prose is Polish nobody checks either. On 3 August a real reading contained
*"ten układ tends to ask for harmonizowanie energii"*: five English words inside
a Polish sentence, lifted verbatim from an instruction that said, in quotation
marks, to write "this configuration tends to ask for". A quoted English example
sitting near a LANGUAGE block that insists some things stay in English character
for character is an easy thing to misread. `languageFor` now says once, for
every call, that quoted examples illustrate a shape and are never to be reused
word for word — and that exemplar is stated as a rule about grammatical subject
with no phrase left to lift. If you add an example to a prompt, assume it can
come back in the answer.

Read every string you touch, out loud if it helps.
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
  have been the menu `PRODUCT.md` rejected.
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

**Done, 4 August:** `test/golden/long_view_golden_test.dart` draws
`EngravedLongView` directly — a week with two nights nobody recorded, a year at
320 dp and at 600 dp for the sheet after it has widened, and pages, which is the
one measure with a real zero. The shell's capture harness drives the shell
rather than the sheet, and the panel is fourteen taps of a bead down it, so
nothing else in the suite had ever drawn any of this.

It is worth the four pictures for one reason: **an unrecorded period is an open
tick below the baseline and a recorded zero is nothing at all**, the two are a
few pixels apart, and they mean opposite things. No assertion says that as well
as the image does.

### 3 · The Letter · *built, and run against the real model*

`core/aether/letter.dart`, schema 13's `Letters` table, `letter` in `CALLS` at
0.7, and `EterPrompts.version` now at 7. `ENGINEERING.md` now documents six calls.

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
- `Letters` has **no retention expiry**, deliberately. `ENGINEERING.md` §6 says why.

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
`EterPrompts.version` was raised because of it; it is **10** in
`core/ai/prompts.dart` today, and the same failure came back on 4 August — see
item 2 at the top, and `LetterParser`, which no longer trusts the instruction. See the version note for what changed.

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

### It never arrived, and here is why · *fixed 3 August*

**The receivers were not in the APK.** `zonedSchedule` registers an alarm whose
PendingIntent targets
`com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver`, and that
component was declared **nowhere** — not in the app manifest, and not merged in
from the plugin. AlarmManager accepts such an alarm perfectly happily, fires it
on time, and delivers the broadcast to nothing.

The failure mode is the worst available: no notification, no exception, no log
line, and `dumpsys alarm` *showing the receiver's name* the whole time — because
that string is just the intent's component, not evidence anything can receive it.

It cost three evenings — 31 July, 1 August, 3 August — and the icon was blamed
twice. The icon was never the cause.

**Both receivers are declared in `AndroidManifest.xml` now**, and the boot one
carries `MY_PACKAGE_REPLACED` as well as `BOOT_COMPLETED`: Android drops an app's
alarms when the package is replaced, which is every store update, so without it
an update would silently end the invitation for anybody who had it on.

**Check it on the APK, never on the source**, because it is the merge that fails:
dump the built APK's manifest with `aapt2 dump xmltree` and grep for
`dexterous`. Empty means broken. Reading `AndroidManifest.xml` proves nothing.

**Proven end to end on the device**, app in the background: the notification
posts, lands under **Silent** at `importance=2`, carries no sound and no
vibration, and `ic_notification` renders on the status bar as the arc and the
plumb — not the white blob an adaptive icon would have given. That closes both
of the two rows this document had been carrying as unproven since 31 July.

**Two debug-only controls now exist in the Sanctum**, gated on
`kDebugMode && !eterRunningTests()`:

- `SEND INVITATION NOW` calls `LocalNotificationSink.debugShowNow`, which posts
  the notification directly. It is what isolated the fault: it worked while the
  scheduled one did not, which ruled out the icon, the channel and the
  permission in one tap.
- `SCHEDULE IN 60s` goes through the real `scheduleAt`, so the alarm-and-receiver
  half can be watched inside a minute instead of once per sunset.

`eterRunningTests()` matters as much as `kDebugMode` there: `flutter test` is a
debug build, and without it these two appear in every Sanctum test and golden —
fourteen failures for a control that only means anything on a phone.

**Still to watch, none of which a test can:**

1. ~~One notification that evening, silent and low-importance~~ — **done**, by
   the 60-second probe. Still worth seeing fire at a real sunset once.
2. Write a page during the day; that evening must stay silent.
3. Turn it off; anything pending must disappear immediately.
4. Reboot mid-afternoon; that evening's invitation must survive. This is now
   actually plausible — before 3 August the boot receiver did not exist either,
   so it could not have worked.

**And the thing the device changed about the design.** The profile carries
`birth_place = 'Warsaw'` and **no coordinates**, so `registerCoordinates` returns
null and the invitation is scheduled at the flat fallback hour — the alarm landed
at 20:00, not at sunset. That branch was named `polarFallbackHour` and documented
as an Arctic edge case; it is the ordinary path for anyone whose place was typed
and never geocoded. Renamed, documented, and the Sanctum copy now says "at your
own sunset — or at eight, if Eter does not know where you are" rather than
promising a sunset it may not have.

**The icon.** It was scheduled against `@mipmap/ic_launcher`, which is adaptive
and full-colour, and Android draws a small icon as an alpha mask.
`res/drawable/ic_notification.xml` is the mark reduced to what survives at 24dp:
the arc and the plumb. **Seen on a status bar on 3 August** and it renders
exactly as drawn.

Worth being honest about, since it is the kind of thing that misleads the next
person: changing this icon was necessary but it fixed nothing at the time, and
it was recorded here as though it had. The notification was never reaching the
point of having an icon. See the section above.

### 5 · Import · *done, including other apps*, and the prompt fixtures

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

**Reading other apps · done, 4 August.** Daylio, Bearable and Apple Health, in
`core/privacy/`, reached from the Sanctum beneath the restore. This is the
version that gets somebody to switch, and almost every rule in it is the
opposite of the restore's:

- **It does not need an empty device**, because somebody importing three years
  of Daylio has usually been using Eter for a fortnight first — that is what
  sends them looking. So every record carries a natural key checked against
  what is here: the same words at the same minute are the same page. Importing
  the same file twice adds nothing; an overlapping export adds only what is new.
- **Nothing imported is queued for interpretation.** `AutoInterpret` acts on
  `pending`; an import of nine hundred old pages would be nine hundred model
  calls nobody asked for. Imported pages carry their own status — and a test
  pins that the Journal still *shows* them, because a status chosen to keep the
  queue away could as easily have hidden them from the person.
- **What cannot be kept is named and counted**, not dropped. "Imported 1,412
  records" and "…and ignored your medication log" are different sentences.

Three judgement calls worth knowing before changing any of it:

- **Daylio's five shipped moods rank one to five and a custom mood takes no
  number at all** — ranking it in the middle would be a measurement nobody
  made. The mood names are read in Polish too: the export is written in the
  app's own language, and a reader that knew only the English five would
  import a decade of feelings as unranked words.
- **Bearable's file does not say what scale its ratings are on.** Eter keeps
  self-reports on 1..5 and the Long View averages and plots them, so a raw 8
  is not a rough import but a corrupt one. The scale is read off the file: a
  rating above five is proof it is not a five-point scale, which is the only
  inference that cannot be wrong in the dangerous direction. A test ties the
  imported range to `LifestyleReading.marks.length` rather than to the number
  five.
- **Apple Health is streamed, and mostly left alone.** The file runs to
  hundreds of megabytes, so `apple_health_scanner.dart` is fed chunks and
  keeps only what straddles a boundary. It takes the long history — weight,
  sleep, resting heart rate, variability — and refuses steps and active
  energy, which already have a pipeline here: a file carries no notion of
  which device measured what, so importing them would double every day a live
  source is already reporting. `SourcePriority.importedFile` is appended last
  so nothing imported outranks the device, and a day whose vitals are already
  recorded is left exactly as it is and counted.

Two things are refused rather than guessed anywhere they appear: a weight with
no stated unit, and a date that is not a real date. The first halves or doubles
somebody's body; the second files a page against a day that never happened.

**Not verified on a device**, like everything else from 3–4 August. And **no
real export has been read** — the formats come from the apps' own documentation
and from independent analyses of real files. Daylio's eight columns are exact;
Bearable's value formats are inferred, and the two places to change when a real
file turns up are named in `bearable_import.dart`.

**Apple Health exports a `.zip`** and Eter reads the `export.xml` inside it. The
Sanctum says so, because a person who picks the archive would otherwise get an
unreadable-file sentence with no idea why. Unpacking it here would mean a zip
dependency reading an arbitrary archive off somebody's phone.

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

**Seen on screen, 3 August.** `EKSPORTUJ` on the device wrote
`/sdcard/Download/Eter export 2026-08-03T18-14-32-127508Z/` containing
`eter-local-data.json` at 4.6 MB, `minute_buckets.csv`, `raw_buckets.csv`,
`README.txt`, and two zero-length CSVs (`activity_sessions`, `live_sessions`)
for the measures this record has nothing in — absent, not zero. The Sanctum then
offers `KOPIUJ ŚCIEŻKĘ` and says the copy is in Downloads. The last unproven
part of this item is now proven.

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

### 6 · The home-screen widget · *Android built; iOS needs a Mac; nobody has placed one*

One sentence of the day's synthesis, in Eter's own ground, no counts and no
controls. `EterWidgetProvider.kt`, `core/widget/home_screen_widget.dart`, and a
`eter/widget` method channel between them.

- **RemoteViews, not Glance.** Glance means Jetpack Compose and its compiler
  plugin in a build that has already broken three times over toolchain versions,
  for a surface that is one `TextView`.
- **It reads a preference, never the database.** A widget process opening Drift
  would be a second reader of a migrating schema holding a lock outside the
  app's lifetime — and it would put a whole record within reach of a process
  that needs one line of it.
- **The synthesis, never a dimension.** It is the passage already thought about
  as something another person might see: it is the one the Correspondence may
  send. A test pins that the three dimensions never reach the launcher.
- **Today's or nothing.** The day is written beside the sentence and the widget
  compares it against the day *the app* believes it is, so a redraw the system
  triggers at midnight cannot disagree with the app about what today means.
- **Withdrawing AI consent clears it.** The rows stay and a launcher goes on
  drawing whatever it was last given; this is the one surface a revocation
  cannot reach on its own.

The receiver is confirmed **in the built APK** with `aapt2 dump xmltree`, not in
the source, for the reason the evening invitation took three evenings to learn.

**Nobody has placed one on a home screen.** That is the whole of what is left
for Android: add it, watch it change when guidance composes, and watch it empty
when consent is withdrawn. The iOS half is WidgetKit and SwiftUI and cannot be
built or verified without a Mac.

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

---

## The repeated card, and the reading that explains it

The Vessel draws **the same card twice in a row** on the owner's chart —
`ZASTANE` and `ODZIEDZICZONE`, both Kochankowie, same plate, same keywords, one
directly under the other. It looks like a rendering fault and it is arithmetic:
`given` reduces the day, 25 → 7, and `inherited` is the month, already 7. Two
positions landing on one card is a normal outcome of `buildArcanaMatrix`.

**The reading is what makes that legible, and it is now required to.**
`VesselReadingRequest.recurrences` works out on the device every card holding
more than one position, and the prompt says a recurrence must be read somewhere
in the movements — named as one card standing in two places, not as two facts
that happen to rhyme. It was left to the model to notice before, which worked,
which is exactly the kind of thing that works until it does not.

Confirmed against the live model on the owner's chart, prompt v9:

> *Pustelnik powraca w tym układzie dwukrotnie, wiążąc ze sobą Drogę życia oraz
> Marsa w Pannie.*

> *Uran i Neptun dzielą tę samą kartę Diabła.*

> *…za sprawą potrójnej obecności Sprawiedliwości. Karta ta leży jednocześnie w
> Księżycu, w Jowiszu oraz na Ascendencie.*

Three of them in one reading, including a card in **three** positions read as one
thing rather than three — which is the case `vessel_reading_composer_test.dart`
pins as a single entry rather than two pairs.

**Where the reading lives, because it is easy to miss.** The movements are the
chart's synopsis, part four of six, under `CAŁY KOSMOGRAM`. They used to be the
whole of the Vessel's writing and they are now a fifth of it.

**Done, 4 August:** `test/fixtures/live/` holds a v10 recording of this call
made from invented inputs. The Polish passages above are the owner's own chart
and are quoted here only; they are not, and must not become, a fixture.

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
**The English lettering on the card art is deliberate** — asked about on
3 August, and the owner's answer is that it stays. Do not "fix" it.

---
