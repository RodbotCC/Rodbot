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

## Next architectural direction (captured, not yet built — see TCL 0019)

Full-stack vision dropped by operator on 2026-04-19 (TCL 0019). Three tiers:

- **Claude Cowork (sweep)** — connector-driven sweeps over Close CRM (leads/opps/automations), Slack (team comms → style profiling + present-state temporal continuity), ClickUp + Google Workspace (operational accounting). One heavyweight **seeded sweep** (semi-manual, operator overwatches), then **hourly residual sweeps** on workdays that only surface what's new since the prior state.
- **Claude Code (score)** — Routines, 15/day. Takes residuals and scores them against the ledgers. Starter scoring set: North Stars, **Sales Daily + Weekly (new — requires sales-team interviews)**, Temporal Continuity, Ratio Lattice, **Open Problems (new)**.
- **Mission Control (present)** — local filesystem → GitHub → Render. Possibly runs its own Anthropic/Opus API key for live reasoning, but open question is whether Code+Routines can precompute enough that Mission Control is presentation-only and keyless. See TCL 0019 §"Open architectural questions" for Claude's current read.

Design-first still holds. No code until pieces of TCL 0019 get their own design TCLs.

## Active risks / watchpoints

- `AGENTS.md` may still reference the now-wiped pipeline. Operator will rewrite when ready.
- Homebrew `bash` is still installed (`/opt/homebrew/bin/bash`). Harmless; may or may not be useful for the next architecture. Do not uninstall unilaterally.
