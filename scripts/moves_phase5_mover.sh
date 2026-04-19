#!/usr/bin/env bash
# moves_phase5_mover.sh
# Phase 5: consume ledgers/moves/receipts/<id>.md, execute moves per
# disposition, update receipt status, append index lines.

set -euo pipefail

HOME_DIR="${HOME:-/Users/rodbot}"
MOVES_DIR="$HOME_DIR/ledgers/moves"
RECEIPTS_DIR="$MOVES_DIR/receipts"
INDEX_FILE="$MOVES_DIR/index.jsonl"
DELETE_QUEUE_FILE="$MOVES_DIR/delete-queue.md"
EVENTS_LOG="$MOVES_DIR/mover-events.jsonl"
PAUSED_FILE="$MOVES_DIR/PAUSED"

POLL_SECONDS=5

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

MODE="daemon"
SEEN_ONCE=0
SEEN_DRY=0
for arg in "$@"; do
  case "$arg" in
    --once) SEEN_ONCE=1 ;;
    --dry-run) SEEN_DRY=1 ;;
    -h|--help) grep '^#' "$0" | head -40; exit 0 ;;
    *) echo "usage: $0 [--once] [--dry-run]" >&2; exit 2 ;;
  esac
done
if [ "$SEEN_ONCE" = 1 ] && [ "$SEEN_DRY" = 1 ]; then MODE="dry-run-once"
elif [ "$SEEN_ONCE" = 1 ]; then MODE="once"
elif [ "$SEEN_DRY" = 1 ]; then MODE="dry-run"
fi

mkdir -p "$MOVES_DIR" "$RECEIPTS_DIR"
touch "$EVENTS_LOG" "$INDEX_FILE"

log_event() {
  local kind="$1"
  local payload="${2:-{\}}"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -cn --arg ts "$ts" --arg kind "$kind" --argjson payload "$payload" \
    '{ts:$ts, kind:$kind, payload:$payload}' >>"$EVENTS_LOG" 2>/dev/null || true
}

