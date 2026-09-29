#!/usr/bin/env bash
set -e
APP=build/macos/Build/Products/Release/gramvidya.app
rm -rf build/dmg; mkdir -p build/dmg; cp -R "$APP" build/dmg/; ln -s /Applications build/dmg/Applications
hdiutil create -volname "GramVidya AI" -srcfolder build/dmg -ov -format UDZO build/GramVidya.dmg
