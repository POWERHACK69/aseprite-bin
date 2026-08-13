#!/usr/bin/env bash
set -euo pipefail

# Build Aseprite for Linux and package it as an AppImage.
#
# Usage:
#   ./buildappimage.sh            # build latest version and create AppImage
#   ./buildappimage.sh 1.3.18.2   # build specific version and create AppImage
#
# Uses linuxdeploy to bundle libraries and appimagetool to produce the
# AppImage. Both tools are downloaded to the current directory on first run.

VERSION="${1:-${ASEPRITE_VERSION:-}}"

if [ -z "$VERSION" ]; then
  TAG=$(git ls-remote --tags --sort=-version:refname https://github.com/aseprite/aseprite.git \
    | awk -F'/' '/refs\/tags\/v/ && !/\^\{\}/ { print $3; exit }')
  VERSION=${TAG#v}
fi

echo "building aseprite v$VERSION"

if [ ! -d "aseprite-v$VERSION" ]; then
  ASEPRITE_VERSION="v$VERSION" ./build.sh
else
  echo "using existing build output aseprite-v$VERSION"
fi

LINUXDEPLOY="$PWD/linuxdeploy-x86_64.AppImage"
APPIMAGETOOL="$PWD/appimagetool-x86_64.AppImage"

if [ ! -f "$LINUXDEPLOY" ]; then
  curl -sfL https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage -o "$LINUXDEPLOY"
fi
if [ ! -f "$APPIMAGETOOL" ]; then
  curl -sfL https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -o "$APPIMAGETOOL"
fi
chmod +x "$LINUXDEPLOY" "$APPIMAGETOOL"

APPDIR="$PWD/AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

install -m 0755 "aseprite-v$VERSION/aseprite" "$APPDIR/usr/bin/aseprite"
cp -r "aseprite-v$VERSION/data" "$APPDIR/usr/bin/data"
cp -r "aseprite-v$VERSION/docs" "$APPDIR/usr/bin/docs"

cat > "$APPDIR/usr/share/applications/aseprite.desktop" <<EOF
[Desktop Entry]
Name=Aseprite
GenericName=Sprite Editor
Comment=Animated sprite editor and pixel art tool
Exec=aseprite
Icon=aseprite
Terminal=false
Type=Application
Categories=Graphics;2DGraphics;RasterGraphics;
Keywords=pixel;art;sprite;animation;drawing;
StartupNotify=true
EOF

install -m 0644 "aseprite-v$VERSION/data/icons/ase256.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/aseprite.png"

"$LINUXDEPLOY" --appimage-extract-and-run \
  --appdir "$APPDIR" \
  --executable "$APPDIR/usr/bin/aseprite" \
  --desktop-file "$APPDIR/usr/share/applications/aseprite.desktop" \
  --icon-file "$APPDIR/usr/share/icons/hicolor/256x256/apps/aseprite.png" \
  >/dev/null

"$APPIMAGETOOL" --appimage-extract-and-run "$APPDIR" >/dev/null

rm -f "aseprite-v$VERSION-x86_64.AppImage"
mv "Aseprite-x86_64.AppImage" "aseprite-v$VERSION-x86_64.AppImage"

echo "AppImage written to aseprite-v$VERSION-x86_64.AppImage"