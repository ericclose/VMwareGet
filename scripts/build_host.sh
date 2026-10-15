#!/usr/bin/env bash
set -e

# ==============================================================================
# VMwareGet - Host OS Automated Build Script
# Automatically targets and compiles exclusively for the current host OS & Arch
# ==============================================================================

OS="$(uname -s)"
RAW_ARCH="$(uname -m)"
case "$RAW_ARCH" in
  x86_64|amd64) ARCH="x64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) ARCH="$RAW_ARCH" ;;
esac

echo "--------------------------------------------------------"
echo "VMwareGet Build System"
echo "Host OS: $OS | Host Architecture: $ARCH"
echo "Targeting Flutter SDK: 3.47.7"
echo "--------------------------------------------------------"

case "$OS" in
  Darwin*)
    echo "==> Compiling native release bundle for macOS ($ARCH)..."
    flutter build macos --release
    echo "==> macOS build complete: build/macos/Build/Products/Release/VMwareGet.app"
    echo "==> Packaging macOS DMG ($ARCH) with /Applications drag-and-drop installer..."
    ./scripts/package_macos_dmg.sh "VMwareGet-macos-${ARCH}.dmg"
    echo "==> Packaging macOS ZIP release archive ($ARCH)..."
    ditto -c -k --sequesterRsrc --keepParent "build/macos/Build/Products/Release/VMwareGet.app" "VMwareGet-macos-${ARCH}.zip"
    echo "==> macOS distribution packages ready: VMwareGet-macos-${ARCH}.dmg, VMwareGet-macos-${ARCH}.zip"
    ;;
  Linux*)
    echo "==> Compiling native release bundle for Linux ($ARCH)..."
    flutter build linux --release
    echo "==> Linux build complete: build/linux/*/release/bundle/"
    tar -czf "VMwareGet-linux-${ARCH}.tar.gz" -C build/linux/*/release/bundle .
    echo "==> Linux distribution package ready: VMwareGet-linux-${ARCH}.tar.gz"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo "==> Compiling native release bundle for Windows ($ARCH)..."
    flutter build windows --release
    echo "==> Windows build complete: build/windows/*/runner/Release/"
    tar -a -c -f "VMwareGet-windows-${ARCH}.zip" -C build/windows/*/runner/Release .
    echo "==> Windows distribution package ready: VMwareGet-windows-${ARCH}.zip"
    ;;
  *)
    echo "Unknown host platform '$OS'. Attempting host build..."
    flutter build "${1:-macos}" --release
    ;;
esac

echo "--------------------------------------------------------"
echo "Build finished successfully for current host OS ($OS) and architecture ($ARCH)."
echo "--------------------------------------------------------"
