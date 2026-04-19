# Phase 5 — Mover. Cursor handoff spec.

**Audience:** Cursor, picking up the moves pipeline after phase 4 receipt
generation is running in Cursor. You have the same repo. Phases 1–3 are live;
phase 4 is Cursor-operated per `scripts/moves_phase4_cursor_spec.md`. Your job
is to implement phase 5 — the mover — following the same style and
conventions as phases 1–3.

**Guiding principle:** phase 5 is the first phase that *mutates the
filesystem outside `ledgers/moves/` itself*. Be conservative. Operator trust
in this pipeline hinges on phase 5 never destroying anything silently.

## 1. What phase 5 is (and isn't)

**Is:** a long-lived LaunchAgent that:
- watches `ledgers/moves/receipts/*.md`
- reads each receipt's YAML frontmatter
- executes the proposed move per the disposition contract (below)
- marks the receipt `phase5_status: done` (or `failed`)
- appends one line to `ledgers/moves/index.jsonl` per processed receipt

**Is not:**
- A decision-maker. Phase 4 (LLM auditor) made the call. Phase 5 executes.
- A deleter. `disposition: delete-candidate` **never** causes a delete.
  Phase 5 surfaces it to the operator and halts for that id.

## 2. Contract with phase 4 (don't break this)

- Receipt filename = `<id>.md`, matches the former inbox job id.
- Frontmatter schema is the authoritative source. The body is human-facing.
- Fields phase 5 reads: `id`, `sha256`, `disposition`, `proposed_destination`,
  `proposed_slug` (informational), `contains_sensitive`, `sensitive_reason`,
  `phase5_status`, `original_path`.
