#!/usr/bin/env bash
# Generates the platform folders once, then applies permissions the app needs. Safe to re-run.
set -e
[ -d android ] || flutter create --platforms=android,windows,macos,linux --org org.gramvidya --project-name gramvidya .
flutter pub get
if ! grep -q RECORD_AUDIO android/app/src/main/AndroidManifest.xml; then
  perl -0pi -e 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n    <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"/>\n    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>\n    <uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE"/>\n    <application android:usesCleartextTraffic="true"#' android/app/src/main/AndroidManifest.xml
fi
for f in macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements; do
  grep -q audio-input "$f" || perl -0pi -e 's#</dict>#\t<key>com.apple.security.network.server</key><true/>\n\t<key>com.apple.security.network.client</key><true/>\n\t<key>com.apple.security.device.audio-input</key><true/>\n</dict>#' "$f"
done
grep -q NSMicrophoneUsageDescription macos/Runner/Info.plist || perl -0pi -e 's#</dict>\n</plist>#\t<key>NSMicrophoneUsageDescription</key><string>Voice questions</string>\n</dict>\n</plist>#' macos/Runner/Info.plist
grep -q NSSpeechRecognitionUsageDescription macos/Runner/Info.plist || perl -0pi -e 's#</dict>\n</plist>#\t<key>NSSpeechRecognitionUsageDescription</key><string>Voice questions</string>\n</dict>\n</plist>#' macos/Runner/Info.plist
echo "Setup done."
