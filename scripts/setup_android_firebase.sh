#!/bin/bash

# Setup script for Android Firebase configuration
# This script copies google-services.json to the correct location and sets up the project

set -e  # Exit on any error

echo "🔧 Setting up Android Firebase configuration..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the Flutter project root directory"
    exit 1
fi

# Check if google-services.json exists in root
if [ ! -f "google-services.json" ]; then
    echo "❌ Error: google-services.json not found in project root"
    exit 1
fi

# Create android/app directory if it doesn't exist
mkdir -p android/app

# Copy google-services.json to the correct location
echo "📋 Copying google-services.json to android/app/..."
cp google-services.json android/app/google-services.json

# Verify the file was copied
if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json copied successfully"
else
    echo "❌ Error: Failed to copy google-services.json"
    exit 1
fi

# Check if GoogleService-Info.plist exists for iOS
if [ -f "GoogleService-Info.plist" ]; then
    echo "📋 Copying GoogleService-Info.plist to ios/Runner/..."
    cp GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
    echo "✅ GoogleService-Info.plist copied successfully"
else
    echo "⚠️  Warning: GoogleService-Info.plist not found in project root"
    echo "   You'll need to add this file for iOS push notifications to work"
fi

# Check if the Android build.gradle has the Google Services plugin
if grep -q "com.google.gms.google-services" android/app/build.gradle.kts; then
    echo "✅ Google Services plugin already configured in android/app/build.gradle.kts"
else
    echo "❌ Error: Google Services plugin not found in android/app/build.gradle.kts"
    echo "   Please ensure the plugin is added to the build.gradle.kts file"
    exit 1
fi

# Check if the root build.gradle has the Google Services classpath
if grep -q "com.google.gms:google-services" android/build.gradle.kts; then
    echo "✅ Google Services classpath already configured in android/build.gradle.kts"
else
    echo "❌ Error: Google Services classpath not found in android/build.gradle.kts"
    echo "   Please ensure the classpath is added to the root build.gradle.kts file"
    exit 1
fi

echo ""
echo "🎉 Android Firebase setup complete!"
echo ""
echo "Next steps:"
echo "1. Run 'flutter clean' to clean the build cache"
echo "2. Run 'flutter pub get' to update dependencies"
echo "3. Run 'flutter build apk' or 'flutter run' to test the build"
echo ""
echo "For iOS setup:"
echo "1. Add GoogleService-Info.plist to your Xcode project"
echo "2. Open ios/Runner.xcworkspace in Xcode"
echo "3. Right-click on Runner folder > Add Files to Runner"
echo "4. Select GoogleService-Info.plist and add to target"
