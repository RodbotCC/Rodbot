#!/usr/bin/env bash
# moves_phase2_debouncer.sh
# Phase 2 only: consume raw fswatch events and emit settled file events.

set -euo pipefail

HOME_DIR="${HOME:-/Users/rodbot}"
MOVES_DIR="$HOME_DIR/ledgers/moves"
EVENTS_LOG="$MOVES_DIR/events.log"
SETTLED_LOG="$MOVES_DIR/settled.log"
PAUSED_FILE="$MOVES_DIR/PAUSED"
PENDING_DIR="$MOVES_DIR/.phase2-pending"

POLL_SECONDS="0.5"
SETTLE_SECONDS=3
ABANDON_SECONDS=$((10 * 60))

b64_encode() {
  printf '%s' "$1" | base64 | tr -d '\n'
}

b64_decode() {
  printf '%s' "$1" | base64 -D 2>/dev/null || printf '%s' "$1" | base64 --decode 2>/dev/null
}

is_fswatch_flag() {
  case "$1" in
    Created|Updated|Removed|Renamed|MovedFrom|MovedTo|OwnerModified|AttributeModified|IsFile|IsDir|IsSymLink|Link|PlatformSpecific|Unknown)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

derive_event_type() {
  local flags="$1"
  case "$flags" in
    *Created*) printf 'created' ;;
    *MovedTo*|*Renamed*) printf 'renamed' ;;
    *Updated*|*OwnerModified*|*AttributeModified*) printf 'updated' ;;
    *Removed*|*MovedFrom*) printf 'removed' ;;
    *) printf 'observed' ;;
  esac
}

