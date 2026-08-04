# Eter · where the work stands, and what to do next

Written 30 July – 4 August 2026 across five long sessions on branch
`eter-audit-fixes`, two of them with a real phone attached.
Read this first if you are picking the work up cold; then `DECISIONS.md` for what
the product owner has settled, then the specific document each task names.

---

## Pick up here · 4 August

Everything is committed and green. **All of the code asked for is written.**
What is left is device work, reading, and owner-only work.

### 1. The Vessel's surface · *done, and never seen*

`vessel_section.dart` now holds all five parts and renders the owner's order:
the wheel led by the Sun, Moon and Ascendant with their passages, the twelve
house cards, the angles, the chart synopsis, the figure place by place, the
figure's synopsis. Then today's Positions, which is the only part that changes.

Three things about it worth knowing before changing any of it:

- **The Sun, Moon and Ascendant are lifted out of the position list.** They
  lead the wheel and are not printed again below, which is why `SUN` is no
  longer a row anywhere and the surface no longer has a "don't draw this card
  twice" special case.
- **A part is asked for at most once per opening.** The compose pass hangs on
  a post-frame callback, so it runs again on every rebuild, and a part that
  failed leaves exactly the empty row that starts the pass. Without the
  `_attempted` set a part the model kept refusing would be requested — and
  billed — on every frame that touched this surface. The set is cleared when
  the birth context changes, because that is a different chart.
- **The houses are composed only when the angles are real**, the same
  condition `buildChartReadingRequest` uses to decide whether to send them.
  The surface never shows a band of houses the reading was never asked about.

`InitialVesselReadings` still composes only the chart's synopsis when a birth
time is saved; the other four arrive on the first opening of the Vessel. That
is deliberate — five calls at save time to write four parts nobody is looking
at yet — and it is the reason the surface has to render partial states well.

**Not seen by anybody.** Composed only against fakes. See item 2.

### 2. The five parts have now been read against the live model · *4 August*

Three recording rounds against the deployed endpoint, twelve calls each.
`test/fixtures/live/` holds prompt **v10** and `EterPrompts.version` is 10.
Everything below **passed every shape check and every safety rule on the first
run** and was still wrong, which is the entire argument for reading the output:

- **"The records show"** — in the houses, the angles *and* the figure's
  synopsis. Eter as an archive reporting on somebody: the same failure as the
  letter's "We watched the third short night".
- **`occupants`, a field name, in the prose of five houses.** The instruction
  had used the word twice in its own sentences. *An example in a prompt can
  come back in the answer* — and a field name is an example nobody meant to
  set.
- **Orbs printed to two decimals**, and **transits described in a natal chart
  that has none**.
- **Ten of twelve houses opened with one clause and a swapped card name.**
- **House 1 never said the word Ascendant**, which is the one thing it exists
  to say: the surface shows that card above the list, so without it the reader
  sees the same card apparently printed twice with no explanation.
- **The figure's synopsis named places by their internal keys** — "The Moon
  across the sun, the era, and mercury". `recurrences` stopped carrying `keys`
  at all: a field the answer must not quote is a field the request should not
  have.

`EterPrompts._vesselRegister` is the shared half of the fix and applies to all
five parts. Four new tests in `live_fixtures_test.dart` hold each of these
against the recording, because none of them is a shape a parser can see.

**And one that came back after being forbidden since v6.** The re-recorded
letter closed with *"We saw the short nights return."* It has been banned by
instruction in four consecutive prompt versions. `LetterParser` refuses it
outright now — language-aware, because Polish carries the first person plural
on the verb (`widzieliśmy`) while the English pronoun `we` is an ordinary
Polish preposition ("we wtorek"), so the English rule applied to Polish would
refuse most letters for saying "on Tuesday". A refusal costs a retry; a letter
is best-effort, is not cached when it fails, and is attempted again the next
time the Journal opens.