trim() {
  printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

oldest_pending_receipt() {
  local f candidate="" candidate_mtime=""
  for f in "$RECEIPTS_DIR"/*.md; do
    [ -f "$f" ] || continue
    grep -qE '^phase5_status: pending[[:space:]]*$' "$f" || continue
    local m
    m="$(stat -f%m "$f" 2>/dev/null || echo 0)"
    if [ -z "$candidate_mtime" ] || [ "$m" -lt "$candidate_mtime" ]; then
      candidate="$f"
      candidate_mtime="$m"
    fi
  done
  [ -n "$candidate" ] && printf '%s' "$candidate"
}

extract_frontmatter() {
  local receipt_file="$1"
  awk '
    BEGIN {d=0}
    /^---[[:space:]]*$/ { d++; next }
    d==1 { print; next }
    d>=2 { exit }
  ' "$receipt_file"
}

extract_body() {
  local receipt_file="$1"
  awk '
    BEGIN {d=0}
    /^---[[:space:]]*$/ { d++; next }
    d>=2 { print }
  ' "$receipt_file"
}

parse_receipt_frontmatter() {
  local receipt_file="$1"
  local delimiters
  delimiters="$(awk '/^---[[:space:]]*$/ {c++} END {print c+0}' "$receipt_file")"
  [ "$delimiters" -ge 2 ] || {
    echo "missing frontmatter delimiters" >&2
    return 1
  }

  local obj='{}'
  local line key raw val
  while IFS= read -r line; do
    [ -n "$(trim "$line")" ] || continue
    case "$line" in
      *:*) ;;
      *) echo "bad frontmatter line: $line" >&2; return 1 ;;
    esac
    key="$(trim "${line%%:*}")"
    raw="${line#*:}"
    val="$(trim "$raw")"
    [ -n "$key" ] || {
      echo "empty key in frontmatter" >&2
      return 1
    }

    if [ -z "$val" ] || [ "$val" = "null" ]; then
      obj="$(printf '%s' "$obj" | jq --arg k "$key" '. + {($k): null}')" || return 1
    elif [ "$val" = "true" ] || [ "$val" = "false" ]; then
      obj="$(printf '%s' "$obj" | jq --arg k "$key" --argjson v "$val" '. + {($k): $v}')" || return 1
    elif [[ "$val" =~ ^-?[0-9]+$ ]]; then
      obj="$(printf '%s' "$obj" | jq --arg k "$key" --argjson v "$val" '. + {($k): $v}')" || return 1
    elif [[ "$val" =~ ^\".*\"$ ]]; then
      val="${val#\"}"
      val="${val%\"}"
      val="${val//\\\"/\"}"
      val="${val//\\\\/\\}"
      obj="$(printf '%s' "$obj" | jq --arg k "$key" --arg v "$val" '. + {($k): $v}')" || return 1
    else
      obj="$(printf '%s' "$obj" | jq --arg k "$key" --arg v "$val" '. + {($k): $v}')" || return 1
    fi
  done < <(extract_frontmatter "$receipt_file")

  printf '%s' "$obj"
}

yaml_scalar_from_json() {
  local json="$1"
  local key="$2"
  local t
  t="$(printf '%s' "$json" | jq -r --arg k "$key" '.[$k] | type')"
  case "$t" in
    null) printf 'null' ;;
    boolean|number) printf '%s' "$(printf '%s' "$json" | jq -r --arg k "$key" '.[$k]')" ;;
    string)
      local s
      s="$(printf '%s' "$json" | jq -r --arg k "$key" '.[$k]')"
      s="${s//\\/\\\\}"
      s="${s//\"/\\\"}"
      printf '"%s"' "$s"
      ;;
    *)
      printf '"%s"' "$(printf '%s' "$json" | jq -c --arg k "$key" '.[$k]')"
      ;;
  esac
}

update_receipt_status() {
  local receipt_file="$1"
  local new_status="$2"
  shift 2

  local fm_json
  fm_json="$(parse_receipt_frontmatter "$receipt_file")" || return 1
  fm_json="$(printf '%s' "$fm_json" | jq --arg s "$new_status" '.phase5_status = $s')" || return 1

  while [ "$#" -ge 2 ]; do
    local k="$1"
    local v="$2"
    shift 2
    if [ "$v" = "__NULL__" ]; then
      fm_json="$(printf '%s' "$fm_json" | jq --arg k "$k" '. + {($k): null}')" || return 1
    elif [ "$v" = "true" ] || [ "$v" = "false" ]; then
      fm_json="$(printf '%s' "$fm_json" | jq --arg k "$k" --argjson v "$v" '. + {($k): $v}')" || return 1
    elif [[ "$v" =~ ^-?[0-9]+$ ]]; then
      fm_json="$(printf '%s' "$fm_json" | jq --arg k "$k" --argjson v "$v" '. + {($k): $v}')" || return 1
    else
      fm_json="$(printf '%s' "$fm_json" | jq --arg k "$k" --arg v "$v" '. + {($k): $v}')" || return 1
    fi
  done

  local body_tmp out_tmp
  body_tmp="$(mktemp)"
  out_tmp="$(mktemp)"
  extract_body "$receipt_file" >"$body_tmp"

  {
    echo "---"
    while IFS= read -r key; do
      printf '%s: %s\n' "$key" "$(yaml_scalar_from_json "$fm_json" "$key")"
    done < <(printf '%s' "$fm_json" | jq -r 'keys[]')
    echo "---"
    cat "$body_tmp"
  } >"$out_tmp"

  mv "$out_tmp" "$receipt_file"
  rm -f "$body_tmp"
}

fallback_mark_parse_failed() {
  local receipt_file="$1"
  local tmp
  tmp="$(mktemp)"
  awk '
    BEGIN {done=0}
    {
      if (!done && $0 ~ /^phase5_status: pending[[:space:]]*$/) {
        print "phase5_status: failed"
        done=1
      } else {
        print
      }
    }
  ' "$receipt_file" >"$tmp"
  mv "$tmp" "$receipt_file"
}

write_phase5_log() {
  local receipt_file="$1"
  local reason="$2"
  local log_file="${receipt_file%.md}.phase5.log"
  {
    echo "ts: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "reason: $reason"
  } >"$log_file"
}

write_index_line() {
  local json_line="$1"
  printf '%s\n' "$json_line" >>"$INDEX_FILE"
}

check_destination_safety() {
  local dest="$1"
  local original_path="$2"

  [[ "$dest" == "$HOME_DIR/"* ]] || {
    echo "destination must be under $HOME_DIR" >&2
    return 1
  }
  [ "$dest" != "$original_path" ] || {
    echo "destination equals source path" >&2
    return 1
  }
  [ ! -e "$dest" ] || {
    echo "destination already exists: $dest" >&2
    return 1
  }

  local rel="${dest#"$HOME_DIR"/}"
  local prefix
  for prefix in "${DEST_DENY_PREFIXES[@]}"; do
    if [[ "$rel" == "$prefix"* ]]; then
      echo "destination denied by prefix: $prefix" >&2
      return 1
    fi
  done
}

verify_source_unchanged() {
  local original_path="$1"
  local expected_sha256="$2"
  local expected_size="$3"

  [ -f "$original_path" ] || {
    echo "source missing: $original_path" >&2
    return 1
  }

  local size
  size="$(stat -f%z "$original_path" 2>/dev/null || echo -1)"
  [ "$size" = "$expected_size" ] || {
    echo "source size mismatch: expected=$expected_size got=$size" >&2
    return 1
  }

  local sha256
  sha256="$(shasum -a 256 "$original_path" | awk '{print $1}')"
  [ "$sha256" = "$expected_sha256" ] || {
    echo "source sha256 mismatch: expected=$expected_sha256 got=$sha256" >&2
    return 1
  }
}

ensure_gitignored() {
  local relative_path="$1"
  local receipt_id="$2"
  local reason="$3"
  local gitignore_file="$HOME_DIR/.gitignore"

  if git -C "$HOME_DIR" check-ignore -q -- "$relative_path"; then
    return 0
  fi

  if grep -Fxq "$relative_path" "$gitignore_file"; then
    return 0
  fi

  {
    echo
    echo "# receipt $receipt_id — sensitive: $reason"
    echo "$relative_path"
  } >>"$gitignore_file"
}

mark_failed() {
  local receipt_file="$1"
  local id="$2"
  local reason="$3"
  local original_path="$4"

  write_phase5_log "$receipt_file" "$reason"
  update_receipt_status "$receipt_file" "failed" "phase5_error" "$reason" || true
  write_index_line "$(jq -cn \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg id "$id" \
    --arg disposition "failed" \
    --arg reason "$reason" \
    --arg from "$original_path" \
    --arg receipt "ledgers/moves/receipts/$id.md" \
    '{ts:$ts,id:$id,disposition:$disposition,reason:$reason,from:$from,to:null,receipt:$receipt}')"
  log_event "failed" "$(jq -cn --arg id "$id" --arg reason "$reason" '{id:$id,reason:$reason}')"
}

handle_moved() {
  local fm_json="$1"
  local receipt_file="$2"
  local id original_path destination sha256 expected_size contains_sensitive sensitive_reason
  id="$(printf '%s' "$fm_json" | jq -r '.id // ""')"
  original_path="$(printf '%s' "$fm_json" | jq -r '.original_path // ""')"
  destination="$(printf '%s' "$fm_json" | jq -r '.proposed_destination // ""')"
  sha256="$(printf '%s' "$fm_json" | jq -r '.sha256 // ""')"
  expected_size="$(printf '%s' "$fm_json" | jq -r '.original_size_bytes // -1')"
  contains_sensitive="$(printf '%s' "$fm_json" | jq -r '.contains_sensitive // false')"
  sensitive_reason="$(printf '%s' "$fm_json" | jq -r '.sensitive_reason // ""')"

  verify_source_unchanged "$original_path" "$sha256" "$expected_size" || {
    mark_failed "$receipt_file" "$id" "source changed between audit and move" "$original_path"
    return 0
  }
  check_destination_safety "$destination" "$original_path" || {
    mark_failed "$receipt_file" "$id" "unsafe destination: $destination" "$original_path"
    return 0
  }

  if [ "$contains_sensitive" = "true" ]; then
    local rel
    rel="${destination#"$HOME_DIR"/}"
    ensure_gitignored "$rel" "$id" "$sensitive_reason" || {
      mark_failed "$receipt_file" "$id" "failed to update .gitignore for sensitive file" "$original_path"
      return 0
    }
  fi

  mkdir -p "$(dirname "$destination")"
  mv "$original_path" "$destination" || {
    mark_failed "$receipt_file" "$id" "mv failed to destination" "$original_path"
    return 0
  }

  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  update_receipt_status "$receipt_file" "done" "moved_at" "$ts" "moved_to" "$destination" || true
  write_index_line "$(jq -cn \
    --arg ts "$ts" \
    --arg id "$id" \
    --arg disposition "moved" \
    --arg from "$original_path" \
    --arg to "$destination" \
    --arg sha256 "$sha256" \
    --arg receipt "ledgers/moves/receipts/$id.md" \
    '{ts:$ts,id:$id,disposition:$disposition,from:$from,to:$to,sha256:$sha256,receipt:$receipt}')"
  log_event "moved" "$(jq -cn --arg id "$id" --arg from "$original_path" --arg to "$destination" '{id:$id,from:$from,to:$to}')"
}

handle_left_in_place() {
  local fm_json="$1"
  local receipt_file="$2"
  local id original_path
  id="$(printf '%s' "$fm_json" | jq -r '.id // ""')"
  original_path="$(printf '%s' "$fm_json" | jq -r '.original_path // ""')"

  if [ ! -f "$original_path" ]; then
    mark_failed "$receipt_file" "$id" "left-in-place source path missing" "$original_path"
    return 0
  fi

  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  update_receipt_status "$receipt_file" "done" "left_in_place_at" "$ts" || true
  write_index_line "$(jq -cn \
    --arg ts "$ts" \
    --arg id "$id" \
    --arg disposition "left-in-place" \
    --arg from "$original_path" \
    --arg receipt "ledgers/moves/receipts/$id.md" \
    '{ts:$ts,id:$id,disposition:$disposition,from:$from,to:null,receipt:$receipt}')"
  log_event "left_in_place" "$(jq -cn --arg id "$id" '{id:$id}')"
}

handle_deferred() {
  local fm_json="$1"
  local receipt_file="$2"
  local id original_path
  id="$(printf '%s' "$fm_json" | jq -r '.id // ""')"
  original_path="$(printf '%s' "$fm_json" | jq -r '.original_path // ""')"

  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  update_receipt_status "$receipt_file" "done" "deferred_at" "$ts" || true
  write_index_line "$(jq -cn \
    --arg ts "$ts" \
    --arg id "$id" \
    --arg disposition "deferred" \
    --arg from "$original_path" \
    --arg receipt "ledgers/moves/receipts/$id.md" \
    '{ts:$ts,id:$id,disposition:$disposition,from:$from,to:null,receipt:$receipt}')"
  log_event "deferred" "$(jq -cn --arg id "$id" '{id:$id}')"
}

handle_delete_candidate() {
  local fm_json="$1"
  local receipt_file="$2"
  local id original_path sensitive_reason rationale
  id="$(printf '%s' "$fm_json" | jq -r '.id // ""')"
  original_path="$(printf '%s' "$fm_json" | jq -r '.original_path // ""')"
  sensitive_reason="$(printf '%s' "$fm_json" | jq -r '.sensitive_reason // ""')"
  rationale="$(printf '%s' "$fm_json" | jq -r '.rationale // ""')"

  local reason="delete-candidate requires operator sign-off"
  update_receipt_status "$receipt_file" "failed" "phase5_error" "$reason" || true

  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  write_index_line "$(jq -cn \
    --arg ts "$ts" \
    --arg id "$id" \
    --arg disposition "delete-candidate-surfaced" \
    --arg from "$original_path" \
    --arg receipt "ledgers/moves/receipts/$id.md" \
    '{ts:$ts,id:$id,disposition:$disposition,from:$from,to:null,receipt:$receipt}')"

  {
    [ -f "$DELETE_QUEUE_FILE" ] || printf '# Delete Queue\n\n' >"$DELETE_QUEUE_FILE"
    printf -- '- %s — %s — %s%s\n' "$id" "$original_path" \
      "${sensitive_reason:-operator review required}" \
      "${rationale:+ (rationale: $rationale)}"
  } >>"$DELETE_QUEUE_FILE"
  write_phase5_log "$receipt_file" "$reason"
  log_event "delete_candidate_surfaced" "$(jq -cn --arg id "$id" '{id:$id}')"
}

process_one_receipt() {
  local receipt_file
  receipt_file="$(oldest_pending_receipt)"
  [ -n "$receipt_file" ] || return 1

  local id
  id="$(basename "$receipt_file" .md)"
  local fm_json
  if ! fm_json="$(parse_receipt_frontmatter "$receipt_file" 2>/tmp/phase5-parse-err.$$)"; then
    local err
    err="$(cat /tmp/phase5-parse-err.$$ 2>/dev/null || true)"
    rm -f /tmp/phase5-parse-err.$$
    fallback_mark_parse_failed "$receipt_file"
    write_phase5_log "$receipt_file" "malformed frontmatter: $err"
    write_index_line "$(jq -cn \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg id "$id" \
      --arg disposition "failed" \
      --arg reason "malformed frontmatter: $err" \
      --arg receipt "ledgers/moves/receipts/$id.md" \
      '{ts:$ts,id:$id,disposition:$disposition,reason:$reason,from:null,to:null,receipt:$receipt}')"
    log_event "parse_failed" "$(jq -cn --arg id "$id" --arg err "$err" '{id:$id,err:$err}')"
    return 0
  fi
  rm -f /tmp/phase5-parse-err.$$

  local disposition
  disposition="$(printf '%s' "$fm_json" | jq -r '.disposition // ""')"

  if [ "$MODE" = "dry-run" ] || [ "$MODE" = "dry-run-once" ]; then
    printf '[dry-run] id=%s disposition=%s receipt=%s\n' "$id" "$disposition" "$receipt_file"
    log_event "dry_run_plan" "$(jq -cn --arg id "$id" --arg disposition "$disposition" '{id:$id,disposition:$disposition}')"
    touch -A 01 "$receipt_file" 2>/dev/null || true
    return 0
  fi

  case "$disposition" in
    moved) handle_moved "$fm_json" "$receipt_file" ;;
    left-in-place) handle_left_in_place "$fm_json" "$receipt_file" ;;
    deferred) handle_deferred "$fm_json" "$receipt_file" ;;
    delete-candidate) handle_delete_candidate "$fm_json" "$receipt_file" ;;
    *)
      local original_path
      original_path="$(printf '%s' "$fm_json" | jq -r '.original_path // ""')"
      mark_failed "$receipt_file" "$id" "unknown disposition: $disposition" "$original_path"
      ;;
  esac
  return 0
}

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
