#!/bin/bash

# Flutter run script with automatic setup
# This script sets up permissions and runs the app on a connected device

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to project directory
cd "$PROJECT_DIR"

echo "🚀 Starting Flutter app..."

# Function to show usage
show_usage() {
    echo "Usage: $0 [platform] [options]"
    echo ""
    echo "Platforms:"
    echo "  ios     - Run on iOS device"
    echo "  android - Run on Android device"
    echo "  auto    - Auto-detect connected device (default)"
    echo ""
    echo "Options:"
    echo "  --hot     - Enable hot reload (default)"
    echo "  --no-hot  - Disable hot reload"
    echo "  --setup   - Run setup before running"
    echo ""
    echo "Examples:"
    echo "  $0 ios"
    echo "  $0 android --no-hot"
    echo "  $0 auto --setup"
}

# Parse arguments
PLATFORM="auto"
HOT_RELOAD="--hot"
SETUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        ios|android|auto)
            PLATFORM="$1"
            shift
            ;;
        --hot)
            HOT_RELOAD="--hot"
            shift
            ;;
        --no-hot)
            HOT_RELOAD=""
            shift
            ;;
        --setup)
            SETUP=true
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

# Run setup if requested
if [ "$SETUP" = true ]; then
    echo "🔧 Running setup..."
    if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "auto" ]; then
        "$SCRIPT_DIR/setup_ios_permissions.sh"
    fi
fi

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Find device
device_lines=$(flutter devices)
echo "🔍 Checking for cached device ID..."
if [ -r .flutter_device ]; then
    echo -n "🔍 FOUND cached device ID: "
    DEVICE_ID=$(cat .flutter_device);
    echo $DEVICE_ID
elif [ "$PLATFORM" = "auto" ]; then
    echo "🔍 Auto-detecting connected device..."
    DEVICE_ID=$(echo $device_lines | grep -E "(iPhone|iPad|Android|BJF)") | head -1 | awk '{print $1}'
    if [ "$DEVICE_ID" = "16" ]; then
	DEVICE_ID=$(echo $device_line | grep -E "BFOX") | head -1 | awk '{print $6;}'
    fi

    if [ -z "$DEVICE_ID" ]; then
        echo "❌ No connected device found. Please connect a device and try again."
        exit 1
    else
	echo "$DEVICE_ID" | cat >.flutter_device
    fi
    echo "📱 Found device: $DEVICE_ID"
fi

# Run the app
echo "🏃 Running app on device: $DEVICE_ID"
if [ -n "$HOT_RELOAD" ]; then
    echo "🔥 Hot reload enabled"
    flutter run -d "$DEVICE_ID" $HOT_RELOAD
else
    echo "❄️ Hot reload disabled"
    flutter run -d "$DEVICE_ID"
fi
