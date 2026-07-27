# Eter

Eter is a private AI companion. Its two surfaces are a **Journal** you write or dictate
into, and a **Dashboard** carrying the day's guidance, a health widget, and your
astrogram. **Aether** is the intelligence that reads them together.

This is the v2 tree. The v1 fitness application lives at `../Eter` and is superseded.

## Canonical documentation

- [Steering brief](docs/STEERING_BRIEF.md) — the authoritative product direction.
  Read this first; it overrides anything else here.
- [Wearable integrations](docs/11-wearable-integrations.md) — per-vendor paths, OAuth via
  Functions, the deduplication ladder.
- [Data models](docs/14-data-models-firebase.md) — Drift and Firestore, the sync engine.
- [Notifications and haptics](docs/15-notifications-haptics.md)
- [Privacy and compliance](docs/16-privacy-compliance.md)
- [Asset manifest](docs/ASSET_MANIFEST.md) — the reusable generation style string.
- [Icon system plan](docs/ICON_SYSTEM_PLAN.md) — a specified 24-glyph set, uncommissioned.

## Working rules

- Drift is the local source of truth. Firestore mirrors what should survive a phone swap;
  it is never the calculation source.
- Astrology and numerology are deterministic. The model interprets structured results; it
  does not compute them.
- Health and safety information overrides conflicting symbolic interpretation.
- AI responses are schema-validated and bounded before they reach the database.
- The application must remain usable with no network and no AI.

## Workspace

- `app/` — the Flutter application
- `docs/` — canonical documentation
- `tools/` — art and motion pipeline (Python + PowerShell)
- repository root — Firebase configuration and rules
