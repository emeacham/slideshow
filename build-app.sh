#!/usr/bin/env bash
# Compiles Slideshow and assembles a runnable .app bundle.
#
# Usage:
#   ./build-app.sh                   release build → Slideshow.app in project root
#   ./build-app.sh debug             debug build
#   ./build-app.sh release install   release build + copy to /Applications

set -euo pipefail

APP_NAME="Slideshow"
BUILD_CONFIG="${1:-release}"
INSTALL="${2:-}"

echo "▸ Compiling ${APP_NAME} (${BUILD_CONFIG})…"
swift build -c "${BUILD_CONFIG}"

# --show-bin-path returns the architecture-specific directory, so this works
# identically on Intel and Apple Silicon.
BIN_DIR=$(swift build -c "${BUILD_CONFIG}" --show-bin-path)
BINARY="${BIN_DIR}/${APP_NAME}"

if [ ! -f "${BINARY}" ]; then
    echo "✗ Binary not found at: ${BINARY}"
    exit 1
fi

APP_BUNDLE="${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"

echo "▸ Assembling ${APP_BUNDLE}…"
rm -rf "${APP_BUNDLE}"
mkdir -p "${CONTENTS}/MacOS"
mkdir -p "${CONTENTS}/Resources"

cp "${BINARY}"                   "${CONTENTS}/MacOS/${APP_NAME}"
cp "Resources/Info.plist"        "${CONTENTS}/Info.plist"
cp "Resources/AppIcon.icns"      "${CONTENTS}/Resources/AppIcon.icns"

# Ad-hoc signing — no Apple Developer account required.
# On first launch macOS will show a Gatekeeper warning; right-click → Open to approve once.
echo "▸ Signing (ad-hoc)…"
codesign --deep --force --sign - "${APP_BUNDLE}"

if [ "${INSTALL}" = "install" ]; then
    DEST="/Applications/${APP_BUNDLE}"
    echo "▸ Installing to ${DEST}…"
    rm -rf "${DEST}"
    cp -r "${APP_BUNDLE}" "${DEST}"
    echo ""
    echo "✓ Installed. Open with: open '${DEST}'"
    echo "  Or search 'Slideshow' in Spotlight (⌘Space)"
else
    echo ""
    echo "✓ ${APP_BUNDLE} is ready."
    echo "  Run:     open ${APP_BUNDLE}"
    echo "  Install: ./build-app.sh ${BUILD_CONFIG} install"
fi
