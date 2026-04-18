---
id: 0004
slug: flatten-root
date: 2026-04-17
operator: rodbot (human)
assistants: Claude Code (Opus 4.7)
status: done
---

# 0004 — Flatten RodBot/ into $HOME

## What happened

Operator caught a self-inflicted redundancy: I had created `/Users/rodbot/RodBot/` as the project root, which defeats the whole framing that "this machine *is* RodBot." The home directory itself is the substrate — there should be no nested `RodBot/` folder.

## What changed

- `/Users/rodbot/RodBot/README.md` → `/Users/rodbot/README.md`
- `/Users/rodbot/RodBot/ledgers/` → `/Users/rodbot/ledgers/`
- `/Users/rodbot/RodBot/intake/` → `/Users/rodbot/intake/`
- Removed the now-empty `/Users/rodbot/RodBot/` directory.
- Rewrote every internal path reference in the six ledger files and both memory files (`project_rodbot.md`, `project_comeketo.md`) from `/Users/rodbot/RodBot/...` to `/Users/rodbot/...`.
- No collisions: no pre-existing `README.md`, `ledgers`, or `intake` at `$HOME`.

## What we learned

- When the framing is "the machine *is* X," the project lives directly in `$HOME`, not in `$HOME/X/`. Easy mistake, worth making once and never again.
- Flattening was cheap because the project is four sessions old. Same mistake caught six months from now would have been materially worse — cheap lesson.

## Next

- Resume where 0003 paused: operator ratification of NS-01..NS-09 in `ledgers/north_star.md`.
- Still pending from 0002: Claude Code restart to pick up the Pieces MCP server.
