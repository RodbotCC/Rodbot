# Contents Ledger

One line per file under `/Users/rodbot/`.

Format: `path — one-sentence purpose`.

Update rule: any file created/renamed/deleted → update in the same session it happened.

## Entries

- `README.md` — top-level description of RodBot, its principles, and the ledger map.
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
- `.gitignore` — allowlist config; ignores everything in `$HOME` except `README.md`, `ledgers/`, `intake/`.
- `intake/2026-04-17-bootstrap/⭐SALES PLAYBOOK V2.0 - Comeketo Catering.txt` — Comeketo's inbound sales playbook V2.0 (SDR/Closer roles, 5-min speed-to-lead, tasting pipeline, Close CRM SOPs).
- `intake/2026-04-17-bootstrap/Tasting.txt` — Rodrigo's narrated walkthrough of the Comeketo tasting experience.
- `intake/2026-04-17-bootstrap/Extraction.txt` — 33-point analysis of the business's current operating shape; key framing: "manually overextended, not broken."
- `ledgers/directory_ledger.md` — this system's map of directories.
- `ledgers/contents_ledger.md` — this file; map of file purposes.
- `ledgers/ratio_lattice.md` — scoring system relating ledger entries to each other (v0 conventions).
- `ledgers/north_star.md` — the goals RodBot is built to achieve; NS-01..NS-09 drafted, pending operator ratification.
