# Eter · UI audit

Pass 2 of three, 28 July 2026. Every surface and state walked, captured and
read as a composition rather than a viewport.

The material: `flutter test test_capture --update-goldens`
writes 46 captures to `artifacts/ui/` (gitignored), and
`tool/build_contact_sheets.py` assembles them into reviewable sheets. The
inventory is not a golden suite — it asserts nothing. It exists so the
interface can be looked at whole, including the states a golden would never
bother to pin: an empty first day, a half-open editor, a form at 200% type.

Two defects were found by building it and are already fixed:

- **The onboarding wordmark was not in the product's typeface.** It used
  `headlineMedium` — the single `TextTheme` slot `EterTheme` does not define —
  so the first ETER a user ever sees rendered in the platform default face.
  Now the shell's own lockup.
- **`STRENGTH / RECORD` overflowed at 320 dp and 200% type** by 0.9 px. The
  golden matrix covers the *collapsed* dashboard at that size; nothing covered
  the expanded Body, which is where the longest eyebrow lives.

What follows is what the captures showed, and what the product owner decided
on 28 July 2026. **All eight were answered and all eight are done**; each
section keeps the original finding above the resolution, so the reasoning
survives the change.

---

## A. The Vessel's card is a postage stamp

`whole-vessel-day`, `whole-vessel-night`

The daily Arcana renders at **92 dp wide**, top-left, with three lines of prose
crowded to its right. The commissioned deck is the most expensive art in the
product and the brief treats the Arcana as a signature element; at this size
the image is decoration beside the text rather than the thing the section is
about.

It is also the reason the deck was shipping at 1030 px for a 92 dp surface.

**Proposed:** give the card real presence — either ~150 dp with the prose
below it rather than beside it, or a full-width plate with the title beneath.
In the day register it additionally needs help: light card art on parchment at
92 dp is nearly invisible.

**Related, from Pass 1:** `AnimatedArcanaCard` exists and nothing uses it. If
the card gets presence, the animated version is suddenly worth its 5.8 MB — or
it should go.

**Resolved.** The card leads at 168 dp, centred, with the prose beneath it
rather than crowded to its right, and every position under `READ DEEPER` is now
headed by its own card at 140 dp. Cards animate in the night register through
the shipped loops and stay still in day — the same rule the shell follows —
with the static art always drawn underneath, so a missing or slow loop is
invisible. `EterArcanaPlate` in `vessel_section.dart` is the one place this is
decided.

That also answers Pass 1 §0.4: the 23 Arcana loops are reachable now, on the
surface they were commissioned for.

## B. Body says WEIGHT twice

`whole-body-day`

The expanded Body has a `WEIGHT` eyebrow over the trend chart, and a second
`WEIGHT / RECORD` line further down. Two headings, one subject, separated by
the activity-by-time instrument.

**Proposed:** one weight line — the trend with `RECORD` on its own heading row,
the way `FOOD` already carries `ADD MEAL`.

**Resolved.** One `WEIGHT` heading over the trend. The second came from the
weight capture line, which is gone with the rest of capture (see D).

## C. Capture and reading are interleaved

`whole-body-day`

Reading order today: conclusion → recovery signals → balance → **capture**
(activity, strength, food) → **reading** (RHR, HRV, sleep, sleep history,
weight trend, activity by time) → **capture** (weight) → reading (food notes).

Capture appears, disappears and returns. The section is legible because each
line is quiet, not because the order means anything.

**Proposed:** one ordering principle, stated. Either *conclusion → instruments
→ everything you can add*, or the reverse. Splitting the difference is what
produces the current shuffle.

**Resolved, by removing one side of the interleave.** The Body is now
conclusion → today's instruments → history → food notes, and nothing on it asks
the user for anything.

## D. Four equal actions in the strength composer

`whole-capture-strength`

Open, the tracker offers `ADD SET`, `STRAIGHT SETS`, `ADD EXERCISE` and
`KEEP WORKOUT` as a 2×2 of letterspaced caps at near-identical weight. The
committing action is distinguished only by its doubled rule, which is correct
per the control system and still quiet against three neighbours.

Also: the composer never says what it is about to record. The energy estimate
and duration are derived at commit and appear only afterwards, as a message.

