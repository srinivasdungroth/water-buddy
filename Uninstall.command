#!/bin/bash
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.waterbuddy.plist"

pkill -x WaterBuddy 2>/dev/null || true

if [ -f "$LAUNCH_AGENT" ]; then
    launchctl unload "$LAUNCH_AGENT"
    rm "$LAUNCH_AGENT"
fi

rm -rf "$(cd "$(dirname "$0")" && pwd)/build"
echo "✅ WaterBuddy uninstalled."
