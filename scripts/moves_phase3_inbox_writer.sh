#!/usr/bin/env bash
# moves_phase3_inbox_writer.sh
# Phase 3 only: consume settled events and emit inbox jobs.

set -euo pipefail

HOME_DIR="${HOME:-/Users/rodbot}"
MOVES_DIR="$HOME_DIR/ledgers/moves"
SETTLED_LOG="$MOVES_DIR/settled.log"
INBOX_DIR="$MOVES_DIR/inbox"
INDEX_FILE="$MOVES_DIR/index.jsonl"
CURSOR_FILE="$MOVES_DIR/.phase3-cursor"
PAUSED_FILE="$MOVES_DIR/PAUSED"
DUPLICATES_LOG="$MOVES_DIR/duplicates.log"
VANISHED_LOG="$MOVES_DIR/vanished.log"

have_jq() {
  command -v jq >/dev/null 2>&1
}

read_cursor() {
  if [ -f "$CURSOR_FILE" ]; then
    local val
    val="$(tr -d '[:space:]' <"$CURSOR_FILE" 2>/dev/null || echo "0")"
    case "$val" in
      ''|*[!0-9]*) echo "0" ;;
      *) echo "$val" ;;
    esac
  else
    echo "0"
  fi
}

write_cursor() {
  local value="$1"
  local tmp="$CURSOR_FILE.tmp"
  printf '%s\n' "$value" >"$tmp"
  mv "$tmp" "$CURSOR_FILE"
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

first_line_from_offset() {
  local offset="$1"
  local start=$((offset + 1))
  # Subshell with pipefail disabled: awk exits after line 1, tail keeps reading
  # a large settled.log and dies with SIGPIPE (141). That's expected here and
  # must not propagate through `set -o pipefail` and kill the agent.
  (set +o pipefail; tail -c +"$start" "$SETTLED_LOG" 2>/dev/null | awk 'NR==1 {print; exit}')
}

sha256_file() {
  local path="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
  else
    openssl dgst -sha256 "$path" | awk '{print $2}'
  fi
}

to_iso_utc() {
  local epoch="$1"
  if [ -n "$epoch" ] && [ "$epoch" -ge 0 ] 2>/dev/null; then
    date -u -r "$epoch" +"%Y-%m-%dT%H:%M:%SZ"
  else
    date -u +"%Y-%m-%dT%H:%M:%SZ"
  fi
}

is_sensitive_name() {
  local name_lc
  name_lc="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$name_lc" in
    *password*|*secret*|*credential*|*token*|*.env|*.pem|*.key|*.p12|*api_key*|*.keychain)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

log_duplicate() {
  local path="$1"
  local id="$2"
  local mode="$3"
  local ref="$4"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if have_jq; then
    if [ "$mode" = "inbox" ]; then
      jq -cn --arg ts "$ts" --arg path "$path" --arg id "$id" \
        '{captured_at:$ts,path:$path,id:$id,existing_job:"inbox"}' >>"$DUPLICATES_LOG"
    else
      jq -cn --arg ts "$ts" --arg path "$path" --arg id "$id" --arg receipt "$ref" \
        '{captured_at:$ts,path:$path,id:$id,existing_receipt:$receipt}' >>"$DUPLICATES_LOG"
    fi
  else
    if [ "$mode" = "inbox" ]; then
      printf '{"captured_at":"%s","path":"%s","id":"%s","existing_job":"inbox"}\n' \
        "$(json_escape "$ts")" "$(json_escape "$path")" "$(json_escape "$id")" >>"$DUPLICATES_LOG"
    else
      printf '{"captured_at":"%s","path":"%s","id":"%s","existing_receipt":"%s"}\n' \
        "$(json_escape "$ts")" "$(json_escape "$path")" "$(json_escape "$id")" "$(json_escape "$ref")" >>"$DUPLICATES_LOG"
    fi
  fi
}

log_vanished() {
  local path="$1"
  local settled_at="$2"
  local reason="${3:-vanished_before_inbox}"
  local diag="${4:-}"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if have_jq; then
    jq -cn --arg ts "$ts" --arg path "$path" --arg settled_at "$settled_at" \
           --arg reason "$reason" --arg diag "$diag" \
      '{captured_at:$ts,path:$path,settled_at:$settled_at,reason:$reason,diag:$diag}' >>"$VANISHED_LOG"
  else
    printf '{"captured_at":"%s","path":"%s","settled_at":"%s","reason":"%s","diag":"%s"}\n' \
      "$(json_escape "$ts")" "$(json_escape "$path")" "$(json_escape "$settled_at")" \
      "$(json_escape "$reason")" "$(json_escape "$diag")" >>"$VANISHED_LOG"
  fi
}

historical_receipt_id() {
  local id="$1"
  local line receipt

  [ -f "$INDEX_FILE" ] || return 1
  line="$(awk -v needle="$id" 'index($0, needle) {print; exit}' "$INDEX_FILE" 2>/dev/null || true)"
  [ -n "$line" ] || return 1

  if have_jq; then
    receipt="$(printf '%s' "$line" | jq -r '.receipt_id // .receipt // .move_id // .id // empty' 2>/dev/null || true)"
  else
    receipt=""
  fi

  if [ -z "$receipt" ]; then
    receipt="unknown"
  fi
  printf '%s' "$receipt"
  return 0
}

emit_job() {
  local settled_json="$1"
  local path captured_at event raw_event_count
  local sha256 id size mime stat_triplet mtime_epoch birth_epoch mtime birthtime
  local original_filename original_dir preview_text suspect_sensitive detected_at
  local job_file tmp_file receipt_id

  path="$(printf '%s' "$settled_json" | jq -r '.path // empty')"
  captured_at="$(printf '%s' "$settled_json" | jq -r '.captured_at // empty')"
  event="$(printf '%s' "$settled_json" | jq -r '.event // "observed"')"
  raw_event_count="$(printf '%s' "$settled_json" | jq -r '.raw_event_count // 1')"

  [ -n "$path" ] || return 1

  if [ ! -e "$path" ] || [ ! -f "$path" ]; then
    # Capture diagnostic context so we can tell TCC / cwd / PATH bugs apart
    # from genuinely-gone files.
    local diag_e diag_f diag_stat diag_parent
    [ -e "$path" ] && diag_e="1" || diag_e="0"
    [ -f "$path" ] && diag_f="1" || diag_f="0"
    diag_stat="$(stat -f '%z %m' "$path" 2>&1 | head -c 120)"
    diag_parent="$(ls -ld "$(dirname "$path")" 2>&1 | head -c 120)"
    log_vanished "$path" "$captured_at" "vanished_before_inbox" \
      "e=$diag_e f=$diag_f cwd=$(pwd) home=${HOME:-unset} stat=[$diag_stat] parent=[$diag_parent]"
    return 0
  fi

  sha256="$(sha256_file "$path" 2>/dev/null || true)"
  [ -n "$sha256" ] || {
    log_vanished "$path" "$captured_at" "sha256_failed" \
      "stat=$(stat -f '%z %m' "$path" 2>&1 | head -c 120) cwd=$(pwd)"
    return 0
  }
  id="${sha256:0:12}"

  job_file="$INBOX_DIR/$id.json"
  if [ -f "$job_file" ]; then
    log_duplicate "$path" "$id" "inbox" ""
    return 0
  fi

  if receipt_id="$(historical_receipt_id "$id")"; then
    log_duplicate "$path" "$id" "historical" "$receipt_id"
    return 0
  fi

  mime="$(file --mime-type -b "$path" 2>/dev/null || echo "application/octet-stream")"
  stat_triplet="$(stat -f '%z %m %B' "$path" 2>/dev/null || echo "0 0 0")"
  size="$(printf '%s' "$stat_triplet" | awk '{print $1}')"
  mtime_epoch="$(printf '%s' "$stat_triplet" | awk '{print $2}')"
  birth_epoch="$(printf '%s' "$stat_triplet" | awk '{print $3}')"
  mtime="$(to_iso_utc "$mtime_epoch")"
  birthtime="$(to_iso_utc "$birth_epoch")"

  original_filename="$(basename "$path")"
  original_dir="$(dirname "$path")"
  detected_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  preview_text=""
  if [[ "$mime" == text/* ]]; then
    preview_text="$(dd if="$path" bs=2048 count=1 2>/dev/null | base64 | tr -d '\n')"
  fi

  suspect_sensitive="false"
  if is_sensitive_name "$original_filename"; then
    suspect_sensitive="true"
  fi

  tmp_file="$INBOX_DIR/.${id}.json.tmp"
  if have_jq; then
    if [ -n "$preview_text" ]; then
      jq -cn \
        --arg id "$id" \
        --arg sha256 "$sha256" \
        --arg path "$path" \
        --arg original_filename "$original_filename" \
        --arg original_dir "$original_dir" \
        --arg mime "$mime" \
        --arg mtime "$mtime" \
        --arg birthtime "$birthtime" \
        --arg captured_at "$captured_at" \
        --arg detected_at "$detected_at" \
        --arg preview_text "$preview_text" \
        --arg event "$event" \
        --argjson size "$size" \
        --argjson suspect_sensitive "$suspect_sensitive" \
        --argjson raw_event_count "$raw_event_count" \
        '{
          id:$id,
          sha256:$sha256,
          path:$path,
          original_filename:$original_filename,
          original_dir:$original_dir,
          size:$size,
          mime:$mime,
          mtime:$mtime,
          birthtime:$birthtime,
          captured_at:$captured_at,
          detected_at:$detected_at,
          suspect_sensitive:$suspect_sensitive,
          preview_text:$preview_text,
          settled_event:{event:$event,raw_event_count:$raw_event_count}
        }' >"$tmp_file"
    else
      jq -cn \
        --arg id "$id" \
        --arg sha256 "$sha256" \
        --arg path "$path" \
        --arg original_filename "$original_filename" \
        --arg original_dir "$original_dir" \
        --arg mime "$mime" \
        --arg mtime "$mtime" \
        --arg birthtime "$birthtime" \
        --arg captured_at "$captured_at" \
        --arg detected_at "$detected_at" \
        --arg event "$event" \
        --argjson size "$size" \
        --argjson suspect_sensitive "$suspect_sensitive" \
        --argjson raw_event_count "$raw_event_count" \
        '{
          id:$id,
          sha256:$sha256,
          path:$path,
          original_filename:$original_filename,
          original_dir:$original_dir,
          size:$size,
          mime:$mime,
          mtime:$mtime,
          birthtime:$birthtime,
          captured_at:$captured_at,
          detected_at:$detected_at,
          suspect_sensitive:$suspect_sensitive,
          preview_text:null,
          settled_event:{event:$event,raw_event_count:$raw_event_count}
        }' >"$tmp_file"
    fi
  else
    printf '{\n' >"$tmp_file"
    printf '  "id": "%s",\n' "$(json_escape "$id")" >>"$tmp_file"
    printf '  "sha256": "%s",\n' "$(json_escape "$sha256")" >>"$tmp_file"
    printf '  "path": "%s",\n' "$(json_escape "$path")" >>"$tmp_file"
    printf '  "original_filename": "%s",\n' "$(json_escape "$original_filename")" >>"$tmp_file"
    printf '  "original_dir": "%s",\n' "$(json_escape "$original_dir")" >>"$tmp_file"
    printf '  "size": %s,\n' "$size" >>"$tmp_file"
    printf '  "mime": "%s",\n' "$(json_escape "$mime")" >>"$tmp_file"
    printf '  "mtime": "%s",\n' "$(json_escape "$mtime")" >>"$tmp_file"
    printf '  "birthtime": "%s",\n' "$(json_escape "$birthtime")" >>"$tmp_file"
    printf '  "captured_at": "%s",\n' "$(json_escape "$captured_at")" >>"$tmp_file"
    printf '  "detected_at": "%s",\n' "$(json_escape "$detected_at")" >>"$tmp_file"
    printf '  "suspect_sensitive": %s,\n' "$suspect_sensitive" >>"$tmp_file"
    if [ -n "$preview_text" ]; then
      printf '  "preview_text": "%s",\n' "$(json_escape "$preview_text")" >>"$tmp_file"
    else
      printf '  "preview_text": null,\n' >>"$tmp_file"
    fi
    printf '  "settled_event": {"event": "%s", "raw_event_count": %s}\n' "$(json_escape "$event")" "$raw_event_count" >>"$tmp_file"
    printf '}\n' >>"$tmp_file"
  fi

  mv "$tmp_file" "$job_file"
  return 0
}

mkdir -p "$MOVES_DIR" "$INBOX_DIR"
touch "$SETTLED_LOG" "$DUPLICATES_LOG" "$VANISHED_LOG"

if ! have_jq; then
  echo "moves_phase3_inbox_writer: jq is required for settled.log parsing." >&2
  exit 1
fi

while true; do
  while [ -f "$PAUSED_FILE" ]; do
    sleep 1
  done

  cursor="$(read_cursor)"
  file_size="$(stat -f%z "$SETTLED_LOG" 2>/dev/null || echo 0)"

  if [ "$cursor" -gt "$file_size" ]; then
    cursor="0"
    write_cursor "$cursor"
  fi

  if [ "$cursor" -ge "$file_size" ]; then
    sleep 1
    continue
  fi

  line="$(first_line_from_offset "$cursor")"
  if [ -z "$line" ]; then
    sleep 1
    continue
  fi

  line_bytes="$(printf '%s\n' "$line" | wc -c | tr -d ' ')"
  next_cursor=$((cursor + line_bytes))

  if emit_job "$line"; then
    write_cursor "$next_cursor"
  else
    sleep 1
  fi
done
