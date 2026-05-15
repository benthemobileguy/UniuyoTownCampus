#!/bin/bash

# Uniuyo Town Campus - Build and Run Script
# Builds and runs the Flutter app on iOS simulator and Android

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load Mapbox access token from local.properties
MAPBOX_TOKEN=""
if [ -f "android/local.properties" ]; then
    MAPBOX_TOKEN=$(grep "^MAPBOX_ACCESS_TOKEN=" android/local.properties | cut -d'=' -f2)
fi

# Build Flutter command with token if available
FLUTTER_ARGS=""
if [ -n "$MAPBOX_TOKEN" ]; then
    FLUTTER_ARGS="--dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_TOKEN"
    echo "✓ Loaded Mapbox token from local.properties"
fi

echo "🏗️  Uniuyo Town Campus - Build and Run"
echo "========================================"
echo ""

# 1. Run setup if not already done
if [ ! -d "$SCRIPT_DIR/.dart_tool" ]; then
    echo "📦 Running initial setup..."
    ./setup.sh
else
    echo "✓ Project already set up"
fi

echo ""
echo "🔍 Checking for running devices..."
echo ""

# 2. Check for iOS simulator
IOS_DEVICE=$(flutter devices | grep "ios" | grep "simulator" | head -1 | awk '{print $NF}' | tr -d '()')

if [ -n "$IOS_DEVICE" ]; then
    echo "📱 Found iOS Simulator: $IOS_DEVICE"
    echo ""
    echo "🚀 Building and running on iOS Simulator..."
    flutter run $FLUTTER_ARGS -d "$IOS_DEVICE" &
    IOS_PID=$!
    echo "  iOS app started (PID: $IOS_PID)"
else
    echo "⚠️  No iOS simulator running. To run iOS:"
    echo "   1. Open Xcode or Simulator app"
    echo "   2. Start a simulator"
    echo "   3. Run: flutter run -d <device-id>"
fi

echo ""
echo "🤖 Building Android APK..."
flutter build apk $FLUTTER_ARGS --debug

if [ $? -eq 0 ]; then
    APK_PATH="$SCRIPT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "✅ Android APK built successfully!"
    echo "   Location: $APK_PATH"
    echo ""

    # Check for Android emulator
    ANDROID_DEVICE=$(flutter devices | grep "android" | grep "emulator" | head -1 | awk '{print $NF}' | tr -d '()')

    if [ -n "$ANDROID_DEVICE" ]; then
        echo "📱 Found Android Emulator: $ANDROID_DEVICE"
        echo "🚀 Installing APK on Android Emulator..."
        flutter install -d "$ANDROID_DEVICE"
    else
        echo "💡 No Android emulator running. To install APK:"
        echo "   1. Start an Android emulator"
        echo "   2. Run: flutter install -d <device-id>"
        echo "   Or manually install: adb install $APK_PATH"
    fi
else
    echo "❌ Android build failed"
fi

echo ""
echo "========================================"
echo "✅ Build process complete!"
echo ""
echo "Running devices:"
flutter devices
echo ""

# Wait for iOS process if it's running
if [ -n "$IOS_PID" ]; then
    echo "Press Ctrl+C to stop the iOS app..."
    wait $IOS_PID
fi
