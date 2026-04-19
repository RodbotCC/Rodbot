---
id: 0014
slug: phase3-tcc-fix-and-phase4-auditor
date: 2026-04-19
operator: rodbot (human)
assistants: Claude Code (Opus 4.7, 1M context) — diagnostician + phase 4 builder
status: phase 3 fully green under launchd with TCC resolved; phase 4 code landed, dry-run certified, LaunchAgent not yet loaded (operator gates on ANTHROPIC_API_KEY)
---

# 0014 — Phase 3 unblocked under launchd; phase 4 auditor landed

## What happened

Two action-units in one session, tightly coupled: resolving the phase-3
launchd freeze from TCL 0013, then building phase 4 (auditor) now that the
pipeline could actually stay running. Operator welcomed this session with
two milestones — (1) Jump Desktop portal from his personal Mac into this
RodBot mac is live, (2) Claude Max subscription active, meaning Opus 4.7
with 1M context is the interpreter of record going forward.

### Action-unit A: phase 3 launchd unblock

TCL 0013 left phase 3 diagnosed-but-broken under launchd: running fine
manually but misclassifying every file as `vanished_before_inbox` when
loaded as a LaunchAgent. Three distinct issues fell out of investigation,
addressed in order:

**1. SIGPIPE in `first_line_from_offset`** (Claude Code diagnosed + fixed).
`launchctl list` showed exit code 141 — the agent wasn't "misclassifying,"
it was crashing on SIGPIPE and then KeepAlive was restarting it. Root
cause: `tail -c +N | awk 'NR==1 {print; exit}'` — with a small settled.log
(manual test) the output fit in the pipe buffer before awk closed; with a
large one (soak had grown settled.log to ~20KB with lots of Photos Library
churn) tail's writes hit the closed pipe and died with SIGPIPE, which
`set -o pipefail` propagated and killed the script. Fix: scope the pipe in
a subshell with `set +o pipefail` so the expected SIGPIPE can't propagate.

**2. Diagnostic enrichment** (Claude Code). Extended `log_vanished` to
accept a `reason` + `diag` string. The `emit_job` vanished-branch now
captures `e=` / `f=` / `stat=` / `cwd=` / `parent=` context so next failure
is self-explanatory. This is what surfaced issue #3 below in one test cycle.

**3. TCC Full Disk Access** (Claude Code diagnosed; operator executed the
fix). With SIGPIPE gone, the diagnostic log immediately revealed the real
second bug: `diag: "stat=38 1776564663 cwd=/"` plus `reason: "sha256_failed"`.
`stat()` succeeded — so `[ -e ]` / `[ -f ]` worked. But `shasum` (which
requires content-read) failed. Proved definitively via a minimal LaunchAgent
probe (`/tmp/tcc-probe.sh` + one-shot plist) that showed `Operation not
permitted` for `shasum` and `cat` on `~/Downloads/*` and `~/Desktop/*`
while `/tmp/*` worked fine. This is macOS TCC: `/bin/bash` under launchd
has metadata access to protected folders but not content-read access.
Also confirmed, importantly, that this is NOT a Claude-Code or Cursor TCC
issue — running `shasum` via this tool's own Bash context worked fine,
because Claude Code itself is TCC-authorized.

Operator resolved by (a) `brew install bash` (got `/opt/homebrew/bin/bash`
5.3.9), (b) rewriting all three `~/Library/LaunchAgents/com.rodbot.moves.*.plist`
`ProgramArguments` to invoke `/opt/homebrew/bin/bash` instead of `/bin/bash`,
(c) granting Full Disk Access to just that binary via System Settings. This
scopes the permission narrowly rather than elevating the system bash.

**Live smoke test** (operator, post-fix): dropped 4 files — unique.txt,
dup-a.txt, dup-b.txt (byte-identical to dup-a), secret.env — into Downloads.
Results verified:
- `events.log` captured raw events.
- `settled.log` got settled entries for all four.
- `inbox/` received 3 jobs (unique + one duplicate-content hash collapsed
  to one job + secret).