**Proposed:** move `STRAIGHT SETS` (a per-exercise property) beside the
exercise name rather than into the action row, and show the derived line —
"about 24 min · 180 kcal" — above `KEEP WORKOUT`, so the user sees what the
MET fallback concluded before agreeing to it.

**Resolved by a product rule, not a layout change.** *The Dashboard reads; the
Journal writes.* Every capture control left the Body — add activity, add meal,
record strength, record weight. Input outside the Sanctum happens by writing a
page and letting interpretation derive from it.

The write services are intact and still tested; only the surface moved. The
unfinished half is recorded in `ROADMAP.md` §1a: the classification contract
covers food and lifestyle, so weight, activity and strength currently have no
route in at all until it grows.

## E. The sleep rail reads as an unlabelled slider

`whole-body-day`

`LAST NIGHT` renders a thin horizontal rail with a dark segment, then a bare
row of `LIGHT 237m  DEEP 78m  REM 115m  AWAKE 18m`. The rail carries the
proportions and the numbers carry the values, but nothing ties the two
together — the rail has no key, and at a glance it looks like a control.

**Proposed:** either tie the numbers to the rail (each figure under its own
segment) or drop the rail and let the numbers stand, which the brief's
"instrument, not chart junk" instinct would probably prefer.

**Resolved.** The rail keeps the proportions; beneath it each figure carries a
short rule struck in its own stage's weight, so the two read as one instrument.
Positional alignment was tried first and cannot work — awake against a whole
night gives a column too narrow to hold the word.

## F. Onboarding step 2 buries its error and centres its choices

`onboarding-3`, `whole-onboarding-2`

Two things:

1. `BODY CONTEXT` presents Female / Male / Another as **centred** labels in a
   left-aligned form, with the current choice marked only by an underline. It
   reads as three captions, not a choice.
2. The birth-date validation message appears at the very bottom of the step,
   below the optional birth-place field — several fields away from the input it
   is about.

**Proposed:** left-align the body-context choices into the form's own rhythm,
and put each validation message under the field that raised it.

**Resolved.** Body-context choices are left-aligned into the form's rhythm, and
the birth-date message sits directly under the birth-date field.

## G. The first day is very quiet

`empty-dashboard-day`, `empty-body-day`, `empty-journal-day`

A new user with a profile and no history sees: "Today's guidance has not been
composed yet", one `COMPOSE GUIDANCE` action, and `LOOK DEEPER`. That is honest
and it is beautiful, and it is also the moment the product is most likely to be
abandoned — there is nothing to do that produces a result, and the one action
offered cannot work until a provider exists (Pass 1, §1).

The empty Body is better: it names each absence precisely and offers three
capture routes.

**Proposed:** nothing structural — but this is the screen to revisit once the
AI transport exists, and the one place a single line of orientation ("Add a
meal or a walk, or write a page — guidance builds from what you record") would
earn its keep.

**Resolved.** The day's first look at the Dashboard composes guidance on its
own, once per local day, and only when a transport exists. The explicit action
is now a quiet `COMPOSE NOW` retry rather than the way in, and it disappears
while composing — the sentence above says what is happening.

## H. What holds up

Said plainly, because an audit that only lists faults is not an audit.

- Day and night are genuinely two registers, not a palette swap. The night
  astrolabe and plate carry weight the day composition does not need.
- The line rhythm — eyebrow left, action right, hairline between — survives
  every surface it was applied to, including three new ones.
- Every empty state names what is missing rather than rendering a zero. The
  Body at first run is a small masterclass in this.
- The Sanctum reads as a document, not a settings screen, and the consent
  language is exact.
- 320 dp at 200% type degrades gracefully everywhere now that the one overflow
  is gone.

## I. The balance, redrawn

Not a finding — a request. The `EngravedBalance` read as a diagram: a thin
beam, small pans, a stick on a triangle. It is now an instrument: a slim
tapered column on a stepped plinth, a graduated scale with a pointer that
swings with the beam below the pivot where a beam balance actually carries it,
chains with struck links instead of two straight hangers, and pans with rim,
body and depth. Still one colour and still code-native, so it holds in both
registers by construction and costs nothing at any size.
