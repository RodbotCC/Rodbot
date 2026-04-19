#!/usr/bin/env bash
# moves_phase4_auditor.sh
# Phase 4: consume inbox/<id>.json jobs, invoke LLM auditor, emit receipts.
#
# Phase 4 produces NO filesystem mutations beyond the receipt file itself
# and the consumed inbox job. Phase 5 (mover) reads receipts and executes.
#
# Receipts are markdown with YAML frontmatter and are INTENTIONALLY
# operator-editable. Frontmatter is the machine interface phase 5 reads;
# the body is for humans reviewing the auditor's reasoning.
#
# Usage:
#   moves_phase4_auditor.sh                # daemon mode (tick forever)
#   moves_phase4_auditor.sh --once         # process up to one job then exit
#   moves_phase4_auditor.sh --dry-run      # skip LLM, write skeleton receipts
#                                          # (useful to verify wiring before
#                                          #  setting ANTHROPIC_API_KEY)
#
# LLM backend: direct Anthropic Messages API via curl.
# Key resolution, in order:
#   1. $ANTHROPIC_API_KEY in the environment
#   2. /Users/rodbot/.config/rodbot/anthropic.env (sourced; must set
#      ANTHROPIC_API_KEY=sk-ant-... with shell syntax, file chmod 600)
# Model: $ANTHROPIC_MODEL env var, defaults to "claude-sonnet-4-5".
#        Auditor work is structured classification — Sonnet is the right
#        price/perf point; override to Opus only if quality forces it.
#
# Dependencies: jq, curl, file, base64, stat. All present on macOS by default
# except jq (Homebrew).

set -euo pipefail

HOME_DIR="${HOME:-/Users/rodbot}"
MOVES_DIR="$HOME_DIR/ledgers/moves"
INBOX_DIR="$MOVES_DIR/inbox"
POISONED_DIR="$INBOX_DIR/.poisoned"
RECEIPTS_DIR="$MOVES_DIR/receipts"
EVENTS_LOG="$MOVES_DIR/auditor-events.jsonl"
ATTEMPTS_DIR="$MOVES_DIR/.auditor-attempts"
PAUSED_FILE="$MOVES_DIR/PAUSED"
CONFIG_ENV="$HOME_DIR/.config/rodbot/anthropic.env"

POLL_SECONDS=5
MAX_ATTEMPTS=3
REQUEST_TIMEOUT_SECONDS=60
ANTHROPIC_API_URL="https://api.anthropic.com/v1/messages"
ANTHROPIC_API_VERSION="2023-06-01"
DEFAULT_MODEL="claude-sonnet-4-5"
MAX_TOKENS=1500

# ─── arg parsing ──────────────────────────────────────────────────────────────
# MODE is one of: daemon, once, dry-run, dry-run-once.
MODE="daemon"
SEEN_ONCE=0 SEEN_DRY=0
for arg in "$@"; do
  case "$arg" in
    --once)    SEEN_ONCE=1 ;;
    --dry-run) SEEN_DRY=1 ;;
    -h|--help) grep '^#' "$0" | head -40; exit 0 ;;
    "")        ;;
    *) echo "usage: $0 [--once] [--dry-run]" >&2; exit 2 ;;
  esac
done
if [ "$SEEN_ONCE" = 1 ] && [ "$SEEN_DRY" = 1 ]; then MODE="dry-run-once"
elif [ "$SEEN_ONCE" = 1 ]; then MODE="once"
elif [ "$SEEN_DRY" = 1 ]; then MODE="dry-run"
fi

mkdir -p "$MOVES_DIR" "$INBOX_DIR" "$POISONED_DIR" "$RECEIPTS_DIR" "$ATTEMPTS_DIR"
touch "$EVENTS_LOG"

# ─── helpers ──────────────────────────────────────────────────────────────────

log_event() {
  # Append a structured event to auditor-events.jsonl. Never fatal.
  local kind="$1" ; shift
  local payload="${1:-{\}}"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -cn --arg ts "$ts" --arg kind "$kind" --argjson payload "$payload" \
    '{ts:$ts, kind:$kind, payload:$payload}' >>"$EVENTS_LOG" 2>/dev/null || true
}

