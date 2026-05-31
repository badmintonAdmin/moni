#!/bin/bash
# Build Moni.app and install it into /Applications (for local development).
# For a distributable disk image, use ./make-dmg.sh instead.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

APP_NAME="Moni"
INSTALL_DIR="/Applications"
STAGE="$(mktemp -d)"

bash scripts/build-app.sh "${STAGE}"

DEST="${INSTALL_DIR}/${APP_NAME}.app"
echo "==> Installing to ${INSTALL_DIR}…"
if [[ -d "${DEST}" ]]; then
  osascript -e "tell application \"${APP_NAME}\" to quit" 2>/dev/null || true
  rm -rf "${DEST}"
fi
cp -R "${STAGE}/${APP_NAME}.app" "${INSTALL_DIR}/"
rm -rf "${STAGE}"

echo ""
echo "✅ Installed ${DEST}"
echo "   Launch with:  open \"${DEST}\""
echo "   First launch may need: System Settings → Privacy & Security → Open Anyway"
