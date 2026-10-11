#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$PROJECT_ROOT/build/macos/Build/Products/Release/VMwareGet.app"
DMG_OUTPUT="$PROJECT_ROOT/VMwareGet-macOS.dmg"
VOL_NAME="VMwareGet"
STAGING_DIR="$PROJECT_ROOT/build/dmg_staging"
TEMP_DMG="$PROJECT_ROOT/build/temp_rw.dmg"
MOUNT_POINT="/Volumes/$VOL_NAME"

if [ ! -d "$APP_PATH" ]; then
  echo "Error: VMwareGet.app not found at $APP_PATH. Please run build.sh first."
  exit 1
fi

echo "==> Preparing DMG staging environment..."
rm -rf "$STAGING_DIR" "$TEMP_DMG" "$DMG_OUTPUT"
mkdir -p "$STAGING_DIR"

# Copy the app bundle into staging
echo "==> Copying VMwareGet.app to staging..."
cp -R "$APP_PATH" "$STAGING_DIR/"

# Create symlink to /Applications for drag-and-drop installation
echo "==> Creating /Applications drag-and-drop symlink..."
ln -s /Applications "$STAGING_DIR/Applications"

# Copy AppIcon as volume icon if available
if [ -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]; then
  cp "$APP_PATH/Contents/Resources/AppIcon.icns" "$STAGING_DIR/.VolumeIcon.icns"
fi

# Create a temporary read-write DMG
echo "==> Creating temporary writable disk image..."
hdiutil create -srcfolder "$STAGING_DIR" -volname "$VOL_NAME" -fs HFS+ -format UDRW -ov "$TEMP_DMG"

# Mount temporary DMG
echo "==> Mounting temporary disk image..."
device=$(hdiutil attach "$TEMP_DMG" -readwrite -nobrowse -noverify -noautoopen | awk 'NR==1{print $1}')
sleep 2

# Find the mount point
actual_mount=$(hdiutil info | grep -B 5 "$VOL_NAME" | grep "/Volumes/" | awk -F'/Volumes/' '{print "/Volumes/"$2}' | head -n 1)
if [ -z "$actual_mount" ]; then
  actual_mount="$MOUNT_POINT"
fi

echo "==> Configuring Finder window layout and positions on $actual_mount..."
# Set volume icon attribute if SetFile exists
if [ -f "$actual_mount/.VolumeIcon.icns" ] && command -v SetFile >/dev/null 2>&1; then
  SetFile -a C "$actual_mount" || true
fi

# Apply AppleScript layout
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

# Sync changes and unmount
echo "==> Finalizing and detaching temporary disk image..."
sync
hdiutil detach "$device" -force || hdiutil detach "$actual_mount" -force || true
sleep 1

# Convert to compressed release DMG
echo "==> Converting to release compressed DMG: $DMG_OUTPUT..."
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_OUTPUT" -ov

# Clean up temporary artifacts
rm -rf "$STAGING_DIR" "$TEMP_DMG"

echo "==> DMG generation complete: $DMG_OUTPUT ($(ls -lh "$DMG_OUTPUT" | awk '{print $5}'))"
