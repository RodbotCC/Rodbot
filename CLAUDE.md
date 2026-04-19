# CLAUDE.md — RodBot operating manual

**This file loads into every Claude Code session on this machine. Read it top to bottom before doing anything else.**

---

## 1. What this machine is

This machine **is RodBot**. It is not a normal user account named "rodbot." The home directory `/Users/rodbot/` is the project substrate — `ledgers/`, `intake/`, and `README.md` sit directly in `$HOME` alongside the macOS defaults. There is no nested `RodBot/` folder; flattening it was session 0004. If you catch yourself about to create `~/RodBot/` or `~/Projects/RodBot/`, stop — that's the mistake.

**Mission:** a semi-autonomous / autonomous intelligence-syndication system for Comeketo Catering (Rodrigo Souza's Brazilian catering business). Every tool on the computer — Claude Code / Work / Desktop, GPT, Codex, Cursor, Warp terminal, Wispr Flow, Logi Options+, Raycast, Pieces — is syndicated against that mission. Pieces (MCP at `http://localhost:39300/model_context_protocol/2025-03-26/mcp`) is the continuous-activity backbone and should always be consulted for "what happened recently on this computer."

**Canonical spelling:** **Comeketo**. Speech-to-text will produce "Kamiketa / Kamiketo / Comic Keto" — those are errors. Correct silently.

**Origin:** both home and work machines were wiped 2026-04-17 to restart clean. This is iteration N+1 of a project that previously "worked but didn't feel different enough." The ledger discipline below is what makes this iteration different — do not dilute it.

---

## 2. Reading order for a fresh session

When you wake up in a new thread, read in this order before taking action:

1. This file (`~/.claude/CLAUDE.md`).
2. `~/AGENTS.md` — Cursor-only operating guide (read for cross-tool continuity, not as Claude's own contract).
3. `~/.claude/projects/-Users-rodbot/memory/MEMORY.md` — memory index; follow the links you need.
4. `~/README.md` — project principles and ledger map.
5. The **last three TCL entries** — `ls -t ~/ledgers/TCL/*.md | head -3` — so you know where we left off.
6. `~/ledgers/north_star.md` — the goals currently in play.
7. `~/ledgers/contents_ledger.md` if you need to know what any specific file is.

Don't reread the `intake/` files on every session — they are large and don't change. Memory file `project_comeketo.md` summarizes them.

---

## 3. The five ledgers — update discipline is non-negotiable

All under `~/ledgers/`:

| Ledger | File(s) | When to update |
|---|---|---|
| **TCL — Temporal Continuity Ledger** | `TCL/NNNN-slug.md`, one per action-unit | Every non-trivial commit-sized action. Append-only. See `TCL/README.md` for the entry template. |
| **Sessions (diary)** | `sessions/NNNN-slug.md`, one per working period | End of a working period. Coarser than TCL — tells the arc of the whole sitting. See `sessions/README.md`. |
| **Directory Ledger** | `directory_ledger.md` | Any new directory created → add a line same session. |
| **Contents Ledger** | `contents_ledger.md` | Any file created / renamed / deleted → update same session. |
| **Ratio Lattice Ledger** | `ratio_lattice.md` | When you score relationships between entries. v0 conventions only; evolve as we go. |
| **North Star Ledger** | `north_star.md` | When goals change, progress moves, or importance is rewritten. |
| **Pieces Memory Ledger** | `pieces_memory_ledger.md` | When Pieces exports are ingested into `pieces/exports/`. See §3.5. |

**Rule:** when in doubt, update. A ledger that's a session out of date is still useful. A ledger that's two weeks out of date is a liability.

TCL entries must include: `date`, `operator`, `assistants`, `status`, and the sections **What happened / What changed / What we learned / Next**. The "Next" section is load-bearing — it's how the next thread resumes work.

---

## 3.5. Pieces memory — third-party continuity feed

Pieces (https://pieces.app) runs continuously on this machine and curates cross-tool activity into structured markdown summaries. Operator exports them into `pieces/exports/YYYY-MM-DD/<HHMM>-<slug>.md`.

**Directory layout:**
```
pieces/
  exports/          # raw markdown (the only layer built in v0)
```
Downstream layers (`normalized/`, `packets/`, `visuals/`) are deliberately deferred — no consumer yet. Raw exports are grep-queryable today; build storage when something needs it.

**When you ingest a new export:** log it in `ledgers/pieces_memory_ledger.md` under the date section. Pieces summaries overlap with our TCL + sessions but carry cross-tool detail (Cursor, Warp, Finder, ChatGPT, CleanShot settings, etc.) that file-based ledgers don't — so the value is in the *overlap*, not replacement.

---

## 4. Operating principles (operator preferences, memorized)

1. **Build one piece of functionality at a time.** Build → test → certify → log TCL → update directory + contents ledgers → commit → next. No batching. (Memory: `feedback_build_style.md`)

2. **Design-as-we-go, not lock-then-build.** Schemas, scoring systems, and goal sets evolve alongside the work. Do not gate progress on "we need to finalize X before we can start Y" for two things we're building in parallel. Stamp things v0, flag open questions inline, let them co-evolve. (Memory: `feedback_draft_and_iterate.md`)

3. **Every material change is logged, every logged session is committed.** The commit cadence is **one commit per TCL session**. Commit message starts with `Session NNNN:` and summarizes what changed and why.

4. **Preserve the operator's visual shorthand.** Rodrigo's existing systems (Sheets, color-coded side-by-side layouts) are the result of years of operational tuning. When building replacements, respect that visual language — fast comprehension is a real feature of his current workflow.

5. **"Manually overextended, not broken."** The business already has structure. Your job is to remove manual assembly cost, not to impose new structure on top. Default to augmenting what exists before proposing replacements.

---

## 5. Git / GitHub

- **Remote:** `https://github.com/RodbotCC/Rodbot` (public).
- **Branch:** `main`. Always push after each session commit.
- **Identity:** `user.name = RodbotCC`, `user.email = tech@comeketocatering.com` (repo-local config).
- **Auth:** `gh` CLI, authed as `RodbotCC`.
- **Scope:** `.gitignore` is **allowlist**-style — ignores everything in `$HOME` except `README.md`, `AGENTS.md`, `CLAUDE.md`, `ledgers/`, `intake/`, `scripts/`, `pieces/`. Do not add entries to the allowlist casually; `Library/`, `Desktop/`, `Downloads/`, `Documents/`, `Pictures/` are deliberately invisible to git. Intake material goes in `intake/<slug>/` (slug-led, no date prefix), never in `Downloads/`.
- **Commit template:**
  ```
  Session NNNN: <short description>

  <one paragraph on what changed and why>

  Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
  ```

---

## 6. MCP servers / ingress

Currently connected:
- **Pieces** (`http://localhost:39300/...`) — continuous activity capture. Use `mcp__pieces__ask_pieces_ltm` for "what was I doing earlier" queries, `workstream_*` tools for timeline slices.
- **Slack, ClickUp, Close CRM, Google Calendar, Claude Preview, Claude in Chrome, ccd_directory, mcp-registry, scheduled-tasks** — present via managed plugin.

Any new MCP server added to `~/.claude.json` requires a Claude Code restart to load. Log the addition as a TCL session and note "pending restart" in the status frontmatter.

---

## 7. The North Stars (draft, pending ratification)

Live in `~/ledgers/north_star.md`. Eighteen drafted (NS-01..NS-09 on 2026-04-17, NS-10..NS-18 on 2026-04-18), clustered as:
- **Revenue-side:** NS-01 speed-to-lead · NS-02 tasting funnel · NS-03 venue/planner ops · NS-07 social engine
- **Operating-surface:** NS-04 Close-as-authority · NS-05 unified weekly view · NS-06 Google/Outlook de-fragmentation
- **Awareness layer:** NS-10 shared op awareness · NS-11 queryable mainframe · NS-13 delta anomaly detection
- **Trust layer:** NS-12 style-aware drafting · NS-14 correction-driven trust
- **Execution/architecture:** NS-15 directory-level domain intel · NS-16 trigger bus · NS-17 observable automation · NS-18 durable replayable execution
- **Enabling/meta:** NS-08 RodBot syndication · NS-09 templatable reference model

NS-10..NS-18 rhyme with experimental Delta-side architecture the operator is building separately — **those internals are not RodBot doctrine.** These NSes are adopted here as principles; any Delta port happens deliberately through intake + TCL.

When evaluating whether to do a thing, weigh it against these. When two paths are equivalent, prefer the one that advances the higher-importance North Star.

---

## 8. Canonical facts (so nobody has to re-derive them)

- Operator / founder: **Rodrigo Souza**.
- Business: **Comeketo Catering** (B2C + some B2B, Brazilian, rodízio-style).
- Core stack: Close CRM (sales authority), Google Sheets (extensive — the "manually overextended" layer), Google Calendar (temporal backbone), ClickUp, Slack, mixed Google + Outlook/GoDaddy.
- Org roles: Executive Director → Catering Director + Sales & Marketing Director → Sales Coach, Sales Manager, SDRs (Senior/Junior), Closers (Event Planners + Catering Coordinators).
- Speed-to-lead standard: **5 minutes**, 24/7. This is the uncompromising inbound standard from the playbook.
- Tastings: twice a week, in-person, structured pipeline stage. On-the-spot booking-fee collection is the target.
- #1 referral source: **venues** (then event planners).

---

## 9. Open work queue (keep this current)

Whenever a TCL entry's `Next` section lists work that doesn't get done in that session, mirror it here so fresh threads can see it at a glance. Remove items when done.

- [ ] **Ratify / reweight / rewrite NS-01..NS-09** (from session 0003). Operator to read `ledgers/north_star.md` and either confirm or edit.
- [ ] **Verify Pieces MCP sanity query** — server is now live and initialized per operator (reported in session 0007). Confirm with a real call from this thread (e.g. `mcp__pieces__ask_pieces_ltm`).
- [ ] **Diff the `extraction-section-*` files against the master `Extraction.txt`** to see whether any carry unique content. Low priority.
- [ ] **Skim `intake/2026-04-17-bootstrap/raw-ai-mission-control.html`** — prior dashboard concept; will inform NS-05 design.
- [ ] **Ratio Lattice v0.1** — design the first real comparator schema once we have ≥3 scoreable pairs worth recording.
- [ ] **Design the Cowork + Code + Mission Control architecture** — full-stack vision captured in TCL 0019 (2026-04-19). Three tiers: Cowork sweeps (Close/Slack/ClickUp/GWorkspace), Code Routines score residuals against ledgers, Mission Control presents from GitHub→Render. Subsumes the prior "design intake/triage from clean slate" item. Open questions on Mission Control's Anthropic key and Cowork/Code vocabulary logged at the bottom of TCL 0019 for operator confirmation.
- [ ] **Stand up two new scoring ledgers** (from TCL 0019): `ledgers/sales/` (daily + weekly goals, blocked on operator interviewing the sales team) and `ledgers/open_problems.md`. Intent only — do not create until design lands.

---

## 10. When in doubt

- **Before a big action:** ask. Operator prefers one-piece-at-a-time over speed.
- **When the work shifts focus:** mark a chapter (the transcript tool).
- **When you notice out-of-scope work worth doing:** flag it as a spawnable task, don't derail the current turn.
- **When you're not sure where something belongs:** `ledgers/` is for memory of the system, `intake/` is for raw source material brought in from outside, `$HOME` root is for core orientation files (`README.md`, `AGENTS.md`, `CLAUDE.md`) only. If it's neither, ask.

---

*This file is maintained as the system evolves. When operating principles, ledger rules, or canonical facts change, update this file in the same session and commit.*
