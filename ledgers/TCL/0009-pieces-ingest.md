---
id: 0009
slug: pieces-ingest
date: 2026-04-18
operator: rodbot (human)
assistants: Claude Code (Opus 4.7, account-swap mid-session)
status: done
---

# 0009 — Pieces memory ingest subsystem

## What happened

Operator was talking with ChatGPT about a set of Pieces-exported markdown files sitting in `Downloads/`. ChatGPT sketched an ambitious architecture — `pieces/exports/`, `pieces/normalized/`, `pieces/packets/`, `pieces/visuals/`, a pieces_memory_ledger, plus half a dozen candidate downstream visualizations (continuity timeline, decision graph, open-threads dashboard, tool-activity map, resource-review map, bootstrap storyboard). Operator asked me to follow that plan and move the files out of Downloads.

Mid-session context: the operator had to swap Claude accounts after hitting an Opus limit. This TCL entry is the second half of the work; commit `6546b5e` (Session 0008 — intake watcher) was pushed right before the swap.

**Scoping decision.** I built only `pieces/exports/` and the ledger. Deferred `normalized/`, `packets/`, and `visuals/` per the draft-and-iterate principle: none of those layers have a consumer yet, and the raw exports are grep-queryable today. Building empty storage shells before a consumer exists would lock the schema prematurely. When a consumer shows up (digest pass, dashboard, etc.), we decide shape then.

## What changed

- **New top-level dir** `pieces/exports/2026-04-18/` with the 10 Pieces markdown exports moved from `Downloads/` and renamed to `2026-04-18-HHMM-<slug>.md` (using mtime for HHMM, stripped `pieces_rodbot_` prefix, underscores → hyphens).
- **New ledger** `ledgers/pieces_memory_ledger.md` — narrative index of ingested exports, directory layout conventions, and a list of deferred downstream visualizations so the thread isn't lost.
- **Protocol update** `scripts/triage_protocol.md` — added rule 2.5 (above rule 3): Pieces exports auto-route to `pieces/exports/YYYY-MM-DD/`. Detection: filename `pieces_*.md` OR first line contains `*Shared Summary from Pieces`.
- **Allowlist update** `.gitignore` — `!pieces/` added so the new top-level dir is tracked.
- **CLAUDE.md** — added §3.6 on Pieces memory (directory layout, deferred layers, ingestion rule), added rows to the ledger table in §3, updated the Git scope line in §5.
- **Script bug fix** `scripts/audit_intake.sh` — empty-array iteration crashed under `set -u`. Fixed with `${pending[@]+"${pending[@]}"}` idiom. Now gracefully emits the "0 pending" body when watched dirs are clean.
- **10 event-log entries** appended to `ledgers/intake_events.jsonl`, one per Pieces export moved.
- **Intake state** updated: `last_swept[Downloads] = 16:55:00Z`, 10 new `known_handled_paths`.
- **Directory + contents ledgers** reflect the new `pieces/` tree.

## What we learned

1. **ChatGPT's architecture was right in direction, wrong in depth.** The `pieces/exports/` lane is correct and should have existed from the moment Pieces started running — that's the part we built today. But building `normalized/packets/visuals/` without a consumer is exactly the "lock-then-build" failure mode operator already called out in 0003. Raw markdown is enough until it isn't.
2. **Pieces exports overlap with TCL + sessions but aren't redundant.** Reviewing `2026-04-18-1249-ledger-ai-files.md` showed it captured CleanShot settings, macOS Login Items, Raycast/Wispr hotkey conflicts, Cursor/Finder activity — none of which made it into our own ledgers. The value is the *cross-tool* view we can't observe from the filesystem.
3. **Pieces exports are near-duplicates of each other.** Ten exports from 12:48–12:49 on the same day with heavily overlapping content. At scale this will need dedup. Not today.
4. **The SessionStart hook works across account swaps.** The account swap triggered a fresh session; the hook fired, ran `audit_intake.sh`, correctly reported 0 pending items (because the only remaining Downloads file — the deferred playbook — was already in `known_handled_paths`). This is the desired behavior: a swept-and-filed file should not reappear as pending.

## Next

- **Still pending from 0008:** delete `/Users/rodbot/Downloads/⭐SALES PLAYBOOK V2.0 - Comeketo Catering.txt` (byte-identical duplicate of the tracked copy). Operator hasn't signed off yet.
- **Watch the Pieces drop cadence.** Operator said they can "do this manually once a day for now." When we have a week's worth (≈70 exports if daily), consider whether the `normalized/` or `packets/` layers are worth building. Don't build them preemptively.
- **The deferred downstream visualizations** (timeline, decision graph, etc.) stay in `pieces_memory_ledger.md` as a candidate list. Any of them could become a real NS-05 sub-goal (unified weekly view) when that goal activates.
- **Carried forward:** NS-01..NS-09 ratification, Pieces MCP sanity query from a live thread (tools are available but haven't been exercised from any of my threads yet), skim `raw-ai-mission-control.html`, Ratio Lattice v0.1.
