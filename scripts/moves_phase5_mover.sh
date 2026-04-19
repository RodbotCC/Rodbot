#!/usr/bin/env bash
# moves_phase5_mover.sh
# Phase 5: consume ledgers/moves/receipts/<id>.md, execute the move per
# disposition, update receipt frontmatter, append to index.jsonl.
#
# Phase 5 is the first phase that mutates the filesystem outside
# ledgers/moves/. Be conservative. Fail loudly. Never delete silently.
#
# Usage:
#   moves_phase5_mover.sh            # daemon mode (tick forever)
#   moves_phase5_mover.sh --once     # process up to one pending receipt then exit
#   moves_phase5_mover.sh --dry-run  # parse + validate + plan; do NOT mv; do NOT edit
#                                    # receipts; do NOT append to index. Emits planned
#                                    # actions to stdout. Use to sanity-check the queue.
#
# Contract, full spec: scripts/moves_phase5_handoff.md
# Receipt schema:      ledgers/moves/receipts/README.md
#
# Dependencies (all present on stock macOS + Homebrew bash):
#   jq, sed, awk, stat, file, date, mv, mkdir, git (check-ignore)

set -euo pipefail

HOME_DIR="${HOME:-/Users/rodbot}"
MOVES_DIR="$HOME_DIR/ledgers/moves"
RECEIPTS_DIR="$MOVES_DIR/receipts"
INDEX_FILE="$MOVES_DIR/index.jsonl"
DELETE_QUEUE_FILE="$MOVES_DIR/delete-queue.md"
EVENTS_LOG="$MOVES_DIR/mover-events.jsonl"
PAUSED_FILE="$MOVES_DIR/PAUSED"

POLL_SECONDS=5

# Destination deny-list. Any proposed_destination starting with one of these
# prefixes (relative to $HOME_DIR) fails the sanity check in step 3.1.2 of
# the handoff spec. Keep in sync with that list.
DEST_DENY_PREFIXES=(
  "Library/"
  "Applications/"
  ".git/"
  ".claude/"
  ".cursor/"
  ".codex/"
  "scripts/"
  "ledgers/"
  "pieces/normalized/"
  "pieces/packets/"
  "pieces/visuals/"
)

# ─── arg parsing ──────────────────────────────────────────────────────────────
# Same shape as phase 4 (auditor) — --once and --dry-run can combine.
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
if   [ "$SEEN_ONCE" = 1 ] && [ "$SEEN_DRY" = 1 ]; then MODE="dry-run-once"
elif [ "$SEEN_ONCE" = 1 ]; then MODE="once"
elif [ "$SEEN_DRY" = 1 ]; then MODE="dry-run"
fi

mkdir -p "$MOVES_DIR" "$RECEIPTS_DIR"
touch "$EVENTS_LOG"

# ─── helpers ──────────────────────────────────────────────────────────────────

log_event() {
  # Append a structured event to mover-events.jsonl. Never fatal.
  local kind="$1"; shift
  local payload="${1:-{\}}"
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -cn --arg ts "$ts" --arg kind "$kind" --argjson payload "$payload" \
    '{ts:$ts, kind:$kind, payload:$payload}' >>"$EVENTS_LOG" 2>/dev/null || true
}

