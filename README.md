[Aseprite][] binary build for 64-bit Windows and Linux.

Step by step guide to build binaries for latest version:

# 1. Create fork by clicking `Fork` button on the top right

![step1a](images/step1a.png)
![step1b](images/step1b.png)

# 2. Click `Actions` tab on the top, and enable actions

![step2](images/step2.png)

# 3. Open `aseprite` workflow, and click `Run workflow`

Optionally specify which version of Asprite to build (e.g. v1.3.10) in text field.
Leave it empty to build latest released version.
See list of available Aseprite versions [here][versions].

![step3](images/step3.png)

# 4. Wait ~13min for build to finish, then open latest run

![step4](images/step4.png)

# 5. Scroll to the bottom to download .zip archive

![step5](images/step5.png)

For building newer aseprite version repeat steps 3 to 5.

# Building for Linux

Run the `aseprite-linux` workflow from the `Actions` tab (same steps as the
Windows workflow, but produces a `.rpm`, `.deb`, and `.AppImage`), or build
locally:

```bash
# install build dependencies (Debian/Ubuntu)
sudo apt-get install -y g++ cmake ninja-build \
  libx11-dev libxcursor-dev libxi-dev libxrandr-dev \
  libgl1-mesa-dev libfontconfig1-dev libssl-dev

# build latest version (set ASEPRITE_VERSION=v1.3.18.2 for a specific one)
./build.sh
```

The portable build will be written to `aseprite-v<version>/` with an
`aseprite.ini` so it behaves as a portable program.

## Building an RPM

```bash
# Fedora/RHEL: install build dependencies and rpm-build
sudo dnf install -y rpm-build gcc-c++ cmake ninja-build \
  libX11-devel libXcursor-devel libXi-devel libXrandr-devel \
  mesa-libGL-devel fontconfig-devel openssl-devel

# build latest version and package it as an RPM
./buildrpm.sh

# or build a specific version
./buildrpm.sh 1.3.18.2
```

The RPM will be written to `~/rpmbuild/RPMS/x86_64/`. Install it with:

```bash
sudo dnf install ~/rpmbuild/RPMS/x86_64/aseprite-*.rpm
```

## Building a .deb and AppImage

```bash
# Debian/Ubuntu: install build dependencies (see build.sh) and dpkg
# build latest version and package it as a .deb
./builddeb.sh
sudo dpkg -i aseprite_*.deb

# build latest version and package it as an AppImage
# (downloads linuxdeploy and appimagetool on first run)
./buildappimage.sh
./aseprite-*-x86_64.AppImage
```

[Aseprite]: https://github.com/aseprite/aseprite
[versions]: https://github.com/aseprite/aseprite/tags
