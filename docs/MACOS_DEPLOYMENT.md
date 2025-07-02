# macOS Deployment Guide

This guide covers how to build, deploy, and distribute the Azure Key Vault Manager for macOS.

## Prerequisites

### Development Environment
- macOS 10.14 or later
- Flutter SDK with macOS support enabled
- Xcode (latest stable version)
- CocoaPods (`sudo gem install cocoapods`)

### End User Requirements
- macOS 10.14 or later
- Azure CLI installed
- Valid Azure subscription with Key Vault access

## Building for macOS

### Quick Build
```bash
# Run the automated build script
./scripts/build_macos.sh
```

### Manual Build
```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build for macOS
flutter build macos --release
```

The built application will be located at:
```
build/macos/Build/Products/Release/Azure Key Vault Manager.app
```

## Installation and Setup

### 1. Install Azure CLI
Users need Azure CLI installed on their macOS system:

```bash
# Using Homebrew (recommended)
brew install azure-cli

# Or download from Microsoft
# Visit: https://aka.ms/installazureclimac
```

### 2. Authenticate with Azure
```bash
# Login to Azure
az login

# Verify authentication
az account show

# List available Key Vaults (to test permissions)
az keyvault list
```

### 3. Install the Application
- Copy `Azure Key Vault Manager.app` to `/Applications/`
- Or run directly from the build location

## App Store Distribution

### Code Signing
For App Store distribution, you'll need:

1. **Apple Developer Account** ($99/year)
2. **App Store certificates** configured in Xcode
3. **App Store provisioning profile**

### Prepare for App Store
```bash
# Build with App Store configuration
flutter build macos --release --build-name=1.0.0 --build-number=1
```

### App Store Connect Setup
1. Create new app in App Store Connect
2. Configure app metadata:
   - **Name**: Azure Key Vault Manager
   - **Category**: Developer Tools
   - **Description**: Secure Azure Key Vault management interface

### Entitlements Review
The app uses these entitlements:
- `com.apple.security.network.client` - For Azure API communication
- `com.apple.security.files.user-selected.read-write` - For file operations
- `com.apple.security.app-sandbox` - Required for App Store

## Direct Distribution (Outside App Store)

### Code Signing for Direct Distribution
```bash
# Sign the application
codesign --force --deep --sign "Developer ID Application: Your Name" \
  "build/macos/Build/Products/Release/Azure Key Vault Manager.app"

# Verify signing
codesign --verify --verbose \
  "build/macos/Build/Products/Release/Azure Key Vault Manager.app"
```

### Notarization (macOS 10.14.5+)
For distribution outside the App Store:

```bash
# Create DMG for distribution
hdiutil create -volname "Azure Key Vault Manager" -srcfolder \
  "build/macos/Build/Products/Release/Azure Key Vault Manager.app" \
  -ov -format UDZO "Azure Key Vault Manager.dmg"

# Notarize with Apple
xcrun notarytool submit "Azure Key Vault Manager.dmg" \
  --apple-id "your-apple-id@example.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID"
```

## Platform-Specific Features

### macOS Integration
- **Native window management**
- **macOS-style menus** (File, Edit, Window, Help)
- **Dock integration** with app icon
- **Spotlight search** integration
- **Quick Look** support for exported data

### Security Features
- **Keychain integration** for secure credential storage
- **Gatekeeper compatibility** for safe app launching
- **Sandboxed execution** for enhanced security
- **Privacy-first design** with minimal permissions

### Performance Optimizations
- **Native ARM64 support** for Apple Silicon Macs
- **Intel compatibility** for older Macs
- **Optimized for macOS Monterey+** features

## Troubleshooting

### Common Issues

#### "App is damaged and can't be opened"
```bash
# Remove quarantine attribute
xattr -dr com.apple.quarantine "Azure Key Vault Manager.app"
```

#### Azure CLI Not Found
Users should install Azure CLI:
```bash
# Check if Azure CLI is installed
which az

# Install if missing
brew install azure-cli
```

#### Permission Denied Errors
```bash
# Verify Azure CLI authentication
az account show

# Check Key Vault permissions
az keyvault list

# Re-authenticate if needed
az login --use-device-code
```

### Debug Mode
For development and testing:
```bash
# Run in debug mode
flutter run -d macos

# With verbose logging
flutter run -d macos --verbose
```

## File Structure

```
macos/
├── Runner/
│   ├── Info.plist              # App metadata and permissions
│   ├── DebugProfile.entitlements   # Debug entitlements
│   ├── Release.entitlements        # Release entitlements
│   └── Assets.xcassets/            # App icons
├── Runner.xcodeproj/           # Xcode project
└── Flutter/                    # Flutter macOS framework
```

## Best Practices

### Security
- **Minimal permissions** - Only request necessary entitlements
- **Secure storage** - Use Keychain for sensitive data
- **Input validation** - Validate all Azure CLI commands
- **Network security** - Use HTTPS for all API calls

### User Experience
- **Native feel** - Follow macOS Human Interface Guidelines
- **Responsive UI** - Optimize for different screen sizes
- **Error handling** - Provide clear, actionable error messages
- **Accessibility** - Support VoiceOver and keyboard navigation

### Performance
- **Lazy loading** - Load Key Vault data on demand
- **Background tasks** - Use async operations for CLI commands
- **Memory management** - Dispose resources properly
- **Startup time** - Minimize app launch time

## Support

For issues specific to macOS deployment:

1. **Check logs**: `Console.app` → "Azure Key Vault Manager"
2. **Verify setup**: Ensure Azure CLI is properly installed
3. **Test CLI**: Run `az keyvault list` in Terminal
4. **Report bugs**: Include macOS version and error logs

## Resources

- [Flutter macOS Desktop](https://docs.flutter.dev/platform-integration/macos/building)
- [macOS App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Code Signing Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)