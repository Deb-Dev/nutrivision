#!/bin/bash

# Script to build and distribute NutriVision app
# Usage: ./distribute.sh [ios|android|both]

# Functions
build_ios() {
  echo "📱 Building iOS app..."
  cd ios
  flutter build ios --release --no-codesign
  cd ..
}

build_android() {
  echo "🤖 Building Android app..."
  # Clean first
  flutter clean
  # Build the APK directly with Flutter
  flutter build apk --release
}

distribute_ios() {
  echo "🚀 Distributing iOS app..."
  cd ios
  # Build the app with fastlane
  fastlane beta
  
  # Now use Firebase CLI directly for distribution
  echo "📲 Uploading to Firebase App Distribution..."
  firebase appdistribution:distribute "./build/ios/NutriVision.ipa" \
    --app "1:115156539680:ios:b731050a1eda881d1f9f45" \
    --groups "beta-testers" \
    --release-notes "$(cat metadata/en-US/release_notes.txt 2>/dev/null || echo 'New beta release')"
  cd ..
}

distribute_android() {
  echo "🚀 Distributing Android app..."
  
  # Check if the APK was built successfully
  APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
  
  if [ -f "$APK_PATH" ]; then
    echo "📲 Uploading to Firebase App Distribution..."
    # Use Firebase CLI directly for distribution
    firebase appdistribution:distribute "$APK_PATH" \
      --app "1:115156539680:android:c5ada66de89205341f9f45" \
      --groups "beta-testers" \
      --release-notes "$(cat android/app/src/main/play/release-notes/en-US/default.txt 2>/dev/null || echo 'New beta release')"
  else
    echo "❌ Error: APK file not found at $APK_PATH. Build failed?"
    exit 1
  fi
}

# Main execution
case "$1" in
  "ios")
    echo "🍎 iOS Build and Distribution"
    build_ios
    distribute_ios
    ;;
  "android")
    echo "🤖 Android Build and Distribution"
    build_android
    distribute_android
    ;;
  "both")
    echo "🍎🤖 Building and Distributing for both platforms"
    build_ios
    distribute_ios
    build_android
    distribute_android
    ;;
  *)
    echo "Usage: ./distribute.sh [ios|android|both]"
    exit 1
    ;;
esac

echo "✅ Distribution process completed!"
