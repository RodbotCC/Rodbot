# Current State Snapshot

Last updated: 2026-04-19 (post-wipe)

## Where we are now

**Clean slate.** The 5-phase filesystem-trigger pipeline built across sessions 0012–0017 was wiped in session 0018. All bash daemons, LaunchAgents, inbox/receipts/index workspace, and the legacy `audit_intake.sh` SessionStart hook are gone. The TCL entries documenting what was built and what we learned remain as history.

## What's still standing

- **Ledger discipline** — TCL, sessions, directory ledger, contents ledger, ratio lattice, north stars, pieces memory ledger. All intact.
- **North Stars** — NS-01..NS-18 drafted, pending ratification. Unchanged by the wipe.
- **Pieces memory ingest** — `pieces/exports/` subsystem still works as the third-party continuity feed. Operator exports Pieces summaries into dated subfolders.
- **Intake folder** — `intake/` still exists as the destination for curated material. `intake/2026-04-17-bootstrap/` (legacy date-folder, grandfathered) and `intake/screenshots/2026-04/` are preserved.
- **Git repo + GitHub remote** — `RodbotCC/Rodbot` public, main branch, unchanged.
- **Claude Code connectors** — ClickUp, Close, Google Calendar, Slack, Pieces, etc. all still present.
- **MCP servers** — Pieces at `http://localhost:39300/...` and managed-plugin MCPs untouched.

## What's gone

- All five phases of the old moves pipeline (detector, debouncer, inbox writer, Cursor-auditor spec, mover).
- All moves-pipeline LaunchAgents and their plists (both repo templates and live versions under `~/Library/LaunchAgents/`).
- The `ledgers/moves/` workspace (events.log, settled.log, inbox/, receipts/, index.jsonl, all runtime artifacts).
- `ledgers/intake_ledger.md`, `intake_events.jsonl`, `intake_state.json` (legacy intake-watcher state).
- `scripts/audit_intake.sh`, `scripts/triage_protocol.md` (legacy rules and ingress script).
- `~/.claude/settings.local.json` SessionStart hook removed.

## Next architectural direction (not yet designed)

- The new triage/intake approach will be a **Claude Code Routine** — scheduled, hourly batch sweep, single agent with full toolchain (filesystem + connectors). Not always-on, not event-driven. Explicit batching is a feature: files stay put while the operator is working, then get swept to their destinations during scheduled windows.
- Claude Code Routines allow 15 scheduled runs per day — enough for hourly coverage during working hours.
- Design work (cadence, folder topology, routine prompt, deletion authority, sweep-log format) is the next action-unit. Design first, then build. No code should be written until the design lands in a TCL.

## Active risks / watchpoints

- `AGENTS.md` may still reference the now-wiped pipeline. Operator will rewrite when ready.
- Homebrew `bash` is still installed (`/opt/homebrew/bin/bash`). Harmless; may or may not be useful for the next architecture. Do not uninstall unilaterally.
