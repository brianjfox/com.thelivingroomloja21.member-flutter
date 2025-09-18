#!/bin/bash

# Flutter iOS build script with automatic permissions setup
# This script ensures iOS permissions are set up before building

set -e

echo "🚀 Starting Flutter iOS build process..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to project directory
cd "$PROJECT_DIR"

echo "📁 Project directory: $PROJECT_DIR"

# Run iOS permissions setup
echo "🔧 Setting up iOS permissions..."
"$SCRIPT_DIR/setup_ios_permissions.sh"

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for iOS
echo "🔨 Building for iOS..."
flutter build ios --debug

echo "✅ iOS build complete!"
echo "📱 You can now run the app with: flutter run -d <device_id>"