- `duplicates.log` recorded the second duplicate pointing at the existing
  id.
- `suspect_sensitive: true` fired correctly on `secret.env`.
- IDs derived from content hash matched expected: `5588d8f8e8be` (unique),
  `b898706a7724` (dup content), `bdd0fb7031f2` (secret).

Phases 1→2→3 chain certified working under launchd.

### Action-unit B: phase 4 auditor built

With the pipeline producing inbox jobs, built phase 4 per TCL 0013's spec.
Same single-file-shell-daemon style as phases 1–3.

Design decisions, locked inline in the script header for durability:
- **LLM backend:** direct Anthropic Messages API via `curl`. No CLI
  dependency. API key resolved from `$ANTHROPIC_API_KEY` env or from
  `~/.config/rodbot/anthropic.env` (sourced). Chose this over the `claude`
  CLI because: (a) `claude` CLI isn't installed on this machine, (b) direct
  API is one fewer moving part, (c) explicit key management is more
  auditable than wrapping someone else's session.
- **Default model:** `claude-sonnet-4-5`, overridable via `$ANTHROPIC_MODEL`.
  Phase 4's work is structured file classification, not deep reasoning;
  Sonnet is the right price/perf point. Operator can flip to Opus via env.
- **Runtime:** long-lived LaunchAgent, 5s poll, one job per tick. Same
  shape as phases 1–3, which matters: the pipeline is now five files of
  similar-looking bash, trivial to reason about end-to-end.
- **Receipt location:** `ledgers/moves/receipts/<id>.md` flat (no date
  partitioning). IDs are the primary key; date-partitioning subfolders
  would obscure the lookup without adding navigation value until we have
  hundreds of receipts. Defer date partitioning to when volume demands.
- **Receipt format:** YAML frontmatter (machine-readable, phase 5 contract)
  + markdown body (human-readable, rationale / risks / tags). Operator can
  edit frontmatter to override the auditor. `phase5_status: pending` gates
  phase 5 consumption; setting to `skip` takes the receipt out of play
  forever.
- **Failure handling:** LLM errors / malformed responses bump a
  per-id attempt counter in `.auditor-attempts/`. At `MAX_ATTEMPTS=3` the
  job moves to `inbox/.poisoned/` and stops auto-retrying. Operator decides
  whether to re-drop the file or restore the job.
- **Vision audits happen inside phase 4.** Image jobs (mime `image/*` and
  file ≤ ~4.5MB) get their content base64'd and attached as an image block
  in the API `content` array. This is the reason we moved past
  `audit_intake.sh` — vision audit is now a stream step, not a
  boot-time-only capability.
- **Dry-run mode** (`--once --dry-run` or `--dry-run`) writes skeleton
  receipts with placeholder fields, no LLM call. Lets operator / Cursor
  certify the wiring before an API key exists. Verified end-to-end in this
  session against the live 7-job inbox: picked oldest job, wrote well-formed
  receipt, deleted inbox job, logged `started` + `audited` events. Then
  restored the consumed job.

### Scope line I explicitly did NOT cross

- **Did not load the phase-4 LaunchAgent.** Operator has no API key set
  yet and hasn't decided whether phase 4 should run autonomously or only
  on-demand. Loading is a one-liner: `scripts/setup_moves_phase4_launchagent.sh`
  once `ANTHROPIC_API_KEY` is in place.
- **Did not touch the 24-item legacy audit_intake.sh queue.** TCL 0013
  explicit directive: don't chew it manually — let the new pipeline handle
  it organically once phase 5 lands. That queue is debris from phase-2/3
  bring-up anyway.
- **Did not build phase 5.** Operator reiterated he wants Cursor to
  continue driving the builder role as a general principle. Phase 5 spec
  handed off in `scripts/moves_phase5_handoff.md`.

