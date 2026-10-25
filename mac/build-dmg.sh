#!/bin/sh
# ZoldDesk — Copyright (C) 2026 inukaasith. GPL-3.0, see LICENSE.
# Creates dist/ZoldDesk.dmg from dist/ZoldDesk.app (npm run dmg): the app and an Applications
# link over the hand-drawn background in dmg/ (dmg/make-background.sh renders it).
# The window layout is written by dmgbuild, installed once into dist/.dmgbuild (needs python3).
set -e
cd "$(dirname "$0")"

APP="dist/ZoldDesk.app"
DMG_NAME=${1:-ZoldDesk.dmg}
case "$DMG_NAME" in
  */*) DMG="$DMG_NAME" ;;
  *) DMG="dist/$DMG_NAME" ;;
esac
VOLNAME="ZoldDesk"
VENV="dist/.dmgbuild"

if [ ! -d "$APP" ]; then
  echo "Error: $APP not found. Run ./build-app.sh first." >&2
  exit 1
fi

if [ ! -x "$VENV/bin/dmgbuild" ]; then
  echo "Installing dmgbuild into $VENV..."
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install --quiet --disable-pip-version-check dmgbuild
fi

echo "Creating disk image $DMG..."
rm -f "$DMG"
"$VENV/bin/dmgbuild" -s dmg/settings.py \
  -D app="$APP" -D icon=dist/ZoldDesk.icns -D background=dmg/background.tiff \
  "$VOLNAME" "$DMG"

echo "DMG created successfully: $DMG"
ls -lh "$DMG"
