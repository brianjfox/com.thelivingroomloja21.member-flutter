#!/bin/bash

# Complete project setup script
# This script sets up the entire project after a fresh git checkout

set -e

echo "🚀 Setting up TLR Member Flutter project..."
echo "=============================================="

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "📁 Project root: $PROJECT_ROOT"

# Change to project directory
cd "$PROJECT_ROOT"

# 1. Get Flutter dependencies
echo ""
echo "📦 Getting Flutter dependencies..."
flutter pub get

# 2. Setup Android configuration
echo ""
echo "🤖 Setting up Android configuration..."
if [ -f "scripts/setup_android.sh" ]; then
    ./scripts/setup_android.sh
else
    echo "⚠️  Android setup script not found"
fi

# 3. Setup iOS configuration (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "🍎 Setting up iOS configuration..."
    
    # Update iOS deployment target if needed
    IOS_PODFILE="$PROJECT_ROOT/ios/Podfile"
    if [ -f "$IOS_PODFILE" ]; then
        # Ensure iOS deployment target is at least 11.0 for biometric support
        if ! grep -q "platform :ios, '11.0'" "$IOS_PODFILE"; then
            echo "🔧 Updating iOS deployment target..."
            sed -i '' "s/platform :ios, '[^']*'/platform :ios, '11.0'/g" "$IOS_PODFILE"
            echo "✅ iOS deployment target updated to 11.0"
        else
            echo "✅ iOS deployment target is already sufficient"
        fi
    fi
    
    # Install iOS pods
    echo "📦 Installing iOS pods..."
    cd ios && pod install && cd ..
    echo "✅ iOS pods installed"
else
    echo "⚠️  Skipping iOS setup (not on macOS)"
fi

# 4. Generate code (if needed)
echo ""
echo "🔧 Generating code..."
if [ -f "pubspec.yaml" ] && grep -q "json_serializable" pubspec.yaml; then
    echo "📝 Running code generation..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
    echo "✅ Code generation complete"
else
    echo "ℹ️  No code generation needed"
fi

# 5. Clean and get dependencies again
echo ""
echo "🧹 Cleaning and refreshing dependencies..."
flutter clean
flutter pub get

echo ""
echo "🎉 Project setup complete!"
echo "=========================="
echo ""
echo "📋 What was set up:"
echo "   • Flutter dependencies installed"
echo "   • Android MainActivity configured for biometric auth"
echo "   • Android permissions added"
echo "   • iOS deployment target updated (if on macOS)"
echo "   • iOS pods installed (if on macOS)"
echo "   • Code generation completed"
echo ""
echo "🚀 You can now run:"
echo "   • flutter run (to run on connected device)"
echo "   • flutter run -d chrome (to run in web browser)"
echo ""
echo "💡 To revert Android changes: ./scripts/revert_android.sh"
echo "💡 To re-run setup: ./scripts/setup_project.sh"
