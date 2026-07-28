# Eter · what stands between here and a release

28 July 2026. Ordered so nothing waits on something below it.

The honest position: **the local product is finished and the intelligence is
inert.** Every surface works, 209 tests pass, `flutter analyze` is clean, and
the release bundle is 81 MB against Play's 150 MB ceiling. What is missing is
not polish. It is the five model calls the product is shaped around, and a
handful of things that only became gaps *because* the shape changed.

---

## 0. Blockers — a release cannot happen without these

### 0.1 The AI transport, and the server behind it

Five calls exist as validated, consent-gated contracts with **no provider**:
guidance, the Journal's day story, journal interpretation, Vessel readings, and
Positions. Every one fails honestly today and writes nothing.

`AI_FLOW.md` §6 is the wiring order. In short: an owner-controlled endpoint
that authenticates the caller, holds the credential and forwards
`{system, user, responseSchema}` unchanged; three thin client implementations
that return the raw string without parsing; providers overridden in `main.dart`.

**The client must never hold a model key.** This is the one constraint the
steering brief states twice.

### 0.2 Recording weight, activity and strength

Created deliberately, unfinished deliberately. Capture left the Dashboard under
*the Dashboard reads; the Journal writes*, and journal classification accepts
food and lifestyle shapes only. So today:

| Record | Route in |
|---|---|
| Food, mood, sleep, meditation | Journal interpretation ✓ |
| Weight | **none** — health hub only |
| Activity | **none** — health hub only |
| Strength | **none at all** |

Needs bounded weight/activity/strength shapes in
`classification_contract.dart` and a commit path through the services that
already exist and are already tested. Blocked on 0.1.

### 0.3 Owner-only items

Upload keystore, Play and Apple accounts, a public privacy-policy URL, the
health-data declarations. All in `RELEASE.md` §2. None can be done from this
repo, and the keystore in particular should be created early — losing it later
means losing the ability to update the listing.

---

## 1. Should ship in 1.0, but the product works without them

1. **Read deeper for every position.** Currently four positions (Life Path,
   Sun, Moon, Ascendant). The intent is all twelve houses and the 22-arcana
   destiny matrix. This is the largest unbuilt feature and it needs its own
   research pass before any code: the matrix is a numerological construction
   with several competing traditions, and picking one and documenting it is
   most of the work.
2. **New card backs.** `ART_COMMISSIONS.md` Commission 4. The current pair was
   authored at the wrong proportion and cropped into shape.
3. **A first-run integration test.** Every test starts from a seeded fixture.
   The one path every real user takes — empty database, onboarding, tutorial,
   first day — is covered only in pieces.
4. **Crash reporting, or a recorded decision not to have it.** Shipping with no
   crash signal is flying blind; adding it needs consent and a privacy-policy
   line. Either answer is defensible, silence is not.

## 2. Test coverage that is genuinely missing

Fourteen core modules have no test naming them. Most are widgets the goldens
cover indirectly, but four carry real logic and should be tested before they
ship:

| Module | Why it matters |
|---|---|
| `symbolic/transits.dart` | Aspect detection, applying vs separating, orb weighting. Pure arithmetic, trivially testable, currently unverified. |
| `journal/day_story.dart` | Consent gating, the fingerprint cache, and the parser's bounds. It writes to the database. |
| `vessel/positions_composer.dart` | Caching per day and chart, and the safety gate on the note that reaches guidance. |
| `health/daily_activity_summary.dart` | The resting-burn path, including the new Katch-McArdle branch when body fat is known. |

Also worth adding: a **prompt fixture set** (`AI_FLOW.md` §5.5) — recorded
good, malformed, unsafe and empty responses for each of the five calls, so the
parsers are tested against real model output rather than hand-written JSON.

## 3. Deferred with intent

Not gaps; decisions. Recorded so they are not rediscovered as bugs.

- **Cloud continuity.** Rules and indexes are committed; nothing reads them.
  Local-only is a legitimate 1.0.
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
3. The four missing tests (§2), against the real transport.
4. The remaining four contracts.
5. Weight/activity/strength shapes (0.2), which 0.1 unblocks.
6. Card backs (1.2) and the first-run test (1.3).
7. Read deeper's full expansion (1.1) — the biggest, and the most safely
   deferred to 1.1 if the release is time-boxed.

Steps 1–5 are a shippable 1.0: a private journal and body log with working
intelligence, honest about everything it cannot do.
