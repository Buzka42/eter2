# Eter · where the work stands, and what to do next

Written 30 July 2026, at the end of a long session on branch `eter-audit-fixes`.
Read this first if you are picking the work up cold; then `DECISIONS.md` for what
the product owner has settled, then the specific document each task names.

**State of the tree:** nothing uncommitted. `flutter analyze` clean. **707 tests
pass, 7 skipped** — the seven are live-provider tests that need a deployed
endpoint. Schema is at **13**; the twelve migrations were verified on a real
Android device with real data, but **13 was not** — `Letters` is created through
`_createTableIfMissing`, so it repairs itself, and it still wants one upgrade run
on a device with existing data before release.

---

## Start here

```bash
cd app
flutter test          # expect 707 pass, 7 skipped
flutter analyze       # expect clean
```

If either disagrees with those numbers, something in the working tree is wrong —
fix that before starting anything below.

---

## The queue, in dependency order

Nothing here is blocked on anything above it except where stated.

### 1 · The Polish sentences · *done, and read once more if you like*

All fifteen sections of `docs/TRANSLATIONS.md` were read against the two tests in
`POLISH.md`, in six slices, and everything that failed one was rewritten. What was
actually wrong, in descending order of how badly it read:

- **Gender agreement in assembled sentences.** The sweep summary put one fixed
  adjective ending after fifteen nouns of two genders, and fed it clauses where a
  noun belongs. The retrospective left a participle in the wrong case above four.
  `POLISH.md` now has a section on both shapes.
- **Gendered verbs addressing the reader** — *chciałabyś lub chciałbyś*, and
  *Potwierdziłem* on a button. There are none left in the file; the grep that
  finds them is in that same section.
- **Vocabulary the lexicon had already retired**, still in place: `SANKTUARIUM`
  titled the Sanctum, `Pulpit` was an opening page, `CIĄGŁOŚĆ` was a consent, and
  *komponować* survived in three strings.
- **Words that mean something else here** — the food estimate stayed out of *the
  weight*, and the first matrix cell was called *Dane*.
- **Aether now declines**, because it is a name. See `POLISH.md`.

`EKSPORT LOKALNY` was kept and `POLISH.md` records why: the native word is *kopia*
and the cloud section owns it. `WGLĄD` still does two jobs; leave it until use
says otherwise, and change the *section* rather than the destination.

**Watch for:** no test reads Polish for sense, so a spliced or ungrammatical
sentence passes everything. Read every string you touch, out loud if it helps.
`python tool/pair_translations.py` regenerates the pairing — and note it drops any
member whose comment sits between `@override` and the signature.

**Left deliberately:** *rosnący garb* for a waxing gibbous moon. It is transparent
but it is not what Polish astronomy says, and every alternative reads worse inside
`Księżyc w fazie …`. A decision, not an oversight.

### 2 · The Long View surface · *built; wants a look on a real device*

`LongViewSource` loads a window, `EngravedLongView` draws it, and the History
sheet widens on its own as you turn back. No charting package, no model call, no
new destination.

The parts worth knowing before changing any of it:

- **There is no zoom control, on purpose.** `longViewSpanFor` turns
  distance-from-today into a scale — under a fortnight a day, then week, month,
  year — and the beads step by whatever scale you are on. A zoom button would
  have been the menu `DECISIONS.md` rejected.
- **An unrecorded period is an open tick below the baseline**, not a bar of no
  height. That is the absent-not-zero rule made visible, and it is the one thing
  in the painter that must not be "simplified". Pages written is the exception
  and draws a real zero: Eter knows for certain that nothing was written.
- **Marginalia only on a week.** Thirty recall notes is a wall of text, which is
  the same reason `LongViewComposer` returns none for a month cell.
- A week ends on the anchor day; a year is the twelve months ending with the
  anchor's month. Both are in `long_view_source.dart` with the reasoning.

**Not done:** no golden covers a widened sheet. The panel is behind fourteen taps
of a bead, and the capture harness drives the shell rather than the sheet. Worth
adding if the sheet changes again; worth *looking at on a phone* either way,
because a twelve-cell year axis at 320 dp with 200 % text has never been rendered.

### 3 · The Letter · *built; never run against a real model*

`core/aether/letter.dart`, schema 13's `Letters` table, `letter` in `CALLS` at
0.7, and `EterPrompts.version` at 5. `AI_FLOW.md` now documents six calls.

- **The cache key is the month.** One request per person per month, and a month
  already written is never composed again. There is a test for that specifically,
  because a monthly page that quietly re-bills is the worst kind of cost.
