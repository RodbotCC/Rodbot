---
id: 0005
slug: github-live
date: 2026-04-18
operator: rodbot (human)
assistants: Claude Code (Opus 4.7)
status: done
---

# 0005 — GitHub repo live

## What happened

Put the RodBot ledger system under version control and pushed to `RodbotCC/Rodbot` on GitHub (public). Commit cadence going forward: **one commit per TCL session**.

Operator fixed `/opt/homebrew` ownership, installed `gh`, authed as `RodbotCC` via device-code flow.

Before I pushed, operator had already uploaded the ledger files (plus a `Downloads/` folder of extra intake material) to the repo via the GitHub web UI. Local `Birth` commit was rebased onto that upload, so history is: `2126417 Add files via upload` → `f765f0d Birth: scaffold RodBot ledger system`.

## What changed

- Set git identity: `user.name = RodbotCC`, `user.email = tech@comeketocatering.com`.
- Wrote `.gitignore` with an **allowlist** approach at `$HOME`: ignore everything, then re-include `.gitignore`, `README.md`, `ledgers/`, `intake/`. Prevents `Library/`, `Desktop/`, etc. from ever leaking into git.
- `git init` on `main`, first commit covering sessions 0001–0004, rebased onto remote, pushed.
- Remote tracking set: `main` → `origin/main`.

## What we learned

- The remote has a tracked `Downloads/` directory from the operator's web-UI upload. Locally, `Downloads/` is gitignored (it's a standard macOS folder for transient files — correctly excluded by the allowlist). That mismatch is a **divergence risk**: anything edited in the remote `Downloads/` via the GitHub web UI will not flow back to the local machine because git sees it as ignored.
- The files in the remote `Downloads/` look like intake material (extracted business-analysis sections: "Overall business shape", "Sales and lead management", "weekly labor reporting", etc., plus two `Pasted text` files). They belong in `intake/`, not `Downloads/`.

## Open question for operator

**Should we move the remote `Downloads/*` into `intake/` (and delete `Downloads/` from the repo)?**

Recommendation: yes. `Downloads/` as a tracked path is a footgun on macOS — any random download dragged into the folder becomes a git question. Canonical intake location is `intake/YYYY-MM-DD-<slug>/`. I'll wait for your call before doing this.

## Next

- Operator decision on the `Downloads/` → `intake/` move.
- Still pending from 0002: Claude Code restart for Pieces MCP.
- Still pending from 0003: North Star ratification.
