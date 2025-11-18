#!/bin/bash

# ==============================================================================
# Azure Key Vault Manager - macOS Release Build Script
# ==============================================================================
# This script builds, signs, and packages the app for distribution without
# Apple Developer Program membership (using ad-hoc signing).
#
# Requirements:
#   - Flutter SDK installed
#   - Xcode command line tools (for codesign)
#   - create-dmg (optional, for professional DMG creation)
#     Install with: npm install -g create-dmg
#
# Usage:
#   ./scripts/build_macos_release.sh
#
# Output:
#   - dist/AzureKeyVaultManager-v{VERSION}.dmg
#   - dist/AzureKeyVaultManager-v{VERSION}.dmg.sha256
# ==============================================================================

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Azure Key Vault Manager"
BUILD_DIR="build/macos/Build/Products/Release"
OUTPUT_DIR="dist"

echo ""
echo "======================================================================"
echo "  Azure Key Vault Manager - macOS Release Build"
echo "======================================================================"
echo ""

# Ensure we're in the project root directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}📂 Project directory: $PROJECT_DIR${NC}"

# Extract version from pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | cut -d'+' -f1 | tr -d ' ')
BUILD_NUMBER=$(grep "^version:" pubspec.yaml | sed 's/version: //' | cut -d'+' -f2 | tr -d ' ')

if [ -z "$VERSION" ]; then
    echo -e "${RED}❌ Error: Could not extract version from pubspec.yaml${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Building version: $VERSION (build $BUILD_NUMBER)${NC}"
echo ""

# Step 1: Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Step 2: Get dependencies
echo ""
echo -e "${BLUE}📦 Getting dependencies...${NC}"
flutter pub get

# Step 3: Build for macOS
echo ""
echo -e "${BLUE}🔨 Building macOS application (Release mode)...${NC}"
echo "This may take a few minutes..."
flutter build macos --release

if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo -e "${RED}❌ Error: Build failed - app bundle not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build completed successfully${NC}"

# Step 4: Ad-hoc code signing (required for Apple Silicon)
echo ""
echo -e "${BLUE}✍️  Code signing (ad-hoc)...${NC}"
echo "This is required for the app to run on Apple Silicon Macs"

codesign -s - -f --deep "$BUILD_DIR/$APP_NAME.app"

# Step 5: Verify signature
echo ""
echo -e "${BLUE}🔍 Verifying code signature...${NC}"
codesign -v --verbose "$BUILD_DIR/$APP_NAME.app"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Code signature verified${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: Code signature verification had issues${NC}"
    echo "The app may still work, but proceed with caution"
fi

# Step 6: Create DMG
echo ""
echo -e "${BLUE}📦 Creating DMG installer...${NC}"

DMG_NAME="AzureKeyVaultManager-v${VERSION}.dmg"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"

# Check if create-dmg is available
if command -v create-dmg &> /dev/null; then
    echo "Using create-dmg for professional DMG creation..."

    # Create a temporary directory for DMG contents
    TEMP_DMG_DIR=$(mktemp -d)
    cp -R "$BUILD_DIR/$APP_NAME.app" "$TEMP_DMG_DIR/"

    # Create DMG with create-dmg
    create-dmg \
        --volname "$APP_NAME" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 175 190 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 425 190 \
        "$DMG_PATH" \
        "$TEMP_DMG_DIR" \
        --overwrite \
        2>/dev/null || true

    # Clean up temp directory
    rm -rf "$TEMP_DMG_DIR"

    if [ -f "$DMG_PATH" ]; then
        echo -e "${GREEN}✅ DMG created with create-dmg${NC}"
    else
        echo -e "${YELLOW}⚠️  create-dmg failed, falling back to hdiutil...${NC}"
        # Fallback to hdiutil
        hdiutil create -volname "$APP_NAME" \
            -srcfolder "$BUILD_DIR/$APP_NAME.app" \
            -ov -format UDZO "$DMG_PATH"
    fi
else
    echo -e "${YELLOW}ℹ️  create-dmg not found, using basic hdiutil method${NC}"
    echo "Install create-dmg for better DMG appearance: npm install -g create-dmg"
    echo ""

    # Use hdiutil (built-in macOS tool)
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$BUILD_DIR/$APP_NAME.app" \
        -ov -format UDZO "$DMG_PATH"

    if [ -f "$DMG_PATH" ]; then
        echo -e "${GREEN}✅ Basic DMG created${NC}"
    fi
fi

if [ ! -f "$DMG_PATH" ]; then
    echo -e "${RED}❌ Error: DMG creation failed${NC}"
    exit 1
fi

# Step 7: Generate SHA256 checksum
echo ""
echo -e "${BLUE}🔐 Generating SHA256 checksum...${NC}"
cd "$OUTPUT_DIR"
shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"
CHECKSUM=$(cat "${DMG_NAME}.sha256")
cd "$PROJECT_DIR"
echo -e "${GREEN}✅ Checksum: $CHECKSUM${NC}"

# Step 8: Get file size
FILE_SIZE=$(du -h "$DMG_PATH" | cut -f1)

# Step 9: Success summary
echo ""
echo "======================================================================"
echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo "======================================================================"
echo ""
echo -e "${BLUE}📱 Application Details:${NC}"
echo "   Name:     $APP_NAME"
echo "   Version:  $VERSION"
echo "   Build:    $BUILD_NUMBER"
echo ""
echo -e "${BLUE}📦 Distribution Package:${NC}"
echo "   DMG:      $DMG_PATH"
echo "   Size:     $FILE_SIZE"
echo "   Checksum: ${DMG_NAME}.sha256"
echo ""
echo -e "${BLUE}🔐 SHA256:${NC}"
echo "   $CHECKSUM"
echo ""
echo "======================================================================"
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo "======================================================================"
echo ""
echo "This app is signed with ad-hoc signature (not Apple Developer ID)."
echo "Users will need to bypass macOS Gatekeeper to install it."
echo ""
echo -e "${BLUE}Installation instructions for users:${NC}"
echo "1. Download the DMG file"
echo "2. Open DMG and drag app to Applications"
echo "3. Run this command in Terminal:"
echo "   ${GREEN}xattr -cr \"/Applications/$APP_NAME.app\"${NC}"
echo "4. Launch the app normally"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Test the DMG on a clean macOS system"
echo "2. Create a GitHub release"
echo "3. Upload the DMG and checksum file"
echo "4. Include installation instructions (see INSTALL.md)"
echo ""
echo "======================================================================"
echo ""

# Manual verification checkpoint
echo -e "${YELLOW}🔍 Manual Verification Steps:${NC}"
echo ""
echo "Before distributing, please verify:"
echo "[ ] Open the DMG and check it mounts correctly"
echo "[ ] Drag the app to a test location"
echo "[ ] Run: xattr -cr \"/path/to/$APP_NAME.app\""
echo "[ ] Launch the app and verify it works"
echo "[ ] Test Azure CLI integration"
echo "[ ] Test authentication flow"
echo "[ ] Verify all Key Vault operations"
echo ""
echo -e "${GREEN}Press Enter when verification is complete...${NC}"
read -r

echo ""
echo -e "${GREEN}🎉 Ready for distribution!${NC}"
echo ""
