# Pieces Memory Ledger

Narrative index of Pieces exports ingested into `/Users/rodbot/pieces/exports/`.

## What this is

Pieces (https://pieces.app) runs continuously on this machine and curates what happened into structured markdown summaries. When the operator exports them, they land in `Downloads/` and get routed here via the intake watcher (see `scripts/triage_protocol.md` rule 2.5).

Each export has a consistent shape:
- **TLDR** — one paragraph.
- **Core Tasks & Projects** — what got done.
- **Key Discussions & Decisions** — what was decided and why.
- **Resources Reviewed** — files, URLs, apps touched.
- **Next Steps** — what was still open at the end.

This makes them a **third-party memory feed** that overlaps with — but is independently curated from — our own TCL + sessions ledgers. Valuable precisely because the overlap is partial: Pieces sees continuous cross-tool activity (Cursor, Warp, Finder, browser, ChatGPT) that our file-based ledgers don't.

## Directory layout

```
pieces/
  exports/
    YYYY-MM-DD/
      YYYY-MM-DD-HHMM-<slug>.md     # raw markdown from Pieces
```

**Downstream layers deferred** until a consumer needs them:
- `pieces/normalized/` — structured JSON versions (when something queries them programmatically).
- `pieces/packets/` — extracted tasks/decisions/resources (when a dashboard or digest needs them).
- `pieces/visuals/` — graph/timeline outputs (when visualization work starts).

Per the draft-and-iterate principle: don't build storage layers without a consumer. The raw exports are already queryable via grep today.

## Ingest log

*(newest first)*

### 2026-04-18 — first Pieces drop (10 exports)

- Imported 10 markdown exports, all dated 2026-04-18 12:48–12:49, covering the bootstrap arc from project initiation through ledger/sessions formalization and the Tier 1 intake watcher design.
- All 10 overlap with TCL 0001–0008 and session diary 0001, but carry cross-tool detail our own ledgers don't (Cursor, Warp, Finder, ChatGPT activity; CleanShot settings; macOS login-items pane; Raycast/Wispr hotkey conflicts).
- Observation: several exports are near-duplicates of each other (Pieces curates overlapping windows). For v0 we keep all of them. If this redundancy becomes a problem at scale, add a dedup/merge pass in a future TCL entry.

Files (see `pieces/exports/2026-04-18/`):
- `2026-04-18-1248-project-initiation.md`
- `2026-04-18-1248-project-initialization.md`
- `2026-04-18-1248-system-setup.md`
- `2026-04-18-1248-infrastructure-setup.md`
- `2026-04-18-1249-ai-setup.md`
- `2026-04-18-1249-ai-setup-complete.md`
- `2026-04-18-1249-setup-ai-comm.md`
- `2026-04-18-1249-project-setup.md`
- `2026-04-18-1249-project-setup-analysis.md`
- `2026-04-18-1249-ledger-ai-files.md`

## Downstream uses (candidate, not yet built)

The other agent suggested these — capturing here so we can pull the thread later:
- **Continuity timeline** — chronological feed of events/decisions/next-steps across exports.
- **Decision graph** — nodes for named decisions, edges to files/commits/ledgers.
- **Open-threads dashboard** — "Next Steps" items that recur across exports without resolution.
- **Tool-activity map** — which tools co-occur, which feed memory vs execution.
- **Resource-review map** — which docs/URLs/whiteboards are load-bearing.
- **Bootstrap storyboard** — client-readable version of RodBot becoming real.

None of these are built. They're candidates for when we have enough exports (≥30?) that manual review stops scaling. The raw `exports/` store is the necessary precondition for any of them.
