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
  i386|i686|armv7l|armhf)
    echo "ERROR: 32-bit architecture ($RAW_ARCH) is not supported. VMwareGet requires a 64-bit platform." >&2
    exit 1
    ;;
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
    echo "==> macOS distribution package ready: VMwareGet-macos-${ARCH}.dmg"
    ;;
  Linux*)
    echo "==> Compiling native release bundle for Linux ($ARCH)..."
    flutter build linux --release
    echo "==> Linux build complete: build/linux/*/release/bundle/"
    if command -v dpkg-deb >/dev/null 2>&1; then
      echo "==> Packaging Debian package ($ARCH)..."
      DEB_ARCH="$ARCH"
      [ "$ARCH" = "x64" ] && DEB_ARCH="amd64"
      mkdir -p build/deb/DEBIAN build/deb/usr/bin build/deb/usr/lib/VMwareGet build/deb/usr/share/applications
      cp -r build/linux/*/release/bundle/* build/deb/usr/lib/VMwareGet/
      cat << 'EOF' > build/deb/usr/bin/vmwareget
#!/bin/bash
exec /usr/lib/VMwareGet/vmwareget "$@"
EOF
      chmod +x build/deb/usr/bin/vmwareget
      cat << EOF > build/deb/DEBIAN/control
Package: vmwareget
Version: 1.0.0
Section: utils
Priority: optional
Architecture: ${DEB_ARCH}
Maintainer: VMwareGet Contributors <dev@vmwareget.internal>
Description: VMware Download & Account Companion App
EOF
      dpkg-deb --build build/deb "VMwareGet-linux-${ARCH}.deb"
      echo "==> Linux distribution package ready: VMwareGet-linux-${ARCH}.deb"
    else
      echo "==> Linux native release bundle is available at: build/linux/"
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo "==> Compiling native release bundle for Windows ($ARCH)..."
    flutter build windows --release
    echo "==> Windows build complete: build/windows/*/runner/Release/"
    ISCC="/c/Program Files (x86)/Inno Setup 6/ISCC.exe"
    if [ -f "$ISCC" ]; then
      "$ISCC" "/DMyOutputBaseFilename=VMwareGet-windows-${ARCH}-setup" windows/installer/vmwareget.iss
      echo "==> Windows installer ready: VMwareGet-windows-${ARCH}-setup.exe"
    else
      echo "==> Windows release binaries ready in build/windows/*/runner/Release/"
    fi
    ;;
  *)
    echo "Unknown host platform '$OS'. Attempting host build..."
    flutter build "${1:-macos}" --release
    ;;
esac

echo "--------------------------------------------------------"
echo "Build finished successfully for current host OS ($OS) and architecture ($ARCH)."
echo "--------------------------------------------------------"
