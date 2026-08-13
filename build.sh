#!/usr/bin/env bash
set -euo pipefail

# Linux build script for Aseprite (mirrors build.cmd for Windows).
#
# Required packages:
#   Debian/Ubuntu: sudo apt-get install -y g++ cmake ninja-build libx11-dev libxcursor-dev libxi-dev libxrandr-dev libgl1-mesa-dev libfontconfig1-dev libssl-dev
#   Fedora/RHEL:   sudo dnf install -y gcc-c++ cmake ninja-build libX11-devel libXcursor-devel libXi-devel libXrandr-devel mesa-libGL-devel fontconfig-devel openssl-devel
#
# Set ASEPRITE_VERSION to a specific tag (e.g. v1.3.18.2) or leave empty to build latest.

ASEPRITE_VERSION="${ASEPRITE_VERSION:-}"

command -v git >/dev/null 2>&1 || { echo "ERROR: git not found"; exit 1; }

# *** ninja

if ! command -v ninja >/dev/null 2>&1; then
  command -v unzip >/dev/null 2>&1 || { echo "ERROR: unzip not found"; exit 1; }
  curl -LOsf https://github.com/ninja-build/ninja/releases/download/v1.13.1/ninja-linux.zip || { echo "failed to download ninja"; exit 1; }
  unzip -qo ninja-linux.zip || exit 1
  rm ninja-linux.zip
  export PATH="$PWD:$PATH"
fi

command -v cmake >/dev/null 2>&1 || { echo "ERROR: cmake not found"; exit 1; }

# *** clone aseprite repo

if [ ! -d aseprite ]; then
  git clone --recursive --tags https://github.com/aseprite/aseprite.git aseprite || { echo "failed to clone repo"; exit 1; }
else
  git -C aseprite fetch --tags || { echo "failed to fetch repo"; exit 1; }
fi

# *** get name of newest tag

if [ -z "$ASEPRITE_VERSION" ]; then
  ASEPRITE_VERSION=$(git -C aseprite tag --sort=creatordate | tail -n 1)
fi

echo "building $ASEPRITE_VERSION"

# *** update local aseprite repo to selected tag

git -C aseprite clean --quiet -fdx
git -C aseprite submodule foreach --recursive git clean -xfd
git -C aseprite fetch --quiet --depth=1 --no-tags origin "$ASEPRITE_VERSION:refs/remotes/origin/$ASEPRITE_VERSION" || { echo "failed to fetch repo"; exit 1; }
git -C aseprite reset --quiet --hard "origin/$ASEPRITE_VERSION" || { echo "failed to update repo"; exit 1; }
git -C aseprite submodule update --init --recursive || { echo "failed to update submodules"; exit 1; }

python3 -c "v = open('aseprite/src/ver/CMakeLists.txt').read(); open('aseprite/src/ver/CMakeLists.txt', 'w').write(v.replace('1.x-dev', '${ASEPRITE_VERSION:1}'))"

# *** download skia

if [ -f aseprite/laf/misc/skia-tag.txt ]; then
  SKIA_VERSION=$(cat aseprite/laf/misc/skia-tag.txt)
elif [[ "$ASEPRITE_VERSION" == *beta* ]]; then
  SKIA_VERSION=m124-08a5439a6b
else
  SKIA_VERSION=m102-861e4743af
fi

if [ ! -d "skia-$SKIA_VERSION" ]; then
  mkdir -p "skia-$SKIA_VERSION"
  SKIA_URL="https://github.com/aseprite/skia/releases/download/$SKIA_VERSION/Skia-Linux-Release-x64.zip"
  if ! curl -sfL -o skia-linux.zip "$SKIA_URL"; then
    SKIA_URL="${SKIA_URL%.zip}-libstdc++.zip"
    curl -sfL -o skia-linux.zip "$SKIA_URL" || { echo "failed to download skia"; exit 1; }
  fi
  (cd "skia-$SKIA_VERSION" && unzip -q ../skia-linux.zip) || exit 1
  rm skia-linux.zip
fi

# *** build aseprite

rm -rf build

cmake \
  -G Ninja \
  -S aseprite \
  -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
  -DLAF_BACKEND=skia \
  -DSKIA_DIR="$PWD/skia-$SKIA_VERSION" \
  -DSKIA_LIBRARY_DIR="$PWD/skia-$SKIA_VERSION/out/Release-x64" \
  || { echo "failed to configure build"; exit 1; }

ninja -C build || { echo "build failed"; exit 1; }

# *** create output folder

mkdir -p "aseprite-$ASEPRITE_VERSION/docs"
cp -r aseprite/docs/. "aseprite-$ASEPRITE_VERSION/docs/"
echo "# This file is here so Aseprite behaves as a portable program" > "aseprite-$ASEPRITE_VERSION/aseprite.ini"
cp build/bin/aseprite "aseprite-$ASEPRITE_VERSION/"
cp -r build/bin/data "aseprite-$ASEPRITE_VERSION/data/"

if [ -n "${GITHUB_WORKFLOW:-}" ]; then
  mkdir -p github
  mv "aseprite-$ASEPRITE_VERSION" github/
  echo "ASEPRITE_VERSION=$ASEPRITE_VERSION" >> "$GITHUB_OUTPUT"
fi