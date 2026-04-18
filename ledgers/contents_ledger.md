# Contents Ledger

One line per file under `/Users/rodbot/`.

Format: `path — one-sentence purpose`.

Update rule: any file created/renamed/deleted → update in the same session it happened.

## Entries

- `README.md` — top-level description of RodBot, its principles, and the ledger map.
- `AGENTS.md` — Cursor-specific operating guide for rebooting threads and resuming from current TCL/North Star context.
- `ledgers/TCL/README.md` — defines the TCL entry format and its load-bearing role.
- `ledgers/TCL/0001-birth.md` — first session; records the founding vision and the creation of this scaffold.
- `ledgers/TCL/0002-pieces-mcp.md` — wires up the Pieces MCP server as the first ingress; pending Claude Code restart.
- `ledgers/TCL/0003-north-star-draft.md` — drafts NS-01..NS-09 from Comeketo source material; pending operator ratification.
- `ledgers/TCL/0004-flatten-root.md` — flattens the redundant `RodBot/` nesting up into `$HOME`; the machine *is* RodBot.
- `ledgers/TCL/0005-github-live.md` — repo under version control at RodbotCC/Rodbot; allowlist .gitignore; flags tracked-`Downloads/` divergence risk.
- `ledgers/TCL/0006-downloads-to-intake.md` — resolves the Downloads divergence: moves intake material into `intake/` and removes `Downloads/` from the repo.
- `ledgers/TCL/0007-claude-md-global.md` — writes global CLAUDE.md orientation manual; symlinked from ~/.claude/CLAUDE.md, tracked at repo root.
- `ledgers/sessions/README.md` — defines the session-entry granularity (diary, one per working period) as distinct from TCL (commit log, one per action-unit).
- `ledgers/sessions/0001-birth-and-bootstrap.md` — narrative of the full 2026-04-17/18 bootstrap session; covers TCL 0001–0007 as one arc.
- `CLAUDE.md` — orientation manual loaded into every Claude Code session on this machine (via symlink at ~/.claude/CLAUDE.md). Canonical source of truth for operating rules on RodBot.
- `intake/2026-04-17-bootstrap/extraction-section-*.txt` — seven per-section extracts of the business Extraction doc (visual-readability, jobs-events-detailed, overall-shape, sales-lead-mgmt, scheduling, calendar, weekly-labor).
- `intake/2026-04-17-bootstrap/pasted-text-1.txt`, `pasted-text-2.txt` — two clipboard-sourced notes from the bootstrap upload.
- `intake/2026-04-17-bootstrap/raw-ai-mission-control.html` — "RAW AI Mission Control" dashboard concept from prior iterations; informs any future unified-weekly-view design.
- `.gitignore` — allowlist config; ignores everything in `$HOME` except core tracked roots (`README.md`, `AGENTS.md`, `CLAUDE.md`, `ledgers/`, `intake/`, `scripts/`, `pieces/`).
- `scripts/moves_phase1_detector.sh` — phase-1 filesystem detector; runs `fswatch` on an allowlist and appends raw events to `ledgers/moves/events.log`.
- `scripts/moves_phase2_debouncer.sh` — phase-2 stream processor; tails `events.log`, debounces/coalesces file events, filters hard-noise, and writes settled JSONL lines to `ledgers/moves/settled.log`.
- `scripts/moves_phase3_inbox_writer.sh` — phase-3 inbox writer; reads `settled.log` by byte cursor, hashes files, deduplicates, and writes atomic `ledgers/moves/inbox/<id>.json` jobs.
- `scripts/launchd/com.rodbot.moves.phase1-detector.plist` — launchd LaunchAgent definition for phase-1 detector autostart/restart.
- `scripts/launchd/com.rodbot.moves.phase2-debouncer.plist` — launchd LaunchAgent definition for phase-2 debouncer autostart/restart.
- `scripts/launchd/com.rodbot.moves.phase3-inbox-writer.plist` — launchd LaunchAgent definition for phase-3 inbox-writer autostart/restart.
- `scripts/setup_moves_phase1_launchagent.sh` — helper to install/reload the phase-1 LaunchAgent into `~/Library/LaunchAgents/`.
- `scripts/setup_moves_phase2_launchagent.sh` — helper to install/reload the phase-2 LaunchAgent into `~/Library/LaunchAgents/`.
- `scripts/setup_moves_phase3_launchagent.sh` — helper to install/reload the phase-3 LaunchAgent into `~/Library/LaunchAgents/`.
- `ledgers/moves/README.md` — phase status, kill-switch behavior, and runtime artifact map for the filesystem-trigger pipeline.
- `intake/2026-04-17-bootstrap/⭐SALES PLAYBOOK V2.0 - Comeketo Catering.txt` — Comeketo's inbound sales playbook V2.0 (SDR/Closer roles, 5-min speed-to-lead, tasting pipeline, Close CRM SOPs).
- `intake/2026-04-17-bootstrap/Tasting.txt` — Rodrigo's narrated walkthrough of the Comeketo tasting experience.
- `intake/2026-04-17-bootstrap/Extraction.txt` — 33-point analysis of the business's current operating shape; key framing: "manually overextended, not broken."
- `ledgers/directory_ledger.md` — this system's map of directories.
- `ledgers/contents_ledger.md` — this file; map of file purposes.
- `ledgers/ratio_lattice.md` — scoring system relating ledger entries to each other (v0 conventions).
- `ledgers/north_star.md` — the goals RodBot is built to achieve; NS-01..NS-18 drafted, all pending operator ratification.
- `ledgers/TCL/0008-intake-watcher.md` — builds the intake watcher: detection script, triage protocol, SessionStart hook, first sweep.
- `ledgers/intake_ledger.md` — narrative index of every intake sweep (grouped events, rationale, open questions).
- `ledgers/intake_events.jsonl` — append-only JSONL event log; one object per file triaged.
- `ledgers/intake_state.json` — state file for the watcher (watched dirs, last_swept timestamps, known_handled_paths).
- `scripts/triage_protocol.md` — v0 rules for categorizing files landing in watched dirs (hard-noise, screenshots, business source, installers, etc.).
- `scripts/audit_intake.sh` — detection script; enumerates pending files and emits SessionStart `additionalContext` JSON.
- `intake/screenshots/2026-04/claude-rodbot-setup-questions.{png,json}` — Claude Code session asking RodBot setup clarifying questions; sidecar holds title/summary/tags.
- `intake/screenshots/2026-04/rodbot-origin-diagram.{png,json}` — whiteboard timeline of RodBot's birth arc; sidecar holds title/summary/tags.
- `ledgers/TCL/0009-pieces-ingest.md` — sets up the `pieces/` subsystem and ingests the first drop of 10 Pieces exports.
- `ledgers/TCL/0010-screenshot-naming.md` — drops the `screenshot-YYYY-MM-DD-HHMM-` prefix from screenshot filenames; the slug is now the whole name.
- `ledgers/TCL/0011-north-stars-10-18.md` — drafts NS-10..NS-18 in RodBot-native terms; separates from Delta-side experimental architecture; all pending ratification.
- `ledgers/TCL/0012-moves-pipeline-scaffold.md` — scaffolds phases 1–3 of the filesystem-trigger pipeline (detector, debouncer, inbox-writer) built by Cursor from Claude Code specs; propagates no-date-folders and move-not-copy preferences into the triage protocol; live bring-up and soak pending.
- `ledgers/pieces_memory_ledger.md` — narrative index of Pieces exports ingested; describes the third-party memory feed and directory layout.
- `pieces/exports/2026-04-18/2026-04-18-HHMM-<slug>.md` — 10 Pieces-curated session summaries covering the 2026-04-17/18 bootstrap arc (project-initiation/initialization, system-setup, infrastructure-setup, ai-setup + ai-setup-complete, setup-ai-comm, project-setup + project-setup-analysis, ledger-ai-files).