## What changed

### Patches (phase 3)

**`scripts/moves_phase3_inbox_writer.sh`**
- `first_line_from_offset()`: pipe now runs in subshell with `set +o pipefail`,
  scoped to just that line, preventing SIGPIPE-141 agent crashes.
- `log_vanished()`: now takes `reason` and `diag` as optional 3rd + 4th args;
  JSON output includes both fields. The diag string is how we caught TCC.
- `emit_job()`: the `[ ! -e ]` / `[ ! -f ]` vanish-branch now captures
  `e=/f=/stat=/cwd=/parent=` context; the sha256 failure branch captures
  `stat=` + `cwd=`.

### New (phase 4)

- `scripts/moves_phase4_auditor.sh` — the auditor daemon. Supports `--once`,
  `--dry-run`, `--once --dry-run`. Well-commented header documents the
  whole design; reading the first 40 lines explains the file.
- `scripts/launchd/com.rodbot.moves.phase4-auditor.plist` — LaunchAgent.
  `plutil -lint` clean.
- `scripts/setup_moves_phase4_launchagent.sh` — install/reload helper,
  same pattern as phases 1–3.
- `ledgers/moves/receipts/README.md` — receipt frontmatter schema, the
  phase-5 contract, disposition semantics, failure modes, dry-run usage.
- `scripts/moves_phase5_handoff.md` — spec for Cursor to build phase 5
  against. Includes disposition contracts, failure paths, test matrix,
  open design questions (commit policy, hook retirement, race conditions,
  archive policy).

### Updated

- `ledgers/moves/README.md` — phase status now "Phase 4", component list
  and output paths cover auditor artifacts.
- `.gitignore` — added phase-4 runtime artifacts (`auditor-events.jsonl`,
  `phase4-auditor.{stdout,stderr}.log`, `.auditor-attempts/`).
- Operator (not me, from the earlier smoke test): all three existing
  LaunchAgent plists under `~/Library/LaunchAgents/` now point to
  `/opt/homebrew/bin/bash`. **This lives outside the repo** (LaunchAgents
  is under `~/Library/`) so won't show in git status, but it's the
  load-bearing change that unblocked phase 3.

### Landed via this commit (was uncommitted on disk before I started)

- `scripts/launchd/com.rodbot.moves.phase[1-3]-*.plist` — all three had
  already been rewritten from `/bin/bash` to `/opt/homebrew/bin/bash`
  during Cursor's TCC-resolution work; the change just hadn't been
  committed. This commit lands it alongside phase 4, so the repo plists
  now match the live `~/Library/LaunchAgents/` versions. (I assumed mid-
  session there was a sync gap and noted it as a "Next" item — on
  inspecting `git diff` at commit time, the fix was already in-tree.)
- `scripts/moves_phase2_debouncer.sh` — Cursor's Bash-3.2 `read -t` fix
  (introduces `READ_TIMEOUT_SECONDS=1` separately from `POLL_SECONDS=0.5`);
  also uncommitted, lands now.
- `AGENTS.md` — operator rewrote as a Cursor-facing thread-reboot guide
  during the Cursor session; lands now.
- `ledgers/TCL/0013-moves-phases-1-2-live.md` — Cursor's TCL from the
  phases 1+2 bring-up; was untracked, lands now.

### Did not change

- `~/.claude/settings.local.json` SessionStart hook — legacy `audit_intake.sh`
  still fires per boot. Left alone; retire only after phase 5 is trusted.

## What we learned

1. **Exit codes tell more truth than narratives.** TCL 0013 said phase 3
   was "misclassifying files as vanished." `launchctl list` showing 141
   told a different, truer story: the agent was *crashing* on SIGPIPE.
   Narrative and `launchctl list` were both right about something, but the
   narrative's framing misled my first ten minutes of debugging. Rule:
   when a TCL says "misbehaves," always verify the exit code before
   accepting the framing.

