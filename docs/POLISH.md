# Eter · the Polish lexicon

Eter's Polish is not a translation of its English. It is the same product named
again, by somebody writing Polish, and where the two disagree the Polish wins on
its own surface.

This file is the vocabulary. `TRANSLATIONS.md` is the full pairing; that one is
for review, this one is for decisions — a word here governs every sentence that
uses it, so changing one is not a string edit.

---

## The one problem with the name

**In Polish, *eter* is the word for ether.** So the product and its intelligence
collapse into the same common noun, and "Eter przygotował dzisiejsze wskazania"
reads as though the substance did it.

The fix in force is to keep **Aether** in its Greek spelling. A foreign spelling
in a Polish sentence reads as a proper name, which is exactly what it is, and it
holds the distinction the steering brief asks for: Eter is the place, Aether is
the one who reads. Nothing else needs doing, but it should not be quietly
"corrected" later by somebody tidying spellings.

---

## The vocabulary

Kept where the Polish already stands on its own. Every change below is either a
word that means something else in ordinary Polish, or a word that belongs to
software rather than to this product.

| Surface | English | Polish | Why |
|---|---|---|---|
| the app | Eter | **Eter** | Works unchanged, and sounds native. |
| the intelligence | Aether | **Aether** | See above. |
| left destination | JOURNAL | **DZIENNIK** | Kept. A *dziennik* is a diary and a day-book at once, which is precisely what this is. |
| right destination | DASHBOARD | **WGLĄD** | Was `PULPIT`, the Windows desktop. `TARCZA` was proposed — the face of an instrument — and rejected as clever rather than true. *Wgląd* is **insight**, and a look into something. |
| settings and consents | SANCTUM | **ZACISZE** | Was `SANKTUARIUM`: eleven letterspaced caps, and churchy in a way the English is not. *Zacisze* is a still, quiet, private place — warmer, secular, and four characters shorter, which the shell's header has wanted for some time. |
| the disclosure | LOOK DEEPER | **GŁĘBIA** | Was `ZAJRZYJ GŁĘBIEJ`: an imperative verb phrase among nouns, casual, and the longest label on the resting screen. *Głębia* is "the depth" — a place you go rather than an instruction, and it matches the shape of every other label. |
| the reading | GUIDANCE | **WGLĄD** | The same word as the destination, deliberately. *Wskazania* — instrument readings — was defensible but reads clinically beside the rest. See the note below. |
| health section | THE BODY | **CIAŁO** | Kept. |
| symbolic section | VESSEL | **KRĄG** | Was `NACZYNIE`, whose everyday sense is a dish — *naczynia* is what is in the sink. A *krąg* is a circle or ring, which is literally what a chart wheel is, and it is native rather than borrowed. |
| the cloud copy | CLOUD CONTINUITY | **KOPIA W CHMURZE** | Was `CIĄGŁOŚĆ W CHMURZE`. *Ciągłość* is an abstraction from a consultancy deck; a person keeps a **copy**, and the whole section exists to say plainly what is kept where. |
| the export | LOCAL EXPORT | **EKSPORT LOKALNY** | Kept, reluctantly. It is application vocabulary by the second test, and the native replacement is *kopia* — which the cloud section above already owns. Two different things called *kopia*, one of which leaves the device and one of which never does, is worse than one borrowed word. |

### One word doing two jobs

`WGLĄD` names both the right-hand destination and the guidance section inside it,
and they render **on the same screen, about 100 dp apart** — the rail says
`WGLĄD` and the heading below it says `WGLĄD`.

That is either elegant or confusing and only use will tell which. The reading
that makes it elegant: the surface *is* the insight, and the section within it is
the pure form of it, the way `DZIENNIK` names both a book and the act of keeping
one. The reading that makes it confusing: two different tappable things wearing
one name, on one screen.

If it grates, the section is the one to change — the destination is the more
load-bearing of the two. One line.

### Kept without change

`CIAŁO` · `SEN` · `WAGA` · `KONTO` · `STARE STRONY` · `HISTORIA ZDROWIA` ·
`DZIENNIK` · `Słucham…` · `Dyktuj`

These are already the words a Polish speaker would reach for.

---

## The rule behind all of it

A translation that is accurate and still sounds like a translation is worse than
a free one that sounds like something a person would say. Two tests, both cheap:

**Read the Polish alone.** Cover the English column. If the sentence only makes
sense once you know what it was, it is not finished.

**Ask whether the word belongs to the product or to software.** `PULPIT`,
`CIĄGŁOŚĆ`, `EKSPORT` are the vocabulary of an application. `GŁĘBIA`,
`ZACISZE`, `KRĄG`, `WGLĄD` are the vocabulary of this one.

## What this does not touch

Identifiers never move — `Zodiac.aries` carries `'Aries'`, aspects are keyed
`'conjunction'`, dimensions `'health'`, arcana `'the-fool'`. `LANGUAGES.md` §2
explains what breaks when one does, and it breaks silently and only in Polish.

The model's instructions are written in English in every language, and say so on
purpose; see `AI_FLOW.md` §6a.

## Gender, and the sentences that cannot be assembled

Polish agreement is what breaks a string that was written by joining pieces, and
it breaks invisibly — the app renders, the tests pass, and only a reader notices.
Two shapes to watch for, both of which shipped in this branch:

**An adjective after a name.** `seriesLabel` returns the name of a measurement
and the sweep sentence puts *wyższy* after it, so every name needs a gender and
the adjective has to be chosen from it. The same names must also be nouns: English
can say "when how long you slept is higher", Polish cannot.

**An adjective inside a counted phrase.** The numeral decides the case, so
*1 zgłoszony sygnał* / *2 zgłoszone sygnały* / *5 zgłoszonych sygnałów* differ in
both words. Tabulate the adjective with the noun in `_plural`, never join them.

And the third: **do not address the reader with a past-tense verb.** *urodziłaś
się lub urodziłeś* is not a sentence a person writes. Reach for the present
tense, an impersonal (*zapisano*), or a noun.

## The reader is addressed in lower case

*twoja historia*, not *Twoja historia*, mid-sentence. The capitalised forms are
the register of a letter to a stranger, and Eter is not that. Sentence-initial
capitals are of course still capitals.

## Still to do

The vocabulary above is applied, and so is the Sanctum and the locally composed
prose. The rest of the **sentences** are not: the remaining sections in
`TRANSLATIONS.md` are still translated English rather than written Polish, and
they should be reread against the two tests above.
