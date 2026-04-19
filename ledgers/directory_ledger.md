# Directory Ledger

Every directory and subdirectory under `/Users/rodbot/` (and eventually the broader user folder, once we open that scope) gets a line here.

Format: `path — purpose`.

Update rule: any `mkdir` or new top-level folder → add an entry in the same commit/session.

## Entries

- `/Users/rodbot/` — project root for the RodBot intelligence syndication system.
- `/Users/rodbot/ledgers/` — all five ledgers that form the system's memory.
- `/Users/rodbot/ledgers/TCL/` — Temporal Continuity Ledger, one file per session.
- `/Users/rodbot/ledgers/sessions/` — raw session artifacts (transcripts, screenshots, attachments) referenced by TCL entries.
- `/Users/rodbot/intake/` — source material brought into the project from outside (files, exports, transcripts). Subfoldered by date.
- `/Users/rodbot/intake/2026-04-17-bootstrap/` — sales playbook, tasting narrative, and business extraction used to draft the initial North Stars.
- `/Users/rodbot/intake/screenshots/` — all triaged screenshots, subfoldered by capture month.
- `/Users/rodbot/intake/screenshots/2026-04/` — April 2026 screenshots, named `<slug>.png` with matching `.json` sidecars. (Legacy month-folder — new top-level intake folders going forward are slug-led, not date-led.)
- `/Users/rodbot/ledgers/moves/inbox/` — phase 3 job queue; one `<content-hash-id>.json` per settled file awaiting audit. Runtime-only, gitignored.
- `/Users/rodbot/scripts/` — operational shell scripts and protocol docs (e.g. `audit_intake.sh`, `triage_protocol.md`).
- `/Users/rodbot/scripts/launchd/` — tracked launchd agent templates committed in-repo before installation into `~/Library/LaunchAgents/`.
- `/Users/rodbot/pieces/` — Pieces memory ingest subsystem; third-party activity summaries exported from the Pieces app.
- `/Users/rodbot/pieces/exports/` — raw markdown exports from Pieces, subfoldered by capture date.
- `/Users/rodbot/pieces/exports/2026-04-18/` — first drop: 10 bootstrap-era session summaries.
- `/Users/rodbot/ledgers/moves/` — filesystem-trigger pipeline ledger workspace (phase 1 detector logs now; later inbox/receipts/index).
- `/Users/rodbot/ledgers/moves/receipts/` — phase 4 auditor output; one `<id>.md` per audited inbox job, operator-editable, phase 5's input.
- `/Users/rodbot/ledgers/moves/inbox/.poisoned/` — phase 4 "gave up on this job" archive after `MAX_ATTEMPTS` failures. Runtime-only, gitignored via `inbox/` parent rule.
- `/Users/rodbot/ledgers/moves/.auditor-attempts/` — per-job retry counters for phase 4. Runtime-only, gitignored.

## Out-of-scope (for now)

- `/Users/rodbot/Desktop`, `Documents`, `Downloads`, `Movies`, `Music`, `Pictures`, `Public`, `Library` — default macOS folders, gitignored via the `.gitignore` allowlist. `Downloads/` in particular is never tracked; intake material belongs in `intake/<slug>/`, not in `Downloads/`.
