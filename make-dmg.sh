#!/bin/bash
# Build Moni.app and package it into a distributable, compressed DMG with a
# drag-to-Applications layout. Output: dist/Moni-<version>.dmg
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

APP_NAME="Moni"
VERSION="${MONI_VERSION:-1.0}"
DIST="dist"
STAGE="$(mktemp -d)/dmg"
DMG="${DIST}/${APP_NAME}-${VERSION}.dmg"

# 1. Build the app bundle into dist/.
MONI_VERSION="${VERSION}" bash scripts/build-app.sh "${DIST}"

# 2. Stage the DMG contents: the app + a symlink to /Applications.
echo "==> Staging DMG contents…"
mkdir -p "${STAGE}"
cp -R "${DIST}/${APP_NAME}.app" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"

# 3. Build a compressed read-only disk image.
echo "==> Creating ${DMG}…"
rm -f "${DMG}"
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGE}" \
  -ov -format UDZO \
  "${DMG}" >/dev/null

rm -rf "$(dirname "${STAGE}")"

echo ""
echo "✅ Created ${DMG}"
echo "   Size: $(du -h "${DMG}" | cut -f1)"
