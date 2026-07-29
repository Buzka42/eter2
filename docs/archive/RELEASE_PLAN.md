# Eter · what stands between here and a release

28 July 2026. Ordered so nothing waits on something below it.

The honest position: **the product is feature-complete and the intelligence
works.** All five model calls compose and parse against a live provider, 400
tests pass, `flutter analyze` is clean, and the release APK is 83 MB against
Play's 150 MB ceiling. Accounts, the cloud mirror, the arcana figure, Placidus
houses and crash reporting have all landed since this file was written.

What remains is one server the owner must deploy, a handful of store accounts,
and one art commission.

---

## 0. Blockers — a release cannot happen without these

### 0.1 The server behind the AI transport

**The client half is built.** `core/ai/transport.dart` posts the bounded
`{system, user, responseSchema}` triple to one endpoint and returns the raw
string; five thin adapters cover guidance, the Journal's day story, journal
interpretation, Vessel readings and Positions; all five providers in
`main.dart` resolve through it. Nothing parses in the transport and nothing
falls back. A build compiled without `ETER_AI_ENDPOINT` has no transport, says
so on every surface, and writes nothing — still a shippable configuration.

**What is left is the endpoint itself**, which needs an account and a
credential and therefore cannot come from this repo. Its exact wire contract —
what arrives, what must come back, and the four things the server must not do —
is [`AI_ENDPOINT.md`](AI_ENDPOINT.md).

**The client must never hold a model key.** This is the one constraint the
steering brief states twice, and it is why the endpoint exists at all.

### 0.2 Recording weight, activity and strength — done

Every record now has a route in:

| Record | Route in |
|---|---|
| Food, mood, sleep, meditation | Journal interpretation ✓ |
| Weight | Journal interpretation ✓, or a health hub |
| Activity | Journal interpretation ✓, or a health hub |
| Strength | Journal interpretation ✓ |

The shapes are in `classification_contract.dart`, each carrying the rule that
keeps it honest: a weight is read and never estimated, an activity carries the
same reviewable estimate a meal does, and lifted work carries reps and load but
no energy — that is derived on the device from body weight, and any other
number would disagree with the Register.

`journal/body_commit.dart` commits through `ManualWeightService`,
`ManualActivityService` and `StrengthWorkoutService` rather than around them,
so a run written in the Journal lands where a run entered by hand lands.

### 0.3 Owner-only items

Upload keystore, Play and Apple accounts, a public privacy-policy URL, the
health-data declarations. All in `RELEASE.md` §2. None can be done from this
repo, and the keystore in particular should be created early — losing it later
means losing the ability to update the listing.

---

## 1. Should ship in 1.0

1. ~~**Read deeper for every position.**~~ Done, in two halves.

   *Houses.* Placidus, computed properly and verified against the properties a
   quadrant system must have — angles on cusps one, four, seven and ten,
   opposites exactly opposed, spans summing to a turn, unequal at latitude and
   nearly even at the equator. Inside the polar circles the system genuinely
   has no answer, so the chart falls back to equal houses and says which one it
   used in `houseSystem`.

   *The figure.* `core/arcana/matrix.dart` reads a birth date as seven arcana:
   the given, the inherited, the era, the turning, the meeting, the long thread
   and the centre. **The construction is Eter's own and is written down in that
   file** — it is arithmetic over the twenty-two cards, arranged the way this
   product already thinks, and it reproduces no published system's diagram or
   position meanings. The centre resolves to the same card the Life Path
   arrives at, so the figure explains the card the Vessel already shows rather
   than repeating it.

   Its positions are ordinary `VesselReadingPosition`s, so they compose, cache
   and retire through the machinery that already existed. The matrix needed no
   machinery of its own.

2. ~~**A first-run integration test.**~~ Done: `test/first_run_test.dart` walks
   an empty database through intake, tutorial, the first day and the first
   entry, plus the two states either side of it.
