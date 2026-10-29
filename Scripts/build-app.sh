#!/usr/bin/env bash
# Build, sign and package Breather as a menu bar .app bundle.
#
# Usage:   Scripts/build-app.sh
# Env:
#   SIGN_ID=<hash|name>   pick signing identity explicitly. When unset, a
#                         Developer ID Application identity is used if present,
#                         otherwise the bundle is ad-hoc signed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="Breather"
BUNDLE_ID="com.duola8789.Breather"

VERSION="$(/usr/bin/grep -E 'static let version' "$ROOT/Sources/BreatherCore/AppInfo.swift" \
  | /usr/bin/sed -E 's/.*"([^"]+)".*/\1/')"
[[ -z "$VERSION" ]] && VERSION="0.0.0"

DIST="$ROOT/dist"
APP_DIR="$DIST/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Building $APP_NAME $VERSION (arm64 release)"
swift build -c release --arch arm64

BIN="$(swift build -c release --arch arm64 --show-bin-path)/$APP_NAME"
if [[ ! -f "$BIN" ]]; then
  echo "ERROR: built binary not found at $BIN" >&2
  exit 1
fi

echo "==> Assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"
cp "$BIN" "$MACOS/$APP_NAME"

echo "==> Generating app icon"
ICONSET="$DIST/AppIcon.iconset"
rm -rf "$ICONSET"
"$MACOS/$APP_NAME" --dump-appicon "$ICONSET" >/dev/null
iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"
rm -rf "$ICONSET"

if [[ -d "$ROOT/Resources" ]]; then
  for lproj in "$ROOT"/Resources/*.lproj; do
    [[ -d "$lproj" ]] || continue
    cp -R "$lproj" "$RESOURCES/"
  done
fi

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>LSMultipleInstancesProhibited</key><true/>
  <key>NSHumanReadableCopyright</key><string>Copyright © 2026. Personal use.</string>
</dict>
</plist>
PLIST
echo "APPL????" > "$CONTENTS/PkgInfo"

plutil -lint "$CONTENTS/Info.plist" > /dev/null

# Prefer a stable signing identity: the same Team ID (or at least the same
# certificate) across builds is what keeps TCC permissions and login items
# working. Ad-hoc has no identity and changes on every build.
SIGN_ID="${SIGN_ID:-}"
if [[ -z "$SIGN_ID" ]]; then
  for pattern in "Developer ID Application" "Apple Development" "Breather Self-Signed" "Mac Developer"; do
    SIGN_ID="$(security find-identity -v -p codesigning 2>/dev/null \
      | awk -v p="$pattern" 'index($0, p) {print $2; exit}')"
    if [[ -n "$SIGN_ID" ]]; then
      SIGN_KIND="$pattern"
      break
    fi
  done
fi

if [[ -z "$SIGN_ID" || "$SIGN_ID" == "-" ]]; then
  echo "==> No signing identity found — AD-HOC signing (no timestamp: nothing to timestamp)."
  echo "    The bundle is unsigned for distribution purposes: recipients must"
  echo "    clear quarantine (right-click > Open, or: xattr -dr com.apple.quarantine $APP_NAME.app)."
  SIGN_ID="-"
  codesign --force --deep --sign - "$APP_DIR"
else
  # Always timestamp real certificates. Apple Development certs expire after a
  # year; an un-timestamped signature becomes invalid the moment the cert does,
  # which retroactively breaks already-distributed copies.
  echo "==> Signing with $SIGN_KIND: $SIGN_ID (timestamped)"
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_ID" "$APP_DIR"
fi

echo "==> Verifying"
codesign -dv "$APP_DIR" 2>&1 | /usr/bin/grep -E 'Identifier|Signature|Authority' || true
lipo -info "$MACOS/$APP_NAME"

if [[ "${SKIP_DMG:-0}" != "1" ]]; then
  echo "==> Building DMG (drag-to-Applications layout)"
  DMG="$DIST/$APP_NAME-$VERSION.dmg"
  STAGE="$DIST/dmg-stage"
  rm -rf "$STAGE"
  mkdir -p "$STAGE"
  cp -R "$APP_DIR" "$STAGE/"
  ln -s /Applications "$STAGE/Applications"
  rm -f "$DMG"
  hdiutil create -volname "$APP_NAME $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
  if [[ "$SIGN_ID" == "-" ]]; then
    codesign --force --sign - "$DMG"
  else
    codesign --force --timestamp --sign "$SIGN_ID" "$DMG"
  fi
  rm -rf "$STAGE"
  echo "==> Done: $DMG"
else
  echo "==> Done: $APP_DIR"
fi
