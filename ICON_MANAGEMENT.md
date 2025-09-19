# TLR Flutter App Icon Management

This document describes the icon management system for the TLR Flutter app, similar to the Ionic app's icon management system.

## Overview

The icon management system provides automated generation and deployment of app icons and previews for both iOS and Android platforms. It uses ImageMagick to generate all required icon sizes from a single source image.

## Prerequisites

### Required Tools

1. **ImageMagick** - For image processing and resizing
   - macOS: `brew install imagemagick`
   - Ubuntu: `sudo apt-get install imagemagick`
   - Windows: Download from [ImageMagick.org](https://imagemagick.org/)

2. **Flutter** - For Flutter project structure
   - Install from [Flutter.dev](https://flutter.dev/docs/get-started/install)

### Source Image

- **File**: `tlr-icon.png`
- **Location**: Project root directory
- **Format**: PNG with transparency support
- **Recommended Size**: 1024x1024 pixels or larger

## Usage

### Basic Commands

```bash
# Generate all icons and previews
./manage_icons.sh generate

# Deploy icons to Flutter project
./manage_icons.sh deploy

# Generate and deploy everything
./manage_icons.sh all

# Show information about generated icons
./manage_icons.sh info

# Clean all generated icons
./manage_icons.sh clean

# Generate app store previews only
./manage_icons.sh preview
```

### Complete Workflow

1. **Prepare source image**:
   ```bash
   # Ensure tlr-icon.png exists in project root
   ls -la tlr-icon.png
   ```

2. **Generate all icons**:
   ```bash
   ./manage_icons.sh generate
   ```

3. **Deploy to Flutter project**:
   ```bash
   ./manage_icons.sh deploy
   ```

4. **Clean Flutter project**:
   ```bash
   flutter clean
   flutter pub get
   ```

5. **Build and test**:
   ```bash
   flutter build ios
   flutter build android
   ```

## Generated Files

### iOS Icons

Generated in `app-icons/ios/`:
- `icon-20x20@1x.png` (20x20)
- `icon-20x20@2x.png` (40x40)
- `icon-20x20@3x.png` (60x60)
- `icon-29x29@1x.png` (29x29)
- `icon-29x29@2x.png` (58x58)
- `icon-29x29@3x.png` (87x87)
- `icon-40x40@1x.png` (40x40)
- `icon-40x40@2x.png` (80x80)
- `icon-40x40@3x.png` (120x120)
- `icon-60x60@2x.png` (120x120)
- `icon-60x60@3x.png` (180x180)
- `icon-76x76@1x.png` (76x76)
- `icon-76x76@2x.png` (152x152)
- `icon-83.5x83.5@2x.png` (167x167)
- `icon-1024x1024@1x.png` (1024x1024)

### Android Icons

Generated in `app-icons/android/`:
- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)
- `mipmap-mdpi/ic_launcher_round.png` (48x48)
- `mipmap-hdpi/ic_launcher_round.png` (72x72)
- `mipmap-xhdpi/ic_launcher_round.png` (96x96)
- `mipmap-xxhdpi/ic_launcher_round.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher_round.png` (192x192)

### App Store Previews

Generated in `app-icons/previews/`:
- `iPhone_6.7_App_Store_Preview.png` (1290x2796)
- `iPhone_6.5_App_Store_Preview.png` (1242x2688)
- `iPhone_5.5_App_Store_Preview.png` (1242x2208)
- `iPad_Pro_App_Store_Preview.png` (2048x2732)
- `iPad_App_Store_Preview.png` (1536x2048)

## Deployment Locations

### iOS
- **Target**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Contents.json**: Automatically generated with proper icon mappings

### Android
- **Target**: `android/app/src/main/res/`
- **Structure**: Maintains Android's mipmap directory structure

## Troubleshooting

### Common Issues

1. **ImageMagick not found**:
   ```bash
   # Install ImageMagick
   brew install imagemagick  # macOS
   sudo apt-get install imagemagick  # Ubuntu
   ```

2. **Source icon not found**:
   ```bash
   # Ensure tlr-icon.png exists in project root
   cp /path/to/your/icon.png tlr-icon.png
   ```

3. **Flutter directories not found**:
   ```bash
   # Create Flutter project structure
   flutter create .
   ```

4. **Permission denied**:
   ```bash
   # Make script executable
   chmod +x manage_icons.sh
   ```

### Verification

Check if icons were generated correctly:
```bash
./manage_icons.sh info
```

Check if icons were deployed correctly:
```bash
ls -la ios/Runner/Assets.xcassets/AppIcon.appiconset/
ls -la android/app/src/main/res/mipmap-*/
```

## Integration with Build Process

### CI/CD Integration

Add to your build pipeline:
```yaml
# Example GitHub Actions step
- name: Generate App Icons
  run: |
    ./manage_icons.sh all
    flutter clean
    flutter pub get
```

### Package.json Scripts (if using Node.js)

Add to `package.json`:
```json
{
  "scripts": {
    "icons:generate": "./manage_icons.sh generate",
    "icons:deploy": "./manage_icons.sh deploy",
    "icons:all": "./manage_icons.sh all",
    "icons:info": "./manage_icons.sh info",
    "icons:clean": "./manage_icons.sh clean"
  }
}
```

## Comparison with Ionic App

This Flutter icon management system provides similar functionality to the Ionic app's system:

| Feature | Ionic App | Flutter App |
|---------|-----------|-------------|
| Source Image | `tlr-icon.png` | `tlr-icon.png` |
| Icon Generation | `rn-app-icons` | `ImageMagick` |
| iOS Icons | ✅ | ✅ |
| Android Icons | ✅ | ✅ |
| App Previews | ✅ | ✅ |
| Automated Deployment | ✅ | ✅ |
| Script Management | Node.js | Bash |

## Best Practices

1. **Source Image Quality**: Use high-resolution source images (1024x1024 or larger)
2. **Transparency**: Ensure source image supports transparency for best results
3. **Version Control**: Add `app-icons/` to `.gitignore` to avoid committing generated files
4. **Regular Updates**: Regenerate icons when source image changes
5. **Testing**: Always test icons on physical devices after deployment

## Support

For issues or questions:
1. Check this documentation
2. Verify all prerequisites are installed
3. Check the troubleshooting section
4. Review the script output for specific error messages
