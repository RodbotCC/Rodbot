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

## Out-of-scope (for now)

- `/Users/rodbot/Desktop`, `Documents`, `Downloads`, `Movies`, `Music`, `Pictures`, `Public`, `Library` — default macOS folders, empty or system-managed. Will be inventoried when work touches them.
