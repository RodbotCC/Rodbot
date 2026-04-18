# Ratio Lattice Ledger

A scoring system that relates every ledger entry to every other, under a chosen **comparator**. Unlike a flat priority list, the lattice is *relational*: an entry's score shifts depending on what it's being compared against and under which comparator.

## v0 conventions (to be refined)

### Entry identity

Every scoreable thing has a stable ID:
- TCL sessions → `TCL-0001`, `TCL-0002`, …
- North Star goals → `NS-01`, `NS-02`, …
- Directories → `DIR-<slug>`
- Files → `F-<slug>`

### Comparator

A comparator is a named lens under which two entries can be scored against each other. Examples we expect to need:

- `goal-alignment` — how much does A advance B, where B is a North Star goal?
- `dependency` — does A need to exist before B can be built?
- `topical-overlap` — how much do A and B concern the same subject?
- `recency-weighted-relevance` — topical overlap discounted by age.

### Score

For a pair `(A, B)` under comparator `C`, emit a real number in `[-1, 1]`:
- `+1` — A strongly supports / is highly relevant to B.
- `0` — unrelated.
- `-1` — A actively works against B (conflict, regression, distraction).

### Storage

Until we have enough content to justify a real store (sqlite, embeddings, etc.), scores live in this file as a simple table:

| A | B | comparator | score | as_of | rationale |
|---|---|------------|-------|-------|-----------|

(empty for now)

## Open design questions

- Is the lattice symmetric under every comparator? (`dependency` is not; `topical-overlap` is.)
- Should scores decay with time, or only when explicitly re-scored?
- Who/what is allowed to write scores — human only, or can Claude propose and the human ratify?

These get answered when we have real entries to score.
