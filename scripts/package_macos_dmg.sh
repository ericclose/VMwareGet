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
STAGING_DIR="$PROJECT_ROOT/build/$VOL_NAME"

if [ ! -d "$APP_PATH" ]; then
  echo "Error: VMwareGet.app not found at $APP_PATH. Please run build.sh first."
  exit 1
fi

rm -rf "$STAGING_DIR" "$DMG_OUTPUT"
mkdir -p "$STAGING_DIR"

echo "==> Preparing DMG staging structure..."
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

if [ -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]; then
  cp "$APP_PATH/Contents/Resources/AppIcon.icns" "$STAGING_DIR/.VolumeIcon.icns"
fi

echo "==> Packaging release compressed DMG silently ($DMG_OUTPUT)..."
if diskutil image -h >/dev/null 2>&1 && diskutil image create from --format UDZO "$STAGING_DIR" "$DMG_OUTPUT" 2>/dev/null; then
  echo "==> Disk image generated via Apple diskutil image engine."
else
  echo "==> Generating disk image via Apple hdiutil engine..."
  hdiutil create -srcfolder "$STAGING_DIR" -volname "$VOL_NAME" -format UDZO -ov "$DMG_OUTPUT"
fi

rm -rf "$STAGING_DIR"
echo "==> DMG generation complete: $DMG_OUTPUT ($(ls -lh "$DMG_OUTPUT" | awk '{print $5}'))"
