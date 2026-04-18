---
id: 0008
slug: intake-watcher
date: 2026-04-18
operator: rodbot (human)
assistants: Claude Code (Opus 4.7)
status: done
---

# 0008 — Intake watcher: nothing lands on this machine without being seen

## What happened

Operator asked for a system that catches every file landing in the four watched directories (`Downloads/`, `Desktop/`, `Documents/`, `Pictures/`), audits it, and files it correctly — "I don't care how you do it. I just wanted something so we can watch the automation actually happen and so that nothing happens on this computer without you knowing about it and indexing it correctly." Screenshots from CleanShot were called out specifically — operator wanted a vision audit producing title/metadata on each one.

Built the watcher as a boot-time sweep: a `SessionStart` hook runs `scripts/audit_intake.sh`, which enumerates pending files (diffed against a known-handled list) and injects them into the session's context. From there Claude applies `scripts/triage_protocol.md` and logs every decision to `ledgers/intake_events.jsonl` plus a narrative summary in `ledgers/intake_ledger.md`.

Ran the first sweep. Three pending items:
1. `Downloads/⭐SALES PLAYBOOK V2.0 - Comeketo Catering.txt` — byte-identical duplicate of the copy already tracked in `intake/2026-04-17-bootstrap/`. Disposition: **deferred**. Protocol requires explicit sign-off before deletion; the Downloads copy sits untouched until operator OKs removal.
2. `Desktop/CleanShot 2026-04-18 at 10.49.00@2x.png` — screenshot of a Claude Code session asking four RodBot-setup clarifying questions. Vision audited, moved to `intake/screenshots/2026-04/screenshot-2026-04-18-1049-claude-rodbot-setup-questions.png` with sidecar JSON.
3. `Desktop/CleanShot 2026-04-18 at 10.58.43@2x.png` — whiteboard timeline diagram of RodBot's birth arc ("Rodbot is born" → critical apps authorized → "Rodbot Github is created"). Vision audited, moved to `intake/screenshots/2026-04/screenshot-2026-04-18-1058-rodbot-origin-diagram.png` with sidecar JSON.

## What changed

- **New:** `scripts/` directory added to the `.gitignore` allowlist.
- **New:** `scripts/triage_protocol.md` — v0 rules (7 ordered, first match wins): hard-noise → screenshot w/ vision audit → business source material → installer (left-in-place) → non-screenshot media (deferred) → code/configs (deferred) → anything else (deferred). Also specifies the vision-audit JSON schema `{title, summary, slug_hint, contains_sensitive, tags}` and sensitive-handling (gitignore-local-only if `contains_sensitive: true`).
- **New:** `scripts/audit_intake.sh` — hard-noise pre-filter (`.DS_Store`, `.localized`, `._*`, `Icon?`, `.crdownload`, `.download`, `.part`, `.Trash`, `.Spotlight-*`, `.fseventsd`), jq-based JSON emission, `--list` mode for human inspection.
- **New:** `ledgers/intake_ledger.md` (narrative index), `ledgers/intake_events.jsonl` (append-only event log), `ledgers/intake_state.json` (watcher state: watched dirs, last_swept, known_handled_paths).
- **New:** `CLAUDE.md §3.5` — "The intake watcher — nothing lands on this machine without being seen." Operating rules for every future session.
- **New:** `SessionStart` hook in `~/.claude/settings.local.json` running `scripts/audit_intake.sh` with 30s timeout.
- **New:** `intake/screenshots/2026-04/` — first two screenshots moved in with vision-audit sidecars.
- **Updated:** `directory_ledger.md` and `contents_ledger.md` with the new paths.

## What we learned

1. **Boot-time sweep is enough for v0.** Operator explicitly said "even if only at Claude Code boot time" — no need for fsevents / launchd watchers yet. This keeps the whole system file-based, debuggable, and testable without root or LaunchAgents.
2. **The protocol has to tolerate confirmed duplicates without deleting.** The Downloads playbook is byte-identical to the intake copy, and the "right" move is clearly deletion — but the protocol's "no deletion without sign-off" rule is load-bearing for trust. Next iteration of the protocol (v0.1) should add an explicit rule: "byte-identical duplicate of already-tracked intake content → propose deletion, disposition `deferred`, surface explicitly."
3. **Vision audits produce usable slugs immediately.** Both screenshots had a clear dominant subject; the audit JSON slug mapped cleanly onto a filename. If a screenshot were more ambiguous (mixed content, no obvious subject), the protocol would need a fallback slug rule — flag if that ever shows up.
4. **Last-swept timestamps are overkill for the v0 dedup logic.** `known_handled_paths` alone is sufficient: once a path's disposition is recorded, we skip it. `last_swept` is kept as a diagnostic field for now.

## Next

- **Operator sign-off needed:** delete `/Users/rodbot/Downloads/⭐SALES PLAYBOOK V2.0 - Comeketo Catering.txt` (confirmed byte-identical duplicate)? If yes, also add v0.1 protocol rule for this class.
- **Restart / `/hooks` reload:** SessionStart hook was added mid-session; it will fire on the next Claude Code launch, not this one. First real automated sweep will happen on next session start.
- **Watch for new file types.** When a third instance of a currently-deferred category shows up (code files in Downloads, non-screenshot media, etc.), add a rule to `triage_protocol.md` and log the addition as its own TCL entry.
- **Keep NS-01..NS-09 ratification open** (carried from 0003).
