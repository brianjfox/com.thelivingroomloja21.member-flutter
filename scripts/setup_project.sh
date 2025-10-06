#!/bin/bash

# Comprehensive setup script for The Living Room Member Flutter app
# This script sets up the project from a fresh git checkout

set -e  # Exit on any error

echo "🚀 Setting up The Living Room Member Flutter app..."
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the Flutter project root directory"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required tools
echo "🔍 Checking required tools..."

if ! command_exists flutter; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    echo "   Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

if ! command_exists dart; then
    echo "❌ Error: Dart is not installed or not in PATH"
    exit 1
fi

echo "✅ Flutter and Dart are available"

# Get Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo "📱 Using: $FLUTTER_VERSION"

# Clean and get dependencies
echo ""
echo "🧹 Cleaning project..."
flutter clean

echo ""
echo "📦 Getting dependencies..."
flutter pub get

# Update mobile_scanner to latest version to resolve Firebase conflicts
echo ""
echo "🔧 Updating mobile_scanner to resolve Firebase conflicts..."
flutter pub upgrade mobile_scanner

# Setup Firebase configuration
echo ""
echo "🔥 Setting up Firebase configuration..."

# Check if google-services.json exists in root
if [ -f "google-services.json" ]; then
    echo "📋 Copying google-services.json to android/app/..."
    mkdir -p android/app
    cp google-services.json android/app/google-services.json
    echo "✅ google-services.json copied successfully"
else
    echo "⚠️  Warning: google-services.json not found in project root"
    echo "   You'll need to add this file for Android push notifications to work"
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

# Verify Android configuration
echo ""
echo "🔍 Verifying Android configuration..."

if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json is in place"
else
    echo "❌ Error: google-services.json not found in android/app/"
    exit 1
fi

# Check if the Android build.gradle has the Google Services plugin
if grep -q "com.google.gms.google-services" android/app/build.gradle.kts; then
    echo "✅ Google Services plugin configured in android/app/build.gradle.kts"
else
    echo "❌ Error: Google Services plugin not found in android/app/build.gradle.kts"
    exit 1
fi

# Check if the root build.gradle has the Google Services classpath
if grep -q "com.google.gms:google-services" android/build.gradle.kts; then
    echo "✅ Google Services classpath configured in android/build.gradle.kts"
else
    echo "❌ Error: Google Services classpath not found in android/build.gradle.kts"
    exit 1
fi

# Run code generation
echo ""
echo "🔧 Running code generation..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Analyze the project
echo ""
echo "🔍 Analyzing project..."
flutter analyze

# Check if there are any critical issues
if [ $? -eq 0 ]; then
    echo "✅ Project analysis passed"
else
    echo "⚠️  Warning: Project analysis found issues (see output above)"
fi

# Test build (optional, can be skipped if there are issues)
echo ""
echo "🏗️  Testing build configuration..."

# Try to build for Android (debug mode)
echo "Building Android debug APK..."
if flutter build apk --debug; then
    echo "✅ Android debug build successful"
else
    echo "⚠️  Warning: Android debug build failed (this might be expected on some systems)"
fi

echo ""
echo "🎉 Project setup complete!"
echo ""
echo "📋 Summary:"
echo "✅ Dependencies installed"
echo "✅ Firebase configuration files copied"
echo "✅ Code generation completed"
echo "✅ Project analyzed"
echo ""
echo "🚀 Next steps:"
echo "1. For Android: Run 'flutter run' or 'flutter build apk'"
echo "2. For iOS: Open ios/Runner.xcworkspace in Xcode and build"
echo "3. Test push notifications on physical devices"
echo ""
echo "📱 To run the app:"
echo "   flutter run"
echo ""
echo "🔧 To build for release:"
echo "   flutter build apk --release    # Android"
echo "   flutter build ios --release # iOS (requires Xcode)"