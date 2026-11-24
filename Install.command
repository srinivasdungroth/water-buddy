#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="WaterBuddy"
BUILD_DIR="$DIR/build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.waterbuddy.plist"

echo "🔨 Building $APP_NAME..."
mkdir -p "$BUILD_DIR"

swiftc "$DIR/WaterBuddy.swift" \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework Cocoa \
    -framework SceneKit \
    -o "$BUILD_DIR/${APP_NAME}_bin"

# Wrap in .app bundle
mkdir -p "$APP_PATH/Contents/MacOS"
cp "$BUILD_DIR/${APP_NAME}_bin" "$APP_PATH/Contents/MacOS/$APP_NAME"

cat > "$APP_PATH/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>com.waterbuddy</string>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>LSUIElement</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF

cp "$DIR/doraemon.gif" "$APP_PATH/Contents/MacOS/"
echo "✅ App built at $APP_PATH"

# LaunchAgent for login startup
cat > "$LAUNCH_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.waterbuddy</string>
    <key>ProgramArguments</key>
    <array><string>$APP_PATH/Contents/MacOS/$APP_NAME</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><false/>
</dict>
</plist>
EOF

launchctl load "$LAUNCH_AGENT"
open "$APP_PATH"
echo "🚀 WaterBuddy is running and will start at login!"
