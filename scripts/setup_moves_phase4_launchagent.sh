#!/usr/bin/env bash
# Installs/reloads the phase-4 auditor LaunchAgent.
#
# Prerequisite: API key is resolvable before the agent ticks in live mode.
# Either:
#   - export ANTHROPIC_API_KEY=... in your shell before `launchctl load`, OR
#   - create ~/.config/rodbot/anthropic.env containing `ANTHROPIC_API_KEY=sk-ant-...`
#     and `chmod 600` that file.
# Without a key the agent still runs harmlessly — it logs "no ANTHROPIC_API_KEY"
# to auditor-events.jsonl once per inbox job and leaves jobs intact.

set -euo pipefail

HOME_DIR="${HOME:-/Users/rodbot}"
LABEL="com.rodbot.moves.phase4-auditor"
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
echo "Receipts: $HOME_DIR/ledgers/moves/receipts/"
echo "Events:   $HOME_DIR/ledgers/moves/auditor-events.jsonl"
echo
echo "If you have NOT set ANTHROPIC_API_KEY, test wiring first with:"
echo "  $HOME_DIR/scripts/moves_phase4_auditor.sh --once --dry-run"
