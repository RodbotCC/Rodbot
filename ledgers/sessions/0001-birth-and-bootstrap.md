---
id: 0001
slug: birth-and-bootstrap
date_start: 2026-04-17
date_end: 2026-04-18
operator: rodbot (Rodrigo Souza)
assistants: Claude Code (Opus 4.7)
tcl_entries: [0001, 0002, 0003, 0004, 0005, 0006, 0007]
---

# 0001 — Birth and bootstrap

## Frame

Both the home and work machines had just been wiped. The operator came in wanting to try again on a long-running ambition: a semi-autonomous / autonomous intelligence-syndication system for Comeketo Catering, with this machine as the substrate. Previous attempts had been "pretty successful, but didn't feel different enough to be worth what we're doing here." The premise of this iteration was that the difference would come from *discipline* — ledgers capturing everything as we go — rather than from a clever architecture chosen up front.

The walk-in vision was ambitious: every tool on the computer (Claude Code / Work / Desktop, GPT, Codex, Cursor, Warp, Wispr Flow, Logi Options+, Raycast, Pieces) as syndicated pieces of one automation, with Pieces as the continuous activity-capture backbone. Five ledgers: TCL, Directory, Contents, Ratio Lattice, North Star. Build one piece at a time, log each piece, move on.

## Narrative

**The scaffold (0001).** Started by writing the project root, the README, and all five ledgers. Stamped everything v0. The TCL got its own subfolder and a README defining the entry template. The Ratio Lattice and North Star went in empty with scoring conventions sketched in but deliberately undefined — we didn't yet have content to score.

**Pieces MCP (0002).** Operator's priority was ingress before anything else. Pieces was listening at `localhost:39300`; a bare curl got a 400, which is the correct behavior for a streamable-HTTP MCP endpoint. Added it to `~/.claude.json` top-level `mcpServers` (backed up first). Discovered the `claude` CLI wasn't on PATH — Claude.app only. Logged "pending restart" and moved on.

**The source files (0003).** Before drafting goals, operator pulled three files off the old machine: the Comeketo Sales Playbook V2.0, a narrated Tasting walkthrough, and an Extraction document — 33 numbered observations about the business. Archived them into `intake/2026-04-17-bootstrap/`. The Extraction was the most useful single document of the whole session: it mapped the business onto a real operating model and named the key framing we kept returning to — *"The company is not broken — it is manually overextended."*

Drafted nine North Stars from that material, clustered as revenue-side (NS-01 speed-to-lead, NS-02 tasting, NS-03 venues, NS-07 social), operating-surface (NS-04 Close-as-authority, NS-05 unified weekly view, NS-06 Google/Outlook de-fragmentation), and enabling/meta (NS-08 syndication, NS-09 templatable reference model). All marked draft-pending-ratification.

**The first correction (0004).** Operator caught a self-inflicted redundancy: I had built `/Users/rodbot/RodBot/` as project root, which defeats the whole framing that *this machine is RodBot*. Flattened everything up to `$HOME`, rewrote six ledger files and two memory files, and learned the rule: when the framing is "the machine *is* X," the project lives directly in `$HOME`, not in `$HOME/X/`.

**The second correction (pushback on lock-then-build).** Operator pushed back on me framing the Ratio Lattice as "can't design this until North Stars are locked." He was right. That framing treats schemas as prerequisites when they're actually co-products. Saved the principle to memory: **design-as-we-go, not lock-then-build.** This is the kind of thing a fresh thread will need to know without being told — the kind of moment that earns its place in `CLAUDE.md`.

**GitHub (0005).** Operator wanted the whole thing under version control — public, `RodbotCC/Rodbot`. Wrote an allowlist `.gitignore` at `$HOME` (ignore everything, re-include `.gitignore`, `README.md`, `ledgers/`, `intake/`). Set git identity to `RodbotCC / tech@comeketocatering.com`. Fresh machine had neither `gh` nor writable Homebrew permissions; operator fixed Homebrew with a `sudo chown`, installed `gh`, authed via device code. First push collided with a prior web-UI upload — rebased cleanly onto remote, pushed.