3. ~~**Crash reporting, or a recorded decision not to have it.**~~ Decided:
   Eter reports crashes, and only with permission. Off on install, off after a
   restore, revocable, and structurally unable to carry a journal page or a
   measurement. See `core/diagnostics/crash_reporter.dart`.
4. **New card backs.** `ART_COMMISSIONS.md` Commission 4. The current pair was
   authored at the wrong proportion and cropped into shape. The only item here
   that is art rather than code.

## 2. Test coverage — the four that mattered are done

Fourteen core modules had no test naming them. Most are widgets the goldens
cover indirectly; four carried real logic, and those four are now covered:

| Module | Covered by | What is verified |
|---|---|---|
| `symbolic/transits.dart` | `test/transits_test.dart` | Every contact's aspect matches the separation it was found at, orbs stay inside the six/four table, the angles are natal points only, one aspect per pair, applying means tomorrow is tighter, contacts sort by weight, the day is read at noon so the hour of asking does not move it, and the provider context carries no birth inputs or coordinates. |
| `journal/day_story.dart` | `test/journal_day_story_test.dart` | Both consents are required and neither absence reaches a provider; excluded and empty entries are not part of the day; the fingerprint suppresses recomposition and an edit or a later exclusion forces one; the parser's bounds — story length, unknown digest fields, at most three notable phrases — and that a rejected response writes nothing. |
| `vessel/positions_composer.dart` | `test/positions_composer_test.dart` | Reading never calls a provider; the cache is keyed on day *and* chart; a corrupt stored passage degrades rather than crashes; no transport and no consent each refuse without writing; the parser's bounds; and the guidance note passes the same safety gate guidance does, including grounded mode's refusal of fated phrasing. |
| `health/daily_activity_summary.dart` | `test/daily_activity_summary_test.dart` | No profile, no height and no minutes each produce no totals; sums and session counts land on the right local day; a finished day accrues 1440 minutes and today only what has elapsed; the Katch-McArdle branch is taken when body fat is known and differs measurably from Mifflin–St Jeor; age is counted at the end of the window; and a lowered rebuild marks the day recalibrated. |

Still worth adding: a **prompt fixture set** (`AI_FLOW.md` §5.5) — recorded
good, malformed, unsafe and empty responses for each of the five calls, so the
parsers are tested against real model output rather than hand-written JSON.

## 3. Deferred with intent

Not gaps; decisions. Recorded so they are not rediscovered as bugs.

- ~~**Cloud continuity.**~~ Built. Accounts are optional on top of local-first:
  `core/sync/` mirrors the measured record, journal prose only under its own
  separate consent, and a restore refuses on a device that already has
  history. Local-only remains a legitimate configuration and the default.
- **Live BLE sessions and vendor OAuth.** The phone hub covers the same ground
  less precisely.
- **Background health refresh.** Health Connect has no push and the Flutter
  `health` package does not expose HealthKit's background delivery; refresh on
  resume is the honest ceiling without native work.
- **Notifications.** Nothing exists. Whether Eter ever speaks first is an open
  product question, not an unbuilt feature.
- **Entitlements.** No free/paid split exists. Fine while 1.0 is free; the
  brief's warning — one resolver, read at section level, never inside a
  control — is the thing to honour when it arrives.
- **Localisation.** Single hardcoded locale. Cheap now, expensive after the
  copy grows, and the copy *is* the product here.

---

## 4. The order I would take it in

1. Keystore and store accounts (0.3) — slow, external, start now.
2. Server boundary and one wired contract, guidance first (0.1).
3. ~~The four missing tests (§2)~~ — done against fakes, which is where the
   consent gates, caches and parser bounds actually live. The prompt fixture
   set is what still wants a real transport.
4. The remaining four contracts.
5. Weight/activity/strength shapes (0.2), which 0.1 unblocks.
6. Card backs (1.2) and the first-run test (1.3).
7. Read deeper's full expansion (1.1) — the biggest, and the most safely
   deferred to 1.1 if the release is time-boxed.

Steps 1–5 are a shippable 1.0: a private journal and body log with working
intelligence, honest about everything it cannot do.
