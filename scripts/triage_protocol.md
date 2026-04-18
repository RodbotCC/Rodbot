# Triage Protocol v0

Rules Claude follows when processing the intake queue. Draft-and-iterate — refine in place as new file types show up.

## Principles

1. **Move with confidence, ask when unsure.** If a file fits a known rule, execute the move and log it. If the type is new or ambiguous, set disposition to `deferred` and surface for operator input.
2. **Nothing gets deleted without explicit sign-off** unless it's on the hard-noise list (`.DS_Store`, `.crdownload`, `Icon?`) OR it's a byte-duplicate of something already indexed (delete-the-new-arrival is the default; log the decision).
3. **Every action is logged** in `intake_events.jsonl` + summarized in `intake_ledger.md`, regardless of disposition. (When the moves pipeline is live, receipts in `ledgers/moves/YYYY-MM/<id>.md` become the primary accounting record.)
4. **Move, never copy.** Once a file is indexed into RodBot surfaces, the source copy is gone. Double-storage is forbidden — no `.pdf` should live in both `Downloads/` and `intake/` after triage.
5. **Destinations reflect intent, not filetype alone.** A `.pdf` that is a business doc goes to `intake/<slug>/`. A `.pdf` that is a software manual goes to `intake/manuals/`. A `.pdf` that is a contract goes to `intake/contracts/`. Use the content, not just the extension.
6. **Slug-led folder names, no date prefixes.** New folders lead with a content slug (`intake/bootstrap/`, not `intake/2026-04-17-bootstrap/`). Dates live in file mtime and sidecars. Existing dated folders are legacy and left in place; going forward, new folders follow this rule.

## Rules (check in order; first match wins)

### 1. Hard-noise (auto-ignore, no operator prompt)

Disposition: `ignored`. Log only.
- `.DS_Store`, `._*`, `Icon?`
- `*.crdownload`, `*.download`, `*.part`
- macOS quarantine artifacts

### 2. CleanShot / screenshot

Detection: filename starts with `CleanShot` (any case), OR is a `.png`/`.jpg`/`.heic` landing on `Desktop/` or `Pictures/Screenshots/`.

Action: **vision audit** (Claude reads the image and writes a short title + 1-sentence summary), then move to:
```
intake/screenshots/YYYY-MM/<slug>.png
```
where `<slug>` is a 2–4 word kebab-case description derived from the vision audit. No `screenshot-` prefix, no date in the filename — the parent directory encodes the month, and the file's mtime is authoritative for the exact capture time. If a slug collides with an existing file in the same month folder, append `-2`, `-3`, etc.

Also write a sidecar JSON next to the moved file:
```
intake/screenshots/YYYY-MM/<slug>.json
```
containing `{title, summary, original_name, original_path, captured_at, vision_audited_at}`. The sidecar's `captured_at` is the authoritative timestamp; the filename intentionally carries only the content.

### 2.5. Pieces exports

Detection: filename matches `pieces_*.md` OR first line contains `*Shared Summary from Pieces (https://pieces.app)`.

Action: move to `pieces/exports/YYYY-MM-DD/YYYY-MM-DD-HHMM-<slug>.md`, where `<slug>` is derived from the original filename (strip `pieces_rodbot_` prefix, convert `_` to `-`) and `HHMM` is the file's mtime. Then append a ledger note to `ledgers/pieces_memory_ledger.md` under the relevant date section (create one if needed). No vision audit; no parsing — raw markdown only for v0. Downstream normalization/packets/visuals are deferred per the draft-and-iterate principle.

### 3. Business source material (playbooks, SOPs, extractions, exports)

Detection: `.txt`, `.md`, `.pdf`, `.csv`, `.xlsx` that (a) is clearly Comeketo / RodBot-relevant by filename or first-page content, or (b) is a data export from Close, ClickUp, Google Sheets, Slack, etc.

Action: move to `intake/<context-slug>/<clean-name.ext>`. Context slug is content-derived (e.g., `intake/close-export-pipeline/`, `intake/venue-contracts/`). If an open matching folder exists, add to it rather than creating a new one. No date prefix on the folder name — the contents' mtimes and the TCL entry carry that.

### 4. Installers / disk images / archives (apps and software)

Detection: `.dmg`, `.pkg`, `.zip`/`.tar.gz` if filename looks like app distribution, `.app` bundles on Desktop.

Action: **`left-in-place`** with a log entry. These are transient — operator will run/install them, then remove. Claude's job is to catalog, not relocate. Flag only if the same installer has been sitting ≥ 7 days untouched.

### 5. Recognizable media (photos, videos, audio) that isn't a screenshot

Action: **`deferred`** in v0. Too many possible intents (personal photo, marketing asset, b-roll for content, event documentation). Ask operator how they want these routed before establishing a rule.

### 6. Code, configs, dotfiles downloaded ad-hoc

Detection: `.sh`, `.json`, `.yaml`, `.py`, `.js`, `.ts`, etc. landing in Downloads.

Action: **`deferred`**. Could be a one-off snippet, part of a larger project, or an MCP server config. Ask.

### 7. Anything else

Disposition: **`deferred`**. Log with a note asking operator what this is. Never silently move a file whose category is unknown.

## CleanShot vision audit — what to produce

For each screenshot, write a vision audit of the form:

```json
{
  "title": "<concise noun phrase, ≤ 60 chars>",
  "summary": "<one sentence, ≤ 180 chars, what this screenshot shows>",
  "slug_hint": "<2-4 words, kebab-case, suitable for filenames>",
  "contains_sensitive": <true|false>,
  "tags": ["<free-form>", "<tags>"]
}
```

If `contains_sensitive: true` (passwords, API tokens, private DMs, identifying info not already public), do NOT commit the screenshot to git — move it to `intake/screenshots/YYYY-MM/` locally but add the filename to `.gitignore` and note the reason in the sidecar.

## Evolving this protocol

When a new file type shows up for the third time without a rule, add a rule for it here and log the addition in a TCL entry. Rules should accumulate evidence before they crystallize.
