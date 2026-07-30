# Eter

Eter is a private AI companion. Its two surfaces are a **Journal** you write or
dictate into, and a **Dashboard** carrying the day's guidance, a health widget and
your astrogram. **Aether** is the intelligence that reads them together.

This is the v2 tree. The v1 fitness application lives at `../Eter` and is
superseded.

## Canonical documentation

Read in this order. Anything not listed here has been superseded and moved to
[`docs/archive/`](docs/archive) — those files are kept because their reasoning is
still worth having, not because they describe the app as it is.

**What the product is**

- [Steering brief](docs/STEERING_BRIEF.md) — the authoritative product direction,
  transcribed from the owner's own document. It overrides everything else here.
- [Decisions](docs/DECISIONS.md) — dated product decisions the code cannot
  explain: pricing, navigation, what was descoped and why.

**How it is built**

- [UI brief](docs/UI_BRIEF.md) — the surfaces, the non-negotiables, the register.
- [UI direction](docs/UI_DIRECTION.md) — the compositional system and concept
  plates.
- [Data storage](docs/DATA_STORAGE.md) — what is stored, where, and for how long.
  Schema 12.
- [AI flow](docs/AI_FLOW.md) — the five model calls, the trust boundary, what
  happens when any of it fails. **The authority for the AI boundary**: where this
  and a code comment disagree, the code is wrong.
- [AI endpoint](docs/AI_ENDPOINT.md) — the wire contract for the owner-controlled
  server that holds the model key.
- [Languages](docs/LANGUAGES.md) — what it means for Eter to *speak* a language,
  and the one rule that keeps the symbolic engine working.

**Shipping**

- [Release readiness](docs/RELEASE.md) — what is done, what is blocked, and on
  whom.
- [Asset manifest](docs/ASSET_MANIFEST.md) — the reusable generation style string
  and the shipped set.

## Working rules

- Drift is the local source of truth. Firestore mirrors what should survive a
  phone swap; it is never the calculation source.
- Astrology and numerology are deterministic. The model interprets structured
  results; it does not compute them.
- Health and safety information overrides conflicting symbolic interpretation.
- AI responses are schema-validated and bounded before they reach the database.
- The application must remain usable with no network and no AI. Every surface says
  so honestly rather than pretending.
- Journal prose crosses two boundaries, each under its own separate consent — to
  the model, and to the cloud mirror. Neither is implied by the other, and
  `KEEP LOCAL` holds a single page back from both. See the divergence note at the
  end of the steering brief for why this was allowed at all.
- Eter writes back to the platform health record only what it *originated*. Never
  what it read from it — that round-trips and is re-read as a second measurement.

## Workspace

- `app/` — the Flutter application
- `docs/` — canonical documentation; `docs/archive/` — superseded, kept for its
  reasoning
- `server/` — the deployable AI endpoint (Cloudflare Worker)
- `tools/`, `app/tool/` — art, motion and asset pipelines
- repository root — Firebase configuration and rules

## Running the tests

```bash
cd app && flutter test
```

645 pass, 7 skipped. The seven skipped are live-provider tests that need a real
endpoint; everything else runs with no network, no account and no model. Golden
captures loop over every language at 320 dp and 200 % text, which is where
translation breaks layouts — if you change a surface, expect them to tell you.
