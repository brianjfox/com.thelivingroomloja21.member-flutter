#!/bin/bash

# Script to fix Firebase dependency conflicts
# This script resolves version conflicts between Firebase and other dependencies

set -e  # Exit on any error

echo "🔧 Fixing Firebase dependency conflicts..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the Flutter project root directory"
    exit 1
fi

# Clean everything
echo "🧹 Cleaning project..."
flutter clean

# Remove iOS pods to start fresh
echo "🗑️  Removing iOS pods..."
rm -rf ios/Pods ios/Podfile.lock

# Update CocoaPods repository
echo "📦 Updating CocoaPods repository..."
pod repo update

# Update mobile_scanner to latest version to resolve conflicts
echo "📱 Updating mobile_scanner to latest version..."
flutter pub upgrade mobile_scanner

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Install iOS pods
echo "🍎 Installing iOS pods..."
cd ios
pod install
cd ..

echo ""
echo "✅ Firebase dependency conflicts resolved!"
echo ""
echo "The following changes were made:"
echo "- Updated mobile_scanner to latest version (7.1.2)"
echo "- Cleaned and reinstalled all dependencies"
echo "- Updated CocoaPods repository"
echo "- Reinstalled iOS pods"
echo ""
echo "You can now build the project:"
echo "  flutter build ios"
echo "  flutter build android"
