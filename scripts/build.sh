#!/bin/bash

# Flutter build script with automatic platform setup
# This script ensures all platform-specific configurations are set up before building

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to project directory
cd "$PROJECT_DIR"

echo "🚀 Starting Flutter build process..."
echo "📁 Project directory: $PROJECT_DIR"

# Function to show usage
show_usage() {
    echo "Usage: $0 [platform] [options]"
    echo ""
    echo "Platforms:"
    echo "  ios     - Build for iOS"
    echo "  android - Build for Android"
    echo "  all     - Build for both platforms"
    echo ""
    echo "Options:"
    echo "  --debug   - Build in debug mode (default)"
    echo "  --release - Build in release mode"
    echo "  --clean   - Clean before building"
    echo ""
    echo "Examples:"
    echo "  $0 ios --debug"
    echo "  $0 android --release"
    echo "  $0 all --clean"
}

# Parse arguments
PLATFORM=""
BUILD_MODE="--debug"
CLEAN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        ios|android|all)
            PLATFORM="$1"
            shift
            ;;
        --debug|--release)
            BUILD_MODE="$1"
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# If no platform specified, default to all
if [ -z "$PLATFORM" ]; then
    PLATFORM="all"
fi

# Clean if requested
if [ "$CLEAN" = true ]; then
    echo "🧹 Cleaning previous build..."
    flutter clean
fi

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build based on platform
case $PLATFORM in
    ios)
        echo "🍎 Building for iOS..."
        "$SCRIPT_DIR/setup_ios_permissions.sh"
        flutter build ios $BUILD_MODE
        echo "✅ iOS build complete!"
        ;;
    android)
        echo "🤖 Building for Android..."
        flutter build apk $BUILD_MODE
        echo "✅ Android build complete!"
        ;;
    all)
        echo "🍎 Building for iOS..."
        "$SCRIPT_DIR/setup_ios_permissions.sh"
        flutter build ios $BUILD_MODE
        echo "✅ iOS build complete!"
        
        echo "🤖 Building for Android..."
        flutter build apk $BUILD_MODE
        echo "✅ Android build complete!"
        ;;
esac

echo "🎉 Build process complete!"
echo "📱 You can now run the app with: flutter run -d <device_id>"
