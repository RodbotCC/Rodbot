# Phase 4 — Cursor Auditor Spec

This phase is intentionally **Cursor-owned**.

Claude Code is the orchestrator and spec writer. Cursor performs the ongoing
file inspection, classification, and receipt generation work.

## Ownership and runtime model

- Runtime owner: Cursor (Auto mode, long-lived local window on this machine).
- Use Cursor model preset `Auto` for this loop.
- Avoid `Premium` unless operator explicitly asks for escalation.
- Trigger source: `ledgers/moves/inbox/*.json` jobs from phase 3.
- Output target: `ledgers/moves/receipts/<id>.md`.
- Execution rule: process one oldest inbox job at a time; serialize decisions.

No phase-4 launchd daemon should be used in this repo.

## Why this split

- Keeps "thinking stage" token burn off Claude Code.
- Aligns with RodBot architecture: Cursor handles file inspection/rating/indexing
  in the moves pipeline; Codex handles expensive CRM sweeps; Claude orchestrates.
- Preserves deterministic plumbing in bash (phases 1-3) while putting judgment
  into the Cursor loop where flat-rate usage is preferred.

## Cursor operating loop

On each cycle:

1. Read the oldest `ledgers/moves/inbox/<id>.json`.
2. Apply rules from `scripts/triage_protocol.md` and `ledgers/moves/receipts/README.md`.
3. Write `ledgers/moves/receipts/<id>.md` (YAML frontmatter + markdown body).
4. Delete the consumed inbox job.
5. If classification is uncertain, emit `disposition: deferred` with clear rationale.

The receipt frontmatter is phase-5's machine contract. Keep schema strict.

## Receipt requirements

Use the schema in `ledgers/moves/receipts/README.md` exactly.

Hard constraints:
- `id` must match job id.
- `sha256` must match job sha.
- `disposition` in: `moved | left-in-place | deferred | delete-candidate`.
- `proposed_destination` absolute path under `/Users/rodbot/` or null.
- `phase5_status` starts as `pending`.

## Cursor runbook (operator)

1. Keep one Cursor chat/session pinned to "phase 4 auditor."
2. Prompt Cursor to continuously:
   - inspect oldest inbox job,
   - produce receipt,
   - remove consumed job,
   - repeat until inbox empty.
3. Leave session open during soak windows.
4. Spot-check receipts before enabling phase 5 mover.

## Out of scope for phase 4

- No filesystem moves (phase 5 only).
- No `.gitignore` mutation (phase 5 handles sensitive-path ignore updates).
- No retries/poison queue daemon logic in bash (Cursor session handles reattempts).

## Certification checklist

- Every inbox job yields exactly one receipt and job deletion.
- Receipt frontmatter parses cleanly for phase 5.
- `deferred` is used when uncertain, not forced guesses.
- Sensitive screenshot/text cases set `contains_sensitive` correctly.
