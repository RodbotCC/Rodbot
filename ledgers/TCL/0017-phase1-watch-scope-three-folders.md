---
id: 0017
slug: phase1-watch-scope-three-folders
date: 2026-04-19
operator: rodbot (human)
assistants: Cursor (Codex 5.3)
status: done
---

# 0017 — Narrow phase-1 watch scope to three ingress folders

## What happened

Operator confirmed the correct phase-1 automation boundary for now is three
high-signal ingress folders: `Desktop`, `Downloads`, and `Documents`. This
session tightened the detector allowlist to those three paths and removed the
carry-forward queue item about Photos Library churn, since that noise source
is no longer in scope.

## What changed

- `scripts/moves_phase1_detector.sh` watch list narrowed from seven folders
  (`Downloads`, `Desktop`, `Documents`, `Pictures`, `Movies`, `Music`, `Public`)
  to three:
  - `/Users/rodbot/Desktop`
  - `/Users/rodbot/Downloads`
  - `/Users/rodbot/Documents`
- `ledgers/current_state.md` updated to record the narrowed scope as an
  intentional architecture decision.
- `ledgers/moves/README.md` updated with explicit phase-1 watch scope.
- `CLAUDE.md` open queue updated: removed the old "Phase 1 Photos Library
  filter" task because the source folder is no longer watched.

## What we learned

1. Full-home watch ambition is better served by a separate sweeper lane than
   by expanding the live detector ingress scope.
2. Narrow ingress scope materially reduces loop risk and false-positive
   automations while phase 4/5 are still being certified.

## Next

- Reload phase-1 LaunchAgent so running detector process picks up the new
  three-folder watch list.
- Continue phase-4 Cursor run + phase-5 certification against this narrowed
  ingress boundary.
