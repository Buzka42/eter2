# Eter · what is missing, and in what order

Pass 1 of three, 28 July 2026. A code-level audit of the whole repository
against the steering brief, the UI brief and the shipping reality, with the
work ordered so that nothing blocks on something further down the list.

The honest summary: **the local product is finished and the intelligence is
not**. Every surface works, every write is safe, 201 tests pass — and the three
things the product is named for (Aether guidance, journal interpretation,
Vessel readings) have complete, consent-gated, provider-independent contracts
with no provider behind them. A user installing this today gets an excellent
private journal and body log that says, truthfully, that its intelligence is
not connected.

---

## 0. Ship blockers — nothing ships until these are done

### 0.1 The bundle was over Play's limit — **done**

`flutter build appbundle --release` produced **186 MB** against Play's 150 MB
base-module ceiling: it failed at upload, not review.

The cause was authored resolution, not quantity. The Arcana deck shipped at
1030 px wide for a surface that draws it at **92 dp**, and the loops at
5.4 Mbit/s for the same 92 dp. `tool/compress_assets.py` re-encodes every
shipped asset to roughly 2x the largest size the interface can render it at:

| Group | Before | After |
|---|---|---|
| 23 Arcana loops | 69.0 MB | 5.8 MB |
| Arcana deck (46 cards) + backs | 31.2 MB | 4.3 MB |
| Vessel plates (PNG → WebP) | 11.2 MB | 0.5 MB |
| Day ambient field | 1.4 MB | 0.3 MB |
| **Bundle** | **186.2 MB** | **81.2 MB** |

Nothing any surface shows changed; the goldens confirm it (one Vessel capture
moved by re-compression and was re-recorded). The lossless masters are
untouched in the v1 tree and in history.

**Still worth deciding:** 23 of those loops are unreachable — see 0.4.

### 0.2 Thirteen unused dependencies were shipping, with permissions — **done**

`firebase_core`, `firebase_auth`, `firebase_app_check`, `cloud_firestore`,
`cloud_functions`, `firebase_ai`, `firebase_messaging`, `google_sign_in`,
`universal_ble`, `permission_handler`, `workmanager`, `go_router` and
`url_launcher` are declared in `pubspec.yaml` and imported by **zero** Dart
files. They were declared for slices that were never built.

They were not free. The merged release manifest requested:

```
BLUETOOTH, BLUETOOTH_ADMIN, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED,
USE_BIOMETRIC, USE_FINGERPRINT, FOREGROUND_SERVICE, WAKE_LOCK,
INTERNET, ACCESS_NETWORK_STATE
```

Only the last two are defensible today, and even they are unused. An app whose
entire pitch is "your history stays on this device" asking for Bluetooth,
biometrics and boot-completed is a Play review liability, a data-safety form
that cannot be answered honestly, and dead native code in every install.

Removing all thirteen keeps `flutter analyze` clean and every test green —
verified — and saves 4.3 MB of native code on top of the asset work.

**On real-time health specifically**, since that is the reason to hesitate:
keeping these declared buys nothing, because none of them is imported. What
actually governs freshness is the platform, and neither platform offers push:

* **Android.** Health Connect has no push API. You poll it with *changes
  tokens*, and the platform floor for background work is 15 minutes. That slice
  needs `workmanager` — re-added when it is built, not before.
* **iOS.** HealthKit does offer near-real-time wakeups
  (`enableBackgroundDelivery(.immediate)` + `HKObserverQuery`), but the Flutter
  `health` package does not expose them. That is native AppDelegate code, not a
  pub dependency.
* **What the user actually experiences** is the number on screen when they open
  the app — and that gap is now closed (see 0.3), with no dependency at all.

### 0.3 Health data was only as fresh as the last Sanctum visit — **done**

Until now, health moved only when someone opened the Sanctum and pressed
`Refresh Health`. A morning walk recorded by the watch did not exist in Eter
until the user went looking for a settings action, which made the Dashboard
quietly and invisibly stale.

