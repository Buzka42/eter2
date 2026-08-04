# Eter

Eter is a private AI companion. Its two surfaces are a **Journal** you write or
dictate into, and a **Dashboard** carrying the day's guidance, a health widget and
your astrogram. **Aether** is the intelligence that reads them together.

This is the v2 tree. The v1 fitness application lives at `../Eter` and is
superseded.

## Canonical documentation

Five living documents in [`docs/`](docs). Everything else is in
[`docs/archive/`](docs/archive) — accurate when written, superseded since, and
kept because a decision whose reasoning is gone gets relitigated every few
months.

- **[Handoff](docs/HANDOFF.md)** — where the work stands, what to do next, and
  the things that will bite you. **Read this first**, all of it.
- [Product](docs/PRODUCT.md) — what Eter is and why: the owner's steering brief
  (which overrides everything else here), the UI brief and direction, and every
  decision already settled.
- [Engineering](docs/ENGINEERING.md) — the six model calls and the trust
  boundary, the endpoint contract, what is stored and for how long, and the art.
  **The authority for the AI boundary**: where this and a code comment
  disagree, the code is wrong.
- [Language](docs/LANGUAGE.md) — what it means for Eter to *speak* a language,
  the Polish lexicon, and the grammar that has already caused real defects.
  [Translations](docs/TRANSLATIONS.md) is the generated English/Polish pairing.
- [Release readiness](docs/RELEASE.md) — what is blocked, and on whom.

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

681 pass, 7 skipped. The seven skipped are live-provider tests that need a real
endpoint; everything else runs with no network, no account and no model. Golden
captures loop over every language at 320 dp and 200 % text, which is where
translation breaks layouts — if you change a surface, expect them to tell you.