**The Downloads cleanup (0006).** The remote's prior upload had included a tracked `Downloads/` folder with ten files of intake material plus two duplicates of things already in `intake/`. Locally `Downloads/` is gitignored (macOS scratch), so the two copies would have silently diverged forever. Deleted the duplicates, moved the rest into `intake/2026-04-17-bootstrap/` with kebab-case names. Preserved rename history. Discovered a prior-iteration artifact — `raw-ai-mission-control.html` — that we haven't read yet but almost certainly carries Rodrigo's visual shorthand for what an operations dashboard should feel like.

**The day's clock flipped here.** Session started 2026-04-17 and carried into 2026-04-18.

**Pieces verified out-of-thread.** Operator opened a separate thread to verify Pieces was actually initialized end-to-end. It was. The Pieces MCP tool set is now available (`mcp__pieces__ask_pieces_ltm`, workstream search tools, etc.) but hasn't been sanity-queried from *this* thread yet.

**CLAUDE.md (0007).** Operator framed the real risk: across threads, the only reliable carrier of orientation is files on disk. Asked for "the best fucking CLAUDE.md" at user scope. Wrote a ten-section operating manual covering machine identity, reading order, ledger discipline, operating principles, git conventions, MCP state, North Stars map, canonical facts, the open work queue, and when-in-doubt rules. Single source of truth: real file at `~/CLAUDE.md` (tracked), symlinked from `~/.claude/CLAUDE.md` for the global load path.

**Right before this entry:** operator asked the question that produced *this* file. Noted that `ledgers/sessions/` had been created in 0001 and never populated, and that the whole arc above felt like one "session" at a coarser grain than any individual TCL entry. He was right — it is, and the distinction needed to be named: TCL = commit log, sessions = diary.

## Outcomes

What exists now that didn't at 2026-04-17 start-of-day:

- **Project scaffold at `$HOME`:** `README.md`, `CLAUDE.md`, five ledgers, intake folder.
- **Seven TCL entries** (0001–0007) covering birth, Pieces wiring, North Star draft, flattening, GitHub, Downloads cleanup, CLAUDE.md.
- **Nine draft North Stars** (NS-01..NS-09), pending ratification.
- **Git repo live and public** at `RodbotCC/Rodbot`, authed as RodbotCC, four commits on `main`.
- **CLAUDE.md loaded globally** for every Claude Code session on this machine — orientation, discipline, and open-work queue in one file.
- **Three operator-memory entries:** RodBot project, Comeketo business, two feedback principles (build-one-piece-at-a-time, design-as-we-go).
- **Pieces MCP wired and verified live** — tools available in-session, not yet sanity-queried from this thread.
- **Intake archive** with the playbook, the tasting narrative, the Extraction, seven section-level extracts, two pasted-text notes, and a prior dashboard artifact.
- **Two folder-level READMEs** (TCL, sessions) that lock how each ledger is meant to be used.

## Loose threads

- [ ] **Ratify NS-01..NS-09** — operator hasn't read through and confirmed/reweighted yet.
- [ ] **Sanity-query Pieces** from a live thread (`mcp__pieces__ask_pieces_ltm` or similar) to confirm ingress is actually flowing, not just loaded.
- [ ] **Skim `raw-ai-mission-control.html`** — the prior-iteration dashboard concept likely informs NS-05 (unified weekly view).
- [ ] **Diff the `extraction-section-*` files** against the master Extraction to see whether any carry unique content. Low priority.
- [ ] **Ratio Lattice v0.1** — design the first real comparator schema once ≥3 scoreable pairs are worth recording.

## Memorable

- **"The company is not broken — it is manually overextended."** Extraction #33. This reframes every build decision: don't impose structure, remove manual assembly cost.
- **"The machine *is* RodBot."** Caught twice — once in the flattening, once in the CLAUDE.md placement. The framing keeps earning its keep.
- **The pushback on lock-then-build.** Operator was right and I was wrong in a way worth remembering: treating parallel schemas as sequential prerequisites is a failure mode I should watch for.
- **The day flipping over mid-session.** This session literally started one day and ended another. That's appropriate for a birth.
- **"Build one piece at a time, test it, certify it, log it. Log the session, update all the ledgers, and then we can move to whatever the next important thing is to do."** From the first message. Every TCL entry in this session obeyed that cadence. The cadence is now memory, and it is now part of CLAUDE.md.
