# Eter · product decisions

Decisions the product owner has made that the code alone cannot explain, newest
first. Each says what was chosen, what it was chosen *over*, and what it costs —
because the reasoning is the part that gets lost, and a decision whose reasoning
is gone gets relitigated every few months.

This file is not a changelog. It records choices, not work.

---

## 3 August 2026

### The houses get a band of their own, and numerals

The astrogram was reported as not looking right for a chart whose data and
geometry were both verified correct. Rendering the specimen sheet showed four
faults rather than the one that had been hypothesised:

- The eight ordinary cusps were painted in `faint`, **the same weight as the
  sign ring's twenty-four 10° graduation ticks**. That, not the radial extent,
  is why the houses did not read as houses: they were the twenty-fifth through
  thirty-second tick marks.
- The four angular cusps read as unexplained heavy dashes.
- The cusps shared an annulus with the body glyphs, so collision was structural
  rather than bad luck — a cusp through Saturn on the Reykjavík specimen, and
  through the Sun on the reporting chart.
- Nothing said which house was which.

**Chosen: the houses get an annulus to themselves**, between the aspect circle
and 0.62 of the outer radius, closed by a circle at each edge so it reads as a
band. All twelve cusps run its full width, the angles distinguished by weight;
the ordinary eight move up to `thin` so they can never again be confused with a
graduation. All twelve houses carry a numeral at the middle of the arc they
actually occupy.

Chosen **over** two cheaper options. Fixing only the weights and adding numerals
in the existing band would have left the glyph collisions, which are the part
that reads as a bug rather than as a plain chart. Alternating shaded sectors
would have been the most legible of the three and was refused because this
surface's stated rule is no fill and one colour, and a decision that costs a
rule is more expensive than it looks.

**This is not the attempt that failed.** That one ran the cusps to radius zero
and laid two diameters through the aspect figure.

**What it costs:** the aspect figure gives up its outer fifth, 0.62 → 0.50.
Charts drawn *without* houses — anyone who has not given a birth time — keep the
larger figure, because there is nothing to put in the band and a smaller figure
inside a ring of empty paper would be a cost paid for nothing.

**Numerals over no numerals, and over numbering the angular four only.** An
unnumbered division is precisely the unexplained symbol non-negotiable 7
forbids, and the wheel is the one place a person could otherwise never learn
which house a body is in.

---

## 1 August 2026

### The Vessel reads the chart, and asks for nothing

The Life Path and the astrogram were two disclosures with a compose button
each. They are now **one menu**, the reading arrives on its own, and there is
no control anywhere that asks for it.

**What changed in the writing.** The call wrote one passage per position —
eighteen on a full chart. Each was correct; none had looked at the chart. The
owner's word was "generalistic", and the cause is structural: a passage that
can only see one placement has nothing to relate it to. It now returns three
to five **movements**, each about how several placements stand to each other,
naming them as evidence rather than as subjects.