oldest_pending_receipt() {
  # Emit the oldest receipts/<id>.md whose frontmatter has
  # `phase5_status: pending`. Empty string if none.
  #
  # TODO(cursor): see handoff spec §6 for the cheap race-mitigation (require
  # frontmatter line `phase5_status: pending` to exist exactly as a whole
  # line — grep for that before parsing). Also handoff spec §2 for the "only
  # act on pending" rule.
  local f candidate= candidate_mtime=
  for f in "$RECEIPTS_DIR"/*.md; do
    [ -f "$f" ] || continue
    # Skip anything not tagged pending — this is the state-machine gate.
    grep -qE '^phase5_status: pending[[:space:]]*$' "$f" || continue
    local m; m="$(stat -f%m "$f" 2>/dev/null || echo 0)"
    if [ -z "$candidate_mtime" ] || [ "$m" -lt "$candidate_mtime" ]; then
      candidate="$f"; candidate_mtime="$m"
    fi
  done
  [ -n "$candidate" ] && printf '%s' "$candidate"
}

# parse_receipt_frontmatter RECEIPT_FILE → emits JSON to stdout, rc=1 on
# malformed. Extracts every frontmatter key:value into a JSON object so
# downstream handlers can `jq -r '.disposition'` etc.
#
# TODO(cursor): implement. Only the YAML between the first `---` and the next
# `---` matters. Handle quoted strings, booleans, numbers, null. Failure mode:
# print the parse error on stderr and return 1 — caller flips the receipt to
# phase5_status: failed per handoff spec §4.
parse_receipt_frontmatter() {
  local receipt_file="$1"
  # STUB — Cursor fills this. Suggested shape: awk between the two `---`
  # markers, emit `{key: val, ...}` with jq --arg-style building. OR use
  # python3 -c "import yaml,sys,json; print(json.dumps(yaml.safe_load(...)))"
  # if yaml is acceptable — but stdlib-bash is preferred for consistency
  # with the rest of the pipeline.
  echo "parse_receipt_frontmatter: not yet implemented for $receipt_file" >&2
  return 1
}

# update_receipt_status RECEIPT_FILE NEW_STATUS [EXTRA_KEY EXTRA_VALUE]...
# Atomically rewrites the receipt with phase5_status set to NEW_STATUS and
# any additional frontmatter keys appended (e.g. moved_at, moved_to,
# left_in_place_at, deferred_at).
#
# TODO(cursor): implement. Atomic: write to a .tmp sibling, then mv. Must
# preserve the markdown body below the closing `---` untouched. See handoff
# spec §3.1.6, §3.2.2, §3.3.1, §3.4.2.
update_receipt_status() {
  local receipt_file="$1" new_status="$2"; shift 2
  # $@ = pairs of (key, value) to append to frontmatter
  echo "update_receipt_status: not yet implemented ($receipt_file → $new_status)" >&2
  return 1
}

# write_index_line FIELDS…
# Append one JSON line to index.jsonl. Never fatal.
#
# TODO(cursor): build the object per handoff spec §3.1.7 shape and
# variants for §3.2 / §3.3 / §3.4. Accept a mix of --arg pairs or take a
# pre-built JSON string — your call.
write_index_line() {
  echo "write_index_line: not yet implemented" >&2
  return 1
}

# Is the receipt's proposed_destination safe? Emits a reason to stderr and
# returns 1 if not. See handoff spec §3.1.2 and the DEST_DENY_PREFIXES list.
check_destination_safety() {
  local dest="$1"
  # TODO(cursor): implement all of §3.1.2:
  #   - must begin with /Users/rodbot/
  #   - must not already exist (refuse to overwrite)
  #   - must not be inside any DEST_DENY_PREFIXES entry
  #   - must not be identical to original_path (no-op move)
  echo "check_destination_safety: not yet implemented for $dest" >&2
  return 1
}

# Verify original is unchanged since audit (sha256 + size match receipt).
# See handoff spec §3.1.1.
verify_source_unchanged() {
  local original_path="$1" expected_sha256="$2" expected_size="$3"
  # TODO(cursor): implement. On any mismatch, return 1 with a reason on
  # stderr — handler flips receipt to failed, source stays put.
  echo "verify_source_unchanged: not yet implemented" >&2
  return 1
}

# Ensure a relative path is present in .gitignore (append with comment if
# not). See handoff spec §3.1.3. Used only when contains_sensitive=true.
ensure_gitignored() {
  local relative_path="$1" receipt_id="$2" reason="$3"
  # TODO(cursor): implement.
  # - git -C "$HOME_DIR" check-ignore "$relative_path" → already ignored, noop
  # - else: append to .gitignore with a comment like:
  #     # receipt <id> — sensitive: <reason>
  #     <relative_path>
  # - do NOT git add / commit from this script — commit policy is open
  #   (handoff spec §6.1); leave it staged for the operator's chosen cadence.
  echo "ensure_gitignored: not yet implemented ($relative_path)" >&2
  return 1
}

# ─── disposition handlers ─────────────────────────────────────────────────────

# Each handler takes the parsed frontmatter JSON as its only argument. On
# success, updates the receipt and returns 0. On failure, writes a sibling
# <id>.phase5.log explaining why, flips receipt to phase5_status: failed, and
# returns 0 (failure-to-act is still a handled outcome — no retry loops).

handle_moved() {
  local fm_json="$1"
  # TODO(cursor): implement handoff spec §3.1 end-to-end:
  #   1. verify_source_unchanged
  #   2. check_destination_safety
  #   3. if contains_sensitive → ensure_gitignored
  #   4. mkdir -p parent of destination
  #   5. mv original_path → proposed_destination
  #   6. update_receipt_status done, moved_at, moved_to
  #   7. write_index_line disposition=moved, from, to, sha256, receipt
  echo "handle_moved: not yet implemented" >&2
  return 1
}

handle_left_in_place() {
  local fm_json="$1"
  # TODO(cursor): implement handoff spec §3.2:
  #   1. verify original_path exists
  #   2. update_receipt_status done, left_in_place_at
  #   3. write_index_line disposition=left-in-place, from=original, to=null
  echo "handle_left_in_place: not yet implemented" >&2
  return 1
}

handle_deferred() {
  local fm_json="$1"
  # TODO(cursor): implement handoff spec §3.3:
  #   1. update_receipt_status done, deferred_at
  #   2. write_index_line disposition=deferred, from=original, to=null
  echo "handle_deferred: not yet implemented" >&2
  return 1
}

handle_delete_candidate() {
  local fm_json="$1"
  # TODO(cursor): implement handoff spec §3.4:
  #   1. DO NOT DELETE
  #   2. update_receipt_status failed with reason noting sign-off required
  #   3. write_index_line disposition=delete-candidate-surfaced, from=original, to=null
  #   4. Append "- <id> — <original_path> — <sensitive_reason or rationale>" to delete-queue.md
  echo "handle_delete_candidate: not yet implemented" >&2
  return 1
}

# ─── main job loop ────────────────────────────────────────────────────────────

# Returns 0 if a receipt was handled (success OR handled-failure),
# 1 if no pending receipts.
process_one_receipt() {
  local receipt_file; receipt_file="$(oldest_pending_receipt)"
  [ -n "$receipt_file" ] || return 1

  local id; id="$(basename "$receipt_file" .md)"

  local fm_json
  if ! fm_json="$(parse_receipt_frontmatter "$receipt_file" 2>/tmp/phase5-parse-err.$$)"; then
    local err; err="$(cat /tmp/phase5-parse-err.$$ 2>/dev/null || true)"
    rm -f /tmp/phase5-parse-err.$$
    # TODO(cursor): write <id>.phase5.log, flip phase5_status to failed with
    # reason "malformed frontmatter"; see handoff spec §4.
    log_event "parse_failed" "$(jq -cn --arg id "$id" --arg err "$err" \
      '{id:$id, err:$err}')"
    return 0
  fi
  rm -f /tmp/phase5-parse-err.$$

  local disposition; disposition="$(printf '%s' "$fm_json" | jq -r '.disposition // ""')"

  # Dry-run: print the planned action and do nothing.
  if [ "$MODE" = "dry-run" ] || [ "$MODE" = "dry-run-once" ]; then
    printf '[dry-run] id=%s disposition=%s → would run handle_%s\n' \
      "$id" "$disposition" "${disposition//-/_}"
    log_event "dry_run_plan" "$(jq -cn --arg id "$id" --arg disp "$disposition" \
      '{id:$id, disposition:$disp}')"
    # In dry-run we don't consume the receipt — next real tick will pick it up.
    # Move to a different receipt next loop by touching this one's mtime
    # forward a second so oldest_pending_receipt picks the next oldest.
    touch -A 01 "$receipt_file" 2>/dev/null || true
    return 0
  fi

  case "$disposition" in
    "moved")             handle_moved             "$fm_json" ;;
    "left-in-place")     handle_left_in_place     "$fm_json" ;;
    "deferred")          handle_deferred          "$fm_json" ;;
    "delete-candidate")  handle_delete_candidate  "$fm_json" ;;
    *)
      # TODO(cursor): write <id>.phase5.log, flip to failed with reason
      # "unknown disposition: $disposition". See handoff spec §4.
      log_event "unknown_disposition" "$(jq -cn --arg id "$id" --arg disp "$disposition" \
        '{id:$id, disposition:$disp}')"
      ;;
  esac

  return 0
}

# ─── entrypoints ──────────────────────────────────────────────────────────────

log_event "started" "$(jq -cn --arg mode "$MODE" '{mode:$mode}')"

case "$MODE" in
  once|dry-run-once)
    process_one_receipt || { echo "mover: no pending receipts" >&2; exit 0; }
    ;;
  dry-run|daemon)
    while true; do
      while [ -f "$PAUSED_FILE" ]; do sleep 1; done
      if ! process_one_receipt; then
        sleep "$POLL_SECONDS"
      fi
    done
    ;;
esac
