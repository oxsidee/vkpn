#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_MODE="${1:-release}"
PACKAGE_VERSION="${2:?Package version is required}"
PACKAGE_ARCH="${3:-amd64}"

BUNDLE_DIR="$ROOT_DIR/build/linux/x64/$BUILD_MODE/bundle"
DIST_DIR="$ROOT_DIR/dist"
WORK_DIR="$ROOT_DIR/build/linux-packages/deb"
PACKAGE_ROOT="$WORK_DIR/vkpn_${PACKAGE_VERSION}_${PACKAGE_ARCH}"
APP_DIR="$PACKAGE_ROOT/opt/vkpn"

if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "Linux bundle not found at $BUNDLE_DIR"
  exit 1
fi

rm -rf "$PACKAGE_ROOT"
mkdir -p "$APP_DIR" \
  "$PACKAGE_ROOT/DEBIAN" \
  "$PACKAGE_ROOT/usr/bin" \
  "$PACKAGE_ROOT/usr/share/applications" \
  "$PACKAGE_ROOT/usr/share/icons/hicolor/512x512/apps"

cp -R "$BUNDLE_DIR"/. "$APP_DIR"/
ln -s /opt/vkpn/vkpn "$PACKAGE_ROOT/usr/bin/vkpn"
install -m 0644 "$ROOT_DIR/packaging/linux/vkpn.desktop" "$PACKAGE_ROOT/usr/share/applications/vkpn.desktop"
install -m 0644 "$ROOT_DIR/assets/vkpn_logo.png" "$PACKAGE_ROOT/usr/share/icons/hicolor/512x512/apps/vkpn.png"

INSTALLED_SIZE="$(du -sk "$APP_DIR" | cut -f1)"

cat > "$PACKAGE_ROOT/DEBIAN/control" <<EOF
Package: vkpn
Version: $PACKAGE_VERSION
Section: net
Priority: optional
Architecture: $PACKAGE_ARCH
Maintainer: VkPN
Installed-Size: $INSTALLED_SIZE
Depends: libgtk-3-0
Description: VkPN desktop client
 Flutter-based desktop client for WireGuard and VK TURN workflows.
EOF

mkdir -p "$DIST_DIR"
dpkg-deb --build "$PACKAGE_ROOT" "$DIST_DIR/vkpn-linux-amd64-$BUILD_MODE.deb"
