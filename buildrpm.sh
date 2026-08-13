#!/usr/bin/env bash
set -euo pipefail

# Build Aseprite for Linux and package it as an RPM.
#
# Usage:
#   ./buildrpm.sh                # build latest version and create RPM
#   ./buildrpm.sh 1.3.18.2       # build specific version and create RPM
#
# Requirements:
#   rpm-build, rpmdevtools (optional), plus the build.sh dependencies
#   Fedora/RHEL: sudo dnf install -y rpm-build gcc-c++ cmake ninja-build \
#       libX11-devel libXcursor-devel libXi-devel libXrandr-devel \
#       mesa-libGL-devel fontconfig-devel openssl-devel

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

command -v rpmbuild >/dev/null 2>&1 || { echo "ERROR: rpmbuild not found, install rpm-build"; exit 1; }

RPMBUILD_DIR="${RPMBUILD_DIR:-$HOME/rpmbuild}"
for d in BUILD BUILDROOT RPMS SOURCES SPECS SRPMS; do
  mkdir -p "$RPMBUILD_DIR/$d"
done

tar -czf "$RPMBUILD_DIR/SOURCES/aseprite-v$VERSION-linux-x64.tar.gz" "aseprite-v$VERSION"

# --nodeps: on Debian/Ubuntu rpmbuild checks BuildRequires against the rpm
# database, which does not see packages installed via apt/dpkg.
rpmbuild -bb --nodeps aseprite.spec --define "aseprite_version $VERSION"

echo "RPM written to $RPMBUILD_DIR/RPMS/x86_64/"
