#!/bin/bash

# Setup iOS permissions script
# This script programmatically adds required permissions to iOS Info.plist

set -e

echo "🔧 Setting up iOS permissions..."

# Path to Info.plist
INFO_PLIST="ios/Runner/Info.plist"

# Check if Info.plist exists
if [ ! -f "$INFO_PLIST" ]; then
    echo "❌ Error: Info.plist not found at $INFO_PLIST"
    exit 1
fi

# Create backup
cp "$INFO_PLIST" "$INFO_PLIST.backup"
echo "📋 Created backup: $INFO_PLIST.backup"

# Function to add or update a key-value pair in plist
add_plist_key() {
    local key="$1"
    local value="$2"
    
    # Check if key already exists
    if plutil -extract "$key" raw "$INFO_PLIST" >/dev/null 2>&1; then
        echo "🔄 Updating existing key: $key"
        plutil -replace "$key" -string "$value" "$INFO_PLIST"
    else
        echo "➕ Adding new key: $key"
        plutil -insert "$key" -string "$value" "$INFO_PLIST"
    fi
}

# Add Face ID usage description
add_plist_key "NSFaceIDUsageDescription" "This app uses Face ID for secure biometric authentication to access your account."

# Add camera usage description (for future barcode scanning)
add_plist_key "NSCameraUsageDescription" "This app uses the camera to scan barcodes for item identification."

# Add photo library usage description (for future image features)
add_plist_key "NSPhotoLibraryUsageDescription" "This app accesses your photo library to upload profile pictures and item images."

# Add location usage description (for future location features)
add_plist_key "NSLocationWhenInUseUsageDescription" "This app uses your location to provide location-based services and recommendations."

echo "✅ iOS permissions setup complete!"
echo "📱 Added permissions for:"
echo "   - Face ID (biometric authentication)"
echo "   - Camera (barcode scanning)"
echo "   - Photo Library (image uploads)"
echo "   - Location (location services)"

# Validate the plist
if plutil -lint "$INFO_PLIST" >/dev/null 2>&1; then
    echo "✅ Info.plist is valid"
else
    echo "❌ Error: Info.plist is invalid after modifications"
    echo "🔄 Restoring backup..."
    mv "$INFO_PLIST.backup" "$INFO_PLIST"
    exit 1
fi

echo "🎉 Setup complete! You can now build the iOS app."
