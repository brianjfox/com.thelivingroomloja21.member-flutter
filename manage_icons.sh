#!/bin/bash

# TLR Flutter App Icon Management Script
# This script manages app icons and previews for the Flutter app
# Similar to the Ionic app's icon management system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SOURCE_ICON="tlr-icon.png"
ICONS_DIR="app-icons"
TOOLS_DIR="tools"

# Flutter-specific paths
FLUTTER_IOS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
FLUTTER_ANDROID_DIR="android/app/src/main/res"

# Function to print colored output
print_status() {
    echo -e "${BLUE}🎨${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
    echo "=" | tr '\n' '=' | head -c ${#1}; echo
}

# Function to check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check if ImageMagick is installed
    if ! command -v convert &> /dev/null; then
        print_error "ImageMagick is not installed. Please install it:"
        echo "  macOS: brew install imagemagick"
        echo "  Ubuntu: sudo apt-get install imagemagick"
        echo "  Windows: Download from https://imagemagick.org/"
        exit 1
    fi
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed. Please install Flutter first."
        exit 1
    fi
    
    # Check if source icon exists
    if [ ! -f "$SOURCE_ICON" ]; then
        print_error "Source icon not found: $SOURCE_ICON"
        echo "Please ensure $SOURCE_ICON exists in the project root"
        exit 1
    fi
    
    print_success "All dependencies are available"
}

# Function to create directory structure
create_directories() {
    print_status "Creating directory structure..."
    
    mkdir -p "$ICONS_DIR/ios"
    mkdir -p "$ICONS_DIR/android"
    mkdir -p "$TOOLS_DIR"
    
    print_success "Directory structure created"
}

# Function to generate iOS icons
generate_ios_icons() {
    print_status "Generating iOS icons..."
    
    local ios_dir="$ICONS_DIR/ios"
    
    # iOS icon sizes (in points, @1x, @2x, @3x)
    local ios_icons=(
        "20x20@1x:20"
        "20x20@2x:40"
        "20x20@3x:60"
        "29x29@1x:29"
        "29x29@2x:58"
        "29x29@3x:87"
        "40x40@1x:40"
        "40x40@2x:80"
        "40x40@3x:120"
        "60x60@2x:120"
        "60x60@3x:180"
        "76x76@1x:76"
        "76x76@2x:152"
        "83.5x83.5@2x:167"
        "1024x1024@1x:1024"
    )
    
    for icon_spec in "${ios_icons[@]}"; do
        local name="${icon_spec%%:*}"
        local size="${icon_spec##*:}"
        local output_file="$ios_dir/icon-$name.png"
        
        print_status "Generating $name (${size}x${size})..."
        magick "$SOURCE_ICON" -resize "${size}x${size}" "$output_file"
        
        if [ -f "$output_file" ]; then
            print_success "Generated $name"
        else
            print_error "Failed to generate $name"
        fi
    done
    
    print_success "iOS icons generated"
}

# Function to generate Android icons
generate_android_icons() {
    print_status "Generating Android icons..."
    
    local android_dir="$ICONS_DIR/android"
    
    # Android icon sizes (in dp)
    local android_icons=(
        "mipmap-mdpi/ic_launcher.png:48"
        "mipmap-hdpi/ic_launcher.png:72"
        "mipmap-xhdpi/ic_launcher.png:96"
        "mipmap-xxhdpi/ic_launcher.png:144"
        "mipmap-xxxhdpi/ic_launcher.png:192"
        "mipmap-mdpi/ic_launcher_round.png:48"
        "mipmap-hdpi/ic_launcher_round.png:72"
        "mipmap-xhdpi/ic_launcher_round.png:96"
        "mipmap-xxhdpi/ic_launcher_round.png:144"
        "mipmap-xxxhdpi/ic_launcher_round.png:192"
    )
    
    for icon_spec in "${android_icons[@]}"; do
        local path="${icon_spec%%:*}"
        local size="${icon_spec##*:}"
        local output_file="$android_dir/$path"
        local output_dir=$(dirname "$output_file")
        
        # Create directory if it doesn't exist
        mkdir -p "$output_dir"
        
        print_status "Generating $path (${size}x${size})..."
        magick "$SOURCE_ICON" -resize "${size}x${size}" "$output_file"
        
        if [ -f "$output_file" ]; then
            print_success "Generated $path"
        else
            print_error "Failed to generate $path"
        fi
    done
    
    print_success "Android icons generated"
}

