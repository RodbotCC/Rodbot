# Sessions

Narrative write-ups of full working periods (one conversation / sitting / day of work), numbered `NNNN-slug.md`.

## How this differs from TCL

- **TCL entries** (`ledgers/TCL/NNNN-slug.md`) — fine-grained, one per action-unit (build → test → log → commit). A session typically produces several TCL entries.
- **Session entries** (this folder) — coarse-grained, one per working period. Tell the story of the whole sitting: what we set out to do, what happened, what we learned, where we ended.

If TCL is the commit log, sessions are the diary.

## When to write a session entry

At the end of a working period, before the operator steps away or hands off to a different thread. A session entry lets the next thread (or the next day's operator) rehydrate the *arc* of what happened, not just the deltas.

## Entry template

```
---
id: NNNN
slug: short-slug
date_start: YYYY-MM-DD
date_end: YYYY-MM-DD
operator: ...
assistants: ...
tcl_entries: [0001, 0002, ...]    # the TCL entries produced during this session
---

# NNNN — <title>

## Frame
One paragraph: what we walked in wanting.

## Narrative
The story, chronological. Named decisions, branch points, things that surprised us.

## Outcomes
What exists at the end of this session that didn't exist at the start.

## Loose threads
What's still open that the next session will need to pick up.

## Memorable
Anything worth preserving that doesn't fit above — a phrase, a principle, a moment of clarity or frustration. The stuff that makes future threads feel like they're continuing a relationship, not executing a protocol.
```
