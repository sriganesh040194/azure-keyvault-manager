#!/bin/bash

# Build script for Azure Key Vault Manager - macOS

echo "🚀 Building Azure Key Vault Manager for macOS..."

# Ensure we're in the project directory
cd "$(dirname "$0")/.."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for macOS
echo "🔨 Building macOS application..."
flutter build macos --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully!"
    echo ""
    echo "📱 Your macOS app is located at:"
    echo "   build/macos/Build/Products/Release/Azure Key Vault Manager.app"
    echo ""
    echo "🎉 You can now:"
    echo "   1. Double-click the app to run it"
    echo "   2. Copy it to your Applications folder"
    echo "   3. Distribute it to other macOS users"
    echo ""
    echo "⚠️  Requirements for end users:"
    echo "   • macOS 10.14 or later"
    echo "   • Azure CLI installed (brew install azure-cli)"
    echo "   • Valid Azure subscription with Key Vault access"
else
    echo "❌ Build failed!"
    exit 1
fi