2. **A minimal LaunchAgent probe beats hours of theorizing.** `/tmp/tcc-probe.sh`
   + a one-shot plist conclusively separated TCC from cwd from PATH from
   everything else in about 3 minutes. Worth keeping as a pattern: when
   a LaunchAgent misbehaves, write a stripped-down plist that does only
   the suspect operation, load it, read its output. Generalizable debug
   technique.

3. **Claude Code and Cursor's TCC are red herrings for LaunchAgent work.**
   Operator's hypothesis was "maybe Claude Code or Cursor needs FDA,
   not bash." Easily ruled out in 30 seconds by running the same `shasum`
   via this session's Bash tool — it worked fine, proving CC has FDA.
   The LaunchAgent context is wholly separate from the interactive-tool
   context for TCC purposes. This was worth proving before the operator
   did any UI work that might not have helped.

4. **Narrow TCC scope is worth the one extra step.** Installing
   Homebrew bash (`brew install bash`) and pointing LaunchAgents at
   `/opt/homebrew/bin/bash` took ~3 minutes. Granting FDA to that one
   binary instead of `/bin/bash` means every other shell-LaunchAgent on
   the system (now and future, ours and third-party) does NOT silently
   get elevated access. Small friction, real security posture improvement.

5. **"Spec / build / certify" roles are mobile.** This session inverted
   roles — operator explicitly said "you're actually probably going to be
   a better builder anyway" and asked Claude Code to build phase 4, with
   Cursor to continue the story via phase 5. That's fine. The principle
   isn't "tool X is always spec, tool Y is always build" — it's "separate
   spec from build so the artifact can move between tools without
   loss." TCL 0012 was Claude-Code-spec → Cursor-build. TCL 0014 here is
   Claude-Code-both. TCL 0015 (phase 5) can be Cursor-build against
   Claude-Code-spec. Roles follow the work.

6. **The Photos Library is a massive noise generator.** `~/Pictures/Photos
   Library.photoslibrary/**` is constantly rewritten by `photoanalysisd`
   (SQLite wals, plist rewrites, thumbnail caches). Five of the 202 lines
   in settled.log when I started this session were genuinely-vanished-by-
   design Photos Library files. Phase 4 will see these unless phase 1 or
   phase 2 filters them. Not fatal (phase 4 will just classify them as
   `deferred` or `left-in-place`), but costs Anthropic API quota. **A
   path-ignore for `*Photos Library.photoslibrary/*` belongs in phase 1
   before phase 4 goes live.** Noted in "Next."

## Next

- **(operator)** Set `ANTHROPIC_API_KEY`. Either `export ANTHROPIC_API_KEY=…`
  in your shell, or `mkdir -p ~/.config/rodbot && echo 'ANTHROPIC_API_KEY=sk-ant-…' > ~/.config/rodbot/anthropic.env && chmod 600 ~/.config/rodbot/anthropic.env`.
- **(operator)** When ready, load phase 4:
  `scripts/setup_moves_phase4_launchagent.sh`. First live tick should
  produce a real receipt for the oldest inbox job. Inspect `receipts/<id>.md`
  and `auditor-events.jsonl` to gauge quality.
- **(cursor, next session)** Add a path-ignore for `*Photos Library.photoslibrary/*`
  (and probably also `*/.Spotlight-V100/*`, `*/.fseventsd/*` belt-and-suspenders)
  to `scripts/moves_phase1_detector.sh`. Reload phase 1. Verify settled.log
  stops seeing Photos churn.
- **(cursor, next session)** Build phase 5 against `scripts/moves_phase5_handoff.md`.
- **(deferred)** Retire `audit_intake.sh` SessionStart hook — only once
  phase 5 has been live for ~24h with no incidents. Write a separate TCL
  for that change, don't bundle.
- **(carry-forward)** NS ratification, Pieces MCP sanity query, raw-ai-mission-control
  skim, Ratio Lattice v0.1.
