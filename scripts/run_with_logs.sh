#!/bin/bash

# Run Flutter app with logs captured to file
# Usage: ./scripts/run_with_logs.sh [log_file_name]

set -e

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Default log file name with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${1:-flutter_logs_$TIMESTAMP.txt}"

echo "🚀 Running Flutter app with logs..."
echo "📁 Project: $PROJECT_ROOT"
echo "📝 Log file: $LOG_FILE"
echo ""

# Check if device is connected
echo "🔍 Checking for connected devices..."
DEVICES=$(flutter devices --machine | grep -c '"id"')
if [ "$DEVICES" -eq 0 ]; then
    echo "❌ No devices connected. Please connect a device or start an emulator."
    exit 1
fi

echo "✅ Found $DEVICES device(s)"
echo ""

# Run the app with logs
echo "🏃 Starting Flutter app..."
echo "📝 Logs will be saved to: $LOG_FILE"
echo "⏹️  Press Ctrl+C to stop"
echo ""

# Run flutter with logs redirected
flutter run --debug 2>&1 | tee "$LOG_FILE"
