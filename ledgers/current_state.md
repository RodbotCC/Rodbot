# Current State Snapshot

Last updated: 2026-04-19

## Where we are now

- RodBot runs as a staged filesystem pipeline with deterministic plumbing in bash and judgment stages delegated to Cursor.
- Phase ownership is clarified:
  - Claude Code: orchestrator/spec/checkpointing.
  - Cursor (Auto preset): file inspection, classification, receipt generation, mover implementation work.
  - Codex: expensive CRM sweeps (separate track).

## Moves pipeline status

### Phase 1 — Detector

- Status: live.
- Component: `scripts/moves_phase1_detector.sh`
- LaunchAgent: `com.rodbot.moves.phase1-detector`
- Output: `ledgers/moves/events.log`
- Notes: allowlist watchers are active; pipeline kill switch is `ledgers/moves/PAUSED`.

### Phase 2 — Debouncer/filter

- Status: live.
- Component: `scripts/moves_phase2_debouncer.sh`
- LaunchAgent: `com.rodbot.moves.phase2-debouncer`
- Output: `ledgers/moves/settled.log`
- Notes: Bash-3.2 timeout issue was fixed; stream emits settled JSON lines.

### Phase 3 — Inbox writer

- Status: live.
- Component: `scripts/moves_phase3_inbox_writer.sh`
- LaunchAgent: `com.rodbot.moves.phase3-inbox-writer`
- Output: `ledgers/moves/inbox/<id>.json`, `duplicates.log`, `vanished.log`
- Notes: IDs are SHA-256-derived (first 12 chars); dedup and sensitivity heuristic are active.

### Phase 4 — Auditor

- Status: delegated to Cursor (not a bash daemon).
- Runtime policy:
  - Use Cursor model preset `Auto` for this loop.
  - Avoid `Premium` unless operator explicitly asks for escalation.
- Spec: `scripts/moves_phase4_cursor_spec.md`
- Output contract: `ledgers/moves/receipts/<id>.md` per `ledgers/moves/receipts/README.md`

### Phase 5 — Mover

- Status: final build phase pending.
- Handoff spec: `scripts/moves_phase5_handoff.md`
- Goal: execute receipt dispositions, update `phase5_status`, append to `ledgers/moves/index.jsonl`.

## Key architecture decisions locked

- No date-prefixed folder naming for new intake destinations; use slug-led naming.
- Move-not-copy is the default intake behavior.
- Phase 4 remains Cursor-owned to preserve the low-cost Auto-mode workflow.
- Phase 5 remains Cursor-build from the established receipt contract.

## Immediate next sequence

1. Keep phases 1-3 soaking live.
2. Run phase 4 in Cursor Auto mode against inbox jobs.
3. Implement phase 5 mover in Cursor from handoff spec.
4. Certify full chain with smoke matrix.
5. Retire legacy `audit_intake.sh` hook only after clean 24h phase-5 soak.

## Open risks / watchpoints

- `Photos Library.photoslibrary` churn should be filtered at detector level to reduce noise volume.
- After Homebrew upgrades, re-check Full Disk Access for `/opt/homebrew/bin/bash` if launchd behavior regresses.
- Avoid architecture drift: keep phase-4 logic in Cursor spec/session, not in new bash daemons.