- **Below five recall notes Eter does not ask at all.** The instruction already
  keeps a thin month short; this is the floor below which the request is not
  worth making, since paying a model to say "there is not much here yet" is
  worse than not writing.
- Recalls that saw the journal stop travelling when `journalAiConsentAt` is
  withdrawn, so revoking cannot leave last month's pages reaching the model
  laundered through Eter's own prose.
- It arrives on the Journal page where Aether's prose always stands, scrolls
  rather than shrinking to fit, and is answered by the writing field below.
  Composition is attempted when the Journal opens — the only moment Eter has,
  since there is no background poll — and is best-effort.
- `Letters` has **no retention expiry**, deliberately. `AI_FLOW.md` §6 says why.

**Not proven:** no recorded model output has ever been run through
`LetterParser`, because the endpoint is not deployed. It is the sixth entry for
the prompt-fixture work in item 5, and the first one worth capturing — a letter
is the longest thing Aether writes and the likeliest to drift past 2400
characters or into the phrasing `AetherSafetyPolicy` blocks.

### 4 · The evening invitation · *built; delivery unverified*

`core/invitation/` is the feature, split so the rule is testable and only the
platform call is not. Schema 14 carries the consent, null on upgrade. The
Sanctum has the toggle, beside the other consents rather than in a preferences
list — it is the only one that is not about data leaving the device, and what it
grants is the right to interrupt.

- Half an hour **after** the real sunset. At sunset the register turns, and a
  notification on the same minute reads as the app announcing its own theme.
- Somebody who already wrote today is moved to tomorrow. An invitation, not a
  reminder.
- Above the Arctic Circle it degrades to 20:00 rather than falling silent for a
  season — the same way the register degrades with no horizon to read.
- Granting asks the OS first and stores nothing if refused.
- `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED` are back in the manifest,
  each with a comment saying why.

**What the phone has to prove**, none of which a test can:

1. Sanctum → `AN EVENING INVITATION` → ALLOWED. The system sheet should appear
   **once**, and refusing it must leave the control reading OFF.
2. One notification that evening, silent and low-importance, and **only one**.
3. Write a page during the day; that evening must stay silent.
4. Turn it off; anything pending must disappear immediately.
5. Reboot mid-afternoon; that evening's invitation must survive.

**Also unverified:** `flutter_local_notifications` has never been built for
Android here, so the plugin's Gradle side is untested in this project.

**And one thing that is probably wrong already.** The notification is scheduled
against `@mipmap/ic_launcher`, which exists but is an *adaptive, full-colour*
icon. Android's small icon must be a monochrome alpha mask, and a colour one
renders as a white blob. Expect to add a dedicated silhouette drawable — it is a
one-line change once you have seen it on the status bar, and not worth guessing
at blind.

### 5 · Import · *done*, and the prompt fixtures · *blocked on the endpoint*

**Import is built.** `core/privacy/local_data_import.dart`, reached from the
Sanctum under `BRING A RECORD BACK`, directly beneath the export it undoes.

- It only fills an empty device, the same promise cloud Restore makes.
  "Empty" **excludes the profile row** — a new phone has one by the time anybody
  reaches the Sanctum, and counting it would make the feature refuse in exactly
  the case it exists for.
- A snapshot from a newer schema is refused outright; anything else unreadable is
  *reported* — how many records came back, and that part of the file did not.
- The insert is raw SQL. Drift's `validateIntegrity` is written for rows the app
  is composing; a restore is putting back bytes this same schema wrote.

**Still worth doing, and not started:** reading *other* apps — Daylio, Bearable,
Apple Health XML. That is the version that gets somebody to switch, and it is a
different job: those are foreign shapes, not Eter's own snapshot.

**Not verified without a phone:** `file_picker` has never been built for Android
here. The picker is deliberately opened **unfiltered** rather than restricted to
`json` — Android's document picker filters by MIME type and hides a `.json` that
the file manager reports as `application/octet-stream`, which is most of them. A
wrong file is refused with a sentence, which is a better failure than a right
file the person cannot see. Worth confirming a `.json` is actually selectable.

**Prompt fixtures — still blocked.** All *six* parsers are tested against
hand-written JSON, never against recorded model output. Record good, malformed,
unsafe and empty responses per call once the endpoint is deployed. Start with the
Letter: it is the longest thing Aether writes and the likeliest to drift past its
ceiling or into blocked phrasing.

### 6 · The home-screen widget · *needs a device, and a Mac for iOS*

Not started, and **not a short job**: native SwiftUI WidgetKit on iOS, Glance or
RemoteViews on Android, plus a shared read path out of the Drift store. Android
alone is several hours. There is no Mac in this environment, so the iOS half
cannot be built or verified here at all.

