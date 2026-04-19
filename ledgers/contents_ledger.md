# Contents Ledger

One line per file under `/Users/rodbot/`.

Format: `path — one-sentence purpose`.

Update rule: any file created/renamed/deleted → update in the same session it happened.

## Entries

- `README.md` — top-level description of RodBot, its principles, and the ledger map.
- `AGENTS.md` — Cursor-specific operating guide for rebooting threads and resuming from current TCL/North Star context.
- `CLAUDE.md` — orientation manual loaded into every Claude Code session on this machine (via symlink at ~/.claude/CLAUDE.md). Canonical source of truth for operating rules on RodBot.
- `.gitignore` — allowlist config; ignores everything in `$HOME` except core tracked roots (`README.md`, `AGENTS.md`, `CLAUDE.md`, `ledgers/`, `intake/`, `scripts/`, `pieces/`).
- `ledgers/TCL/README.md` — defines the TCL entry format and its load-bearing role.
- `ledgers/TCL/0001-birth.md` — first session; records the founding vision and the creation of this scaffold.
- `ledgers/TCL/0002-pieces-mcp.md` — wires up the Pieces MCP server as the first ingress; pending Claude Code restart.
- `ledgers/TCL/0003-north-star-draft.md` — drafts NS-01..NS-09 from Comeketo source material; pending operator ratification.
- `ledgers/TCL/0004-flatten-root.md` — flattens the redundant `RodBot/` nesting up into `$HOME`; the machine *is* RodBot.
- `ledgers/TCL/0005-github-live.md` — repo under version control at RodbotCC/Rodbot; allowlist .gitignore; flags tracked-`Downloads/` divergence risk.
- `ledgers/TCL/0006-downloads-to-intake.md` — resolves the Downloads divergence: moves intake material into `intake/` and removes `Downloads/` from the repo.
- `ledgers/TCL/0007-claude-md-global.md` — writes global CLAUDE.md orientation manual; symlinked from ~/.claude/CLAUDE.md, tracked at repo root.
- `ledgers/TCL/0008-intake-watcher.md` — HISTORICAL. Built the legacy `audit_intake.sh` SessionStart hook + triage protocol + first sweep. Wiped in session 0018.
- `ledgers/TCL/0009-pieces-ingest.md` — sets up the `pieces/` subsystem and ingests the first drop of 10 Pieces exports.
- `ledgers/TCL/0010-screenshot-naming.md` — drops the `screenshot-YYYY-MM-DD-HHMM-` prefix from screenshot filenames; the slug is now the whole name.
- `ledgers/TCL/0011-north-stars-10-18.md` — drafts NS-10..NS-18 in RodBot-native terms; separates from Delta-side experimental architecture; all pending ratification.
- `ledgers/TCL/0012-moves-pipeline-scaffold.md` — HISTORICAL. Scaffolds phases 1–3 of the filesystem-trigger pipeline. Pipeline wiped in session 0018.
- `ledgers/TCL/0013-moves-phases-1-2-live.md` — HISTORICAL. Phases 1+2 live under launchd. Pipeline wiped in session 0018.
- `ledgers/TCL/0014-phase3-tcc-fix-and-phase4-auditor.md` — HISTORICAL. Phase 3 TCC + SIGPIPE fix; phase 4 auditor built then deleted. Pipeline wiped in session 0018.
- `ledgers/TCL/0015-phase4-rescoped-to-cursor.md` — HISTORICAL. Retires phase-4 bash daemon for Cursor-owned spec. Pipeline wiped in session 0018.
- `ledgers/TCL/0016-phase5-mover-implementation.md` — HISTORICAL. Phase 5 mover built by Cursor. Pipeline wiped in session 0018.
- `ledgers/TCL/0017-phase1-watch-scope-three-folders.md` — HISTORICAL. Phase 1 watch scope narrowed. Pipeline wiped in session 0018.
- `ledgers/TCL/0018-wipe-moves-pipeline.md` — wipes the entire 5-phase filesystem-trigger pipeline + legacy `audit_intake.sh` hook to reset with clean eyes; next triage architecture will be a Claude Code Routine (scheduled, hourly, single-agent), to be designed in a later session.
- `ledgers/sessions/README.md` — defines the session-entry granularity (diary, one per working period) as distinct from TCL (commit log, one per action-unit).
- `ledgers/sessions/0001-birth-and-bootstrap.md` — narrative of the full 2026-04-17/18 bootstrap session; covers TCL 0001–0007 as one arc.
- `ledgers/directory_ledger.md` — this system's map of directories.
- `ledgers/contents_ledger.md` — this file; map of file purposes.
- `ledgers/ratio_lattice.md` — scoring system relating ledger entries to each other (v0 conventions).
- `ledgers/north_star.md` — the goals RodBot is built to achieve; NS-01..NS-18 drafted, all pending operator ratification.
- `ledgers/current_state.md` — operator-facing markdown snapshot of current system state.
- `ledgers/pieces_memory_ledger.md` — narrative index of Pieces exports ingested; describes the third-party memory feed and directory layout.
- `intake/2026-04-17-bootstrap/extraction-section-*.txt` — seven per-section extracts of the business Extraction doc (visual-readability, jobs-events-detailed, overall-shape, sales-lead-mgmt, scheduling, calendar, weekly-labor).
- `intake/2026-04-17-bootstrap/pasted-text-1.txt`, `pasted-text-2.txt` — two clipboard-sourced notes from the bootstrap upload.
- `intake/2026-04-17-bootstrap/raw-ai-mission-control.html` — "RAW AI Mission Control" dashboard concept from prior iterations; informs any future unified-weekly-view design.
- `intake/2026-04-17-bootstrap/⭐SALES PLAYBOOK V2.0 - Comeketo Catering.txt` — Comeketo's inbound sales playbook V2.0 (SDR/Closer roles, 5-min speed-to-lead, tasting pipeline, Close CRM SOPs).
- `intake/2026-04-17-bootstrap/Tasting.txt` — Rodrigo's narrated walkthrough of the Comeketo tasting experience.
- `intake/2026-04-17-bootstrap/Extraction.txt` — 33-point analysis of the business's current operating shape; key framing: "manually overextended, not broken."
- `intake/screenshots/2026-04/claude-rodbot-setup-questions.{png,json}` — Claude Code session asking RodBot setup clarifying questions; sidecar holds title/summary/tags.
- `intake/screenshots/2026-04/rodbot-origin-diagram.{png,json}` — whiteboard timeline of RodBot's birth arc; sidecar holds title/summary/tags.
- `pieces/exports/2026-04-18/2026-04-18-HHMM-<slug>.md` — 10 Pieces-curated session summaries covering the 2026-04-17/18 bootstrap arc (project-initiation/initialization, system-setup, infrastructure-setup, ai-setup + ai-setup-complete, setup-ai-comm, project-setup + project-setup-analysis, ledger-ai-files).
