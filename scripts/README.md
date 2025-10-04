# Setup Scripts for The Living Room Member Flutter App

This directory contains setup scripts to configure the Flutter app for building from a fresh git checkout.

## Scripts Overview

### 1. `setup_project.sh` - Complete Project Setup
**Purpose**: Comprehensive setup script that handles the entire project setup from a fresh git checkout.

**What it does**:
- Checks for required tools (Flutter, Dart)
- Cleans the project
- Installs dependencies
- Copies Firebase configuration files
- Verifies Android configuration
- Runs code generation
- Analyzes the project
- Tests build configuration

**Usage**:
```bash
./scripts/setup_project.sh
```

**When to use**: First time setup or after a fresh git clone.

### 2. `copy_firebase_config.sh` - Firebase Configuration Only
**Purpose**: Simple script to copy Firebase configuration files to the correct locations.

**What it does**:
- Copies `google-services.json` to `android/app/`
- Copies `GoogleService-Info.plist` to `ios/Runner/` (if available)
- Provides next steps guidance

**Usage**:
```bash
./scripts/copy_firebase_config.sh
```

**When to use**: After pulling from git when you only need to update Firebase configuration.

### 3. `setup_android_firebase.sh` - Android Firebase Setup
**Purpose**: Focused script for Android Firebase configuration.

**What it does**:
- Copies `google-services.json` to `android/app/`
- Verifies Google Services plugin configuration
- Provides build instructions

**Usage**:
```bash
./scripts/setup_android_firebase.sh
```

**When to use**: When you only need to set up Android Firebase configuration.

## Prerequisites

Before running any script, ensure you have:

1. **Flutter SDK** installed and in your PATH
2. **Dart SDK** (usually comes with Flutter)
3. **Firebase configuration files** in the project root:
   - `google-services.json` (required for Android)
   - `GoogleService-Info.plist` (required for iOS)

## Quick Start

### For a fresh git checkout:

```bash
# Clone the repository
git clone <repository-url>
cd com.thelivingroomloja21.flutter

# Run the complete setup
./scripts/setup_project.sh
```

### For updating Firebase configuration only:

```bash
# After pulling from git
./scripts/copy_firebase_config.sh

# Clean and rebuild
flutter clean
flutter pub get
```

## Firebase Configuration Files

The app requires Firebase configuration files to be in the project root:

### Android: `google-services.json`
- Must be in the project root
- Will be copied to `android/app/google-services.json`
- Contains Android app configuration for Firebase

### iOS: `GoogleService-Info.plist`
- Must be in the project root
- Will be copied to `ios/Runner/GoogleService-Info.plist`
- Contains iOS app configuration for Firebase
- **Important**: After copying, you must add this file to your Xcode project

## iOS Additional Setup

After running the scripts, for iOS you need to:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click on the Runner folder
3. Select "Add Files to Runner"
4. Choose `GoogleService-Info.plist`
5. Make sure "Copy items if needed" is checked
6. Add to target: Runner

## Troubleshooting

### Script fails with "command not found"
- Ensure Flutter is installed and in your PATH
- Run `flutter doctor` to check your Flutter installation

### Firebase configuration not working
- Verify the configuration files are in the project root
- Check that the bundle ID matches in the configuration files
- Ensure the files are valid JSON/XML

### Build fails
- Run `flutter clean` and try again
- Check that all dependencies are installed with `flutter pub get`
- Verify Firebase configuration files are in the correct locations

### Push notifications not working
- Test on physical devices (not simulators)
- Check that Firebase project is properly configured
- Verify APNs certificates are uploaded to Firebase Console (iOS)
- Check device notification permissions

## File Structure

```
scripts/
├── README.md                    # This file
├── setup_project.sh            # Complete project setup
├── copy_firebase_config.sh     # Firebase config only
└── setup_android_firebase.sh   # Android Firebase setup
```

## Support

If you encounter issues:

1. Check the script output for error messages
2. Verify all prerequisites are met
3. Ensure Firebase configuration files are valid
4. Run `flutter doctor` to check your Flutter installation
5. Check the main project README for additional setup instructions