One sentence from today's synthesis, already sitting in `GuidanceHistory`.

### 7 · The Correspondence · *built; the rules are not deployed*

`core/correspondence/` — the policy, the pairing, and the Firestore gateway.
`firestore.rules` carries the server half and **validates**, but has never run
against the live project.

The parts that are load-bearing rather than incidental:

- **`CorrespondencePolicy` runs on the way out and again on the way in.**
  Neither makes the other redundant: outbound protects them from this device,
  inbound protects this device from a compromised peer or a stale document. It
  refuses any sentence containing a digit — Eter's synthesis never quotes a
  figure, so a digit means something upstream changed, and trimming it would
  leave a sentence still *about* the measurement.
- **The rule is the third check**, and the only one an attacker cannot skip by
  not running our client. A line document may hold exactly `date` and
  `sentence`. Membership can never change. `list` on invitations is denied, so
  the code's length actually buys something.
- **Leaving is unilateral on both sides**, in the rules as well as the client.
- Schema 15 stores the pair id and **nothing about the other person** — no name,
  no address, no history of their lines. Today's line is read, shown, not kept.
- The Polish label is `DZIEŃ OBOK`. Eter does not know who the other person is,
  so `JEJ`/`JEGO` is out.

**What is not done, and needs two accounts and a deployed project:**

1. `firebase deploy --only firestore:rules`. The live project's rules predate
   all of this and will deny every path here — see `RELEASE.md` §2.5.
2. Pair two real accounts end to end: offer, read the code aloud, redeem.
3. Confirm the code is dead after one use, and after 24 hours.
4. Confirm a **non-member** is refused on `correspondences/{pairId}` and on a
   line document. This is the one that matters; everything else is convenience.
5. End it from each side in turn and confirm the other side notices and forgets.

**Not built, deliberately:** any notification that a line arrived. It appears
when you next look, which is the whole register of the feature.

### 8 · Verify nutrition write-back · *needs the phone*

`37b455f` built it and the device run stopped at the permission sheet — I did not
grant health-write access on the owner's behalf. Still unproven:

1. Grant `WRITE_WEIGHT` and `WRITE_NUTRITION` in Health Connect.
2. Sanctum → `WRITE BACK`.
3. Confirm a weight **and a confirmed meal** appear in Health Connect.
4. Tap again; confirm nothing duplicates (`clientRecordId` dedupe).

Nutrition goes through `Health.writeMeal`, which has never run against a real hub.
`DIETARY_ENERGY_CONSUMED` is Apple-only and was filtered out *silently* on
Android — that class of failure is why this needs a device and not an argument.

---

## Things that will bite you

**Golden tests are the honest reviewer.** They run every language at 320 dp and
200 % text, which is where translation breaks layouts. They caught a 112 px English
overflow and a 175 px Polish one on the same row, and they refused to tap when two
widgets ended up sharing a semantics label. When they fail, read the failure before
re-recording — twice in this branch the failure was a real defect, not a stale
image.

**Polish decides layout more often than English.** But not always: `DASHBOARD` is
nine letterspaced caps against `PULPIT`'s six, so the Sanctum mark collided in
*English* first. Render both.

**`flutter test --update-goldens` will happily bake in a bug.** If a capture throws
an overflow, updating records the yellow stripes as the new truth. Check the
failure reason.

**Schema migrations must be idempotent.** `_addColumnIfMissing` and the backfill
pattern in `app_database.dart` exist because a half-applied migration once left the
app unable to open. Follow that shape; never key on `from`.

**Consent is re-read, never cached.** Every path re-reads the profile so revoking
takes effect on the next pass. Do not add a cached flag.

**A record nobody made is absent, not zero.** This is the single rule most likely
to be violated by new code — averages, charts, summaries. v1 told somebody who had
not logged food that they were 828 kcal down. `long_view.dart` and
`sleep_totals.dart` both carry the rule in their doc comments.

---

## Owner-only, still outstanding

None of these can be done from the repo. `RELEASE.md` §2 is the full list; the ones
that block the most:

1. **Upload keystore** — create it early; losing it means losing the ability to
   update the listing.
2. **Deploy `server/worker.js`**, and **bind the rate limiter** in
   `wrangler.toml`. Without it the worker logs `limits=kv-approximate` and means
   it.
3. **Store subscription products** — `eter.monthly` $4.99, `eter.yearly` $39.99,
   **20 PLN/month in Poland** as a regional price, not a conversion.
4. **A public privacy-policy URL**, and the health-data declarations.
5. **Firestore rules deploy** — the live project's rules predate the mirror and
   would deny it.
6. **Rotate the development Gemini key** before any public build.
