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
| right destination | DASHBOARD | **TARCZA** | Was `PULPIT`, which is the Windows desktop. *Tarcza* is the **face of an instrument** — the dial of a clock, the plate of an astrolabe. The product is built out of engraved instruments; this is the one word in Polish that already belongs to them. |
| settings and consents | SANCTUM | **ZACISZE** | Was `SANKTUARIUM`: eleven letterspaced caps, and churchy in a way the English is not. *Zacisze* is a still, quiet, private place — warmer, secular, and four characters shorter, which the shell's header has wanted for some time. |
| the disclosure | LOOK DEEPER | **GŁĘBIA** | Was `ZAJRZYJ GŁĘBIEJ`: an imperative verb phrase among nouns, casual, and the longest label on the resting screen. *Głębia* is "the depth" — a place you go rather than an instruction, and it matches the shape of every other label. |
| the reading | GUIDANCE | **WSKAZANIA** | Kept, and better than the English. *Wskazania* are **instrument readings** as well as indications, so the word quietly carries the astrolabe. |
| health section | THE BODY | **CIAŁO** | Kept. |
| symbolic section | VESSEL | **KRĄG** | Was `NACZYNIE`, whose everyday sense is a dish — *naczynia* is what is in the sink. A *krąg* is a circle or ring, which is literally what a chart wheel is, and it is native rather than borrowed. |
| the cloud copy | CLOUD CONTINUITY | **KOPIA W CHMURZE** | Was `CIĄGŁOŚĆ W CHMURZE`. *Ciągłość* is an abstraction from a consultancy deck; a person keeps a **copy**, and the whole section exists to say plainly what is kept where. |

### Kept without change

`CIAŁO` · `SEN` · `WAGA` · `KONTO` · `STARE STRONY` · `HISTORIA ZDROWIA` ·
`DZIENNIK` · `WSKAZANIA` · `Słucham…` · `Dyktuj`

These are already the words a Polish speaker would reach for.

---

## The rule behind all of it

A translation that is accurate and still sounds like a translation is worse than
a free one that sounds like something a person would say. Two tests, both cheap:

**Read the Polish alone.** Cover the English column. If the sentence only makes
sense once you know what it was, it is not finished.

**Ask whether the word belongs to the product or to software.** `PULPIT`,
`CIĄGŁOŚĆ`, `EKSPORT` are the vocabulary of an application. `TARCZA`, `GŁĘBIA`,
`ZACISZE`, `KRĄG` are the vocabulary of this one.

## What this does not touch

Identifiers never move — `Zodiac.aries` carries `'Aries'`, aspects are keyed
`'conjunction'`, dimensions `'health'`, arcana `'the-fool'`. `LANGUAGES.md` §2
explains what breaks when one does, and it breaks silently and only in Polish.

The model's instructions are written in English in every language, and say so on
purpose; see `AI_FLOW.md` §6a.

## Still to do

The vocabulary above is applied. The **sentences** are not: roughly 380 strings in
`TRANSLATIONS.md` are still translated English rather than written Polish, and
they should be reread against the two tests above — the guidance and Sanctum prose
first, since those are the longest and the most read.
