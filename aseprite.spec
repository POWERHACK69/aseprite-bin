# RPM spec to package the Aseprite binary built by build.sh into an RPM.
#
# The pre-built folder (aseprite-v<version>) must be present in %%{_sourcedir}
# as the tarball aseprite-v%%{version}-linux-x64.tar.gz (see buildrpm.sh).
#
# Build with:
#   rpmbuild -bb aseprite.spec --define "aseprite_version 1.3.18.2"

%global aseprite_version %{?aseprite_version}%{!?aseprite_version:1.3.18.2}

Name:           aseprite
Version:        %{aseprite_version}
Release:        1%{?dist}
Summary:        Animated sprite editor and pixel art tool

# Aseprite is free of charge for non-commercial use, but distributed under a
# proprietary EULA (see https://aseprite.org/legal for details).
License:        EULA
URL:            https://www.aseprite.org/
Source0:        aseprite-v%{version}-linux-x64.tar.gz

BuildArch:      x86_64

BuildRequires:  desktop-file-utils
Requires:       fontconfig
Requires:       freetype
Requires:       libX11
Requires:       libXcursor
Requires:       libXi
Requires:       libXrandr
Requires:       libglvnd-glx

%global _enable_debug_packages 0

%description
Aseprite is an animated sprite editor and pixel art tool. It lets you create
2D animations, sprites, and pixel art.

This package is built from source (see build.sh) with the Skia rendering
backend and installs the portable build into the system.

%prep
%setup -q -c -T
tar -xzf %{SOURCE0}

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/aseprite/data
mkdir -p %{buildroot}%{_datadir}/aseprite/docs
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/256x256/apps

install -m 0755 aseprite-v%{version}/aseprite %{buildroot}%{_bindir}/aseprite
cp -r aseprite-v%{version}/data/. %{buildroot}%{_datadir}/aseprite/data/
cp -r aseprite-v%{version}/docs/. %{buildroot}%{_datadir}/aseprite/docs/
install -m 0644 aseprite-v%{version}/data/icons/ase256.png %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/aseprite.png

cat > %{buildroot}%{_datadir}/applications/aseprite.desktop <<EOF
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

%files
%{_bindir}/aseprite
%{_datadir}/aseprite/
%{_datadir}/applications/aseprite.desktop
%{_datadir}/icons/hicolor/256x256/apps/aseprite.png

%post
update-desktop-database %{_datadir}/applications &>/dev/null || :

%postun
update-desktop-database %{_datadir}/applications &>/dev/null || :

%changelog
* Thu Aug 13 2026 POWERHACK69 <powerhack69@users.noreply.github.com> - 1.3.18.2-1
- Initial Linux packaging of the portable Aseprite build