# Function to deploy iOS icons
deploy_ios_icons() {
    print_status "Deploying iOS icons..."
    
    if [ ! -d "$FLUTTER_IOS_DIR" ]; then
        print_error "iOS directory not found: $FLUTTER_IOS_DIR"
        print_warning "Run 'flutter create .' first to create iOS project structure"
        return 1
    fi
    
    # Copy all iOS icons
    cp -r "$ICONS_DIR/ios/"* "$FLUTTER_IOS_DIR/"
    
    # Create Contents.json for iOS
    cat > "$FLUTTER_IOS_DIR/Contents.json" << 'EOF'
{
  "images": [
    {
      "filename": "icon-20x20@1x.png",
      "idiom": "iphone",
      "scale": "1x",
      "size": "20x20"
    },
    {
      "filename": "icon-20x20@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "20x20"
    },
    {
      "filename": "icon-20x20@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "20x20"
    },
    {
      "filename": "icon-29x29@1x.png",
      "idiom": "iphone",
      "scale": "1x",
      "size": "29x29"
    },
    {
      "filename": "icon-29x29@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "29x29"
    },
    {
      "filename": "icon-29x29@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "29x29"
    },
    {
      "filename": "icon-40x40@1x.png",
      "idiom": "iphone",
      "scale": "1x",
      "size": "40x40"
    },
    {
      "filename": "icon-40x40@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "40x40"
    },
    {
      "filename": "icon-40x40@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "40x40"
    },
    {
      "filename": "icon-60x60@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "60x60"
    },
    {
      "filename": "icon-60x60@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "60x60"
    },
    {
      "filename": "icon-20x20@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "20x20"
    },
    {
      "filename": "icon-29x29@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "29x29"
    },
    {
      "filename": "icon-40x40@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "40x40"
    },
    {
      "filename": "icon-76x76@1x.png",
      "idiom": "ipad",
      "scale": "1x",
      "size": "76x76"
    },
    {
      "filename": "icon-76x76@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "76x76"
    },
    {
      "filename": "icon-83.5x83.5@2x.png",
      "idiom": "ipad",
      "scale": "2x",
      "size": "83.5x83.5"
    },
    {
      "filename": "icon-1024x1024@1x.png",
      "idiom": "ios-marketing",
      "scale": "1x",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
EOF
    
    print_success "iOS icons deployed"
}

# Function to deploy Android icons
deploy_android_icons() {
    print_status "Deploying Android icons..."
    
    if [ ! -d "$FLUTTER_ANDROID_DIR" ]; then
        print_error "Android directory not found: $FLUTTER_ANDROID_DIR"
        print_warning "Run 'flutter create .' first to create Android project structure"
        return 1
    fi
    
    # Copy all Android icons
    cp -r "$ICONS_DIR/android/"* "$FLUTTER_ANDROID_DIR/"
    
    print_success "Android icons deployed"
}

# Function to generate app previews
generate_app_previews() {
    print_status "Generating app previews..."
    
    local previews_dir="$ICONS_DIR/previews"
    mkdir -p "$previews_dir"
    
    # App Store preview sizes
    local preview_icons=(
        "iPhone_6.7_App_Store_Preview.png:1290x2796"
        "iPhone_6.5_App_Store_Preview.png:1242x2688"
        "iPhone_5.5_App_Store_Preview.png:1242x2208"
        "iPad_Pro_App_Store_Preview.png:2048x2732"
        "iPad_App_Store_Preview.png:1536x2048"
    )
    
    for preview_spec in "${preview_icons[@]}"; do
        local name="${preview_spec%%:*}"
        local size="${preview_spec##*:}"
        local output_file="$previews_dir/$name"
        
        print_status "Generating $name (${size})..."
        magick "$SOURCE_ICON" -resize "$size" -background white -gravity center -extent "$size" "$output_file"
        
        if [ -f "$output_file" ]; then
            print_success "Generated $name"
        else
            print_error "Failed to generate $name"
        fi
    done
    
    print_success "App previews generated"
}

# Function to show icon information
show_icon_info() {
    print_header "TLR Flutter App Icon Management System"
    
    echo -e "${CYAN}📱 Generated Icons:${NC}"
    echo "─" | tr '\n' '-' | head -c 50; echo
    
    if [ -d "$ICONS_DIR/ios" ]; then
        local ios_count=$(find "$ICONS_DIR/ios" -name "*.png" | wc -l)
        echo -e "${GREEN}✅ iOS Icons: $ios_count files${NC}"
    else
        echo -e "${RED}❌ iOS Icons: Not generated${NC}"
    fi
    
    if [ -d "$ICONS_DIR/android" ]; then
        local android_count=$(find "$ICONS_DIR/android" -name "*.png" | wc -l)
        echo -e "${GREEN}✅ Android Icons: $android_count files${NC}"
    else
        echo -e "${RED}❌ Android Icons: Not generated${NC}"
    fi
    
    if [ -d "$ICONS_DIR/previews" ]; then
        local preview_count=$(find "$ICONS_DIR/previews" -name "*.png" | wc -l)
        echo -e "${GREEN}✅ App Previews: $preview_count files${NC}"
    else
        echo -e "${RED}❌ App Previews: Not generated${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📋 Icon Specifications:${NC}"
    echo "─" | tr '\n' '-' | head -c 50; echo
    echo "🎨 Design: Generated from $SOURCE_ICON using ImageMagick"
    echo "📐 Format: PNG with transparency support"
    echo "🔄 Generation: Automated scaling from source image"
    echo "📦 Tool: ImageMagick magick command"
    
    echo ""
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo "─" | tr '\n' '-' | head -c 50; echo
    echo "1. Run: ./manage_icons.sh deploy"
    echo "2. Run: flutter clean && flutter pub get"
    echo "3. Build and test your apps"
}

# Function to clean generated icons
clean_icons() {
    print_status "Cleaning generated icons..."
    
    if [ -d "$ICONS_DIR" ]; then
        rm -rf "$ICONS_DIR"
        print_success "Cleaned generated icons"
    else
        print_warning "No icons to clean"
    fi
}

# Main function
main() {
    case "${1:-help}" in
        "generate")
            print_header "Generating App Icons"
            check_dependencies
            create_directories
            generate_ios_icons
            generate_android_icons
            generate_app_previews
            print_success "Icon generation complete!"
            ;;
        "deploy")
            print_header "Deploying App Icons"
            if [ ! -d "$ICONS_DIR" ]; then
                print_error "Icons not generated. Run './manage_icons.sh generate' first."
                exit 1
            fi
            deploy_ios_icons
            deploy_android_icons
            print_success "Icon deployment complete!"
            ;;
        "preview")
            print_header "Generating App Previews"
            check_dependencies
            create_directories
            generate_app_previews
            print_success "App preview generation complete!"
            ;;
        "info")
            show_icon_info
            ;;
        "clean")
            clean_icons
            ;;
        "all")
            print_header "Complete Icon Management"
            check_dependencies
            create_directories
            generate_ios_icons
            generate_android_icons
            generate_app_previews
            deploy_ios_icons
            deploy_android_icons
            print_success "Complete icon management finished!"
            ;;
        "help"|*)
            print_header "TLR Flutter App Icon Management"
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  generate  - Generate all app icons and previews"
            echo "  deploy    - Deploy generated icons to Flutter project"
            echo "  preview   - Generate app store previews only"
            echo "  info      - Show information about generated icons"
            echo "  clean     - Clean all generated icons"
            echo "  all       - Generate and deploy all icons"
            echo "  help      - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 generate    # Generate icons from $SOURCE_ICON"
            echo "  $0 deploy      # Deploy icons to Flutter project"
            echo "  $0 all         # Generate and deploy everything"
            echo "  $0 info        # Show icon information"
            ;;
    esac
}

# Run main function with all arguments
main "$@"
