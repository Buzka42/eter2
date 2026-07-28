# Eter · release readiness

What is done, what is blocked, and exactly who has to unblock it. Updated
28 July 2026.

The app is complete and green as a **local-first** product: every flow works
with no account, no network and no model. What remains before a store listing
is either an account/credential only the product owner can create, or one
product decision about size.

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
| Tests | 270 passing, 31 golden captures, `flutter analyze` clean. |
| Release build | `flutter build appbundle --release` produces an **81.2 MB** bundle, under Play's 150 MB ceiling. |

**The ordered plan from here — including the AI transport, the recording gap it
unblocks, and the tests still missing — is [`RELEASE_PLAN.md`](RELEASE_PLAN.md).**

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
5. **Firebase project**, if and when cloud continuity ships. Local-only mode is
   complete and is a legitimate 1.0; the mirror is a separate slice.
6. **A model provider and a deployment boundary**, if and when Aether guidance,
   journal interpretation or Vessel readings ship. All three contracts are
   implemented and consent-gated, and all three state honestly that no
   transport is configured. **The client must never embed a model secret** —
   the call has to go through a server the owner controls.
7. **Store listing copy and screenshots.** The golden captures under
   `app/test/golden/` are the honest source for screenshots.

## 3. Size — resolved

The bundle was 186 MB against Play's 150 MB ceiling. `tool/compress_assets.py`
re-encodes every shipped asset to roughly 2x the largest size the interface can
render it at — the Arcana deck was shipping at 1030 px wide for a 92 dp
surface — taking the bundle to **81.2 MB** with no visible change. Thirteen
unused dependencies came out at the same time, removing `BLUETOOTH`,
`BLUETOOTH_ADMIN`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`,
`USE_BIOMETRIC`, `USE_FINGERPRINT`, `FOREGROUND_SERVICE` and `WAKE_LOCK` from
the merged manifest.

Re-run the script after adding art. See `ROADMAP.md` §0.1 and §0.4.

## 4. Not blockers, deliberately deferred

- The 24-glyph icon set in `ICON_SYSTEM_PLAN.md`. The two production
  disclosure marks are already code-native; the rest is a menu, not a gap.
- Vendor OAuth, BLE sessions and background health refresh.
- Any surface that would need a placeholder to exist.
