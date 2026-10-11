#!/usr/bin/env bash
set -e

# ==============================================================================
# VMwareGet - Host OS Automated Build Script
# Automatically targets and compiles exclusively for the current host OS
# ==============================================================================

OS="$(uname -s)"
echo "--------------------------------------------------------"
echo "VMwareGet Build System"
echo "Host Operating System detected: $OS"
echo "Targeting Flutter SDK: 3.47.7"
echo "--------------------------------------------------------"

case "$OS" in
  Darwin*)
    echo "==> Compiling native release bundle for macOS..."
    flutter build macos --release
    echo "==> macOS build complete: build/macos/Build/Products/Release/VMwareGet.app"
    ;;
  Linux*)
    echo "==> Compiling native release bundle for Linux..."
    flutter build linux --release
    echo "==> Linux build complete: build/linux/x64/release/bundle/"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo "==> Compiling native release bundle for Windows..."
    flutter build windows --release
    echo "==> Windows build complete: build/windows/x64/runner/Release/"
    ;;
  *)
    echo "Unknown host platform '$OS'. Attempting host build..."
    flutter build "${1:-macos}" --release
    ;;
esac

echo "--------------------------------------------------------"
echo "Build finished successfully for host operating system."
echo "--------------------------------------------------------"
