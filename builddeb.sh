#!/usr/bin/env bash
set -euo pipefail

# Build Aseprite for Linux and package it as a .deb.
#
# Usage:
#   ./builddeb.sh              # build latest version and create .deb
#   ./builddeb.sh 1.3.18.2     # build specific version and create .deb
#
# Requirements:
#   dpkg, plus the build.sh dependencies (Debian/Ubuntu: see build.sh header)

VERSION="${1:-${ASEPRITE_VERSION:-}}"
VERSION=${VERSION#v}

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

command -v dpkg-deb >/dev/null 2>&1 || { echo "ERROR: dpkg-deb not found, install dpkg"; exit 1; }

DEB_DIR="aseprite_${VERSION}_amd64"
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN" "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/aseprite/data" "$DEB_DIR/usr/share/aseprite/docs"
mkdir -p "$DEB_DIR/usr/share/applications" "$DEB_DIR/usr/share/icons/hicolor/256x256/apps"

install -m 0755 "aseprite-v$VERSION/aseprite" "$DEB_DIR/usr/bin/aseprite"
cp -r "aseprite-v$VERSION/data/." "$DEB_DIR/usr/share/aseprite/data/"
cp -r "aseprite-v$VERSION/docs/." "$DEB_DIR/usr/share/aseprite/docs/"
install -m 0644 "aseprite-v$VERSION/data/icons/ase256.png" "$DEB_DIR/usr/share/icons/hicolor/256x256/apps/aseprite.png"

cat > "$DEB_DIR/usr/share/applications/aseprite.desktop" <<EOF
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

cat > "$DEB_DIR/DEBIAN/control" <<EOF
Package: aseprite
Version: $VERSION
Architecture: amd64
Maintainer: POWERHACK69 <powerhack69@users.noreply.github.com>
Section: graphics
Priority: optional
Homepage: https://www.aseprite.org/
Depends: libc6 (>= 2.31), libfontconfig1, libfreetype6, libx11-6, libxcursor1, libxi6, libxrandr2, libgl1, libglvnd0, zlib1g
Description: Animated sprite editor and pixel art tool
 Aseprite is an animated sprite editor and pixel art tool. This package is
 built from source (see build.sh) with the Skia rendering backend.
EOF

dpkg-deb --build --root-owner-group "$DEB_DIR" >/dev/null

echo "Debian package written to $DEB_DIR.deb"