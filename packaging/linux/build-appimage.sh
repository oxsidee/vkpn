#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_MODE="${1:-release}"

BUNDLE_DIR="$ROOT_DIR/build/linux/x64/$BUILD_MODE/bundle"
DIST_DIR="$ROOT_DIR/dist"
WORK_DIR="$ROOT_DIR/build/linux-packages/appimage"
APPDIR="$WORK_DIR/AppDir"
APPIMAGE_TOOL="$WORK_DIR/appimagetool-x86_64.AppImage"

if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "Linux bundle not found at $BUNDLE_DIR"
  exit 1
fi

rm -rf "$APPDIR"
mkdir -p "$APPDIR"
cp -R "$BUNDLE_DIR"/. "$APPDIR"/
install -m 0755 "$ROOT_DIR/packaging/linux/AppRun" "$APPDIR/AppRun"
install -m 0644 "$ROOT_DIR/packaging/linux/vkpn.desktop" "$APPDIR/vkpn.desktop"
install -m 0644 "$ROOT_DIR/assets/vkpn_logo.png" "$APPDIR/vkpn.png"
install -m 0644 "$ROOT_DIR/assets/vkpn_logo.png" "$APPDIR/.DirIcon"

if [[ ! -f "$APPIMAGE_TOOL" ]]; then
  mkdir -p "$WORK_DIR"
  curl -fsSL \
    https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage \
    -o "$APPIMAGE_TOOL"
  chmod +x "$APPIMAGE_TOOL"
fi

mkdir -p "$DIST_DIR"
ARCH=x86_64 "$APPIMAGE_TOOL" --appimage-extract-and-run "$APPDIR" "$DIST_DIR/vkpn-linux-x64-$BUILD_MODE.AppImage"
