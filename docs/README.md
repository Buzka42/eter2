# Eter · the documentation

Five living documents. Everything else in `archive/` is history — accurate when
it was written, superseded since, and kept because a decision whose reasoning is
gone gets relitigated every few months.

| Read | For |
|---|---|
| **[HANDOFF.md](HANDOFF.md)** | **Start here.** Where the work stands, what to do next, and the traps that have already cost somebody a day. |
| [PRODUCT.md](PRODUCT.md) | What Eter is and why it is like this: the owner's steering brief, the UI brief and direction, and every decision already settled. |
| [ENGINEERING.md](ENGINEERING.md) | How it works: the six model calls and their trust boundary, the endpoint contract, what is stored and for how long, and the art. |
| [LANGUAGE.md](LANGUAGE.md) | Before you touch a Polish word. How the two languages work, the lexicon, and the grammar that has already caused real defects. |
| [RELEASE.md](RELEASE.md) | What is blocked, and which of it only the product owner can unblock. |

`TRANSLATIONS.md` is generated — `python app/tool/pair_translations.py` writes
it. It is the full English/Polish pairing, for review; the *decisions* about
vocabulary live in `LANGUAGE.md`.

`concepts/` holds the three concept plates. They are mood and hierarchy
studies, not screenshots to trace, and they must never be shipped as
application backgrounds.

## If you are an agent picking this up cold

Read `HANDOFF.md` end to end before writing anything. It is long because the
work is, and its "Things that will bite you" section is the highest-value part
of this repository: every entry in it is a defect that reached a person, or
cost a session to find, and several are shapes rather than incidents — a
`RichText` that ignores the reader's font size, a map comprehension that keeps
the wrong row, a scope on `MaterialApp.home` that no pushed route can see.

Two working rules that are not obvious from the code:

- **A record nobody made is absent, not zero.** This is the single rule most
  likely to be broken by new code, and it has been broken before in a way that
  told somebody they were 828 kcal down on a day they had not logged food.
- **A fixture that parses is not a fixture that reads well.** The model's own
  output is checked by reading it, not by the tests passing. Every prompt
  version from 6 onward exists because somebody read a recorded answer and
  found it wrong while every check was green.
