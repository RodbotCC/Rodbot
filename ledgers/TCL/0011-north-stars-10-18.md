---
id: 0011
slug: north-stars-10-18
date: 2026-04-18
operator: rodbot (human)
assistants: Claude Code (Opus 4.7)
status: done
---

# 0011 — North Stars NS-10..NS-18

## What happened

Operator drafted 9 additional North Stars in professionally-structured prose, covering awareness, trust, and execution-architecture dimensions the original NS-01..NS-09 didn't directly name. On first read, the writeups referenced a substantial architecture stack — `world.json`, predictive-processing modules, metacognition, packet lanes, Sales Oracle internals, the 2,032-message analysis — that is *not* present in RodBot's on-disk doctrine. I flagged the mismatch. Operator confirmed that was doctrine from a separate experimental build (Delta / Sylvia) on another machine, and instructed a three-tier separation: keep the ideas, strip Delta implementation language, phrase everything in RodBot-native terms, and mark the batch as principles-not-claims.

## What changed

- **`ledgers/north_star.md`** — appended NS-10..NS-18 with a shared implementation note at the top of the batch making the Delta/RodBot separation explicit. Each NS rewritten in RodBot-native terms (no references to `world.json`, packet lanes, predictive-processing, metacognition, Sales Oracle internals, the 2,032-message corpus, or the 10-module stack). Claude-drafted importances, all `pending ratification` like NS-01..NS-09.
- **`CLAUDE.md` §7** — updated cluster summary (18 NSes, 6 clusters now: revenue-side / operating-surface / awareness / trust / execution-architecture / enabling-meta). Added a one-line Delta-separation caveat.
- **`contents_ledger.md`** — updated the north_star.md entry to NS-01..NS-18.

## Reconciliation done before writing

Checked each of the 9 incoming goals against NS-01..NS-09 for merge opportunities. Closest rhymes and why they stayed separate:
- **NS-16 (Trigger Bus) vs NS-08 (RodBot syndication)** — NS-08 is reach (every tool is a syndicated entry point); NS-16 is routing (events → jobs → runners without collisions). Different architectural layers. NS-16 is partly *how* NS-08 gets realized.
- **NS-10 (Shared Op Awareness) vs NS-05 (unified weekly view)** — NS-05 is a specific Monday surface (cash/labor/jobs/prep); NS-10 is a continuous delta stream across the whole operating surface. Different shapes.
- **NS-12 (Style-Aware Drafting) vs NS-01 (speed-to-lead)** — NS-12 could power NS-01's first-touch at scale, but it's horizontal and serves NS-01, NS-02, NS-03, NS-07 equally. Separate capability.

Result: 9 net-new, 0 merges. Re-clustering added *awareness*, *trust*, and *execution-architecture* tiers alongside the original revenue/operating-surface/enabling-meta groups.

## What we learned

1. **Doctrine imported from another project needs a customs check.** The first pass of NS-10..NS-18 treated Delta architecture as if it were already RodBot-canonical. Catching that before writing saved a conceptual mess — once Delta internals show up in the North Stars, later code starts being written *against* architecture RodBot doesn't actually have. The fix was cheap because nothing had been committed yet; at +1 session it would have been much harder.
2. **"Are those things captured on disk?" is the right load-bearing question.** This will recur every time the operator wants to import ideas from another machine, thread, or notebook. The correct default: if a North Star depends on doctrine that isn't in `ledgers/` or `intake/`, either ingest the doctrine first, or soften the goal to be substrate-agnostic.
3. **Claude-drafted importances are a forcing function.** Having to pick 0.6 vs 0.85 made me re-read each writeup with a critical eye instead of just transcribing. Two goals (NS-13, NS-15) read differently once I was forced to rank them. The operator should still overwrite any of these they disagree with — but the drafted numbers are a better starting point than leaving them blank.

## Next

- **Operator ratification** of NS-01..NS-18 is still open (mirrored in CLAUDE.md §9). This is now a bigger batch than session 0003's carry-forward; worth a dedicated read-through.
- **Delta doctrine import is out-of-scope by default.** If/when a specific Delta artifact (e.g. a `world.json` schema, a packet-lane protocol, a Sales Oracle voice profile) is worth bringing across, it should come through `intake/YYYY-MM-DD-delta-port-<slug>/` with its own TCL, not by slipping references into existing docs.
- **Ratio Lattice v0.1** now has a richer target set — 18 NSes instead of 9 — which may actually unblock it: more goals means more scoring pairs, which was the gating condition from session 0003's Next.
