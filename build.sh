#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/outputs"
APP="$OUT/ColorDropper.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
CACHE="$ROOT/.build/module-cache"

rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES" "$CACHE"

clang "$ROOT/Sources/main.m" \
  -o "$MACOS/ColorDropper" \
  -fobjc-arc \
  -framework AppKit \
  -framework Carbon \
  -framework CoreGraphics

cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"
if [ -f "$ROOT/Resources/AppIcon.icns" ]; then
  cp "$ROOT/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi
chmod +x "$MACOS/ColorDropper"

echo "$APP"
