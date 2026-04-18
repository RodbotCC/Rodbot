---
id: 0007
slug: claude-md-global
date: 2026-04-18
operator: rodbot (human)
assistants: Claude Code (Opus 4.7)
status: done
---

# 0007 — Global CLAUDE.md as orientation manual

## What happened

Operator started a new thread and verified the Pieces MCP server is now live and initialized (confirmed via ToolSearch — `mcp__pieces__*` tools are available). The new thread cannot read the prior thread's context, which surfaced the real risk: **across threads, the only reliable carrier of orientation is files on disk.**

Operator asked for the "best fucking CLAUDE.md" possible — at user-scope, because "the entire computer is always going to be doing exactly this." Wrote the orientation manual.

## What changed

- Wrote `CLAUDE.md` at repo root (`/Users/rodbot/CLAUDE.md`) — the canonical orientation doc for every Claude Code session on this machine. Covers:
  1. What this machine is (RodBot, not nested)
  2. Reading order for a fresh session
  3. Five-ledger update discipline
  4. Operating principles (one-piece-at-a-time, draft-and-iterate, visual shorthand, "manually overextended")
  5. Git / GitHub conventions and commit template
  6. MCP / ingress state
  7. North Stars map
  8. Canonical facts (spelling, roles, 5-min speed-to-lead, #1 referral = venues)
  9. Open work queue
  10. When-in-doubt rules
- Placed the canonical file at `$HOME/CLAUDE.md` (tracked via allowlist) and symlinked `~/.claude/CLAUDE.md → ../CLAUDE.md` so it loads globally regardless of cwd while staying version-controlled.
- Added `!CLAUDE.md` to the `.gitignore` allowlist.

## What we learned

- **Memory files + TCL entries + CLAUDE.md are three overlapping layers.** Memory is summarized-for-future-sessions ("what do I need to know cheaply?"), TCL is the narrative ("what happened in order?"), CLAUDE.md is the operating manual ("how do we work here?"). Each has a distinct job — don't collapse them.
- **Symlinking into `~/.claude/`** keeps a single source of truth tracked in git while preserving the global-load behavior Claude Code gives to `~/.claude/CLAUDE.md`. Repo readers see only the canonical `CLAUDE.md` at root.
- The open-work-queue section of CLAUDE.md should be curated — it's the first thing a fresh thread will try to act on.

## Next

- **Operator**: when a new thread opens, confirm it reads CLAUDE.md and resumes cleanly.
- Sanity-query Pieces from this thread (`mcp__pieces__ask_pieces_ltm` with something like "what was I working on in the last hour?") to verify the ingress is actually flowing, not just loaded.
- Outstanding from earlier sessions (now also mirrored in CLAUDE.md §9):
  - Ratify NS-01..NS-09.
  - Optional: skim `raw-ai-mission-control.html` for dashboard design cues.
  - Optional: diff `extraction-section-*` files against the master Extraction.