- Phase 5 only acts on `phase5_status: pending`. Any other value → skip.
- After acting, phase 5 updates `phase5_status` to `done` or `failed`
  in place (edit the file's frontmatter).

## 3. Disposition handlers

### 3.1 `moved`
1. Sanity-check `original_path` still exists and its `stat -f%z` matches the
   receipt's `original_size_bytes` AND its sha256 matches the receipt's
   `sha256`. If any check fails → `failed` with reason `"source changed
   between audit and move"`. Do NOT execute the move; a different file now
   sits at that path.
2. Sanity-check `proposed_destination`:
   - Must be an absolute path under `/Users/rodbot/`.
   - Must NOT already exist (refuse to overwrite).
   - Must NOT be inside `Library/`, `Applications/`, `.git/`, `.claude/`,
     `.cursor/`, `.codex/`, `scripts/`, `ledgers/`, `pieces/normalized/`,
     `pieces/packets/`, `pieces/visuals/`.
   - If it violates any constraint → `failed`.
3. If `contains_sensitive: true`:
   - Compute the destination's path relative to `/Users/rodbot/`.
   - If that relative path is not already gitignored (check with
     `git check-ignore` from inside the repo), append it to `.gitignore`
     with a comment containing the receipt id and the `sensitive_reason`.
   - Commit that `.gitignore` change as part of the phase-5 commit for this
     receipt (or leave uncommitted — see §6, commit policy is TBD).
4. `mkdir -p` the destination's parent directory.
5. `mv` original_path → proposed_destination.
6. Update receipt frontmatter: `phase5_status: done`,
   `moved_at: <ISO>`, `moved_to: "<final absolute path>"`.
7. Append to `index.jsonl`:
   ```json
   {"ts":"<ISO>","id":"<id>","disposition":"moved","from":"<original>","to":"<destination>","sha256":"<hash>","receipt":"ledgers/moves/receipts/<id>.md"}
   ```

### 3.2 `left-in-place`
1. Sanity-check `original_path` exists.
2. Update receipt: `phase5_status: done`, `left_in_place_at: <ISO>`.
3. Append to `index.jsonl` with `disposition: "left-in-place"`,
   `from: original_path`, `to: null`.
4. No filesystem mutation beyond the receipt edit and index append.

### 3.3 `deferred`
1. Update receipt: `phase5_status: done`, `deferred_at: <ISO>`.
2. Append to `index.jsonl` with `disposition: "deferred"`,
   `from: original_path`, `to: null`.
3. No filesystem mutation beyond the receipt edit and index append.
4. The receipt stays in `receipts/` forever — it's the audit trail that
   "we saw this file and decided we didn't know what to do with it."

### 3.4 `delete-candidate`
1. Do NOT delete.
2. Update receipt: `phase5_status: failed` with reason
   `"delete-candidate requires operator sign-off; flip to disposition:
   deleted (v0.1 rule) only after operator confirms"`.
3. Append to `index.jsonl` with `disposition: "delete-candidate-surfaced"`,
   `from: original_path`, `to: null`.
4. Surface visibly: write a line to a new `ledgers/moves/delete-queue.md`
   (create if missing) with `- <id> — <original_path> — <reason>` so the
   operator has one grep-able place to review deletions. Never auto-delete.

## 4. Failure paths

- Receipt YAML unparseable → `failed` with reason `"malformed frontmatter"`.
- Required field missing → `failed` with reason `"missing field: <name>"`.
- sha256 mismatch → `failed`, leave source untouched.
- Destination collision → `failed`, log the collision.

In all failed cases: `phase5_status: failed` + a plain-text `<id>.phase5.log`
file in the same `receipts/` dir with the full error. Index.jsonl gets a
`{"disposition":"failed","reason":"..."}` line. No retry automation — operator
edits the receipt (fixing `proposed_destination`, or flipping to `deferred`)
and sets `phase5_status: pending` to re-queue.

## 5. Runtime pattern

Match phases 1–4:
- `scripts/moves_phase5_mover.sh` — single bash file, `#!/usr/bin/env bash`,
  `set -euo pipefail`.
- `scripts/launchd/com.rodbot.moves.phase5-mover.plist` — `RunAtLoad`,
  `KeepAlive`, stdout/stderr logs into `ledgers/moves/`.
- `scripts/setup_moves_phase5_launchagent.sh` — install/reload, following
  the bootout → bootstrap → enable → kickstart pattern from phases 1–3 setup helpers.
- Uses `/opt/homebrew/bin/bash` (Bash 5.x, TCC-granted).
- Honors `ledgers/moves/PAUSED` kill switch.
- Poll interval: 5 seconds. Process one receipt per tick for serialization.

## 6. Open design questions (answer explicitly in the TCL for phase 5)

1. **Commit policy.** Does phase 5 git-commit after each successful move, or
   batch? If batched, on what cadence? Per-receipt commits give perfect
   audit history but may spam the log. Suggestion: one commit per sweep
   (one tick that actually did something), message
   `Phase 5: N moves (<ids>)`. Operator to confirm.
2. **Conflict with `audit_intake.sh` SessionStart hook.** The legacy hook
   still sweeps the same dirs. Once phase 5 is proven over ~24h, retire the
   hook (delete it from `~/.claude/settings.local.json` and archive the
   script). Don't do this as part of the phase-5 landing commit; do it as
   a separate TCL once the new pipeline is trusted.
3. **Receipt editing race.** If operator is actively editing a receipt
   when phase 5 ticks, we could read a half-written file. Cheap mitigation:
   require the frontmatter to end with a line `phase5_status: pending` —
   no multi-byte write can split that exact line. If parsing fails, skip
   this tick; the next one will catch it.
4. **Cleanup of `receipts/`.** Receipts for completed moves accumulate
   forever. That's fine for v0 (audit trail), but at some point archive
   `done` receipts to `receipts/archive/YYYY-MM/`. Out of scope for phase 5
   v0 — defer.

## 7. Tests to run before declaring phase 5 certified

Drop these files and verify each one lands correctly per the matrix in
TCL 0013's phase-3 smoke plan, now extended:

| # | Setup | Expected phase-5 outcome |
|---|---|---|
| 1 | Text file dropped in Downloads, audit → `moved` to `intake/<slug>/<name>.ext` | File relocated, index.jsonl line, receipt `done` |
| 2 | CleanShot screenshot on Desktop, audit → `moved` to `intake/screenshots/2026-04/<slug>.png` | Image relocated, same month folder, receipt `done` |
| 3 | `.env` file with `suspect_sensitive: true` → `moved` with `contains_sensitive: true` | `.gitignore` appended, file moved, receipt `done` |
| 4 | `.dmg` installer → `left-in-place` | No move, index line, receipt `done` |
| 5 | Some unknown filetype → `deferred` | No move, index line, receipt `done` |
| 6 | Manually-edit a receipt to change `proposed_destination` before phase 5 ticks | Phase 5 honors edit |
| 7 | Edit a receipt to `phase5_status: skip` | Phase 5 never touches it |
| 8 | Manually corrupt a receipt (remove a field) → `failed` | Source untouched, `.phase5.log` written |
| 9 | Drop a byte-identical file that phase 3 marks duplicate | Phase 3 dedupes (no inbox job), phase 5 never sees it |

## 8. After certification

Write TCL 0015 (or next in sequence): "moves pipeline — phase 5 live, full
chain certified." Include the smoke-matrix results. Update
`ledgers/moves/README.md` to "Current: phase 5 (pipeline complete)."
Propose retiring the legacy `audit_intake.sh` SessionStart hook in a
follow-up TCL.
