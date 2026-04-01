#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_URL="${VKTURN_RELEASE_BASE_URL:-https://github.com/alexmac6574/vk-turn-proxy/releases/latest/download}"

download_asset() {
  local asset_name="$1"
  local output_path="$2"

  mkdir -p "$(dirname "$output_path")"
  curl -fL "$BASE_URL/$asset_name" -o "$output_path"
}

usage() {
  cat <<'EOF'
Usage: bash scripts/fetch_vkturn_binaries.sh [all|android|darwin|windows|desktop]
EOF
}

target="${1:-all}"

case "$target" in
  all)
    targets=(android darwin windows)
    ;;
  desktop)
    targets=(darwin windows)
    ;;
  android | darwin | windows)
    targets=("$target")
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

for current_target in "${targets[@]}"; do
  case "$current_target" in
    android)
      download_asset \
        "client-android-arm64" \
        "$ROOT_DIR/android/app/src/main/jniLibs/arm64-v8a/libvkturn.so"
      ;;
    darwin)
      download_asset \
        "client-darwin-arm64" \
        "$ROOT_DIR/assets/bin/client-darwin-arm64"
      ;;
    windows)
      download_asset \
        "client-windows-amd64.exe" \
        "$ROOT_DIR/assets/bin/client-windows-amd64.exe"
      ;;
  esac
done
