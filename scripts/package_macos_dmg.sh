#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$PROJECT_ROOT/build/macos/Build/Products/Release/VMwareGet.app"
RAW_ARCH="$(uname -m)"
case "$RAW_ARCH" in
  x86_64|amd64) ARCH="x64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) ARCH="$RAW_ARCH" ;;
esac
DMG_OUTPUT="${1:-$PROJECT_ROOT/VMwareGet-macos-${ARCH}.dmg}"
VOL_NAME="VMwareGet"
STAGING_DIR="$PROJECT_ROOT/build/dmg_staging"
TEMP_DMG="$PROJECT_ROOT/build/temp_rw.dmg"
MOUNT_POINT="/Volumes/$VOL_NAME"

if [ ! -d "$APP_PATH" ]; then
  echo "Error: VMwareGet.app not found at $APP_PATH. Please run build.sh first."
  exit 1
fi

rm -rf "$STAGING_DIR" "$TEMP_DMG" "$DMG_OUTPUT"

# Use modern diskutil image (macOS 15+) or fallback to hdiutil (older macOS)
if diskutil image -h >/dev/null 2>&1; then
  echo "==> Packaging DMG using native Apple diskutil image engine..."
  app_size_mb=$(du -sm "$APP_PATH" | awk '{print $1}')
  dmg_size_mb=$((app_size_mb + 60))

  echo "==> Creating temporary writable disk image (${dmg_size_mb}MB)..."
  diskutil image create blank --size "${dmg_size_mb}m" --volumeName "$VOL_NAME" "$TEMP_DMG"

  echo "==> Mounting temporary disk image..."
  diskutil image attach --nobrowse "$TEMP_DMG"
  sleep 1

  echo "==> Populating $MOUNT_POINT with VMwareGet.app and installer link..."
  cp -R "$APP_PATH" "$MOUNT_POINT/"
  ln -s /Applications "$MOUNT_POINT/Applications"

  if [ -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]; then
    cp "$APP_PATH/Contents/Resources/AppIcon.icns" "$MOUNT_POINT/.VolumeIcon.icns"
    if command -v SetFile >/dev/null 2>&1; then
      SetFile -a C "$MOUNT_POINT" || true
    fi
  fi

  if [ -z "$CI" ] && [ -z "$GITHUB_ACTIONS" ]; then
    echo "==> Configuring Finder window layout and positions on $MOUNT_POINT..."
    osascript <<APPLESCRIPT || true
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 200, 940, 560}
        set viewOptions to the icon view options of container window
        set icon size of viewOptions to 110
        set arrangement of viewOptions to not arranged
        try
            set position of item "VMwareGet.app" of container window to {130, 160}
        end try
        try
            set position of item "Applications" of container window to {410, 160}
        end try
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
APPLESCRIPT
  else
    echo "==> CI environment detected: skipping Finder GUI visual positioning..."
  fi

  echo "==> Finalizing and detaching temporary disk image..."
  sync
  diskutil eject "$MOUNT_POINT" || true
  sleep 1

  echo "==> Converting to release compressed DMG: $DMG_OUTPUT..."
  diskutil image create from --format UDZO "$TEMP_DMG" "$DMG_OUTPUT"
  rm -f "$TEMP_DMG"

else
  # Legacy macOS fallback
  echo "==> Preparing DMG staging environment..."
  mkdir -p "$STAGING_DIR"
  cp -R "$APP_PATH" "$STAGING_DIR/"
  ln -s /Applications "$STAGING_DIR/Applications"
  if [ -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]; then
    cp "$APP_PATH/Contents/Resources/AppIcon.icns" "$STAGING_DIR/.VolumeIcon.icns"
  fi

  echo "==> Creating temporary writable disk image..."
  hdiutil create -srcfolder "$STAGING_DIR" -volname "$VOL_NAME" -fs HFS+ -format UDRW -ov "$TEMP_DMG"

  echo "==> Mounting temporary disk image..."
  device=$(hdiutil attach "$TEMP_DMG" -readwrite -nobrowse -noverify -noautoopen | awk 'NR==1{print $1}')
  sleep 2

  actual_mount=$(hdiutil info | grep -B 5 "$VOL_NAME" | grep "/Volumes/" | awk -F'/Volumes/' '{print "/Volumes/"$2}' | head -n 1)
  if [ -z "$actual_mount" ]; then
    actual_mount="$MOUNT_POINT"
  fi

  if [ -z "$CI" ] && [ -z "$GITHUB_ACTIONS" ]; then
    echo "==> Configuring Finder window layout and positions on $actual_mount..."
    osascript <<APPLESCRIPT || true
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 200, 940, 560}
        set viewOptions to the icon view options of container window
        set icon size of viewOptions to 110
        set arrangement of viewOptions to not arranged
        try
            set position of item "VMwareGet.app" of container window to {130, 160}
        end try
        try
            set position of item "Applications" of container window to {410, 160}
        end try
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
APPLESCRIPT
  else
    echo "==> CI environment detected: skipping Finder GUI visual positioning..."
  fi

  echo "==> Finalizing and detaching temporary disk image..."
  sync
  hdiutil detach "$device" -force || hdiutil detach "$actual_mount" -force || true
  sleep 1

  echo "==> Converting to release compressed DMG: $DMG_OUTPUT..."
  hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_OUTPUT" -ov

  rm -rf "$STAGING_DIR" "$TEMP_DMG"
fi

echo "==> DMG generation complete: $DMG_OUTPUT ($(ls -lh "$DMG_OUTPUT" | awk '{print $5}'))"
