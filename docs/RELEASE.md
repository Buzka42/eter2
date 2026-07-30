# Eter · release readiness

What is done, what is blocked, and exactly who has to unblock it. Updated
28 July 2026.

The app is feature-complete and green. Every flow still works with no account,
no network and no model — that property is intact and tested — and everything
that needed a provider now has one. What remains before a store listing is an
account, a credential or a deployment that only the product owner can create.

---

## 1. Done in the repo

| Item | State |
|---|---|
| Application id | `com.eterhealth.eter`, both platforms |
| Display name | `Eter` (Android label, iOS `CFBundleDisplayName`) |
| Launcher icon | Rendered from the shell header itself by `app/tool/render_app_icon.py` — the graduated arc, solar and lunar marks, the wordmark in Cormorant Garamond, the plumb-and-star colophon. Emits every iOS size, the Android legacy square, and an adaptive foreground inside the 66% safe zone with `@color/ic_launcher_background` behind it. Re-run the script after any header change. |
| Release signing | `android/app/build.gradle.kts` reads `android/key.properties`. Absent, the build falls back to the debug key and is installable but unpublishable. Template: `android/key.properties.example`. |
| Shrinking | R8 minify + resource shrink on release, with `proguard-rules.pro` covering Health Connect, sqlite3, speech_to_text and the Play Core stubs. |
| minSdk / target | 26 (Health Connect floor) / Flutter default |
| Permissions | Declared and justified: activity recognition and the seven Health Connect read scopes; HealthKit entitlement on iOS. |
| Privacy policy | `PRIVACY_POLICY.md` — needs a public URL before submission. |
| Tests | **645 passing, 7 skipped**, 58 golden captures, `flutter analyze` clean. The seven skipped are live tests driving all five model calls against a real provider. |
| Release build | `flutter build apk --release` produces an **80.1 MB** APK, under Play's 150 MB ceiling. |
| Account deletion | In-app, two-tap, in the Sanctum. Clears the mirror **then** the account — see `DATA_STORAGE.md` §2 for why that order is not optional. Required by Apple 5.1.1(v) and Play's data-deletion policy for any app offering account creation. |
| Health write-back | Weights and confirmed meals only, and only what Eter originated. See `DATA_STORAGE.md` §5. |
| Entitlements | One resolver, `core/entitlement/entitlement.dart`, read at section level and never inside a control — the coupling `STEERING_BRIEF.md` warns about twice. 30-day trial from first launch; the transport is gated on it as defence in depth, so a surface that forgot cannot spend money. **No billing behind it yet** — `SubscriptionService` has no implementation, exactly as `AccountService` once had none, and null is a shipped configuration. |
| AI transport | `core/ai/transport.dart` posts one bounded payload to an owner-controlled endpoint. No model key in the client. `server/worker.js` is the deployable endpoint; `docs/AI_ENDPOINT.md` is its contract. |
| Accounts | Optional. Email with confirmation, and Google. Firebase project `eter-39165`, billing disabled. Apple sign-in is one provider away and needs a membership. |
| Cloud mirror | `core/sync/`. Measured record under one consent, journal prose under its own. Restore refuses on a device with history. |
| Crash reporting | Consent-gated, off by default, and structurally unable to carry user content. |

**Product decisions — pricing, navigation, what was descoped — are in
[`DECISIONS.md`](DECISIONS.md). The historical ordered plan is
[`archive/RELEASE_PLAN.md`](archive/RELEASE_PLAN.md); most of it has landed.**

## 2. Blocked on the product owner

None of these can be done from this repo; each needs an account, a secret or a
decision.

1. **Upload keystore.** Create it, fill `android/key.properties`, and store the
   `.jks` and its passwords in a password manager. Losing them means losing the
   ability to update the listing. The command is in
   `android/key.properties.example`.
2. **Store accounts.** Google Play developer account and, for iOS, an Apple
   Developer Program membership plus a bundle id and provisioning in Xcode.
3. **A public privacy-policy URL.** Both stores require one at submission.
   Publish `PRIVACY_POLICY.md` and record the URL here.
4. **Health data declarations.** Play's Health Apps declaration and Apple's
   health-data questions both require answers matching what the app actually
   reads — the seven scopes in the manifest, all local, none sold or shared.
5. **Deploy the AI endpoint.** `server/worker.js` is written and runs on
   Cloudflare's free tier; it needs `wrangler login`, two secrets and a
   deploy. Until then the app talks to `tool/dev_endpoint.dart` on a
   development machine. **The client must never embed a model secret** — the
   call goes through a server the owner controls, which is the entire reason
   the endpoint exists.
6. **Firestore rules deploy.** `firebase deploy --only firestore:rules`. The
   rules in this repo cover every mirrored collection; the ones currently live
   on the project predate the mirror and would deny it.
