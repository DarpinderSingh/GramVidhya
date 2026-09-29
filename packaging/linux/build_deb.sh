#!/usr/bin/env bash
set -e
V=${1:-0.1.0}; B=build/linux/x64/release/bundle; D=build/deb/gramvidya_$V
rm -rf build/deb; mkdir -p $D/DEBIAN $D/opt/gramvidya $D/usr/share/applications $D/usr/bin
cp -r $B/* $D/opt/gramvidya/
ln -s /opt/gramvidya/gramvidya $D/usr/bin/gramvidya
cat > $D/DEBIAN/control <<EOF
Package: gramvidya
Version: $V
Architecture: amd64
Maintainer: GramVidya <team@gramvidya.local>
Depends: libgtk-3-0
Description: Offline AI learning for rural and tribal higher education
EOF
cat > $D/usr/share/applications/gramvidya.desktop <<EOF
[Desktop Entry]
Name=GramVidya AI
Exec=/opt/gramvidya/gramvidya
Type=Application
Categories=Education;
EOF
dpkg-deb --build $D build/gramvidya_${V}_amd64.deb