`core/health/foreground_refresh.dart` syncs the recent window when the app is
opened or resumed. It is inert until a hub is connected (a refresh must never
be the thing that first raises a permission prompt), debounced to one sync per
ten minutes however often the app is resumed, silent on both success and
failure, and scoped to today and yesterday — the thirty-day read stays the
Sanctum's explicit action. Five tests cover it.

This is the honest ceiling without background work; see 0.2 for why.

### 0.4 Open: 23 Arcana loops nothing plays

`AnimatedArcanaCard` and `MajorArcana.animationAsset` exist and **no production
surface uses them**. The Vessel's daily card renders a still `Image.asset` at
92 dp. So the app ships 5.8 MB (post-compression) of video that cannot be
reached, plus the widget that would reach it.

Three honest options: wire the animated card into the Vessel and make the
assets earn their place; drop the loops and the widget together; or leave both
as a deliberate, documented reserve. The same question applies to the four
Vessel plates, which no surface draws either.

### 0.5 Owner-only items

Keystore, store accounts, a public privacy-policy URL, health-data
declarations. All in `RELEASE.md` §2. None can be done from this repo.

---

## 1. The intelligence — the product's headline, currently inert

Three contracts are implemented, validated, consent-gated and tested. None has
a transport:

| Contract | Where | What is missing |
|---|---|---|
| Aether guidance | `core/aether/` | A provider behind `guidanceProvider` |
| Journal interpretation | `core/journal/` | A provider behind `journalClassificationProvider` |
| Vessel readings | `core/vessel/` | A provider behind `vesselReadingTransportProvider` |

All three fail honestly today ("not connected on this build yet") and write
nothing. That is the correct behaviour for an unfinished slice and the wrong
behaviour for a shipped product.

What this needs, in order:

1. **A server boundary.** The steering brief is explicit and this is
   non-negotiable: the client must never hold a model key. A Cloud Function (or
   any owner-controlled endpoint) that authenticates the caller, holds the
   credential and forwards a validated request.
2. **A provider choice** and its cost model.
3. **Prompt and context design** — which is Pass 3 of this review, and is where
   the real product risk lives. The request contracts already bound what may
   leave the device; what has never been written down is what the model is
   actually asked, and how its answer is held to the register.
4. **Rate, cost and failure policy.** What happens on the fifth refresh in a
   minute, on a 500, on a timeout mid-compose.

Until 1–4 exist, everything below is optional and this is not.

---

## 1a. The input rule's unfinished half

**Urgent, and created deliberately on 28 July 2026.** Capture left the
Dashboard: the Body no longer offers add-activity, add-meal, record-strength or
record-weight, because all input outside the Sanctum now happens through the
Journal.

The Journal's classification contract accepts **food and lifestyle shapes
only**. So three things a user could record this morning have no route at all
until it grows:

| Record | Was | Is now |
|---|---|---|
| Weight | `WEIGHT / RECORD` on Body | nothing — the health hub only |
| Activity | `ACTIVITY / ADD ACTIVITY` | nothing — the health hub only |
| Strength | `STRENGTH / RECORD` | nothing |

The write services (`ManualWeightService`, `ManualActivityService`,
`StrengthWorkoutService`) are intact and still tested; what is missing is the
bridge from interpreted prose to them. That means extending
`classification_contract.dart` with bounded weight, activity and strength
shapes, and extending the classifier's commit to route them through the same
canonical deduplicated paths those services already use.

Doing this needs the AI transport (§1) to exist first, which is why it is
here and not in §0.

## 2. Promises made in the product docs that have no code

Ordered by how visible the gap is to a user.

