# Intake Ledger

Append-only log of every file that entered a watched directory (`Downloads/`, `Desktop/`, `Documents/`, `Pictures/`) and was triaged.

**Machine-readable events** live in `intake_events.jsonl` (one JSON object per line).
**This file** is the narrative index — groups events by sweep/session, explains rationale, surfaces open questions.

## Dispositions

- `moved` — file relocated into `intake/...` with a new path.
- `renamed` — file stayed in place but got a better name.
- `left-in-place` — file is fine where it is (e.g. app installer in Downloads to be run then deleted). Still recorded.
- `deferred` — need operator input; see rationale.
- `ignored` — below noise threshold (e.g. `.DS_Store`, half-downloaded `.crdownload`). Recorded but not acted on.
- `deleted` — removed entirely (duplicates, confirmed junk). Always requires operator sign-off or explicit rule match.

## Event schema (in `intake_events.jsonl`)

```json
{
  "ts": "2026-04-18T10:45:00Z",
  "session_id": "0008",
  "sweep_id": "2026-04-18-10-45",
  "original_path": "/Users/rodbot/Desktop/CleanShot 2026-04-18 at 10.33.45@2x.png",
  "original_size_bytes": 482193,
  "original_mtime": "2026-04-18T10:33:45Z",
  "detected_type": "cleanshot-screenshot",
  "disposition": "moved",
  "destination": "/Users/rodbot/intake/screenshots/2026-04/screenshot-2026-04-18-1033-settings-panel.png",
  "rationale": "CleanShot screenshot; vision audit produced descriptive slug 'settings-panel'.",
  "vision_audit": {
    "title": "GitHub profile settings panel (Tech Support / RodbotCC)",
    "summary": "Public profile settings page for RodbotCC account, showing tech@comeketocatering.com as the public email."
  }
}
```

## Sweeps

*(each sweep = one invocation of the audit. Newest first.)*

<!-- Template:

### Sweep YYYY-MM-DD-HH-MM — <session NNNN>

- **Watched:** Downloads, Desktop, Documents, Pictures
- **New items seen:** N
- **Triaged this sweep:** list of `original -> disposition -> destination`
- **Notes:**

-->

### Sweep 2026-04-18-15-22 — session 0008

- **Watched:** Downloads, Desktop, Documents, Pictures
- **New items seen:** 3
- **Triaged this sweep:**
  - `Downloads/⭐SALES PLAYBOOK V2.0 - Comeketo Catering.txt` → **deferred** (byte-identical duplicate of the copy already in `intake/2026-04-17-bootstrap/`; awaiting operator sign-off to delete the Downloads copy).
  - `Desktop/CleanShot 2026-04-18 at 10.49.00@2x.png` → **moved** → `intake/screenshots/2026-04/screenshot-2026-04-18-1049-claude-rodbot-setup-questions.png` (+ sidecar JSON). Vision audit: Claude Code session asking RodBot setup clarifying questions.
  - `Desktop/CleanShot 2026-04-18 at 10.58.43@2x.png` → **moved** → `intake/screenshots/2026-04/screenshot-2026-04-18-1058-rodbot-origin-diagram.png` (+ sidecar JSON). Vision audit: RodBot origin timeline whiteboard.
- **Notes:** First real sweep. `audit_intake.sh` + SessionStart hook in `~/.claude/settings.local.json` working correctly. No sensitive content in either screenshot. Operator decision needed on the duplicate playbook — treat as "confirmed duplicate of tracked content" policy candidate for v0.1 of the protocol.

