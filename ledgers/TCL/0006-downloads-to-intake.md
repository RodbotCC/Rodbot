---
id: 0006
slug: downloads-to-intake
date: 2026-04-18
operator: rodbot (human)
assistants: Claude Code (Opus 4.7)
status: done
---

# 0006 — Remote `Downloads/` → `intake/`

## What happened

Closed the divergence risk flagged in 0005: the repo had a tracked `Downloads/` folder from the operator's initial web upload, but locally `Downloads/` is (correctly) gitignored as macOS scratch space. Anything edited in the remote `Downloads/` via the web UI would have silently failed to flow back.

Operator authorized the cleanup. All tracked files moved into the canonical intake location.

## What changed

Deleted (already-duplicated elsewhere):
- `Downloads/Extraction.txt` — byte-identical to `intake/2026-04-17-bootstrap/Extraction.txt`.
- `Downloads/Tasting.txt` — byte-identical to `intake/2026-04-17-bootstrap/Tasting.txt`.

Renamed into `intake/2026-04-17-bootstrap/` with kebab-case, descriptive names (git preserved rename history):
- `He uses visual readability…txt` → `extraction-section-visual-readability.txt`
- `Jobs:events are operationally detailed.txt` → `extraction-section-jobs-events-detailed.txt`
- `Overall business shape.txt` → `extraction-section-overall-business-shape.txt`
- `Sales and lead management.txt` → `extraction-section-sales-lead-management.txt`
- `Scheduling is a major operational function .txt` → `extraction-section-scheduling.txt`
- `The calendar is a core source.txt` → `extraction-section-calendar.txt`
- `weekly labor reporting.txt` → `extraction-section-weekly-labor.txt`
- `Pasted text.txt` → `pasted-text-1.txt`
- `Pasted text (1).txt` → `pasted-text-2.txt`
- `index.html` → `raw-ai-mission-control.html` (a prior-work dashboard concept titled "RAW AI Mission Control")

After the commit, `Downloads/` no longer exists in the repo; locally it remains a normal macOS folder and is gitignored.

## What we learned

- The seven "extraction-section" files are the Extraction doc's numbered observations broken out per section. They overlap with the master `Extraction.txt` but may carry extra phrasing worth preserving — worth a diff pass later.
- `raw-ai-mission-control.html` is the most interesting artifact: a dashboard concept from the operator's prior iterations. Skim it before designing any new dashboard — the operator already has a visual language to respect (per Extraction #10: fast visual comprehension).

## Next

- Still pending from 0002: Claude Code restart for Pieces MCP verification.
- Still pending from 0003: North Star ratification (NS-01..NS-09).
- Low-priority: diff extraction-section files against the master Extraction to see if any carry unique content, or are redundant.
- Low-priority: open `raw-ai-mission-control.html` and understand what the operator had in mind — may inform NS-05 (unified weekly view) design.
