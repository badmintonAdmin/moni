#!/bin/bash
# Builds Moni.app (release, arm64, ad-hoc signed) into an output directory.
# Does NOT install — used by both build.sh (local install) and make-dmg.sh.
#
# Usage: scripts/build-app.sh [OUTPUT_DIR]   (default: ./dist)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="Moni"
BUNDLE_ID="ventures.nimble.moni"
PRODUCT="Moni"                      # executable target name
ICON_SRC="icon.png"
MIN_MACOS="14.0"
VERSION="${MONI_VERSION:-1.0}"

OUT_DIR="${1:-dist}"
APP="${OUT_DIR}/${APP_NAME}.app"
CONTENTS="${APP}/Contents"
MACOS_DIR="${CONTENTS}/MacOS"
RES_DIR="${CONTENTS}/Resources"

echo "==> Building (release, arm64)…"
swift build -c release --arch arm64

echo "==> Assembling ${APP}…"
rm -rf "${APP}"
mkdir -p "${MACOS_DIR}" "${RES_DIR}"
cp ".build/release/${PRODUCT}" "${MACOS_DIR}/${APP_NAME}"

if [[ -f "${ICON_SRC}" ]]; then
  echo "==> Generating app icon…"
  ICONSET="$(mktemp -d)/AppIcon.iconset"
  mkdir -p "${ICONSET}"
  for size in 16 32 128 256 512; do
    sips -z $size $size             "${ICON_SRC}" --out "${ICONSET}/icon_${size}x${size}.png"     >/dev/null
    sips -z $((size*2)) $((size*2)) "${ICON_SRC}" --out "${ICONSET}/icon_${size}x${size}@2x.png" >/dev/null
  done
  iconutil -c icns "${ICONSET}" -o "${RES_DIR}/AppIcon.icns"
fi

echo "==> Writing Info.plist…"
cat > "${CONTENTS}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>     <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>      <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>      <string>${BUNDLE_ID}</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>${VERSION}</string>
    <key>CFBundleVersion</key>         <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>  <string>${MIN_MACOS}</string>
    <key>LSUIElement</key>             <true/>
    <key>NSHumanReadableCopyright</key><string>Moni</string>
</dict>
</plist>
PLIST

echo "==> Code signing (ad-hoc)…"
codesign --force --deep --sign - "${APP}"

echo "✅ Built ${APP}"
