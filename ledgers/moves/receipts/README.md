# Moves Pipeline — Receipts

Phase 4 (auditor) writes one `<id>.md` receipt per inbox job. Phase 5 (mover)
reads the YAML frontmatter at the top of each receipt and executes the
proposed move (or leaves the file in place per `disposition`).

**Receipts are operator-editable.** If the auditor got a call wrong — wrong
disposition, wrong destination, wrong sensitive flag — edit the frontmatter
directly before phase 5 runs. The body of the receipt is for humans; only
the frontmatter is authoritative.

## Frontmatter schema

```yaml
---
id:                         <12-hex, same as the consumed inbox job>
sha256:                     <64-hex, content hash>
audited_at:                 <ISO 8601 UTC>
auditor_model:              <Anthropic model id that produced this receipt>
original_path:              "<absolute source path when detected>"
original_filename:          "<basename>"
original_size_bytes:        <integer>
original_mime:              "<mime/type>"
original_mtime:             "<ISO 8601 UTC>"
suspect_sensitive_heuristic: <bool, from phase 3 filename heuristic>
disposition:                moved | left-in-place | deferred | delete-candidate
proposed_destination:       "<absolute target path>" | null
proposed_slug:              "<kebab-case>" | null
contains_sensitive:         <bool, auditor's judgment>
sensitive_reason:           "<string>" | null
phase5_status:              pending | skip | done | failed
---
```

## Disposition semantics (phase 5 contract)

| Disposition | Phase 5 action |
|---|---|
| `moved` | `mv` original_path → proposed_destination. `contains_sensitive: true` adds the destination (relative to repo root) to `.gitignore` before the move. |
| `left-in-place` | No move. Record a `left-in-place` event in `index.jsonl`. |
| `deferred` | No move. Record a `deferred` event in `index.jsonl`. Do not re-audit automatically — auditor made an intentional "I don't know" call. |
| `delete-candidate` | No move. Surface to operator. Deletion requires operator sign-off; phase 5 never deletes silently. |

## phase5_status — operator override field

- `pending` — auditor wrote it; phase 5 will pick it up.
- `skip` — operator has decided to ignore this receipt entirely. Phase 5 leaves it alone forever.
- `done` — phase 5 set this after successful execution.
- `failed` — phase 5 set this after the proposed move could not be executed (reason in a sibling `<id>.phase5.log`).

## Lifecycle

```
phase 3 writes inbox/<id>.json
  ↓
phase 4 reads inbox/<id>.json
  ↓ calls Anthropic API with metadata (+ image if applicable)
  ↓ writes receipts/<id>.md (frontmatter + body)
  ↓ deletes inbox/<id>.json
  ↓ logs {kind:"audited", id, receipt} to auditor-events.jsonl
  ↓
(operator optionally edits receipts/<id>.md)
  ↓
phase 5 reads receipts/<id>.md, executes, updates phase5_status, appends to index.jsonl
```

## Failure modes (phase 4)

- **LLM call fails** (network / rate-limit / timeout): inbox job stays, attempt count in `.auditor-attempts/<id>` bumps, retry next tick.
- **Receipt JSON is malformed or misses required fields:** inbox job stays, attempt bumps, `invalid_receipt` event logged.
- **≥3 attempts:** job moves to `inbox/.poisoned/<id>.json`, `poisoned` event logged. No automatic retry — operator must inspect and either re-drop the file or manually restore the job.
- **Missing API key:** `failed` event logged; job stays in inbox indefinitely. Resolution: set `ANTHROPIC_API_KEY` or write `~/.config/rodbot/anthropic.env`.

## Testing without an API key

```
scripts/moves_phase4_auditor.sh --once --dry-run
```

produces a skeleton receipt with placeholder fields so phase 5 can be
exercised against it without calling an LLM. Useful when bringing up the
whole chain on a new machine.
