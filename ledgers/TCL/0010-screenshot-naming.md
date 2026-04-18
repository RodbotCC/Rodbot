---
id: 0010
slug: screenshot-naming
date: 2026-04-18
operator: rodbot (human)
assistants: Claude Code (Opus 4.7)
status: done
---

# 0010 — Screenshot naming: drop the prefix and the date

## What happened

Operator flagged that screenshot filenames like `screenshot-2026-04-18-1049-claude-rodbot-setup-questions.png` are front-loaded with redundant information. `screenshot-` is obvious from the `screenshots/` parent directory; the date is already in file metadata and in the `YYYY-MM/` subfolder. The actual content signal — the slug — is buried at the end. Convention reversed: filenames are now just `<slug>.png` + `<slug>.json`.

## What changed

- **Renamed 4 existing files** in `intake/screenshots/2026-04/`:
  - `screenshot-2026-04-18-1049-claude-rodbot-setup-questions.{png,json}` → `claude-rodbot-setup-questions.{png,json}`
  - `screenshot-2026-04-18-1058-rodbot-origin-diagram.{png,json}` → `rodbot-origin-diagram.{png,json}`
- **`scripts/triage_protocol.md`** rule 2 updated: new path is `intake/screenshots/YYYY-MM/<slug>.{png,json}`; collision rule added (append `-2`, `-3`); sidecar `captured_at` is now the authoritative timestamp.
- **`CLAUDE.md` §3.5 step 3** updated to match.
- **`ledgers/contents_ledger.md`** entries updated to new filenames.

## What we learned

1. **Filename redundancy quietly erodes scan-speed.** When the first 25 characters of every screenshot are identical (`screenshot-2026-04-18-`), the eye has to skip past them to find the discriminating part. The month folder + mtime already carry the date; the filename should carry only what the folder and metadata can't.
2. **Metadata-first naming is only safe when the metadata is stable.** File mtime survives `mv` on the same filesystem, but *not* all transfers (some cloud sync, zip/unzip, scp without `-p`). That's why the sidecar JSON's `captured_at` is now explicitly the authoritative timestamp — if mtime gets clobbered, we still have the truth.
3. **Convention changes this early are cheap.** Only 4 files to rename; no downstream tooling depends on the old pattern yet. Worth doing immediately before any accumulation.

## Next

- No carry-forward from this TCL. Pre-existing open items (playbook dedupe sign-off, NS ratification, Pieces MCP sanity query, mission-control skim, Ratio Lattice v0.1) remain.