load_api_key() {
  # Returns 0 if a key is available (in $ANTHROPIC_API_KEY), 1 otherwise.
  if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    return 0
  fi
  if [ -r "$CONFIG_ENV" ]; then
    # shellcheck disable=SC1090
    set -a; . "$CONFIG_ENV"; set +a
    [ -n "${ANTHROPIC_API_KEY:-}" ] && return 0
  fi
  return 1
}

oldest_inbox_job() {
  # Emits the oldest (by mtime) inbox job path, or nothing if inbox is empty.
  # Ignores dotfiles / subdirs (.poisoned/).
  local f oldest= oldest_mtime=
  for f in "$INBOX_DIR"/*.json; do
    [ -f "$f" ] || continue
    local m
    m="$(stat -f%m "$f" 2>/dev/null || echo 0)"
    if [ -z "$oldest_mtime" ] || [ "$m" -lt "$oldest_mtime" ]; then
      oldest="$f"; oldest_mtime="$m"
    fi
  done
  [ -n "$oldest" ] && printf '%s' "$oldest"
}

attempt_count_for() {
  # Read current attempt count for a job id (0 if none).
  local id="$1"
  local f="$ATTEMPTS_DIR/$id"
  [ -f "$f" ] && cat "$f" || echo 0
}

bump_attempts() {
  local id="$1"
  local c; c="$(attempt_count_for "$id")"
  c=$((c + 1))
  printf '%s\n' "$c" >"$ATTEMPTS_DIR/$id"
  printf '%s' "$c"
}

clear_attempts() {
  local id="$1"
  rm -f "$ATTEMPTS_DIR/$id"
}

poison_job() {
  # Move a job to .poisoned/ after MAX_ATTEMPTS failures.
  local job_file="$1" id="$2" reason="$3"
  mv "$job_file" "$POISONED_DIR/$id.json" 2>/dev/null || true
  rm -f "$ATTEMPTS_DIR/$id"
  log_event "poisoned" "$(jq -cn --arg id "$id" --arg reason "$reason" \
    '{id:$id, reason:$reason}')"
}

# ─── prompt construction ──────────────────────────────────────────────────────

# System prompt: instructs the auditor on rules + output format. Kept inline
# (not a separate file) so a single `git log` on this script tells the whole
# story of how auditor judgment evolves.
build_system_prompt() {
  cat <<'EOF'
You are the auditor for a filesystem-triage pipeline running on a macOS
machine whose home directory IS the project ("RodBot"). You receive one
incoming file's metadata (and, for images, the image content). You decide
how the file should be handled and emit a strict-JSON receipt. A downstream
process ("mover") will act on your decision; your receipt is authoritative
until the operator edits it.

Output rules:
- Respond with exactly one JSON object. No prose before or after. No markdown
  fences. Just the JSON.
- All fields are required. Use null where explicitly allowed.

Disposition rules (first match wins):

1. Hard-noise (this layer never sees these — phase 2 filters them).

2. Image that looks like a CleanShot/screen capture (filename starts with
   "CleanShot", OR image/png|jpg|heic with mtime & dims consistent with a
   screen capture, OR landed on Desktop/ or Pictures/Screenshots/):
   - disposition: "moved"
   - proposed_destination: "/Users/rodbot/intake/screenshots/YYYY-MM/<slug>.<ext>"
     where YYYY-MM is the file's mtime-month and <slug> is your 2-4 word
     kebab-case summary.
   - proposed_slug: that 2-4 word slug.
   - Vision-audit the image: produce a concrete title + summary.
   - If the image shows secrets (passwords, tokens, private DMs, PII that
     is not already public), set contains_sensitive=true and give a
     concrete sensitive_reason.

3. Pieces markdown export (filename begins with "pieces_", mime text/*):
   - disposition: "moved"
   - proposed_destination:
     "/Users/rodbot/pieces/exports/YYYY-MM-DD/<HHMM>-<slug>.md"
     where YYYY-MM-DD and HHMM come from the file mtime.
   - proposed_slug: 2-4 word kebab-case drawn from the export's apparent
     topic (read the preview).

4. Business source material for Comeketo Catering — SOPs, playbooks,
   extractions, exports from Close CRM, ClickUp, Google Sheets, Slack:
   - disposition: "moved"
   - proposed_destination: "/Users/rodbot/intake/<content-slug>/<clean-name>.<ext>"
   - proposed_slug: content-led kebab-case. NEVER date-led; parent folder
     names must lead with content, never with dates.

5. Application installers (.dmg, .pkg, .app bundles, app-looking .zip):
   - disposition: "left-in-place"
   - proposed_destination: null
   - Flag for delete if mtime is ≥ 7 days old (risks field).

6. Non-screenshot media (personal photos, videos, audio that isn't a capture):
   - disposition: "deferred"
   - proposed_destination: null
   - Rationale: operator has not yet specified a rule for these; ask.

7. Ad-hoc code / configs / dotfiles downloaded from browsers (.sh, .json,
   .yaml, .py, .js, .ts landed in Downloads):
   - disposition: "deferred"
   - proposed_destination: null

8. File whose sha256 matches something already tracked (auditor cannot
   verify this; operator will): note in risks field and set disposition
   to "deferred" or "delete-candidate" as appropriate.

9. Anything else:
   - disposition: "deferred"
   - proposed_destination: null
   - Put the uncertainty in the risks field so the operator can resolve.

Path constraints (hard):
- All proposed_destination values must be absolute paths beginning with
  "/Users/rodbot/".
- Never propose destinations inside Library/, Applications/, .git/, .claude/,
  .cursor/, .codex/, or the scripts/, ledgers/, pieces/normalized/,
  pieces/packets/, pieces/visuals/ trees.
- Never propose overwriting an existing path; if the slug is plausibly
  colliding, suffix "-2", "-3", etc.

Slug rules:
- kebab-case, lowercase, 2-4 words, ≤40 chars
- content-led: derive from what the file IS, not from its metadata
- no date tokens (dates live in parent dirs and mtimes)

JSON output schema (exact keys, exact casing):
{
  "title":                  "noun phrase, ≤60 chars",
  "summary":                "1-3 sentences, ≤280 chars",
  "disposition":            "moved" | "left-in-place" | "deferred" | "delete-candidate",
  "proposed_destination":   "absolute path under /Users/rodbot/, or null",
  "proposed_slug":          "kebab-case, ≤40 chars, or null",
  "rationale":              "which rule applied + why, ≤400 chars",
  "risks":                  ["string", ...],
  "tags":                   ["string", ...],
  "contains_sensitive":     true|false,
  "sensitive_reason":       "string or null"
}
EOF
}

# build_user_content JOB_FILE
# Emits a JSON array (Anthropic "content" blocks) to stdout: text block with
# job metadata JSON, plus image block if the file is an image we can read.
# On any failure, emits just the text block.
build_user_content() {
  local job_file="$1"
  local job_json path mime
  job_json="$(cat "$job_file")"
  path="$(printf '%s' "$job_json" | jq -r '.path // ""')"
  mime="$(printf '%s' "$job_json" | jq -r '.mime // ""')"

  # Anthropic accepts image/png, image/jpeg, image/gif, image/webp, image/heic, image/heif.
  local supports_image=false
  case "$mime" in
    image/png|image/jpeg|image/jpg|image/gif|image/webp|image/heic|image/heif)
      supports_image=true ;;
  esac

  local size_bytes
  size_bytes="$(stat -f%z "$path" 2>/dev/null || echo 0)"
  # Anthropic's documented inline-image max is 5 MB base64-decoded; skip larger.
  if [ "$size_bytes" -gt 4500000 ]; then
    supports_image=false
  fi

  if [ "$supports_image" = "true" ] && [ -r "$path" ]; then
    local b64
    b64="$(base64 <"$path" | tr -d '\n')"
    # Normalize jpg → jpeg for media_type.
    local media_type="$mime"
    [ "$media_type" = "image/jpg" ] && media_type="image/jpeg"
    jq -cn \
      --arg metadata "$job_json" \
      --arg media_type "$media_type" \
      --arg data "$b64" \
      '[
         {type:"text", text:("Job metadata:\n" + $metadata + "\n\nAudit the file described above. Image content is attached below.")},
         {type:"image", source:{type:"base64", media_type:$media_type, data:$data}}
       ]'
  else
    jq -cn \
      --arg metadata "$job_json" \
      '[{type:"text", text:("Job metadata:\n" + $metadata + "\n\nAudit the file described above. No image is attached (either non-image or unreadable).")}]'
  fi
}

# ─── LLM call ─────────────────────────────────────────────────────────────────

# invoke_llm SYSTEM_PROMPT USER_CONTENT_JSON → prints JSON text on stdout, rc=0
#                                              on failure rc=1, error on stderr.
invoke_llm() {
  local system_prompt="$1"
  local user_content="$2"
  local model="${ANTHROPIC_MODEL:-$DEFAULT_MODEL}"
  local request_json

  request_json="$(jq -cn \
    --arg model "$model" \
    --arg system "$system_prompt" \
    --argjson content "$user_content" \
    --argjson max_tokens "$MAX_TOKENS" \
    '{model:$model, max_tokens:$max_tokens, system:$system,
      messages:[{role:"user", content:$content}]}')"

  local response
  response="$(curl -sS --max-time "$REQUEST_TIMEOUT_SECONDS" \
    -X POST "$ANTHROPIC_API_URL" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: $ANTHROPIC_API_VERSION" \
    -H "content-type: application/json" \
    --data-binary "$request_json" 2>&1)" || {
      echo "llm: curl failed: $response" >&2
      return 1
    }

  # Extract the text content. If the API returned an error, surface it.
  local text
  text="$(printf '%s' "$response" | jq -r '.content[0].text // empty' 2>/dev/null || true)"
  if [ -z "$text" ]; then
    local api_error
    api_error="$(printf '%s' "$response" | jq -c '.error // empty' 2>/dev/null || echo "$response")"
    echo "llm: no text in response. api_error=$api_error" >&2
    return 1
  fi
  printf '%s' "$text"
}

# ─── receipt construction ─────────────────────────────────────────────────────

# validate_receipt JSON_STRING → rc=0 if valid, 1 otherwise (reason on stderr)
validate_receipt() {
  local text="$1"
  local problems
  problems="$(printf '%s' "$text" | jq -r '
    [
      (if has("title") and (.title|type=="string") then empty else "missing/invalid title" end),
      (if has("summary") and (.summary|type=="string") then empty else "missing/invalid summary" end),
      (if (.disposition? // "") | IN("moved","left-in-place","deferred","delete-candidate") then empty else "invalid disposition" end),
      (if has("proposed_destination") then empty else "missing proposed_destination" end),
      (if has("proposed_slug") then empty else "missing proposed_slug" end),
      (if has("rationale") and (.rationale|type=="string") then empty else "missing/invalid rationale" end),
      (if (.risks? // []) | type=="array" then empty else "risks must be array" end),
      (if (.tags? // []) | type=="array" then empty else "tags must be array" end),
      (if (.contains_sensitive? // false) | type=="boolean" then empty else "contains_sensitive must be boolean" end)
    ] | join("; ")
  ' 2>&1 || echo "not valid JSON")"
  if [ -n "$problems" ]; then
    echo "receipt: $problems" >&2
    return 1
  fi
}

# write_receipt JOB_FILE RECEIPT_JSON
# Writes ledgers/moves/receipts/<id>.md. Atomic via tmp → mv.
write_receipt() {
  local job_file="$1" receipt_json="$2"
  local job_json id sha256 path filename size mime mtime suspect_sensitive
  job_json="$(cat "$job_file")"
  id="$(printf '%s' "$job_json" | jq -r '.id')"
  sha256="$(printf '%s' "$job_json" | jq -r '.sha256')"
  path="$(printf '%s' "$job_json" | jq -r '.path')"
  filename="$(printf '%s' "$job_json" | jq -r '.original_filename')"
  size="$(printf '%s' "$job_json" | jq -r '.size')"
  mime="$(printf '%s' "$job_json" | jq -r '.mime')"
  mtime="$(printf '%s' "$job_json" | jq -r '.mtime')"
  suspect_sensitive="$(printf '%s' "$job_json" | jq -r '.suspect_sensitive')"

  local audited_at model
  audited_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  model="${ANTHROPIC_MODEL:-$DEFAULT_MODEL}"

  local title summary disposition proposed_destination proposed_slug
  local rationale contains_sensitive sensitive_reason risks_md tags_md
  title="$(printf '%s' "$receipt_json" | jq -r '.title')"
  summary="$(printf '%s' "$receipt_json" | jq -r '.summary')"
  disposition="$(printf '%s' "$receipt_json" | jq -r '.disposition')"
  proposed_destination="$(printf '%s' "$receipt_json" | jq -r '.proposed_destination // "null"')"
  proposed_slug="$(printf '%s' "$receipt_json" | jq -r '.proposed_slug // "null"')"
  rationale="$(printf '%s' "$receipt_json" | jq -r '.rationale')"
  contains_sensitive="$(printf '%s' "$receipt_json" | jq -r '.contains_sensitive // false')"
  sensitive_reason="$(printf '%s' "$receipt_json" | jq -r '.sensitive_reason // "null"')"
  risks_md="$(printf '%s' "$receipt_json" | jq -r '(.risks // []) | if length == 0 then "- (none)" else map("- " + .) | join("\n") end')"
  tags_md="$(printf '%s' "$receipt_json" | jq -r '(.tags // []) | if length == 0 then "- (none)" else map("- " + .) | join("\n") end')"

  local dest_yaml slug_yaml sensitive_reason_yaml
  if [ "$proposed_destination" = "null" ]; then
    dest_yaml="null"
  else
    dest_yaml="\"$proposed_destination\""
  fi
  if [ "$proposed_slug" = "null" ]; then
    slug_yaml="null"
  else
    slug_yaml="\"$proposed_slug\""
  fi
  if [ "$sensitive_reason" = "null" ]; then
    sensitive_reason_yaml="null"
  else
    sensitive_reason_yaml="\"$sensitive_reason\""
  fi

  local receipt_file="$RECEIPTS_DIR/$id.md"
  local tmp="$RECEIPTS_DIR/.$id.md.tmp"
  cat >"$tmp" <<EOF
---
id: $id
sha256: $sha256
audited_at: $audited_at
auditor_model: $model
original_path: "$path"
original_filename: "$filename"
original_size_bytes: $size
original_mime: "$mime"
original_mtime: "$mtime"
suspect_sensitive_heuristic: $suspect_sensitive
disposition: $disposition
proposed_destination: $dest_yaml
proposed_slug: $slug_yaml
contains_sensitive: $contains_sensitive
sensitive_reason: $sensitive_reason_yaml
phase5_status: pending
---

# $title

## Summary

$summary

## Rationale

$rationale

## Risks / uncertainties

$risks_md

## Tags

$tags_md

<!--
  This receipt is operator-editable. Phase 5 (mover) reads the frontmatter
  above as authoritative. Edit disposition / proposed_destination /
  proposed_slug / contains_sensitive before phase 5 runs if the auditor
  got it wrong. Set phase5_status to "skip" to have phase 5 ignore this
  receipt entirely.
-->
EOF
  mv "$tmp" "$receipt_file"
  printf '%s' "$receipt_file"
}

# Skeleton receipt for --dry-run: valid shape, placeholder values, operator
# can fill in by editing. Lets us verify the pipeline without an LLM.
dry_run_receipt_json() {
  local job_file="$1"
  local job_json filename mime
  job_json="$(cat "$job_file")"
  filename="$(printf '%s' "$job_json" | jq -r '.original_filename')"
  mime="$(printf '%s' "$job_json" | jq -r '.mime')"
  jq -cn \
    --arg filename "$filename" \
    --arg mime "$mime" \
    '{
       title: ("[dry-run] " + $filename),
       summary: ("Skeleton receipt produced without an LLM call. mime=" + $mime + ". Operator should either enable the live backend (set ANTHROPIC_API_KEY) and re-audit, or fill these fields in manually."),
       disposition: "deferred",
       proposed_destination: null,
       proposed_slug: null,
       rationale: "Dry-run mode — no judgment applied. Operator input required.",
       risks: ["Dry-run: no auditor judgment was actually applied."],
       tags: ["dry-run"],
       contains_sensitive: false,
       sensitive_reason: null
     }'
}

# ─── main job loop ────────────────────────────────────────────────────────────

process_one_job() {
  # Returns 0 if a job was handled (success OR handled-failure), 1 if no jobs.
  local job_file
  job_file="$(oldest_inbox_job)"
  [ -n "$job_file" ] || return 1

  local id
  id="$(jq -r '.id' "$job_file" 2>/dev/null || echo "")"
  if [ -z "$id" ]; then
    # Malformed job JSON — poison immediately, don't retry.
    local base; base="$(basename "$job_file" .json)"
    mv "$job_file" "$POISONED_DIR/${base}.json" 2>/dev/null || true
    log_event "poisoned" "$(jq -cn --arg file "$base" \
      '{id:$file, reason:"unparseable job json"}')"
    return 0
  fi

  local attempts; attempts="$(attempt_count_for "$id")"
  if [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
    poison_job "$job_file" "$id" "max_attempts_exceeded ($attempts)"
    return 0
  fi

  local receipt_json receipt_file
  if [ "$MODE" = "dry-run" ] || [ "$MODE" = "dry-run-once" ]; then
    receipt_json="$(dry_run_receipt_json "$job_file")"
    receipt_file="$(write_receipt "$job_file" "$receipt_json")"
    log_event "audited" "$(jq -cn --arg id "$id" --arg receipt "$receipt_file" \
      --arg mode "dry-run" '{id:$id, receipt:$receipt, mode:$mode}')"
    clear_attempts "$id"
    rm -f "$job_file"
    return 0
  fi

  # Live path. Verify we have a key.
  if ! load_api_key; then
    bump_attempts "$id" >/dev/null
    log_event "failed" "$(jq -cn --arg id "$id" \
      '{id:$id, reason:"no ANTHROPIC_API_KEY and no config file"}')"
    return 0
  fi

  local system_prompt user_content text
  system_prompt="$(build_system_prompt)"
  user_content="$(build_user_content "$job_file")"

  if ! text="$(invoke_llm "$system_prompt" "$user_content" 2>/tmp/auditor-llm-err.$$)"; then
    local err; err="$(cat /tmp/auditor-llm-err.$$ 2>/dev/null || true)"
    rm -f /tmp/auditor-llm-err.$$
    bump_attempts "$id" >/dev/null
    log_event "llm_failed" "$(jq -cn --arg id "$id" --arg err "$err" \
      '{id:$id, err:$err}')"
    return 0
  fi
  rm -f /tmp/auditor-llm-err.$$

  # Strip markdown fences if the model disobeyed instructions and used them.
  text="$(printf '%s' "$text" | sed -E 's/^```(json)?//; s/```$//' | sed '/^$/d')"

  if ! validate_receipt "$text" 2>/tmp/auditor-val-err.$$; then
    local err; err="$(cat /tmp/auditor-val-err.$$ 2>/dev/null || true)"
    rm -f /tmp/auditor-val-err.$$
    bump_attempts "$id" >/dev/null
    log_event "invalid_receipt" "$(jq -cn --arg id "$id" --arg err "$err" --arg raw "$text" \
      '{id:$id, err:$err, raw:($raw | .[0:500])}')"
    return 0
  fi
  rm -f /tmp/auditor-val-err.$$

  receipt_file="$(write_receipt "$job_file" "$text")"
  log_event "audited" "$(jq -cn --arg id "$id" --arg receipt "$receipt_file" --arg mode "live" \
    '{id:$id, receipt:$receipt, mode:$mode}')"
  clear_attempts "$id"
  rm -f "$job_file"
  return 0
}

# ─── entrypoints ──────────────────────────────────────────────────────────────

log_event "started" "$(jq -cn --arg mode "$MODE" '{mode:$mode}')"

case "$MODE" in
  once|dry-run-once)
    process_one_job || { echo "auditor: inbox empty" >&2; exit 0; }
    ;;
  dry-run|daemon)
    while true; do
      while [ -f "$PAUSED_FILE" ]; do sleep 1; done
      if ! process_one_job; then
        sleep "$POLL_SECONDS"
      fi
    done
    ;;
esac
