#!/usr/bin/env bash
# Installs/reloads the phase-5 mover LaunchAgent.
#
# Prerequisite: /opt/homebrew/bin/bash exists and has Full Disk Access
# granted. Same requirement as phases 1-3 post-TCC fix. If you haven't
# granted it yet, see TCL 0014 "Next" section.
#
# Phase 5 will start moving files as soon as it's loaded. Before loading:
#   - Run `bash scripts/moves_phase5_mover.sh --dry-run` at least once
#     against a real receipt queue and verify the planned actions look
#     right.
#   - Make sure ledgers/moves/PAUSED does NOT exist unless you want it to
#     start paused.

set -euo pipefail

HOME_DIR="${HOME:-/Users/rodbot}"
LABEL="com.rodbot.moves.phase5-mover"
SOURCE_PLIST="$HOME_DIR/scripts/launchd/$LABEL.plist"
TARGET_DIR="$HOME_DIR/Library/LaunchAgents"
TARGET_PLIST="$TARGET_DIR/$LABEL.plist"

mkdir -p "$TARGET_DIR"
cp "$SOURCE_PLIST" "$TARGET_PLIST"

if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)" "$TARGET_PLIST" || true
fi

launchctl bootstrap "gui/$(id -u)" "$TARGET_PLIST"
launchctl enable "gui/$(id -u)/$LABEL"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

echo "Loaded $LABEL"
echo "Index:  $HOME_DIR/ledgers/moves/index.jsonl"
echo "Events: $HOME_DIR/ledgers/moves/mover-events.jsonl"
echo
echo "Tail the events log to watch phase 5 execute:"
echo "  tail -f $HOME_DIR/ledgers/moves/mover-events.jsonl"