7. **Google Sign-In OAuth client.** Enable Google in the Firebase console's
   Authentication providers and set the support email. Email sign-in works
   without it; the Google button is present and will start working once the
   client provisions. Sign in with Apple additionally needs a paid Apple
   Developer membership, and an iOS listing that offers Google must offer
   Apple too.
8. **Store listing copy and screenshots.** The golden captures under
   `app/test/golden/` are the honest source for screenshots.
9. **Store subscription products.** Two of them — `eter.monthly` at $4.99 and
   `eter.yearly` at $39.99 — created in both consoles, with **regional pricing
   set rather than a flat conversion**. Poland is set deliberately at
   **20 PLN a month**, against a conversion of about 36. Polish is one of Eter's
   two languages and its cheapest acquisition market, and Polish subscription apps
   land at 19–29 — the conversion price would discard that. The prices in
   `_AetherAccess` are placeholders and must be replaced by the store's own
   localised strings, not translated.
10. **Bind the rate limiter** (`server/wrangler.toml`) before there are paying
    users. Without it the worker logs `limits=kv-approximate` and means it.
11. **Rotate the development Gemini key** before any public build. It has been
   handled in plain text during development and belongs only to
   `tool/dev_endpoint.secret`, which is gitignored and has never been
   committed.

## 3. Size — resolved

The bundle was 186 MB against Play's 150 MB ceiling. `tool/compress_assets.py`
re-encodes every shipped asset to roughly 2x the largest size the interface can
render it at — the Arcana deck was shipping at 1030 px wide for a 92 dp
surface — taking the bundle to **81.2 MB** with no visible change. Thirteen
unused dependencies came out at the same time, removing `BLUETOOTH`,
`BLUETOOTH_ADMIN`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`,
`USE_BIOMETRIC`, `USE_FINGERPRINT`, `FOREGROUND_SERVICE` and `WAKE_LOCK` from
the merged manifest.

A later pass took it to **80.1 MB** by deleting 5.3 MB of art that was declared
in `pubspec.yaml` and referenced by no Dart file — `cloud-hero-cutout.png` alone
was 4.1 MB and had escaped the WebP pass entirely. The APK saving is smaller than
the on-disk figure because it was already compressing that PNG.

Re-run the script after adding art. Verify unreferenced assets by extracting
`assets/…` literals from `lib/` rather than by eye, and remember that some paths
are *composed* — `Zodiac.medallionAsset` builds its own, so the element medallions
look unreferenced and are not. See `archive/ROADMAP.md` §0.1 and §0.4.

## 4. Corrections worth remembering

Two faults shipped in this repo for months and were found only by testing a
property rather than reading the code. Both are fixed; both are recorded
because the *method* is the lesson.

- **The ascendant was the descendant.** The formula negated the numerator
  rather than the denominator, returning the antipode — a real degree, in a
  real sign, reading plausibly, and wrong for every chart. Found by scanning
  the ecliptic for the degree actually on the eastern horizon and requiring the
  engine to agree. `test/ascendant_test.dart`.
- **The chart cache key lived in five places.** They all had to agree forever,
  and nothing checked that they did. It now lives once, in `natalInputHash`,
  and carries an engine version so a correction retires what the old engine
  wrote instead of leaving it on screen indefinitely.

## 5. Not blockers, deliberately deferred

Reasons, where they exist, are in [`DECISIONS.md`](DECISIONS.md).

- The 24-glyph icon set in `archive/ICON_SYSTEM_PLAN.md`. The two production
  disclosure marks are already code-native; the rest is a menu, not a gap.
- Vendor OAuth and background health refresh.
- BLE straps — deferred *to* breathwork rather than dropped, because live RR
  intervals are the one thing a hub cannot give and the only way to show somebody
  what a breathing practice did to them.
- Sign in with Apple. Blocked on a paid membership, and an iOS listing offering
  Google must offer Apple too.
- Any surface that would need a placeholder to exist.

## 6. Known gaps in what has been proven

Not defects — things believed correct on reasoning and tests, without a device run
behind them. Recorded so they are not mistaken for verified.

- **Nutrition write-back.** The Health Connect permission sheet opened and offered
  Weight; the permission was not granted, so no write has ever landed.
  `Health.writeMeal` has never run against a real hub.
- **The push-to-talk race.** `_holding` guards a release that arrives before the
  recogniser is ready. Verified by a device run and by reading; it lives in async
  widget state and has no automated test.
- **Prompt fixtures.** The five parsers are tested against hand-written JSON, never
  against recorded real model output — good, malformed, unsafe and empty.
- **Firestore rules.** Committed and covering every mirrored collection, but the
  live project's rules predate the mirror and would deny it. Deploying them is in
  §2.
