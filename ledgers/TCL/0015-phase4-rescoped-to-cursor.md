---
id: 0015
slug: phase4-rescoped-to-cursor
date: 2026-04-19
operator: rodbot (human)
assistants: Cursor (Codex 5.3)
status: done
---

# 0015 — Rescope phase 4 to Cursor ownership

## What happened

Operator clarified architecture boundaries after a drift in session 0014:
phase 4 ("thinking" auditor work) must run in Cursor, not as a bash daemon
calling a paid API from Claude-side orchestration. This session removed the
phase-4 daemon approach and replaced it with a Cursor-owned runtime spec.

## What changed

- Deleted phase-4 daemon artifacts:
  - `scripts/moves_phase4_auditor.sh`
  - `scripts/launchd/com.rodbot.moves.phase4-auditor.plist`
  - `scripts/setup_moves_phase4_launchagent.sh`
- Added `scripts/moves_phase4_cursor_spec.md` to define the Cursor Auto-mode
  loop for inbox inspection, receipt writing, and job consumption.
- Updated `ledgers/moves/README.md` to reflect "phase 3 live + phase 4
  delegated to Cursor" and removed daemon/runtime-log references for phase 4.
- Updated `ledgers/moves/receipts/README.md` so the receipt contract is
  tooling-agnostic and Cursor-centered.
- Updated `scripts/moves_phase5_handoff.md` wording to align with a
  Cursor-generated phase-4 receipt stream.
- Added `ledgers/current_state.md` as a concise operator-facing markdown
  snapshot of overall pipeline status and next sequence.
- Updated `CLAUDE.md` open queue entry for phase 4 to reference Cursor spec
  instead of `ANTHROPIC_API_KEY` + launchd bring-up.
- Updated `.gitignore` to remove no-longer-used phase-4 daemon runtime
  artifacts.
- Updated `ledgers/contents_ledger.md` entries for the above adds/deletes.

## What we learned

1. Pipeline stages should be split by function type, not by "what was easiest
   to script first." Deterministic IO plumbing (phases 1-3) belongs in daemon
   bash; judgment stages (phase 4) belong in Cursor per operator cost model.
2. Architecture drift can happen even with a strong TCL discipline; the fix is
   to write an explicit rescope TCL immediately so future threads do not
   recover stale assumptions.

## Next

- Run phase 4 in Cursor Auto mode using `scripts/moves_phase4_cursor_spec.md`.
- Keep soaking phases 1-3 under launchd.
- Proceed to phase 5 implementation in Cursor using `scripts/moves_phase5_handoff.md`.
