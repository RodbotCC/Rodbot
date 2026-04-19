---
id: 0018
slug: wipe-moves-pipeline
date: 2026-04-19
operator: rodbot (human)
assistants: Claude Code (Opus 4.7, 1M context)
status: done
---

# 0018 — Wipe the entire moves pipeline; clean slate for Routines-based reset

## What happened

Operator ended the moves-pipeline arc by requesting a full nuke: all 5
phases, all LaunchAgents, the legacy `audit_intake.sh` SessionStart hook,
the `ledgers/moves/` workspace, the triage protocol document — everything
that constituted the filesystem-trigger pipeline built across sessions
0008 and 0012–0017. Operator's framing: *"I don't want to juggle the
thing we had with the thing we're going to do."* Trying to design the
next approach while the old one sat on disk was causing cognitive load
and friction, with zero upside because the old approach was already
decided-to-be-replaced.

The wipe was preceded by an arc of architectural flip-flops all in the
service of answering "who runs the thinking layer (phase 4)?":

1. **Session 0014:** built phase 4 as a bash daemon calling the Anthropic
   API. Wrong — metered billing violated the operator's flat-rate-tools-only
   cost model.
2. **Session 0015 (Cursor):** rescoped phase 4 to Cursor-owned Auto-mode
   loop, fixing the cost problem.
3. **Mid-session 0018 (before the wipe):** realized the Cursor-owned runtime
   was architecturally worse than the cost bug it fixed — Cursor is not a
   daemon, it requires a human-attended session, it can't soak, it has no
   auto-restart or observable error handling. Proposed flipping back to a
   bash daemon on OpenAI's Responses API using operator's prepaid credits
   (a third architecture).
4. **Operator intervention:** called out the flip-flopping, reminded Claude
   that **every decision and captured idea must land in a ledger before any
   action**, and then unlocked the actual right answer — Claude Code
   **Routines** (released ~4 days ago per operator). 15 scheduled runs/day,
   hourly batch sweeps during working hours, one agent doing everything
   (inspect, classify, move, index, commit) with full connector access
   (Slack, ClickUp, Close, Calendar), native to the Claude Code infrastructure.
5. **Reset decision:** rather than migrate the old pipeline to the new
   shape, wipe it entirely. Clean eyes for the new design.

## What changed

### Removed (scripts)

- `scripts/moves_phase1_detector.sh`
- `scripts/moves_phase2_debouncer.sh`
- `scripts/moves_phase3_inbox_writer.sh`
- `scripts/moves_phase5_mover.sh`
- `scripts/setup_moves_phase1_launchagent.sh`
- `scripts/setup_moves_phase2_launchagent.sh`
- `scripts/setup_moves_phase3_launchagent.sh`
- `scripts/setup_moves_phase5_launchagent.sh`
- `scripts/moves_phase4_cursor_spec.md`
- `scripts/moves_phase5_handoff.md`
- `scripts/audit_intake.sh` (legacy intake watcher)
- `scripts/triage_protocol.md` (legacy classification rules)
- `scripts/launchd/` (directory + all four plist templates)

### Removed (ledger runtime)

- `ledgers/moves/` (entire subtree — events.log, settled.log, inbox/,
  receipts/, index.jsonl, duplicates.log, vanished.log, phase*.stdout/stderr
  logs, .phase3-cursor, .phase2-pending/, .auditor-attempts/, README)
- `ledgers/intake_ledger.md`
- `ledgers/intake_events.jsonl`
- `ledgers/intake_state.json`

### Removed (live system)

- `~/Library/LaunchAgents/com.rodbot.moves.phase1-detector.plist` (after
  `launchctl bootout`)
- `~/Library/LaunchAgents/com.rodbot.moves.phase2-debouncer.plist` (after
  `launchctl bootout`)
- `~/Library/LaunchAgents/com.rodbot.moves.phase3-inbox-writer.plist` (after
  `launchctl bootout`)
- Verified via `launchctl list | grep rodbot.moves` — none remain.
- `~/.claude/settings.local.json` SessionStart hook block removed (the hook
  that ran `audit_intake.sh` on every Claude Code boot). Permissions array
  also pruned of entries that were specific to pipeline debugging.

### Removed (intake residue)

