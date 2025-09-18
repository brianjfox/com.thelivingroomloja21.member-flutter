# Project Setup Scripts

This directory contains scripts to set up the TLR Member Flutter project after a fresh git checkout.

## Quick Start

After cloning the repository, run:

```bash
./scripts/setup_project.sh
```

This will set up everything needed to run the project.

## Individual Scripts

### `setup_project.sh`
Complete project setup script that:
- Gets Flutter dependencies
- Sets up Android configuration for biometric authentication
- Sets up iOS configuration (on macOS)
- Runs code generation
- Cleans and refreshes dependencies

### `setup_android.sh`
Android-specific setup that:
- Changes MainActivity from `FlutterActivity` to `FlutterFragmentActivity` (required for biometric auth)
- Adds biometric permissions to AndroidManifest.xml
- Ensures compileSdkVersion is sufficient for biometric support

### `revert_android.sh`
Reverts Android changes made by `setup_android.sh`:
- Restores MainActivity to `FlutterActivity`
- Removes biometric permissions from AndroidManifest.xml

## Why These Scripts Are Needed

### MainActivity Change
The `local_auth` plugin requires the Android activity to be a `FragmentActivity`, but Flutter generates a regular `FlutterActivity` by default. This causes biometric authentication to fail with the error:
```
PlatformException(no_fragment_activity, local_auth plugin requires activity to be a FragmentActivity., null, null)
```

### Biometric Permissions
The app needs specific permissions in AndroidManifest.xml to use biometric authentication:
- `android.permission.USE_BIOMETRIC`
- `android.permission.USE_FINGERPRINT`

### iOS Deployment Target
iOS apps using biometric authentication need a minimum deployment target of iOS 11.0.

## Manual Setup (Alternative)

If you prefer to make changes manually:

### Android
1. Edit `android/app/src/main/kotlin/com/thelivingroomloja21/tlr_member_flutter/MainActivity.kt`:
   ```kotlin
   // Change from:
   import io.flutter.embedding.android.FlutterActivity
   class MainActivity : FlutterActivity()
   
   // To:
   import io.flutter.embedding.android.FlutterFragmentActivity
   class MainActivity : FlutterFragmentActivity()
   ```

2. Add to `android/app/src/main/AndroidManifest.xml` before `<application>`:
   ```xml
   <uses-permission android:name="android.permission.USE_BIOMETRIC" />
   <uses-permission android:name="android.permission.USE_FINGERPRINT" />
   ```

### iOS (macOS only)
1. Edit `ios/Podfile`:
   ```ruby
   platform :ios, '11.0'
   ```

## Troubleshooting

### Biometric Authentication Not Working
1. Ensure you've run `./scripts/setup_android.sh`
2. Check that the device has biometric hardware enabled
3. Verify the user has enrolled biometric data (fingerprint/face)
4. Check device logs for any permission errors

### Build Errors
1. Run `flutter clean`
2. Run `flutter pub get`
3. For iOS: `cd ios && pod install && cd ..`
4. Try building again

### Script Permission Errors
Make sure scripts are executable:
```bash
chmod +x scripts/*.sh
```

## Development Workflow

1. **Fresh checkout**: Run `./scripts/setup_project.sh`
2. **Development**: Make your changes
3. **Testing**: Run `flutter run`
4. **Before commit**: Test biometric authentication works
5. **Revert if needed**: Run `./scripts/revert_android.sh`

## Notes

- These scripts modify generated files that are typically not committed to git
- The changes are necessary for biometric authentication to work properly
- Scripts are idempotent - safe to run multiple times
- Always test biometric authentication after setup