#!/bin/bash

# Uniuyo Town Campus Flutter Setup Script
# This script sets up the Flutter project by copying assets and generating code

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_PROJECT="$SCRIPT_DIR/.."

echo "🚀 Setting up Uniuyo Town Campus Flutter project..."
echo ""

# 1. Create directories
echo "📁 Creating asset directories..."
mkdir -p "$SCRIPT_DIR/assets/images"
mkdir -p "$SCRIPT_DIR/assets/geojson"

# 2. Copy image assets from Android project
echo "🖼️  Copying image assets from Android project..."
ANDROID_DRAWABLE="$ANDROID_PROJECT/app/src/main/res/drawable"

if [ -d "$ANDROID_DRAWABLE" ]; then
    images=("directions.png" "search.png" "notifications.png" "study.png" "feedback.png" "info.png" "header.jpeg" "logo_image.jpeg")

    for image in "${images[@]}"; do
        if [ -f "$ANDROID_DRAWABLE/$image" ]; then
            cp "$ANDROID_DRAWABLE/$image" "$SCRIPT_DIR/assets/images/"
            echo "  ✓ Copied $image"
        else
            echo "  ⚠️  Warning: $image not found in Android project"
        fi
    done
else
    echo "  ⚠️  Warning: Android drawable directory not found at $ANDROID_DRAWABLE"
fi

# 3. Verify GeoJSON files
echo ""
echo "🗺️  Verifying GeoJSON files..."
if [ -f "$SCRIPT_DIR/assets/geojson/Buildings111.geojson" ]; then
    echo "  ✓ Buildings111.geojson found"
else
    echo "  ⚠️  Buildings111.geojson not found - please copy from ~/Downloads/"
fi

if [ -f "$SCRIPT_DIR/assets/geojson/Roads111.geojson" ]; then
    echo "  ✓ Roads111.geojson found"
else
    echo "  ⚠️  Roads111.geojson not found - please copy from ~/Downloads/"
fi

# 4. Install Flutter dependencies
echo ""
echo "📦 Installing Flutter dependencies..."
cd "$SCRIPT_DIR"
flutter pub get

# 5. Generate code (Riverpod, Freezed, JSON serialization)
echo ""
echo "🔨 Generating code (Riverpod providers, Freezed models)..."
flutter pub run build_runner build --delete-conflicting-outputs

# 6. Done
echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Connect a device or start an emulator"
echo "  2. Run: flutter run"
echo ""
echo "To rebuild generated code later:"
echo "  flutter pub run build_runner build --delete-conflicting-outputs"
echo ""
