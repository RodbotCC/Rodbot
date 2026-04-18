<<<<<<< ours
# AGENTS.md — Cursor agent operating guide

> CURSOR-ONLY FILE.
> Do not modify this file from Codex, Warp, Claude, or any other agent runtime.
> Other runtimes must use their own platform file (for example `CODEX.md`, `WARP.md`).

This file is for Cursor agents only. It defines how Cursor resumes RodBot work.

If you are not running inside Cursor, do not treat this file as your primary system prompt. Use your platform-specific guide (for example `CLAUDE.md` for Claude Code).

## Cursor startup protocol

1. Read `CLAUDE.md` fully (global RodBot operating manual and source of truth).
2. Read `README.md` for principles and ledger map.
3. Read the latest three TCL entries in `ledgers/TCL/`.
4. Read `ledgers/north_star.md`.
5. Check the open queue in `CLAUDE.md` and carry unfinished "Next" work forward.

## Cursor resume protocol

- Treat `ledgers/TCL/` as canonical timeline memory across all tools.
- Continue from the most recent unresolved item, not from scratch.
- If files changed, update `ledgers/contents_ledger.md` in the same session.
- If directories changed, update `ledgers/directory_ledger.md` in the same session.
- For non-trivial, commit-sized work: add a new TCL entry before closing the session.

## Non-negotiables

- This machine is RodBot; do not create nested project roots.
- Canonical business spelling is `Comeketo`.
- Build one piece at a time: build -> test -> certify -> ledger updates -> commit.
- Preserve operator visual shorthand; augment existing systems before replacing.

## Platform split

- `AGENTS.md` = Cursor-specific operating contract.
- `CLAUDE.md` = Claude Code-specific operating contract.
- Additional platform guides (for Codex, Warp, etc.) should live as separate root files, not folded into this file.
- Cross-app role ownership is intentionally not finalized yet. Until the operator assigns explicit responsibilities, keep coordination lightweight and focus on continuity hygiene (TCL context, open queue carry-forward, ledger discipline).

## If context is unclear

1. Re-read the latest TCL entry's `Next` section.
2. Re-check `CLAUDE.md` section "Open work queue".
3. If still ambiguous, ask the operator a focused clarifying question and proceed.
=======
# Rodbot Codex Agent Operating Notes

This `AGENTS.md` is **for OpenAI Codex agents specifically**.
Codex should treat this as its startup/runbook file for this repository.

## Multi-agent boundary
- This file applies to **Codex only**.
- Other tools (for example Cursor, Warp, Claude, etc.) should use their own tool-specific instruction files.
- Do not assume instructions for other platforms live here.

## Primary goal
Resume work quickly and safely from the most recent saved project state.

## On startup (every new thread/session)
1. Read this file first.
2. Read `SESSION_STATE.md` before making any changes.
3. If present, read `TODO.md` and complete items top-to-bottom unless the user gives a new priority.
4. Confirm assumptions by inspecting the codebase (do not assume state is current without checking files).

## State management rules
- Keep `SESSION_STATE.md` up to date whenever meaningful progress is made.
- Keep entries concise and factual.
- Always include:
  - Current objective
  - What was completed
  - What is in progress
  - Next 1–3 concrete steps
  - Known blockers/questions
  - Last updated date (UTC)

## Safety + workflow
- Prefer small, reviewable commits.
- Run relevant checks/tests before finishing.
- If a request conflicts with these notes, follow direct user/developer/system instructions first.
>>>>>>> theirs
