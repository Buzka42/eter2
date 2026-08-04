# Recorded model output

What the deployed endpoint actually returned, one file per call, captured by
`test/manual/live_smoke_test.dart --dart-define=ETER_RECORD=<dir>`.

These exist because every parser in the app was tested against hand-written
JSON, which proves the parser and proves nothing about the prompt. A contract
can drift until the model stops answering the shape the parser expects, and only
a recorded real response shows it — `live_fixtures_test.dart` runs the real
parsers over these with no network at all.

**The inputs were invented.** The recalls, the retrospective sentences, the
journal page and the chart in the live smoke test are all fabricated for the
test. Nothing here is anybody's record, which is why it can live in the
repository.

Re-record after changing a prompt, and read what comes back before committing
it. The first letter this captured said "We watched the third short night",
which is the sentence that produced `EterPrompts.version` 6.

**Recorded at prompt v10, 4 August.** Twelve calls, including the Vessel's four
new parts for the first time. Everything below passed every shape check and
every safety rule on the *first* run and was still wrong, which is the whole
argument for this directory:

- "The records show" in the houses, the angles and the figure's synopsis —
  Eter as an archive reporting on somebody, the same failure as "We watched".
- `occupants`, a field name, in the prose of five houses. The instruction had
  used the word twice in its own sentences.
- Orbs printed to two decimals; transits described in a chart that has none.
- Ten of twelve houses opening with one clause and a swapped card name.
- House 1 never saying the word Ascendant, which is the one thing it exists to
  say — the surface shows that card above the list.
- The figure's synopsis naming places by their internal keys: "the sun, the
  era, and mercury".

And the one that came back after being forbidden since v6: the letter closed
with **"We saw the short nights return."** `LetterParser` refuses it outright
now, in both languages, rather than trusting the instruction a fifth time.
