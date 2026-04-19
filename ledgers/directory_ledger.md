# Directory Ledger

Every directory and subdirectory under `/Users/rodbot/` (and eventually the broader user folder, once we open that scope) gets a line here.

Format: `path — purpose`.

Update rule: any `mkdir` or new top-level folder → add an entry in the same commit/session.

## Entries

- `/Users/rodbot/` — project root for the RodBot intelligence syndication system.
- `/Users/rodbot/ledgers/` — all core ledgers that form the system's memory.
- `/Users/rodbot/ledgers/TCL/` — Temporal Continuity Ledger, one file per session.
- `/Users/rodbot/ledgers/sessions/` — narrative session diaries (coarser granularity than TCL).
- `/Users/rodbot/intake/` — source material brought into the project from outside (files, exports, transcripts). Slug-led subfolders; no date-prefixed folder names going forward.
- `/Users/rodbot/intake/2026-04-17-bootstrap/` — legacy date-prefixed bootstrap intake folder (predates the no-date-folders rule; grandfathered in).
- `/Users/rodbot/intake/screenshots/` — all triaged screenshots, subfoldered by capture month.
- `/Users/rodbot/intake/screenshots/2026-04/` — April 2026 screenshots, named `<slug>.png` with matching `.json` sidecars.
- `/Users/rodbot/scripts/` — operational shell scripts and protocol docs. Currently empty after session 0018 wipe; will be repopulated as new automation is designed from clean eyes.
- `/Users/rodbot/pieces/` — Pieces memory ingest subsystem; third-party activity summaries exported from the Pieces app.
- `/Users/rodbot/pieces/exports/` — raw markdown exports from Pieces, subfoldered by capture date.
- `/Users/rodbot/pieces/exports/2026-04-18/` — first drop: 10 bootstrap-era session summaries.

## Out-of-scope (for now)

- `/Users/rodbot/Desktop`, `Documents`, `Downloads`, `Movies`, `Music`, `Pictures`, `Public`, `Library` — default macOS folders, gitignored via the `.gitignore` allowlist. `Downloads/` in particular is never tracked; intake material belongs in `intake/<slug>/`, not in `Downloads/`.
