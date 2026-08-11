#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHITECTURE="${ARCHITECTURE:-$(uname -m)}"
if [[ $# -gt 0 ]]; then
  if [[ "$1" != "--arch" || $# -ne 2 ]]; then
    echo "usage: $0 [--arch arm64|x86_64]" >&2
    exit 2
  fi
  ARCHITECTURE="$2"
fi

case "$ARCHITECTURE" in
  arm64|x86_64)
    ;;
  *)
    echo "unsupported architecture: $ARCHITECTURE (expected arm64 or x86_64)" >&2
    exit 2
    ;;
esac

DIST_DIR="$ROOT_DIR/dist/$ARCHITECTURE"
APP_BUNDLE="$DIST_DIR/MacBookPet.app"
STAGING_DIR="$DIST_DIR/dmg-staging"

"$ROOT_DIR/script/build_and_run.sh" --release-app --arch "$ARCHITECTURE" >/dev/null

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
DMG_PATH="$DIST_DIR/CubePet-$VERSION-$ARCHITECTURE.dmg"
VOLUME_NAME="CubePet $VERSION"
IDENTITY="${CODESIGN_IDENTITY:--}"

if [[ "$IDENTITY" == "-" ]]; then
  /usr/bin/codesign --force --sign - "$APP_BUNDLE"
  echo "Created an ad-hoc signature for local distribution."
else
  /usr/bin/codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP_BUNDLE"
  echo "Signed with identity: $IDENTITY"
fi

/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
/usr/bin/ditto "$APP_BUNDLE" "$STAGING_DIR/CubePet.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
/usr/bin/hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"
/usr/bin/hdiutil verify "$DMG_PATH"

echo "$DMG_PATH"
