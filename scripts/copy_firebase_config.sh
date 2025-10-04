#!/bin/bash

# Simple script to copy Firebase configuration files
# Run this after pulling from git to set up Firebase

set -e  # Exit on any error

echo "🔥 Copying Firebase configuration files..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the Flutter project root directory"
    exit 1
fi

# Copy google-services.json for Android
if [ -f "google-services.json" ]; then
    echo "📋 Copying google-services.json to android/app/..."
    mkdir -p android/app
    cp google-services.json android/app/google-services.json
    echo "✅ google-services.json copied successfully"
else
    echo "❌ Error: google-services.json not found in project root"
    echo "   Please ensure this file exists in the project root"
    exit 1
fi

# Copy GoogleService-Info.plist for iOS
if [ -f "GoogleService-Info.plist" ]; then
    echo "📋 Copying GoogleService-Info.plist to ios/Runner/..."
    cp GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
    echo "✅ GoogleService-Info.plist copied successfully"
else
    echo "⚠️  Warning: GoogleService-Info.plist not found in project root"
    echo "   iOS push notifications will not work without this file"
fi

echo ""
echo "🎉 Firebase configuration files copied successfully!"
echo ""
echo "Next steps:"
echo "1. Run 'flutter clean' to clean build cache"
echo "2. Run 'flutter pub get' to update dependencies"
echo "3. For iOS: Add GoogleService-Info.plist to Xcode project"
echo "4. Test on physical devices (push notifications don't work on simulators)"