1. **Cloud continuity.** `firestore.rules`, `firestore.indexes.json` and
   `firebase.json` are committed and complete. Nothing reads them: there is no
   auth, no mirror, no cloud delete. The Sanctum says so honestly ("does not
   claim cloud deletion"), so this is an unbuilt slice rather than a lie — but
   the brief's "survives a phone swap" is unfulfilled, and the divergence note
   treats journal sync as decided.
2. **Live sessions and remembered sensors.** `LiveSessions` and
   `RememberedSensors` have schema and one stray update method between them,
   and no writer, reader or surface. The BLE strap slice (`docs/07`) does not
   exist. `universal_ble` is declared and unused (see 0.2).
3. **Vendor integrations.** `Integrations` has a complete set of database
   methods and no UI at all. Garmin/Polar/Fitbit OAuth (`docs/11`) is unbuilt;
   the phone hub covers the same ground less precisely, which is why this never
   blocked anything.
4. **Notifications.** Nothing exists — no scheduling, no permission request, no
   catalog. `docs/15`'s milestone flash is *deliberately dead* (UI brief
   non-negotiable 5 deleted the milestone system), but the quiet end of that
   document — a gentle evening invitation to write — has never been decided
   either way. **Product decision needed:** does Eter speak first, ever?
5. **Entitlements.** The brief asks for one app with feature entitlements and
   explicitly warns against coupling subscription checks to widgets. There is
   no entitlement concept in the code at all. Nothing is gated. This is fine
   for a 1.0 that is free, and a rewrite hazard if it is bolted on later — the
   brief's warning is the thing to honour: one resolver, read at the section
   level, never inside a control.
6. **Meditation and breathwork guidance.** The brief's expanded experience
   promises guidance; the app records minutes. Logging without content is a
   defensible 1.0, but the gap should be named.

---

## 3. Robustness and craft gaps

Real, unglamorous, and none of them blocking.

1. **No import to match the export.** `local_data_export.dart` writes a
   versioned JSON snapshot plus CSVs, and nothing can read one back. A backup
   you cannot restore is a half-promise; the format is already versioned, so
   the restore path is small work.
2. **No first-run integration test.** Every unit and widget test starts from a
   seeded fixture database. The one path every real user takes — empty
   database, onboarding, first day — is covered only by `onboarding_test.dart`
   in pieces, never end to end.
3. **No crash reporting.** Deliberate or not, a shipped app with no crash
   signal is flying blind. If it stays out, that should be a recorded decision
   (it is consistent with the privacy stance); if it goes in, it needs consent.
4. **Single locale, hardcoded.** Every string is an English literal in the
   widget that uses it, and there are no localization delegates. `intl` is used
   for dates only. Fine for launch in one market; expensive to retrofit after
   the copy grows, and the copy *is* the product here.
5. **The register's day contrast** is documented as measured against the day
   plate's worst case in `EterPlate`, but nothing tests it. A golden that
   asserts contrast ratios would keep a future background from quietly breaking
   legibility.
6. **`IntakeAnswers`** is written by onboarding and read once in `main.dart`.
   That is fine — but it is the one table whose purpose is not obvious from its
   use, and it should either grow a reader or a comment saying why it exists.

---

## 4. What is genuinely finished

Recorded so it is not re-audited every pass: the shell and its two
destinations; the arrival reveal; the Journal including dictation, day
navigation, per-entry AI exclusion, interpretation and undo, and the marginal
check-ins; the Body expansion including manual activity, meals with macros,
weight, strength, sleep staging, RHR/HRV trends and per-item nutrition
correction; the Vessel including local chart, numerology, the daily card and
cached readings; the Sanctum including birth context, independent consents,
health connection, weekly review, local pattern discovery, export, and two-step
memory and device deletion; onboarding with its 16+ gate and consent defaults;
retention enforcement; and the whole energy/dedup pipeline.

---

## 5. Suggested order

1. ~~Remove the thirteen unused dependencies (0.2).~~ Done.
2. ~~Get under Play's ceiling (0.1).~~ Done — 186 MB to 81 MB.
3. ~~Close the health-freshness gap (0.3).~~ Done.
4. Decide the unreachable Arcana loops (0.4). Small, and it is a product call.
5. Pass 3 of this review — design the AI flow properly, on paper, before any
   transport exists.
6. Build the server boundary and wire one contract (guidance) end to end.
7. Then the other two contracts, then cloud continuity, then everything in
   section 2.
