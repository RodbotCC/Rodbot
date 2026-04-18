#!/usr/bin/env bash
# Installs/reloads the phase-3 inbox writer LaunchAgent.

set -euo pipefail

HOME_DIR="${HOME:-/Users/rodbot}"
LABEL="com.rodbot.moves.phase3-inbox-writer"
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
echo "Inbox jobs: $HOME_DIR/ledgers/moves/inbox/"