**Still not read by a person:** the Polish side of any of this. Every recording
above is English, because that is what the smoke test composes.

### 3. What has still not been seen by a person or a model

This is the larger risk and it is not code. Every change below was verified by
tests and by goldens; **almost none of it has been run on the phone, and none of
the new writing has been read.**

- **The Vessel's whole surface has never been on a phone in this shape.** Six
  parts in one column, twelve house cards among them, each with a plate — the
  loop budget caps concurrent decoders at six and hands them back off-screen,
  but that was measured on a column of eighteen plates and this one is longer.
  Worth re-running the frame-differencing check described under *Cards* below.
- Positions has never been composed with the natal context attached, so nobody
  has read what it now says about a retrograde.
- The doubled guidance, the always-present depths row, the Body's macro fields
  and the Journal's confirmation prompt have not been looked at on a device.
- **The depths row now sits above the guidance passage**, so guidance no longer
  owns the first glance. That was forced — see the section below for why — and
  it is the change most worth the owner's eye.

Re-record the fixtures with *invented* inputs. The owner's own chart and record
must not become a fixture. The Vessel parts compose from an invented birth in
`live_smoke_test.dart` — 14 March 1990, 06:45, Warsaw — which is a real birth
as far as the engine is concerned, with genuine houses and genuine angles, and
belongs to nobody.

### 4. The phone, as it was left

A debug build carrying the endpoint defines (`--dart-define=ETER_AI_TOKEN=eter-ai`,
endpoint `https://eter-ai.eter-ai.workers.dev`), the evening invitation switched
**on**, and two debug-only controls in the Sanctum — `SEND INVITATION NOW` and
`SCHEDULE IN 60s` — gated on `kDebugMode && !eterRunningTests()`. A test
notification may still be in the shade; it uses the invitation's own fixed id, so
tomorrow's real one replaces it rather than stacking.

The build is older than the tree. Nothing from the nutrition or Vessel work is on
it.

---

**State of the tree:** nothing uncommitted. `flutter analyze` clean. **879 tests
pass, 14 skipped** — the skips are the live-provider suite, which needs the
endpoint token, and one manual test that needs an export file. The live suite
*has* been run and passes; see item 2. Schema is at **15**, and the upgrade
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

## Start here