- `intake/phase5-smoke/` (Cursor's synthetic phase-5 smoke-test artifacts)

### Updated (in-place edits)

- `.gitignore` — pruned all `ledgers/moves/*` runtime-artifact entries.
  Reverts to the minimal allowlist+noise-patterns shape.
- `CLAUDE.md` — removed §3.5 (intake watcher); renumbered §3.6 (Pieces
  memory) to §3.5; simplified the Pieces paragraph now that it no longer
  references the retired triage protocol. Removed the stale open-queue
  items about phases 4/5 and the retire-hook task; added a single new
  open-queue line pointing at "design the intake/triage system from clean
  slate." Removed `Intake Ledger` row from the ledger discipline table.
- `ledgers/contents_ledger.md` — removed every entry for a deleted file;
  marked TCLs 0008 and 0012–0017 as HISTORICAL (pipeline wiped in
  session 0018) so future sessions don't get confused about whether those
  artifacts still exist.
- `ledgers/directory_ledger.md` — removed `ledgers/moves/` subtree,
  `scripts/launchd/`, and `intake/phase5-smoke/` entries. Noted
  `scripts/` as "currently empty after session 0018 wipe."
- `ledgers/current_state.md` — rewrote entirely to reflect clean-slate
  state, what's still standing, what's gone, and the next architectural
  direction (not yet designed).

### Preserved (history intact)

- All TCL entries (0001–0017), including the ones describing the built
  and now-wiped pipeline. The TCLs ARE the history; deleting them would
  erase the reasoning that produced both the build and the wipe. Marked
  them HISTORICAL in the contents ledger so their status is unambiguous.
- All North Stars (NS-01..NS-18).
- All memory files in `~/.claude/projects/-Users-rodbot/memory/`.
- `intake/2026-04-17-bootstrap/`, `intake/screenshots/2026-04/`,
  `pieces/exports/2026-04-18/` — all content unchanged.
- Homebrew + `/opt/homebrew/bin/bash` — left installed. Harmless; may
  or may not be useful for the next architecture.
- `AGENTS.md` — operator-authored, untouched. May still reference the
  retired pipeline; operator will rewrite when ready.

### Preserved through a pre-wipe commit

Commit before this one: `Session 0017-catchup: preserve pipeline state
before reset` — captured all of Cursor's in-flight work (TCL 0016/0017,
phase 5 mover code, smoke-test artifacts) in git history before deleting.
Allows `git log --follow` to trace the pipeline's full lifecycle if
anyone ever needs to resurrect reasoning from the old design.

## What we learned

1. **If architecture flip-flops twice in one session, that's the signal
   to reset, not to flip-flop a third time.** Two flips = "we might not
   have the right question yet." The third flip would have been
   rebuilding in bash-on-OpenAI. The reset uncovered that the real
   question was "does this need to be real-time at all?" The answer was
   no, and once the answer was no, the whole 5-phase scaffolding became
   unnecessary.

2. **Real-time-event-driven was never actually required.** Every friction
   point the pipeline hit (TCC, SIGPIPE, runtime fragility, Cursor
   ownership, background polling design) was a consequence of
   "always-on event-driven" being the starting assumption. The operator
   never asked for instant triage; he asked for nothing-gets-lost triage.
   Batch-hourly delivers the second without the first's complexity.

3. **Claude Code Routines (released mid-April 2026) changes the shape
   of "always-on auditor" work.** A scheduled agent with full connector
   access replaces the need for a bash-daemon + API-call architecture
   entirely. This is worth capturing as a capability (see §Next below —
   a capabilities ledger is queued as its own task).

4. **Ledger discipline must include destruction, not just creation.**
   Wiping code without writing the reasoning TCL would erase the most
   valuable artifact of this whole arc — the reasoning. TCL 0018 is
   specifically the reason the pipeline's absence is *intelligible* to
   future sessions rather than mysterious.

5. **The operator-yelled rule matters:** *"EVERY SINGLE THING WE DO
   WHETHER IT IS BUILD A ROCKETSHIP OR MOVE A FILE needs to be reflected
   in the LEDGERS."* This was called out earlier in this session after
   noticing three architecture decisions had landed without a Claude-
   authored TCL. This TCL 0018, plus 0017-catchup preserving the prior
   state, plus a queued `ledgers/capabilities.md` or equivalent, are the
   response.

## Next

- **(design, next action-unit)** Design the Claude Code Routines–based
  intake/triage architecture. In scope for that design TCL:
  - Cadence and routine-count budget (15/day)
  - Folder topology (destinations, slug conventions, screenshot month-folders, Pieces export handling)
  - Routine prompt (reads as system prompt; reuses rules content from the
    deleted triage_protocol.md as a design reference but does not inherit
    it wholesale)
  - Deletion authority (what routine can delete silently vs surface)
  - Sweep-log format (one markdown entry per run? append-only JSONL? both?)
  - Git-commit cadence per sweep
  - What replaces the old SessionStart hook (if anything)
  - Status-surface for operator (how do I see "last sweep ran at X, Y files handled"?)
- **(deferred)** Add a `ledgers/capabilities.md` (or per-tool files under
  `ledgers/tools/`) capturing OpenAI / Claude / Cursor / Codex / Pieces
  capability surface + current bindings + noted-for-later items. This was
  proposed mid-session but not executed; queuing explicitly so it's not
  forgotten.
- **(carry-forward, unchanged)** NS-01..NS-18 ratification, Pieces MCP
  sanity query, Ratio Lattice v0.1, `extraction-section-*` dedup check,
  raw-ai-mission-control skim.
