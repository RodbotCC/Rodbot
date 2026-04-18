#!/usr/bin/env bash
# Installs/reloads the phase-2 move debouncer LaunchAgent.

set -euo pipefail

HOME_DIR="${HOME:-/Users/rodbot}"
LABEL="com.rodbot.moves.phase2-debouncer"
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
echo "Settled events: $HOME_DIR/ledgers/moves/settled.log"
