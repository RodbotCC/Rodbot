# AGENTS.md — Cursor agent operating guide

> **CURSOR-ONLY FILE.** Other runtimes use their own:
> - `CLAUDE.md` — Claude Code (orchestrator, operator interface, source of truth)
> - `CODEX.md` — Codex (platform scraping & integrations)
>
> Do not modify this file from Codex, Claude Code, Warp, or any other runtime. Cross-cutting doctrine changes go through Claude Code.

## Scope (v0)

Cursor is the **always-on filesystem layer** for RodBot. Triggers, audits, moves, intake, any bulk file-operation work that Claude Code wouldn't do inline anyway. You build from specs Claude Code writes and commits to `ledgers/TCL/`.

Cross-runner delegation model lives in `CLAUDE.md §11`. Read it.

## Cursor startup protocol

1. Read `CLAUDE.md` fully — global RodBot operating manual and cross-runner source of truth.
2. Read `README.md` for principles and ledger map.
3. Read the latest three TCL entries in `ledgers/TCL/`.
4. Read `ledgers/north_star.md`.
5. Check the open queue in `CLAUDE.md §9` and carry unfinished "Next" work forward.

## Cursor resume protocol

- Treat `ledgers/TCL/` as canonical timeline memory across all tools.
- Continue from the most recent unresolved item, not from scratch.
- If files changed, update `ledgers/contents_ledger.md` in the same session.
- If directories changed, update `ledgers/directory_ledger.md` in the same session.
- For non-trivial, commit-sized work: add a new TCL entry before closing the session. Set `operator: cursor-agent` if Claude Code wasn't in the loop; `assistants: Cursor` always.

## Trace discipline (non-negotiable)

- Every non-trivial action writes to `ledgers/`. TCL for commit-sized work; JSONL for routine automation (e.g. `ledgers/intake_events.jsonl`, future `ledgers/moves/index.jsonl`).
- Claude Code reads these between sessions to know what you did while it was asleep. **If you don't leave a trace, your work is invisible.**

## Non-negotiables

- This machine is RodBot; do not create nested project roots.
- Canonical business spelling is `Comeketo`.
- Build one piece at a time: build → test → certify → ledger updates → commit.
- Preserve operator visual shorthand; augment existing systems before replacing.
- Slug-led folder names; no date prefixes. Move files, never copy, once indexed; no double-storage.

## If context is unclear

1. Re-read the latest TCL entry's `Next` section.
2. Re-check `CLAUDE.md §9` ("Open work queue").
3. If still ambiguous, ask the operator a focused clarifying question and proceed.
