---
id: 0012
slug: moves-pipeline-scaffold
date: 2026-04-18
operator: rodbot (human)
assistants: Claude Code (Opus 4.7 — spec author) + Cursor (builder)
status: scaffolded; live bring-up and soak pending
---

# 0012 — Moves pipeline phases 1–3 scaffolded + convention updates

## What happened

Operator made a deliberate architectural move: push menial always-on work off Claude Code (expensive Opus quota) and onto Cursor (auto-mode, plentiful quota) and eventually Codex (large stipends). First target: the filesystem trigger system that watches for files landing on RodBot surfaces, audits them, and moves them. Prior to this session the only intake mechanism was `scripts/audit_intake.sh` as a `SessionStart` hook — passive, sweep-on-boot, only ran when a Claude Code thread started. The new system is an always-on, event-driven pipeline running under `launchd`.

Claude Code's role: conceptualize and spec. Cursor's role: implement. Then Claude Code certifies and logs. This is the first real test of that division of labor and it worked cleanly.

Three phases were specced and implemented in sequence, each building on the previous phase's stream. No phase is live yet; no fswatch installed, no agents loaded. This TCL captures the scaffolding; certification happens after a live soak.

## What changed

### Phase 1 — Detector (Cursor implemented from Claude spec)
- `scripts/moves_phase1_detector.sh` — runs `fswatch -rx` over the allowlist (`Downloads/`, `Desktop/`, `Documents/`, `Pictures/`, `Movies/`, `Music/`, `Public/`), appends raw event lines to `ledgers/moves/events.log`. Honors `ledgers/moves/PAUSED` kill switch. Hard-fails with a clear message if `fswatch` is missing.
- `scripts/launchd/com.rodbot.moves.phase1-detector.plist` — LaunchAgent template (validated with `plutil -lint`).
- `scripts/setup_moves_phase1_launchagent.sh` — install/reload helper.
- Allowlist explicitly excludes `Library/`, `Applications/`, `.claude/`, `.cursor/`, `.codex/`, `.git/`, and our own write destinations (`ledgers/`, `intake/`, `pieces/`, `scripts/`). This is the single most important design decision — watching literal `$HOME` would flood with macOS Library churn and create feedback loops.

### Phase 2 — Debouncer + filter (Cursor)
- `scripts/moves_phase2_debouncer.sh` — tails `events.log`, drops hard-noise patterns (`.DS_Store`, `._*`, `Icon?`, `*.crdownload`, `*.download`, `*.part`, `*.tmp`, `*.swp`, `.Trash/*`), verifies file still exists, waits for 3s size-stability (500ms polling), abandons after 10-minute cap, coalesces bursts per path, writes settled JSONL to `ledgers/moves/settled.log` with `{path, size, mtime, event, captured_at, raw_event_count}`.
- `scripts/launchd/com.rodbot.moves.phase2-debouncer.plist` — independent LaunchAgent. Detector and debouncer are separately restartable.
- `scripts/setup_moves_phase2_launchagent.sh`
- Cursor rewrote for macOS default Bash 3.2 compatibility (no Bash-4 features).

### Phase 3 — Inbox writer (Cursor)
- `scripts/moves_phase3_inbox_writer.sh` — tails `settled.log` from a byte-offset cursor (`ledgers/moves/.phase3-cursor`, advanced only on successful handling). For each settled event: verifies file still exists (else logs to `vanished.log`), computes SHA-256 (first 12 chars = `id`), dedupes against active inbox + historical `index.jsonl`, collects metadata (mime via `file --mime-type`, size, mtime, birthtime, filename, dir), embeds base64-preview for `text/*` mime, applies conservative `suspect_sensitive` heuristic on filenames matching `*password*`, `*.env`, `*.pem`, `*.key`, etc. Writes job atomically via `.<id>.json.tmp` → `<id>.json` rename.
- `scripts/launchd/com.rodbot.moves.phase3-inbox-writer.plist`
- `scripts/setup_moves_phase3_launchagent.sh`
- Duplicate events log to `ledgers/moves/duplicates.log` (no new job created).