```bash
cd app
flutter test          # expect 879 pass, 14 skipped
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
- **The Vessel reads the chart, in one menu** (superseding the `THE CHART`
  panel built earlier the same day). The Life Path and the astrogram were two
  disclosures with a compose button each; they are one menu now, one list, and
  no control asks for the writing.

  The call itself changed shape. It wrote one passage per position — eighteen
  on a full chart — and every one was correct and none had looked at the
  chart. That is structural, not a prompt that needed tightening: a passage
  that can only see one placement has nothing to relate it to. It now returns
  three to five titled **movements** about how placements stand to each other.
  Prompt v8, same `vesselReadings` call name, so **no worker redeploy** — the
  endpoint reads only the call name and the prompt and schema are built on the
  device. Stored as one row per chart under the reserved key `configuration`;
  the old per-position rows are cleared for the chart being composed.

  **Read against the live model, not assumed.** On a real chart it grouped —
  "Saturn, Uranus and Neptune all point toward material gravity" — and set
  that against the water it had gathered a paragraph earlier. The recorded
  response is now the fixture, and `live_fixtures_test.dart` checks the thing
  a shape check cannot: at least one movement must hold two placements
  together.

  **Nothing composes without a birth time**, approximate or exact. It fires
  when a birth time is saved (owner's choice), and the Vessel also retries
  silently on open if the reading is still missing — stated here because it is
  a deviation from what was asked: save-time only, with the button gone, would
  leave one offline save unwritten forever with nothing to ask again with.
- **Guidance leans on the sky at night.** It read as health reporting even on
  immersive, and the stated 40 % symbolic was not the reason: that half
  arrived as a single sentence while the measured half arrived as a table. A
  model cannot weight what it was not given. Today's Positions passage now
  travels in full rather than as its one-sentence note — already written,
  already validated — and the shares move with it: immersive 30/60/10 after
  sunset, balanced 45/40/15. Grounded never leans. The Dashboard resolves the
  register and passes it in, because it is the only place with a horizon and a
  clock. `AI_FLOW.md` §"what to weigh" has the table.
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

  **This was the one change in this batch that a device had to confirm, and it
  is confirmed** — 3 August, at night, balanced register, on the owner's phone.

  Measured rather than eyeballed, because motion is not visible in a
  screenshot. Two things were counted:

  - **Decoders held, via `dumpsys media.resource_manager`.** Fresh launch with
    the Vessel closed holds **2** — the shell's ambient field. With the Vessel
    open and `CZYTAJ GŁĘBIEJ` expanded, the whole column scrolled: **8**. That
    is 8 − 2 = **six plates, exactly the cap**. The budget holds on hardware.
  - **Motion, by differencing frames.** Four to five screenshots ~0.8 s apart,
    summing pixels over a window *inside* the card art rather than the whole
    screen — the star field animates too, so a full-frame diff proves nothing.
    The Sun card varied across every frame, and so did The Fool **after being
    scrolled into view from off-screen**, which is the half the visibility
    handoff exists for.

  Also still true in this build: `requestAudioFocus` appears **zero** times.

  One thing noticed and deliberately not chased: paging to the Journal does
  *not* release the plates' decoders, because the shell's pager keeps the
  Dashboard mounted and the plates never report themselves off-screen. It costs
  nothing that matters — the cap is still respected, which is the whole point of
  the budget — but it is the obvious next thing if decoders ever get tight.

  If you need to re-run this: the technique is worth more than the result.
  `eterRunningTests()` disables the video plugin outright, so the budget is
  unit-tested (`test/arcana_loop_budget_test.dart`) and the visibility half is
  not testable in the suite at all. Frame differencing plus the resource
  manager is the only way anyone has checked it.
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

## A second round on the phone, 1 August

Eight things came back from real use. Seven are done; the eighth needs a
sentence from the owner before it can be.

- **Dictation filed the same page twice.** `_save` read the draft, awaited the
  insert, and cleared the composer *after* — so any second caller inside that
  await saw the same words. There are four ways in: the recogniser reports
  `notListening` **and** `done`, push-to-talk saves on release, and opening
  History saves on the way out. The draft is claimed before the first await
  now, and handed back if the insert throws.
- **Typing overflowed the page by 28 px.** `_FittedProse` shrinks the day story
  to fit and stops at a 13 pt floor; with the keyboard up there is no room even
  at the floor. It scrolls inside its own box instead — nothing cut, page still
  does not scroll.
- **A footnote over nothing.** A dimension with no correlation answers with an
  empty object and the receipt was drawn whenever the column was non-null,
  opening on `n=null · null · coefficient null`. Drawn only when a field has
  content, and missing fields fall back per field.
- **The reveal arrived in fast batches.** Every sentence was forced into
  `durSentence`, which made the stagger a *remainder*: ten groups divided
  1200 ms and fired 75 ms apart. The stagger is the constant now (190 ms) and a
  sentence takes as long as its length asks, to a 4.2 s ceiling.
- **Birth dates nobody has.** `DateTime.parse` rolls over, so 31 February was
  accepted as 3 March and the chart cast for it. `birthDateProblem` refuses
  non-calendar dates, futures and anything past 130 years — and **the date of
  birth is editable in the Sanctum**, which it never was.
- **Recomposing is one control.** `REFRESH` and `COMPOSE NOW` are gone from the
  Dashboard. The Sanctum has `AGAIN` for the whole day — forcing past the
  context cache, because a person pressing a button has asked for something the
  automatic path is right to refuse — and a second `AGAIN` under the birth
  details for the chart's reading.
- **The first minute, in two halves.** It never fired: the gate reads intake
  through a `FutureBuilder` loaded once and never invalidated, so after
  onboarding it answers from the snapshot taken before it — and a phone
  carrying an earlier install already has the key set. Completing onboarding
  now discounts the stored answers for the session. Part one is the premise
  (no streaks, the three sources, absent-not-zero, where it stays, what it will
  not do); part two is `EterWalkthrough`, a scrim over the running shell with
  one real widget lit at a time.

  **Watched on the phone, 3 August, and part two was broken on its first
  stop.** Three faults, in the order they surfaced:

  1. **The caption overhung the hole.** The caption is white text with nothing
     behind it, legible exactly as far as the scrim reaches — and the scrim has
     the target punched out of it. Nothing checked that the caption fitted in
     what was left. On stop one, which lights the whole journal page, it did
     not: `DALEJ` and `POMIŃ` were drawn in white over the cream page, on top
     of the date and `HISTORIA`. The spotlight now gives up the ground the
     caption stands on — `WalkthroughScrim.lit`.
  2. **Then the controls were dark on dark.** Uncovered by fixing (1), and
     present all along underneath it. The eyebrow and the sentence set
     `Colors.white` themselves; the two `EterAction`s take their ink from the
     ambient theme, which during the day is the ink of the cream page. The
     caption is wrapped in `EterTheme.night()` now, because the scrim it is
     written on is always night whatever register the shell is in.
  3. **The five eyebrows disagreed about case** — `DZIENNIK`, `WGLĄD`,
     `DWOJE DRZWI`, then `Zacisze`. They borrow labels that exist for other
     reasons and four happen to be authored in caps. The eyebrow imposes its
     own case now rather than trusting the string.

  **A caution for whoever reads the next one of these:** a fourth fault was
  reported and was not real. The caption picks its side by which gap is
  bigger; that was written as "is the hole's centre in the top half", and the
  two look different but reduce to the same inequality. Writing the arithmetic
  down as `WalkthroughScrim.captionBelow` disproved it, and a test now pins the
  two formulations together so nobody rediscovers it. Choosing the roomier side
  was never the bug — **no choice of side helps when the target is large enough
  that neither gap fits**, which is why (1) is the fix.

  Three tests in `first_run_test.dart` hold it. All five stops were then walked
  on the device and the walkthrough completed into the Dashboard.

**The astrogram · done, 3 August.** The owner reported it "doesn't look right"
for 25/07/1993 12:30, with the data verified correct — Sun 2.5° Leo, Moon 23°
Libra, Mercury 18° Cancer R, Uranus 19.7° and Neptune 19.4° Capricorn, Pluto
22.7° Scorpio, ASC 22° Libra, MC 29.5° Cancer — and the geometry verified too.
Rendering the specimen sheet found four faults, of which the standing hypothesis
had named one:

- **The eight ordinary cusps were painted in the same weight as the sign ring's
  twenty-four 10° graduations.** This, not the radial extent, is why the houses
  did not read as houses.
- The four angular cusps read as unexplained heavy dashes.
- The cusps shared the body glyphs' annulus, so collision was structural — a
  cusp through Saturn on the Reykjavík specimen, through the Sun on the owner's.
- Nothing named which house was which.

The houses now have an annulus of their own between the aspect circle and
`houseRing`, closed at both edges, with all twelve numbered at the midpoint of
the arc they occupy. `DECISIONS.md` 3 August carries what it was chosen over and
what it costs. The aspect figure gives up its outer fifth **only on charts that
draw houses**; without a birth time it keeps the radius it always had, which is
why the Vessel goldens did not move by a pixel.

Two tests hold it: the house band belongs to the houses alone (no body glyph may
reach into it, and the numerals stay inside both edges), and every house is
numbered off its own midpoint at four latitudes including the equator and the
southern hemisphere. `chart-wheel-houses-{day,night}-340.png` were re-recorded;
the failure was read first and was the intended change, with no overflow.

Render it yourself with `test/manual/chart_wheel_specimen_test.dart`, which
carries that birth as its first specimen.

---

## The restructure of 3–4 August, and what came of it

Six things were asked for across the session: guidance at twice the size; the
disclosures gone and the depths row pinned; the Vessel rebuilt in six parts;
Positions kept but made specific to the chart; nutrition moved and
macronutrients tracked; and carbohydrate counted without being advised on.

**All six are done**, the Vessel's surface last, on 4 August. Every commit
green. None of it has been read against the live model — that is item 2 at the
top of this document and it is the largest remaining risk.

**Done — guidance at twice the size.** `displayMedium` 34 → 68, leading scaled
with it because the theme stores `height` as a *ratio* and doubling the size
alone would have set the lines solid. At 390 dp the passage commands the screen
and still fits; at 320 dp with 200 % text it comes down to a few words a line
and scrolls, which is honest at that extreme and is not an overflow — the
captures throw on overflow and none did.

**Done — no disclosures, no closes, the depths row always present.**
`LOOK DEEPER` and every section `CLOSE` are gone, including the Vessel's own
`READ DEEPER`. At night one depth is open already: `EterRegister.night` is
exactly "immersive, or balanced after sunset", since grounded resolves to day
at every hour, so the rule is one comparison rather than a mode test and a
clock test that could disagree.

The row is held **outside** the scroll, under the destination rail. It was
built first as a pinned `SliverPersistentHeader` and that failed twice over: a
pinned header must state its height before layout, and this row wraps to two
lines at 390 dp and three at 200 % text — the first guess overflowed a plain
phone by 37 px. Measuring it fixed the height and not the second problem, which
is that a header is only built while its sliver is in range, so once guidance
doubled and filled the screen the row stopped existing until it had been
scrolled to. **This cost guidance the first glance**; the three depths sit above
it now. That is a real change to the opening moment and the owner should look at
it.

**Done — the Vessel's machinery, in five parts.** `VesselReadingPart` splits the
reading into houses, aspects, chart synopsis, the figure place by place, and the
figure's synopsis. All five go out under the **existing `vesselReadings` call
name** — the worker checks the name and nothing else, so no redeploy — and each
caches under its own reserved key, so a part that fails is retried alone. The
chart synopsis keeps `configuration`, the key the single-call reading already
used, so charts already read are not re-composed or re-billed.

The twelve houses take the card of the sign on the cusp
(`core/arcana/house_cards.dart`), the owner's choice over the cusp ruler and
over house-number-to-arcana — the last of which gives every person alive the
same twelve cards. House 1 *is* the Ascendant and the model is told so, because
the Ascendant's card is shown above the list and would otherwise look printed
twice. `houseOf` walks the arcs rather than dividing the circle by twelve, which
matters away from the equator where a quadrant can be four times another.

`AetherSafetyPolicy.validateReading` was added for these: `validateGuidance`
refuses anything past 3000 characters, which is right for a day's reading and
wrong for a synopsis the owner asked to be **the longest part of the surface**.
Every rule that is about safety still applies; only the brevity rule is dropped.

**Done — Positions reads the sky against the chart.** The menu stays; it was
writing horoscope. It had the contacts and nothing about the chart being
contacted, so it could name a transit and not say what it landed on. Two things
it never had: **retrograde motion**, computed per position all along and thrown
away before the request was built — the one fact a person is most likely to
already know about today's sky was the one it could not mention — and the natal
chart itself. `core/vessel/positions_natal.dart` supplies placements with their
houses, the twelve houses, and **which of this person's houses today's bodies
are crossing**, which is the join that was missing. Houses are offered only when
the angles are real, because "in your house of work" derived from a noon guess
would be cached and wrong.

**Done — the protein and fat floors** (`core/health/macro_targets.dart`).
1.7 g/kg and 0.5 g/kg, in whole grams from the person's own weight, advised only
where there is strength work. A shortfall is only ever found on a *recorded*
day, and a measure left blank cannot be short. Leaning needs two short recorded
days: one is a Tuesday.

**Done — guidance reads what was eaten.** The request now carries an `intake`
block and, where there is resistance training in the window, `macroFloors`.
`AetherIntakeContext` and `AetherMacroFloors` are in the contract, the assembler
fills them from **confirmed rows only** — an unconfirmed estimate is a guess
nobody has agreed to, and the brief forbids it counting toward any total — and
the prompt says what the floors are *not*: a floor to reach, never a diet, never
a limit, never a reason to eat less of anything else, and never the opening of a
synthesis.

Absent-not-zero is enforced in three places, not one: a day with nothing logged
is dropped from the payload rather than sent as a row of nulls the model would
read as a day of nothing eaten; a macronutrient no row carried is not a key at
all; and a shortfall is only ever counted on a recorded day. Intake is in the
context fingerprint, so confirming a meal recomposes the day instead of being
noticed tomorrow.

**Done — nutrition, the whole of it.** Confirming a derived meal happens in the
**Journal**, under the page it came from: by the time somebody is looking at a
balance they have left the page, and what they can still remember is what was on
the plate. Only unconfirmed meals prompt. Correcting the figures stays in the
Body, which now shows and edits protein, carbohydrate and fat beside the
calories, and can delete a meal in two taps. One row serves both surfaces, so
they cannot drift — deleting from the Body removes it from the page, and
reverting the page takes its meals with it, both pinned by tests.

**Carbohydrate is counted and not advised on.** It has no floor and no target,
and there is no version of "eat fewer carbohydrates" in this product. One
exception, computed on the device rather than left to the model: when a recorded
day was very nearly all carbohydrate *and* protein came in under its floor, the
advice may suggest trading some of one for the other — as a sentence about the
missing protein, not about the carbohydrate being wrong. Dominance is measured
by **energy, not weight**, because a gram of fat is not a gram of anything else.

Blank means not recorded, everywhere: an empty field saves as null rather than
zero, a meal nobody broke down shows no macro line, and a day where only
carbohydrate was written down is a day nobody described rather than a day of
pure carbohydrate.

### The Vessel's surface · *done, 4 August*

The six-part order the owner asked for —

1. the chart wheel, led by the Sun, Moon and Ascendant
2. a card and a passage for each of the twelve houses
3. what the angles say
4. the full chart synopsis, the longest part
5. the figure, place by place
6. the figure's synopsis

— is what `vessel_section.dart` renders. `composePart` returns the stored JSON
and `VesselKeyedPassage.decode` / `VesselSynopsis.decode` read it; the request
already carried `houses` and `aspects`. `test/vessel_parts_test.dart` covers
the composer half and *the Vessel is read in six parts, in the owner's order*
in `shell_test.dart` covers the surface — it checks where each heading lands on
the page rather than the order finders happen to return, because a `Column` will
report its children in order no matter what order they were built in.

Six strings were added for the headings and the houses. `TRANSLATIONS.md` is
regenerated and now pairs **480**; read the Polish once more if you like, and
note `houseOccupants` deliberately has no verb — *stoi* and *stoją* depend on
how many bodies are in the house, and one chart has both.

**Read the section above under "Pick up here" before changing this surface.**
The once-per-opening guard and the Sun/Moon/Ascendant lift are both the kind of
thing that looks like an omission until you know why.

**Done, 4 August:** `test/fixtures/live/` is re-recorded at prompt **v10** and
all four new parts have been read against the live model. What that found is
item 2 at the top of this document, and it is worth reading before writing any
prompt here — every fault was invisible to every parser.

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
sentence passes everything. **And it is not only the strings** — the model's own
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
**The English lettering on the card art is deliberate** — asked about on
3 August, and the owner's answer is that it stays. Do not "fix" it.

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
