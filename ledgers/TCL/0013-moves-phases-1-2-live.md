---
id: 0013
slug: moves-phases-1-2-live
date: 2026-04-18
operator: rodbot (human)
assistants: Cursor (builder, primary) + Claude Code (Opus 4.7 — ledger author, returning to certify)
status: phases 1+2 live and soaking under launchd; phase 3 functional manually but broken under launchd; Cursor work frozen pending this ledger update
---

# 0013 — Moves pipeline phases 1+2 live; phase 3 has a launchd-context bug

## What happened

Operator continued session 0012's work in Cursor (other account, until tokens ran out), doing the live bring-up of the moves pipeline that 0012 had scaffolded but not loaded. Claude Code (this thread) was brought back in at the freeze point to (a) certify the current state against disk and (b) write this TCL entry.

Permission envelope: operator explicitly granted Cursor "install anything needed." Only one install was required — `fswatch`.

Sequence of events inside Cursor's session:
1. Dependency preflight: `jq`, `file`, `shasum`, `openssl`, `launchctl` already present; `fswatch` missing → installed via brew.
2. Loaded phase 1 + phase 2 LaunchAgents.
3. Phase 2 crashed on first run. Cursor diagnosed macOS default Bash 3.2 does not accept fractional seconds in `read -t`. Patched and reloaded. `settled.log` began writing cleanly.
4. Loaded phase 3 LaunchAgent. It "dropped out" (`phase3_not_loaded`) — exited too fast to stay loaded. Investigated.
5. First Phase 3 patch: removed a too-strict `line_has_trailing_newline` guard that was blocking job emission. Manual run of phase 3 now produces jobs correctly.
6. Under launchd, phase 3 still misbehaves — it reads settled lines but misclassifies every file as `vanished_before_inbox`. Likely a launchd process-context difference (cwd, PATH, or file-stat timing under the agent's environment). Cursor stopped phase 3 to avoid polluting logs and left phase 1+2 soaking.

This is the correct fault boundary to stop at: phases 1+2 are demonstrably good, phase 3 has a specific and isolatable bug.

## What changed

### Installed
- `fswatch` (Homebrew). Hard dependency of phase 1 detector. Now the only new system-level install required for the pipeline.

### Code patches (uncommitted on `main` at freeze time — this TCL commits them)

**`scripts/moves_phase2_debouncer.sh`** — 1 line added, 1 changed.
- Introduced `READ_TIMEOUT_SECONDS=1` (integer) separate from `POLL_SECONDS=0.5` (used for size-stability polling, which is `sleep`-based and accepts fractional seconds fine).
- Changed the event-loop `read -r -t "$POLL_SECONDS"` to `read -r -t "$READ_TIMEOUT_SECONDS"`.
- Root cause: macOS default `/bin/bash` is 3.2; its `read -t` only accepts whole seconds. Under `launchd` the agent was crashing on the first tick. This was a Cursor-caught spec miss; the original phase 2 spec didn't call out that `read -t` and `sleep` have different fractional-second tolerances on Bash 3.2.

**`scripts/moves_phase3_inbox_writer.sh`** — 18 lines removed.
- Deleted the `line_has_trailing_newline()` function and its single caller in the main loop.
- Root cause: the check was trying to verify that a settled-log line was fully written before processing, by reading one byte past the line offset and comparing to `\n`. It was over-strict and never passed for real newly-written lines, so phase 3 read every settled line and then silently looped without emitting any job.
- This fix makes phase 3 emit jobs correctly when run manually. It does **not** fix the launchd misclassification (see below).

**`AGENTS.md`** — heavily rewritten by operator during the Cursor session as a Cursor-specific thread-reboot guide. Net: 74 deletions, 22 insertions (much tighter). Not machine-authored; just landing alongside this commit.

### Runtime state on disk (as of this TCL)
- `launchctl list` shows `com.rodbot.moves.phase1-detector` and `com.rodbot.moves.phase2-debouncer` loaded. Phase 3 not loaded.
- `ledgers/moves/events.log` ≈ 20KB, `settled.log` = 58 lines, `inbox/` has 1 job (`64be6663d26d.json`) from a manual phase 3 test run.
- `vanished.log` = 2 lines (from phase 3 launchd-context misclassification during the failed test).
- `duplicates.log` empty.
- `.phase2-pending/` and `.phase3-cursor` present (expected runtime scratch; gitignored per 0012).

### No ledger companions touched
- `contents_ledger.md` — no files created/renamed/deleted, only patched.
- `directory_ledger.md` — no new directories.
- `intake_*` — out of scope for this action-unit.

## What we learned

1. **Spec/build/certify division scaled through an outage.** Operator hit token exhaustion on the account driving Cursor, and the setup still made forward progress because Cursor was the builder and the spec was already durable in-repo. Claude Code returned cold and could fully reconstruct "where we are" from disk state + uncommitted diffs + operator summary. This is exactly the resilience the three-tool division was supposed to buy.
2. **Phase boundaries pay off exactly as predicted in 0012.** The failure is cleanly inside phase 3 under launchd; phases 1+2 are not suspected. The "certify each phase before the next" discipline is what makes that localisability possible.
3. **Bash-3.2 `read -t` is a known macOS footgun.** Worth noting in future shell-phase specs: `sleep` accepts `0.5`, `read -t` does not. Cursor caught this; Claude Code's original spec missed it.
4. **Operator's narrative had one small drift.** In the recap, Cursor's phase 3 patch was described as adding the `line_has_trailing_newline` helper; the diff shows it was removed. This is a reminder to always reconcile narrative against disk state before writing TCL — which is why we do.

## Next

- **Immediate (blocker):** diagnose why phase 3 under launchd treats every settled file as `vanished_before_inbox` while the same script run manually emits jobs. Likely candidates to check, in order: (a) cwd — agent may run in `/` and break any relative-path logic; (b) PATH — `file`, `shasum`, `stat` not found under launchd env; (c) `stat -f` vs GNU `stat` under limited PATH; (d) permissions — `TCC.db` may be blocking agent-context reads of files that manual-context reads can see (File Access permissions for the LaunchAgent). Plan: add targeted diagnostics (log cwd, PATH, and per-file stat exit codes) then re-run under launchd.
- **Once phase 3 is green:** short end-to-end smoke matrix — (1) normal file drop, (2) byte-identical duplicate, (3) filename matching `suspect_sensitive` heuristic, (4) rapid multi-file copy burst — verify each produces the expected inbox outcome.
- **Then:** spec phase 4 (Auditor). This is where an LLM finally enters the pipeline — consumes `inbox/*.json` jobs, produces markdown receipts in `ledgers/moves/YYYY-MM/<id>.md` with proposed destinations. Still no actual moves.
- **Then:** spec phase 5 (Mover) — executes moves per certified receipts, writes `index.jsonl`, retires the `SessionStart` `audit_intake.sh` hook.
- **Queue hygiene:** the `SessionStart` intake queue is showing 18 items dominated by phase-2/3 test artifacts in `Downloads/rodbot-phase*-test/`. These are debris from this session's live bring-up, not real user intake. When phase 3 is green and phase 4 begins drafting receipts, one of the first real receipts should propose cleaning these up. Do not run the legacy sweep to "clear" them — it would double-handle and muddy the first real pipeline test.
- **Carry-forward (unchanged):** NS-01..NS-18 ratification, Pieces MCP sanity query, raw-ai-mission-control skim, Ratio Lattice v0.1.
