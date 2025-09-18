# TLR Member Flutter App

A cross-platform Flutter application for The Living Room Member system, providing authentication, event management, item catalog, and purchase tracking.

## Features

- 🔐 **Secure Authentication** - Email/password and biometric (Face ID/Touch ID) login
- 📱 **Cross-Platform** - iOS and Android support
- 🎫 **Event Management** - View and manage events
- 🍷 **Item Catalog** - Browse wine and item catalog
- 💳 **Purchase Tracking** - Track purchases and balances
- ⚙️ **Settings** - User preferences and biometric configuration

## Quick Start

### Prerequisites

- Flutter SDK (latest stable version)
- iOS development: Xcode and iOS device/simulator
- Android development: Android Studio and Android device/emulator

### Running the App

Use the automated scripts for the best experience:

```bash
# Run on connected device (auto-detect)
./scripts/run.sh

# Run on specific platform
./scripts/run.sh ios
./scripts/run.sh android

# Run with setup (recommended for first run)
./scripts/run.sh --setup
```

### Building the App

```bash
# Build for iOS
./scripts/build.sh ios

# Build for Android
./scripts/build.sh android

# Build for both platforms
./scripts/build.sh all

# Build with options
./scripts/build.sh ios --release --clean
```

## Development

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── services/                 # API and authentication services
├── providers/                # State management
├── screens/                  # UI screens
├── utils/                    # Utilities and routing
└── widgets/                  # Reusable widgets

scripts/
├── setup_ios_permissions.sh  # iOS permissions setup
├── build.sh                  # Build script
└── run.sh                    # Run script
```

### Key Technologies

- **Flutter** - Cross-platform UI framework
- **Provider** - State management
- **GoRouter** - Navigation
- **Dio** - HTTP client
- **Local Auth** - Biometric authentication
- **Secure Storage** - Secure data storage

### API Integration

The app connects to the TLR API at `https://api.thelivingroomloja21.com/api` with the following endpoints:

- Authentication (`/auth/authenticate`)
- Biometric enrollment (`/auth/initiate-biometric-enrollment`)
- User data (`/users/me`)
- Events (`/events`)
- Items (`/items`)
- Purchases (`/purchases`)

## Build Scripts

This project uses automated build scripts to ensure reproducible builds without manual file editing.

### Available Scripts

- `./scripts/setup_ios_permissions.sh` - Sets up iOS permissions programmatically
- `./scripts/build.sh` - Comprehensive build script for all platforms
- `./scripts/run.sh` - Development run script with auto-setup

See [scripts/README.md](scripts/README.md) for detailed documentation.

## Authentication

The app supports two authentication methods:

1. **Email/Password** - Traditional login with username and password
2. **Biometric** - Face ID (iOS) or Fingerprint (Android) authentication

Biometric authentication requires initial setup after first login.

## Contributing

1. Use the provided build scripts for all builds
2. Don't manually edit generated files (Info.plist, etc.)
3. Test on both iOS and Android platforms
4. Follow Flutter best practices and conventions

## Troubleshooting

### Common Issues

1. **iOS Build Issues**: Run `./scripts/setup_ios_permissions.sh` to fix permission issues
2. **Biometric Not Working**: Ensure Face ID/Touch ID is enabled on device
3. **API Connection Issues**: Check network connectivity and API endpoint

### Getting Help

- Check the [scripts/README.md](scripts/README.md) for build script documentation
- Review Flutter documentation: https://docs.flutter.dev/
- Check device logs for detailed error information