parse_payload() {
  local payload="$1"
  local parts i flags path
  local flags_part=""

  IFS=' ' read -r -a parts <<<"$payload"
  [ "${#parts[@]}" -gt 0 ] || return 1

  i=$((${#parts[@]} - 1))
  while [ "$i" -ge 0 ] && is_fswatch_flag "${parts[$i]}"; do
    if [ -z "$flags_part" ]; then
      flags_part="${parts[$i]}"
    else
      flags_part="${parts[$i]} $flags_part"
    fi
    i=$((i - 1))
  done
  [ "$i" -ge 0 ] || return 1

  path="${parts[0]}"
  if [ "$i" -ge 1 ]; then
    local j
    for j in $(seq 1 "$i"); do
      path="$path ${parts[$j]}"
    done
  fi

  PARSED_PATH="$path"
  PARSED_EVENT="$(derive_event_type "$flags_part")"
  return 0
}

is_hard_noise_path() {
  local p="$1"
  local base segment old_ifs

  base="$(basename "$p")"
  case "$base" in
    .DS_Store|Icon?|*.crdownload|*.download|*.part|*.tmp|*.swp)
      return 0
      ;;
  esac

  case "$p" in
    */.Trash/*)
      return 0
      ;;
  esac

  old_ifs="$IFS"
  IFS='/'
  for segment in $p; do
    case "$segment" in
      ._*)
        IFS="$old_ifs"
        return 0
        ;;
    esac
  done
  IFS="$old_ifs"
  return 1
}

pending_key_for_path() {
  printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
}

write_pending_state() {
  local state_file="$1"
  local path="$2"
  local last_seen="$3"
  local count="$4"
  local event="$5"

  cat >"$state_file" <<EOF
PATH_B64=$(b64_encode "$path")
LAST_SEEN=$last_seen
COUNT=$count
EVENT=$event
EOF
}

read_pending_state() {
  local state_file="$1"
  local line key val

  P_PATH=""
  P_LAST_SEEN=""
  P_COUNT=""
  P_EVENT=""

  while IFS= read -r line; do
    key="${line%%=*}"
    val="${line#*=}"
    case "$key" in
      PATH_B64) P_PATH="$(b64_decode "$val")" ;;
      LAST_SEEN) P_LAST_SEEN="$val" ;;
      COUNT) P_COUNT="$val" ;;
      EVENT) P_EVENT="$val" ;;
    esac
  done <"$state_file"
}

wait_until_settled() {
  local path="$1"
  local prev_size="" stable_samples=0 required_samples
  local start_epoch now_epoch size

  required_samples=$((SETTLE_SECONDS * 2))
  start_epoch="$(date +%s)"

  while true; do
    while [ -f "$PAUSED_FILE" ]; do
      sleep 1
    done

    if [ ! -e "$path" ] || [ ! -f "$path" ]; then
      printf 'missing'
      return 0
    fi

    size="$(stat -f%z "$path" 2>/dev/null || true)"
    if [ -z "$size" ]; then
      printf 'missing'
      return 0
    fi

    if [ "$size" = "$prev_size" ]; then
      stable_samples=$((stable_samples + 1))
    else
      stable_samples=0
      prev_size="$size"
    fi

    if [ "$stable_samples" -ge "$required_samples" ]; then
      printf 'settled'
      return 0
    fi

    now_epoch="$(date +%s)"
    if [ $((now_epoch - start_epoch)) -ge "$ABANDON_SECONDS" ]; then
      printf 'unsettled'
      return 0
    fi

    sleep "$POLL_SECONDS"
  done
}

write_settled_json() {
  local path="$1"
  local event_type="$2"
  local raw_count="$3"
  local size mtime captured_at
  local esc_path esc_mtime esc_event esc_captured

  size="$(stat -f%z "$path" 2>/dev/null || echo 0)"
  mtime="$(stat -f%Sm -t '%Y-%m-%dT%H:%M:%SZ' "$path" 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  captured_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if command -v jq >/dev/null 2>&1; then
    jq -cn \
      --arg path "$path" \
      --arg mtime "$mtime" \
      --arg event "$event_type" \
      --arg captured_at "$captured_at" \
      --argjson size "$size" \
      --argjson raw_event_count "$raw_count" \
      '{path:$path,size:$size,mtime:$mtime,event:$event,captured_at:$captured_at,raw_event_count:$raw_event_count}' \
      >>"$SETTLED_LOG"
  else
    esc_path="${path//\\/\\\\}"
    esc_path="${esc_path//\"/\\\"}"
    esc_mtime="${mtime//\\/\\\\}"
    esc_mtime="${esc_mtime//\"/\\\"}"
    esc_event="${event_type//\\/\\\\}"
    esc_event="${esc_event//\"/\\\"}"
    esc_captured="${captured_at//\\/\\\\}"
    esc_captured="${esc_captured//\"/\\\"}"
    printf '{"path":"%s","size":%s,"mtime":"%s","event":"%s","captured_at":"%s","raw_event_count":%s}\n' \
      "$esc_path" "$size" "$esc_mtime" "$esc_event" "$esc_captured" "$raw_count" \
      >>"$SETTLED_LOG"
  fi
}

process_raw_event() {
  local raw_line="$1"
  local payload key state_file now_epoch count event_type

  case "$raw_line" in
    *$'\t'*) payload="${raw_line#*$'\t'}" ;;
    *) return 0 ;;
  esac

  parse_payload "$payload" || return 0
  is_hard_noise_path "$PARSED_PATH" && return 0

  key="$(pending_key_for_path "$PARSED_PATH")"
  state_file="$PENDING_DIR/$key.state"
  now_epoch="$(date +%s)"

  if [ -f "$state_file" ]; then
    read_pending_state "$state_file"
    count="${P_COUNT:-0}"
    count=$((count + 1))
    event_type="$PARSED_EVENT"
    write_pending_state "$state_file" "$PARSED_PATH" "$now_epoch" "$count" "$event_type"
  else
    write_pending_state "$state_file" "$PARSED_PATH" "$now_epoch" "1" "$PARSED_EVENT"
  fi
}

flush_ready_paths() {
  local state_file now_epoch settle_result

  now_epoch="$(date +%s)"
  for state_file in "$PENDING_DIR"/*.state; do
    [ -e "$state_file" ] || break
    read_pending_state "$state_file"

    [ -n "$P_PATH" ] || {
      rm -f "$state_file"
      continue
    }

    if [ $((now_epoch - P_LAST_SEEN)) -lt "$SETTLE_SECONDS" ]; then
      continue
    fi

    if is_hard_noise_path "$P_PATH"; then
      rm -f "$state_file"
      continue
    fi

    if [ ! -e "$P_PATH" ] || [ ! -f "$P_PATH" ]; then
      rm -f "$state_file"
      continue
    fi

    settle_result="$(wait_until_settled "$P_PATH")"
    if [ "$settle_result" = "settled" ]; then
      write_settled_json "$P_PATH" "$P_EVENT" "$P_COUNT"
    elif [ "$settle_result" = "unsettled" ]; then
      printf '%s\t%s\t%s\tcount=%s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$P_PATH" "unsettled_after_${ABANDON_SECONDS}s" "$P_COUNT" >&2
    fi

    rm -f "$state_file"
  done
}

mkdir -p "$MOVES_DIR" "$PENDING_DIR"
touch "$EVENTS_LOG" "$SETTLED_LOG"

tail -n 0 -F "$EVENTS_LOG" | while true; do
  while [ -f "$PAUSED_FILE" ]; do
    sleep 1
  done

  if IFS= read -r -t "$POLL_SECONDS" raw_line; then
    process_raw_event "$raw_line"
  fi

  flush_ready_paths
done
