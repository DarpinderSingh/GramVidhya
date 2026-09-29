#!/usr/bin/env bash
set -e
B=build/linux/x64/release/bundle; A=build/AppDir
rm -rf $A; mkdir -p $A/usr/bin; cp -r $B/* $A/usr/bin/
cat > $A/AppRun <<'EOF'
#!/bin/sh
exec "$(dirname "$(readlink -f "$0")")/usr/bin/gramvidya" "$@"
EOF
chmod +x $A/AppRun
cat > $A/gramvidya.desktop <<EOF
[Desktop Entry]
Name=GramVidya AI
Exec=gramvidya
Icon=gramvidya
Type=Application
Categories=Education;
EOF
cp assets/icon.png $A/gramvidya.png
[ -f appimagetool ] || { curl -L -o appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage; chmod +x appimagetool; }
ARCH=x86_64 ./appimagetool --appimage-extract-and-run $A build/GramVidya-x86_64.AppImage
