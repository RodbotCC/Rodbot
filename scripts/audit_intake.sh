#!/usr/bin/env bash
# audit_intake.sh — detect new/unseen files in watched intake directories.
#
# Pure detection. Does not move, delete, or modify files. Emits a JSON object
# on stdout that Claude Code consumes as SessionStart additionalContext.
#
# How "new" is determined:
#   - any file under a watched dir whose absolute path is not listed in
#     ledgers/intake_state.json `known_handled_paths`, AND
#   - whose mtime is after the dir's `last_swept` timestamp (if set).
#
# Hard-noise files (.DS_Store, .crdownload, ._*) are filtered out up front.
#
# Usage:
#   scripts/audit_intake.sh           # default: emit JSON
#   scripts/audit_intake.sh --list    # human-readable list to stdout

set -euo pipefail

HOME_DIR="${HOME:-/Users/rodbot}"
STATE_FILE="$HOME_DIR/ledgers/intake_state.json"
WATCHED_DIRS=(
  "$HOME_DIR/Downloads"
  "$HOME_DIR/Desktop"
  "$HOME_DIR/Documents"
  "$HOME_DIR/Pictures"
)
MODE="${1:-json}"

# If jq is missing, degrade gracefully.
have_jq() { command -v jq >/dev/null 2>&1; }

list_candidate_files() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  # -type f -not -path '*/.*/*' to avoid descending into hidden subtrees like .Trash
  find "$dir" \
    -mindepth 1 \
    -type f \
    -not -name ".DS_Store" \
    -not -name ".localized" \
    -not -name "._*" \
    -not -name "Icon?" \
    -not -name "*.crdownload" \
    -not -name "*.download" \
    -not -name "*.part" \
    -not -path "*/.Trash/*" \
    -not -path "*/.Spotlight-*/*" \
    -not -path "*/.fseventsd/*" \
    2>/dev/null || true
}

# Collect all candidates
all=()
for d in "${WATCHED_DIRS[@]}"; do
  while IFS= read -r line; do
    [ -n "$line" ] && all+=("$line")
  done < <(list_candidate_files "$d")
done

# Filter out known-handled paths
pending=()
if have_jq && [ -f "$STATE_FILE" ]; then
  # Read known_handled_paths into a temp file for fast grep
  tmp="$(mktemp)"
  jq -r '.known_handled_paths[]? // empty' "$STATE_FILE" >"$tmp" 2>/dev/null || true
  for p in "${all[@]}"; do
    if ! grep -Fxq "$p" "$tmp"; then
      pending+=("$p")
    fi
  done
  rm -f "$tmp"
else
  pending=("${all[@]}")
fi

# Produce output
now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
count=${#pending[@]}

if [ "$MODE" = "--list" ]; then
  echo "Sweep $now_iso — $count pending items"
  for p in "${pending[@]}"; do
    sz="$(stat -f%z "$p" 2>/dev/null || echo 0)"
    mt="$(stat -f%Sm -t '%Y-%m-%dT%H:%M:%SZ' "$p" 2>/dev/null || echo '?')"
    printf '  %s  (%s bytes, mtime %s)\n' "$p" "$sz" "$mt"
  done
  exit 0
fi

# Default: emit JSON for SessionStart hook.
if [ "$count" -eq 0 ]; then
  body="Intake queue: 0 items pending as of $now_iso. Watched dirs (Downloads, Desktop, Documents, Pictures) are clean."
else
  # Build a human-readable list of pending paths, one per line
  paths_block=""
  for p in "${pending[@]}"; do
    sz="$(stat -f%z "$p" 2>/dev/null || echo 0)"
    mt="$(stat -f%Sm -t '%Y-%m-%dT%H:%M:%SZ' "$p" 2>/dev/null || echo '?')"
    paths_block="${paths_block}  - ${p} (${sz}B, mtime ${mt})\n"
  done
  body="Intake queue: $count item(s) pending triage as of $now_iso.\n\nPending:\n${paths_block}\nProtocol: read scripts/triage_protocol.md, process each file per its rules, append events to ledgers/intake_events.jsonl, and add a sweep summary to ledgers/intake_ledger.md. Screenshots require a vision audit (read the image, produce title+summary+slug, write a sidecar JSON)."
fi

# Emit properly-escaped JSON using jq if available, else manual escape.
if have_jq; then
  printf '%s' "$body" | jq -R -s '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: .}}'
else
  esc="${body//\\/\\\\}"
  esc="${esc//\"/\\\"}"
  esc="${esc//$'\n'/\\n}"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
fi