**Chosen over** one single passage (eighteen placements compressed into 1800
characters returns to the generic) and over keeping the per-card passages
underneath a synthesis (which is what "rather than treating each card as
individual" ruled out).

**Nothing is composed without a birth time**, approximate or exact. The angles
are most of what makes a configuration particular, and the reading is cached
for the life of the chart — so a chart cast at noon would be read once, wrongly,
and kept. Somebody with no birth time still gets the wheel, the cards and every
computed placement; only the writing waits.

**The cost, and the mitigation.** Composing on save with no button means a save
that fails has nothing to retry it. So the Vessel attempts it silently when
opened if the reading is still missing — the same automatic behaviour, not a
new affordance. Without that, one offline save would leave the reading
permanently unwritten.

### Guidance leans on the sky at night, and is given something to lean on

In immersive, and in balanced once the sun is down, the symbolic share rises
(to 60% and 40%) and the measured share falls.

**The stated proportions were not the problem.** Immersive already said 40%
symbolic and still read as health reporting. The symbolic half arrived as a
*single sentence* while the measured half arrived as a table — a model cannot
weight what it was not given. So the payload changed with the numbers: today's
Positions passage now travels in full rather than as its one-sentence note. It
was already written and already validated by the Positions call's own safety
policy, so nothing new is composed to carry it.

**Grounded never leans.** That register exists to be plain.

### The Sanctum orders by frequency

The band at the top holds what people actually change — opening page, language,
register, and the evening invitation — and everything once-ever (birth context,
the consents, export, deletion, connections) sinks below the hairline.

**Chosen over** grouping by consequence, which read better as philosophy but
put the register three screens down, and over collapsible sections, which would
have introduced a disclosure idiom the product uses nowhere else. The evening
invitation moved into the top band *although it is stored as a consent*: it is
the one consent people revisit with the seasons.

**The cost:** the "what leaves this device" story is no longer a single
contiguous block — the invitation sits apart from its siblings. The copy on the
toggle still says what it grants.

### The guidance depths slide sideways, by tap

`LOOK DEEPER` now opens a persistent row — guidance · body · vessel, each with
a drawn glyph — and the chosen depth slides in horizontally beneath it while
the day's guidance stays put. Switching depths never scrolls you back to the
top, which was the whole complaint.

**Chosen over** the in-place vertical expansion (the "shell game"), and over a
swipeable nested pager: the shell's pager already owns the horizontal *gesture*
for journal ↔ dashboard, so the depths borrow only the horizontal *motion*. A
swipe that meant "next depth" here and "other surface" a centimetre higher
would be one gesture with two meanings.

**The glyphs are placeholders** in the engraved language (a risen point, a
graduated rule, a bowl), drawn so generated artwork can replace the painters
without touching the row. The text label stays beside each mark —
non-negotiable 7 forbids an unexplained symbol, and nothing has taught these
yet.

### The chart's own writing is not a seventh call

**Superseded the same day on the shape, upheld on the substance** — see "The
Vessel reads the chart" above. It is still one call, still the same composer,
cache and table; what changed is that it answers with movements about the whole
configuration rather than a passage per body, and the separate `THE CHART`
menu is gone. The reasoning below is why it was never a seventh contract, and
that part still holds.

The astrogram explanation behind `THE CHART` composed one passage per
remaining body through the existing `VesselReadingComposer`, into the existing
`VesselReadings` table, under the existing `inputHash`.

**Chosen over** a dedicated `astrogram` call returning one long essay. The
per-position shape means a chart is still paid for **once** — the cache key
already keys on the birth inputs, so re-opening the panel costs nothing and a
reader who composes the named positions today and the planets next week is
billed for exactly the passages they asked for. A single essay would also have
been a seventh contract to parse, version and safety-check.

**The cost:** seven passages read as seven passages, not as one account of a
chart. If that turns out to be the wrong register, the fix is prompt work
inside the same call rather than a new one.

### Birth-place suggestions answer in the geocoder's tongue

The autocomplete asks the device geocoder once, in the device locale, and shows
whatever spelling comes back; either "Warsaw" or "Warszawa" is accepted as
typed.

**Chosen over** resolving in both app languages and merging, which would have
cost two lookups per debounced keystroke to translate a name the person did not
type. The cost: a Polish interface can show an English suggestion on an
English-locale phone. The typed text still resolves on save either way, so the
suggestion list is a convenience, never a gate.

---

## 30 July 2026

### Navigation: extension, not a menu

New material extends something that already exists rather than becoming a
destination. The Long View is the Journal's date axis pulled back — day, week,
month, year, through the page-turn affordance the Journal already owns. The Letter
arrives *as* a Journal page. The Correspondence is one extra line beneath today's
guidance, not a screen.

**Chosen over** a hamburger drawer, which was the obvious answer and the wrong
one: it would have been a fourth navigation idiom in a product that has kept to
one, and a drawer listing features frames them as separate applications — the
exact thing `STEERING_BRIEF.md` says Eter must never feel like.

**The cost, and the mitigation.** Extension is discoverable only if you already
use the thing being extended. So the Sanctum additionally carries named entries
for Long View, Letters and Correspondence — the one place that names everything,
satisfying `UI_BRIEF.md` non-negotiable 7 without putting a menu at the front of
the app. Practices, when they arrive, open from the guidance sentence that
recommends them rather than from a list.

**Note on a stale brief.** `UI_BRIEF.md` §5 said the ETER mark *is* the Sanctum
button, and an audit pass repeated that as a defect. It is not: the shell has had
a named `SANCTUM` word at the foot of the screen for some time, and the mark is
ornament that stays tappable for anyone who learned it. The brief was behind the
code. Corrected there.

### Pricing: $5/month, said plainly to be a launch price

30-day free trial, then **$4.99/month or $39.99/year**, and **20 PLN/month in
Poland** — set as a regional price, not a conversion, which would have been about
36. Polish is one of Eter's two languages and its cheapest acquisition market, and
Polish subscription apps land at 19–29; pricing it at the dollar conversion would
discard the one distribution advantage Eter starts with.

The paywall says in words that $5 is a launch price and will rise.
**No grandfathering** — early subscribers move to the new price rather than
keeping the old one forever.

**Trial length was 14 days and is 30, and the code decided that.** Eter's
differentiator is a learned pattern about your own body, and
`statistics.dart`'s `minimumPairs = 21` means the first one cannot exist before day
21. The recall window that lets guidance say "the third short night this week"
only fills at day 14. A 14-day trial therefore ended one week before the product
became the thing it is sold as, and asked for money on a promise. Thirty days
crosses day 21, so the decision to pay is made by someone who has read a true
sentence about themselves.

**Counted from first launch, stored locally. No clock defence** — moving the
device clock to extend a trial is accepted as a fringe case not worth engineering
against. The commoner hole is a reinstall, which resets a local trial; both stores
track introductory-offer eligibility per account, so the store's own mechanism is
the real per-person gate once billing lands.

**One thing is not fully in our hands:** Apple requires existing subscribers to
actively consent to a price increase above certain thresholds, or the subscription
lapses. So some early users will effectively grandfather themselves by ignoring
the prompt, and others will churn at the raise. Saying "launch price" up front is
what makes that honest rather than a surprise.

**Free stays genuinely good.** Journal, dictation, the local health record, the
Body charts, the deterministic Vessel and export all work with no network and no
model. Gate the intelligence, never the record — for a privacy-positioned product
that is how the right to charge is earned.

### BLE straps arrive with breathwork, not before

The schema (`LiveSessions`, `RememberedSensors`) stays, empty, rather than being
deleted as dead weight.

**Why it is not redundant**, which was the question: Health Connect and HealthKit
give you *recorded* data and a pre-computed overnight HRV. A BLE strap gives a
live stream and **raw RR intervals** — beat-to-beat timing. Coherent breathing at
about six breaths a minute raises HRV measurably within 60–90 seconds, and you can
only *show* someone that with RR intervals as they happen. That is the difference
between "we logged eight minutes" and "here is what those eight minutes did to
you", and it is the whole reason breathwork would be more than a timer.

`LiveSessions.hrSeriesJson` is already the right shape for that series and
`RememberedSensors` for "your strap", so deleting them would mean re-adding them.

### On-device interpretation: dropped

Running `journalInterpretation` locally on Gemini Nano or Apple Foundation Models
was proposed as the strongest privacy position available — "your journal never
leaves this phone" *and* working intelligence.

**Dropped in favour of a self-hosted model later.** If Eter launches, the owner
intends to run a model that can be trained to give better guidance, which is a
different and larger bet than shrinking one call onto the handset.

### Eter may speak first, once

One quiet local notification in the evening, inviting a page. **Off by default.**
Nothing else: no morning reading, no streak nudge, no re-engagement.

This closes an open question that `archive/ROADMAP.md` §2.4 and
`archive/RELEASE_PLAN.md` §3 both left undecided. Worth scheduling on the real
sunset the register already computes rather than a clock time, so the invitation
arrives with the night register instead of arbitrarily.

### Descoped for now

Vendor integrations (Garmin, Polar, Fitbit, Oura) and Sign in with Apple — the
latter blocked on a paid Apple membership in any case. `archive/11-wearable-integrations.md`
holds the per-vendor research, including that the Garmin Health API needs
developer-program approval that takes weeks, which is the reason to start it early
whenever it starts.

Also not built: "Why did Aether suggest this?", and meditation/breathwork
*guidance* as opposed to logging.