### Shared infrastructure
- `ledgers/moves/` — new ledger workspace with its own `README.md` documenting the phase pipeline.
- `.gitignore` updated: runtime-only files stay out of git (`events.log`, `settled.log`, `phase*.stdout.log`, `phase*.stderr.log`, `inbox/`, `duplicates.log`, `vanished.log`, `.phase3-cursor`, `.phase2-pending/`). The scripts, plists, and READMEs are tracked.
- `AGENTS.md` — operator-added, Cursor-specific thread-reboot guide (landed during session, committed here).

### Convention updates (protocol propagation of new operator preferences)
- `scripts/triage_protocol.md` — added principle #4 (move-not-copy, no double-storage), principle #6 (slug-led folder names going forward, no date prefixes). Updated rule 3 to use `intake/<slug>/` instead of `intake/YYYY-MM-DD-<slug>/`.
- `CLAUDE.md` §5 scope line updated to `intake/<slug>/`.
- `ledgers/directory_ledger.md` — annotated existing `intake/screenshots/2026-04/` as legacy; updated screenshot-naming description to `<slug>.png` (reflects TCL 0010 convention that wasn't fully propagated); updated out-of-scope note.
- `ledgers/contents_ledger.md` — registered all phase 1–3 files.
- Two new feedback memories: `feedback_no_date_folders.md` (Rodrigo's "please never name the folders after the time and date" — actually quoted in the memory) and `feedback_no_double_storage.md` (Rodrigo's "we do not need to double everything"), indexed in `MEMORY.md`.

### Operator-deleted file
- `Downloads/⭐SALES PLAYBOOK V2.0 - Comeketo Catering.txt` — operator deleted manually because it had already been indexed under `intake/2026-04-17-bootstrap/` since session 0006. Byte-identical duplicate, no data loss. This is the concrete incident that drove the "no double-storage" memory.

## What we learned

1. **Spec/build/certify division of labor works.** Operator splits: Claude Code writes the spec (expensive Opus thinking well-applied to design), Cursor on auto-mode writes the code (cheap bulk work, trivial for spec-following), Claude Code comes back to certify and log. Three phases landed in one session with the operator writing zero code. That's the right shape for the "menial always-on" layer — mechanical, spec-driven, high-volume.
2. **Cursor's macOS-Bash-3.2 instinct was correct.** Claude Code spec didn't call it out; Cursor noticed the machine's default Bash and refactored. This is a good sign that Cursor as a builder can catch implementation-realities that a spec author misses.
3. **Preferences emerge through friction, not specification.** Both new feedback memories (no-date-folders, no-double-storage) came from operator irritation during real use, not from upfront design conversation. The rule holds: save feedback when the operator pushes back, not when they prescribe in the abstract.
4. **"One at a time" with phased scaffolding is faster than it sounds.** Each phase is ~50-100 lines of shell; the discipline is the constraint, not the implementation. Locking phase N before moving to N+1 means the live soak later will tell us exactly where the failure is if one exists — we'll know whether detector, debouncer, or inbox is the broken stage.

## Next

- **Live bring-up (pending operator go):** `brew install fswatch`, then run `setup_moves_phase1_launchagent.sh` and `setup_moves_phase2_launchagent.sh`. Let the two-stage pipeline soak for ~24h of real use to verify `settled.log` has correct cardinality for intentional drops (Safari download, AirDrop, CleanShot, Finder copy-paste batch).
- **Then bring up phase 3** against the accumulated `settled.log` and verify every settled line → exactly one job or one dupe or one vanished entry.
- **Phase 4 (spec pending):** Auditor — Cursor or Codex agent consumes inbox jobs, applies triage protocol, produces markdown receipts in `ledgers/moves/YYYY-MM/<id>.md` with proposed destinations. Still no actual moves. This is where the LLM finally enters the pipeline.
- **Phase 5 (spec pending):** Mover — executes moves per certified receipts, appends to `index.jsonl`, retires `scripts/audit_intake.sh` SessionStart hook as redundant.
- **Existing dated folders** (`intake/2026-04-17-bootstrap/`, `intake/screenshots/2026-04/`, `pieces/exports/2026-04-18/`) are flagged as legacy but NOT renamed. Any migration is a deliberate separate action-unit, not a retroactive sweep.
- **Carry-forward (unchanged):** NS-01..NS-18 ratification, Pieces MCP sanity query, raw-ai-mission-control skim, Ratio Lattice v0.1.
