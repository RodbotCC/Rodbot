---
id: 0002
slug: pieces-mcp
date: 2026-04-17
operator: rodbot (human)
assistants: Claude Code (Opus 4.7)
status: pending-restart
---

# 0002 — Wire up Pieces MCP (first ingress)

## What happened

Before writing North Star goals, the operator redirected to getting ingress flowing. Pieces is the priority because it's the continuous activity-capture backbone — it needs to be running and queryable before anything else, so nothing that happens on the machine goes uncatalogued.

Pieces exposes an MCP endpoint at:
`http://localhost:39300/model_context_protocol/2025-03-26/mcp`

Confirmed server is live (bare `curl` returns 400, expected for streamable-HTTP MCP without a proper handshake).

## What changed

- Backed up `~/.claude.json` to `~/.claude/backups/claude.json.pre-pieces-20260417-231810.bak`.
- Added `pieces` server to the top-level `mcpServers` in `~/.claude.json`:
  ```json
  { "type": "http", "url": "http://localhost:39300/model_context_protocol/2025-03-26/mcp" }
  ```
- Note: `~/.claude.json` had no prior `mcpServers` entries — the Slack/ClickUp/etc. MCPs visible in the current session come from a different (managed) source.

## What we learned

- Claude CLI is *not* on PATH on this fresh machine (`which claude` → not found). Only the Claude.app desktop bundle is installed. Follow-up: decide whether to install the CLI or operate via app only.
- MCP changes to `~/.claude.json` require a Claude Code restart to take effect in-session.

## Next

- **Operator**: restart Claude Code so the `pieces` MCP server gets loaded.
- Then: verify Pieces tools are callable (e.g. via `ToolSearch` → one of the `pieces` tools) and run a sanity query.
- Then: discuss which other ingress to wire up next (candidates mentioned: Calendar, Slack already present, Close CRM already present, ClickUp already present, Claude Preview, Claude in Chrome). Confirm scope.
- Still deferred: North Star goals.
