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
