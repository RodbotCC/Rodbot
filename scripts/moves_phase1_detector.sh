#!/usr/bin/env bash
# moves_phase1_detector.sh
# Phase 1 only: watch allowlisted drop-zones and append raw fswatch events.

set -euo pipefail

HOME_DIR="${HOME:-/Users/rodbot}"
MOVES_DIR="$HOME_DIR/ledgers/moves"
EVENTS_LOG="$MOVES_DIR/events.log"
PAUSED_FILE="$MOVES_DIR/PAUSED"

WATCH_DIRS=(
  "$HOME_DIR/Downloads"
  "$HOME_DIR/Desktop"
  "$HOME_DIR/Documents"
)

FSWATCH_BIN="$(command -v fswatch || true)"
if [ -z "$FSWATCH_BIN" ] && [ -x "/opt/homebrew/bin/fswatch" ]; then
  FSWATCH_BIN="/opt/homebrew/bin/fswatch"
fi

if [ -z "$FSWATCH_BIN" ]; then
  echo "moves_phase1_detector: fswatch not found. Install fswatch before starting phase 1 detector." >&2
  exit 1
fi

mkdir -p "$MOVES_DIR"
touch "$EVENTS_LOG"

existing_watch_dirs=()
for d in "${WATCH_DIRS[@]}"; do
  if [ -d "$d" ]; then
    existing_watch_dirs+=("$d")
  else
    echo "moves_phase1_detector: skipping missing watch dir: $d" >&2
  fi
done

if [ "${#existing_watch_dirs[@]}" -eq 0 ]; then
  echo "moves_phase1_detector: no watch directories exist; exiting." >&2
  exit 1
fi

if [ -f "$PAUSED_FILE" ]; then
  echo "moves_phase1_detector: PAUSED file present, refusing to start: $PAUSED_FILE" >&2
  exit 0
fi

echo "moves_phase1_detector: starting fswatch on allowlist." >&2
printf 'moves_phase1_detector: watching %s\n' "${existing_watch_dirs[*]}" >&2

# -x emits "<path> <event flags...>" which satisfies phase-1 raw event capture.
"$FSWATCH_BIN" -r -x "${existing_watch_dirs[@]}" | while IFS= read -r raw_line; do
  if [ -f "$PAUSED_FILE" ]; then
    continue
  fi

  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf '%s\t%s\n' "$ts" "$raw_line" >>"$EVENTS_LOG"
done
