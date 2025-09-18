#!/bin/bash

# Setup script for Android-specific changes after git checkout
# This script applies necessary changes to generated Android files

set -e

echo "🔧 Setting up Android configuration..."

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

# 1. Fix MainActivity to use FlutterFragmentActivity for biometric support
echo "🔧 Fixing MainActivity for biometric authentication..."

MAIN_ACTIVITY_FILE="$ANDROID_DIR/app/src/main/kotlin/com/thelivingroomloja21/tlr_member_flutter/MainActivity.kt"

if [ -f "$MAIN_ACTIVITY_FILE" ]; then
    # Backup original file
    cp "$MAIN_ACTIVITY_FILE" "$MAIN_ACTIVITY_FILE.backup"
    
    # Replace FlutterActivity with FlutterFragmentActivity
    sed -i '' 's/import io\.flutter\.embedding\.android\.FlutterActivity/import io.flutter.embedding.android.FlutterFragmentActivity/g' "$MAIN_ACTIVITY_FILE"
    sed -i '' 's/class MainActivity : FlutterActivity()/class MainActivity : FlutterFragmentActivity()/g' "$MAIN_ACTIVITY_FILE"
    
    echo "✅ MainActivity updated to use FlutterFragmentActivity"
else
    echo "⚠️  MainActivity file not found at expected location: $MAIN_ACTIVITY_FILE"
fi

# 2. Ensure proper permissions in AndroidManifest.xml
echo "🔧 Checking Android permissions..."

MANIFEST_FILE="$ANDROID_DIR/app/src/main/AndroidManifest.xml"

if [ -f "$MANIFEST_FILE" ]; then
    # Check if biometric permission is already present
    if ! grep -q "USE_BIOMETRIC" "$MANIFEST_FILE"; then
        echo "🔧 Adding biometric permission to AndroidManifest.xml..."
        
        # Add USE_BIOMETRIC permission before the application tag
        sed -i '' '/<application/i\
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />\
    <uses-permission android:name="android.permission.USE_FINGERPRINT" />\
' "$MANIFEST_FILE"
        
        echo "✅ Biometric permissions added to AndroidManifest.xml"
    else
        echo "✅ Biometric permissions already present in AndroidManifest.xml"
    fi
else
    echo "⚠️  AndroidManifest.xml not found at expected location: $MANIFEST_FILE"
fi

# 3. Update build.gradle if needed for biometric support
echo "🔧 Checking build.gradle configuration..."

BUILD_GRADLE_FILE="$ANDROID_DIR/app/build.gradle"

if [ -f "$BUILD_GRADLE_FILE" ]; then
    # Check if compileSdkVersion is at least 28 (required for biometric)
    if ! grep -q "compileSdkVersion 28\|compileSdkVersion 29\|compileSdkVersion 30\|compileSdkVersion 31\|compileSdkVersion 32\|compileSdkVersion 33\|compileSdkVersion 34" "$BUILD_GRADLE_FILE"; then
        echo "🔧 Updating compileSdkVersion for biometric support..."
        
        # Update compileSdkVersion to 28 or higher
        sed -i '' 's/compileSdkVersion [0-9]*/compileSdkVersion 28/g' "$BUILD_GRADLE_FILE"
        
        echo "✅ compileSdkVersion updated to 28"
    else
        echo "✅ compileSdkVersion is already sufficient for biometric support"
    fi
else
    echo "⚠️  build.gradle not found at expected location: $BUILD_GRADLE_FILE"
fi

echo ""
echo "🎉 Android setup complete!"
echo ""
echo "📋 Summary of changes:"
echo "   • MainActivity changed to FlutterFragmentActivity (required for biometric auth)"
echo "   • Biometric permissions added to AndroidManifest.xml"
echo "   • compileSdkVersion verified for biometric support"
echo ""
echo "🚀 You can now run 'flutter run' and biometric authentication should work properly."
echo ""
echo "💡 To revert changes, run: ./scripts/revert_android.sh"
