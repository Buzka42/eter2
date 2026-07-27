# 16 · Privacy & Compliance

Health data. Treat it accordingly — privacy is a feature of "precise".

## Consent model (granular, revocable, timestamped)

| Consent | When asked | Covers |
|---|---|---|
| Health read | Onboarding step 5 / Integrations | HealthKit/HC scopes, per-type where OS allows |
| Vendor account link | Per vendor connect | OAuth scopes listed in plain words before the browser opens |
| Cloud sync | Onboarding (default on, clearly explained) | Firestore aggregates (14); off = fully local mode (app must work 100% local) |
| AI estimation | First AI estimate | Exactly what's sent (12 payload shown verbatim in the sheet), which provider, that it leaves the device |
| HR sparkline sync | Settings, default off | Downsampled session sparklines to Firestore |

Every consent stored with timestamp + version; revocation takes effect immediately and is honored by Functions too.

## Data handling rules

- HR raw samples: device-only (14). AI payloads: anonymized (no uid/name/DOB — age integer only), TLS, never logged server-side in app-provided mode (Function proxy strips and forwards, logs only quota counters).
- Vendor tokens: KMS-encrypted, Functions-only access (11/14). User API keys (own-key AI): `flutter_secure_storage`, never synced, masked in UI after entry.
- Analytics: Crashlytics + coarse feature counters only; **no health values in any analytics event**; no third-party ad/tracking SDKs. App Check on all backend surfaces.
- Zodiac/arcana: cosmetic personalization only; never used in calculations, never sent to AI, no predictions or health claims anywhere in copy (also an App Store 5.1.1/medical-claims safety).

## GDPR (and general good citizenship)

- **Art. 15 Export**: Settings → Privacy → "Export my data": Function bundles Firestore tree → JSON file to the user; local raw data exports as CSV on-device.
- **Art. 17 Delete**: type-to-confirm → Function `gdpr/delete`: Firestore tree, Auth account, vendor token revocation (call each vendor's revoke endpoint), FCM token cleanup; client wipes Drift + secure storage. Completion email via Auth.
- Lawful basis: consent (explicit, per above). Privacy policy URL required by both stores — keep a `PRIVACY_POLICY.md` draft in repo covering: what's collected, where it lives (Firebase region — pin `europe-west` if primary market is EU), retention (14), processors (Google/Firebase, chosen AI provider), user rights, contact.
- Age gate: 16+ (DOB already collected — if under 16, block with a kind message; avoids parental-consent machinery in v1).

## Store health-app requirements checklist

- **Apple**: HealthKit usage strings (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`) specific and honest; Health data never used for ads (declare in App Privacy labels); Bluetooth usage string for straps.
- **Google**: Health Connect permissions declaration form + privacy policy link; `FOREGROUND_SERVICE_HEALTH` type for live sessions; Data safety form matching reality.
- Both: eating-disorder sensitivity — no aggressive deficit targets (floor −750, 10), neutral copy audited (no "burn off", no "cheat", no shame), and a Settings link to help resources on the goals screen.

## Security posture

- Firebase rules tested in CI (14). Functions: least-privilege service accounts, secrets in Secret Manager, dependency audit in CI.
- Certificate pinning skipped (Firebase SDKs handle TLS), but vendor OAuth redirect URIs locked to exact Function URLs.
- Threat note: the Cloud is pretty; the data is boring to attackers *except* location-adjacent inferences — we store no location, sessions carry no GPS in v1 (explicitly out of scope).

## Acceptance criteria

- Local-only mode: full feature parity minus sync/AI-app-provided (verified by test plan running with Firestore blocked).
- Delete flow leaves zero user docs (emulator assertion) and revokes a live Polar sandbox token.
- AI consent sheet displays the literal outgoing JSON for the user's real pending workout.
- Copy audit pass: no health claims, no shame language (checklist review against all strings in `l10n`).
