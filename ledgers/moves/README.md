# Moves Ledger

Filesystem-trigger pipeline workspace.

## Phase status

- Current: **Phase 3** (detector + debouncer/filter + inbox writer).
- Active components:
  - `scripts/moves_phase1_detector.sh` via launchd label `com.rodbot.moves.phase1-detector`.
  - `scripts/moves_phase2_debouncer.sh` via launchd label `com.rodbot.moves.phase2-debouncer`.
  - `scripts/moves_phase3_inbox_writer.sh` via launchd label `com.rodbot.moves.phase3-inbox-writer`.
- Output in this phase:
  - `events.log` = raw detector stream.
  - `settled.log` = debounced/coalesced settled file events (JSONL), hard-noise filtered.
  - `inbox/<id>.json` = one content-hash job per unique settled file.
  - `duplicates.log` / `vanished.log` = phase-3 skip accounting.
- Not active yet: auditor receipts, mover.

## Kill switch

- Create `ledgers/moves/PAUSED` to pause writes without unloading launchd.
- Remove `ledgers/moves/PAUSED` to resume.

## Paths

- `events.log` — raw detector output (runtime artifact).
- `phase1-detector.stdout.log` / `phase1-detector.stderr.log` — launchd runtime logs.
- `settled.log` — one JSON line per settled file event (runtime artifact).
- `phase2-debouncer.stdout.log` / `phase2-debouncer.stderr.log` — launchd runtime logs.
- `inbox/` — pending phase-4/phase-5 work items; each file is one atomic JSON job.
- `.phase3-cursor` — byte offset cursor for settled-log consumption.
- `duplicates.log` — append-only duplicate detections (active inbox or historical receipts).
- `vanished.log` — append-only records for files gone before job emission.
- `phase3-inbox-writer.stdout.log` / `phase3-inbox-writer.stderr.log` — launchd runtime logs.
