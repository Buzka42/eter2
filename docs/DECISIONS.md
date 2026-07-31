# Eter · product decisions

Decisions the product owner has made that the code alone cannot explain, newest
first. Each says what was chosen, what it was chosen *over*, and what it costs —
because the reasoning is the part that gets lost, and a decision whose reasoning
is gone gets relitigated every few months.

This file is not a changelog. It records choices, not work.

---

## 1 August 2026

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

The astrogram explanation behind `THE CHART` composes one passage per
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
