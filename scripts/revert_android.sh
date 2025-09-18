#!/bin/bash

# Revert script for Android-specific changes
# This script reverts the changes made by setup_android.sh

set -e

echo "🔄 Reverting Android configuration changes..."

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$PROJECT_ROOT/android"

echo "📁 Project root: $PROJECT_ROOT"
echo "📁 Android dir: $ANDROID_DIR"

# Check if Android directory exists
if [ ! -d "$ANDROID_DIR" ]; then
    echo "❌ Android directory not found. Make sure you're in a Flutter project."
    exit 1
fi

# 1. Revert MainActivity to original FlutterActivity
echo "🔄 Reverting MainActivity to FlutterActivity..."

MAIN_ACTIVITY_FILE="$ANDROID_DIR/app/src/main/kotlin/com/thelivingroomloja21/tlr_member_flutter/MainActivity.kt"

if [ -f "$MAIN_ACTIVITY_FILE.backup" ]; then
    # Restore from backup
    cp "$MAIN_ACTIVITY_FILE.backup" "$MAIN_ACTIVITY_FILE"
    rm "$MAIN_ACTIVITY_FILE.backup"
    echo "✅ MainActivity reverted to FlutterActivity"
elif [ -f "$MAIN_ACTIVITY_FILE" ]; then
    # Manual revert if no backup exists
    sed -i '' 's/import io\.flutter\.embedding\.android\.FlutterFragmentActivity/import io.flutter.embedding.android.FlutterActivity/g' "$MAIN_ACTIVITY_FILE"
    sed -i '' 's/class MainActivity : FlutterFragmentActivity()/class MainActivity : FlutterActivity()/g' "$MAIN_ACTIVITY_FILE"
    echo "✅ MainActivity manually reverted to FlutterActivity"
else
    echo "⚠️  MainActivity file not found"
fi

# 2. Remove biometric permissions from AndroidManifest.xml
echo "🔄 Removing biometric permissions from AndroidManifest.xml..."

MANIFEST_FILE="$ANDROID_DIR/app/src/main/AndroidManifest.xml"

if [ -f "$MANIFEST_FILE" ]; then
    # Remove biometric permission lines
    sed -i '' '/<uses-permission android:name="android.permission.USE_BIOMETRIC" \/>/d' "$MANIFEST_FILE"
    sed -i '' '/<uses-permission android:name="android.permission.USE_FINGERPRINT" \/>/d' "$MANIFEST_FILE"
    echo "✅ Biometric permissions removed from AndroidManifest.xml"
else
    echo "⚠️  AndroidManifest.xml not found"
fi

echo ""
echo "🔄 Android configuration reverted to original state!"
echo ""
echo "📋 Summary of reverted changes:"
echo "   • MainActivity reverted to FlutterActivity"
echo "   • Biometric permissions removed from AndroidManifest.xml"
echo ""
echo "💡 To reapply changes, run: ./scripts/setup_android.sh"
