# Azure Key Vault Manager v{VERSION}

<!--
  Release Template for Azure Key Vault Manager

  Instructions:
  1. Replace {VERSION} with the actual version (e.g., 1.0.0)
  2. Replace {BUILD_NUMBER} with the build number (e.g., 1)
  3. Replace {SHA256_HASH} with the actual SHA256 checksum
  4. Update the "What's New" section with actual changes
  5. Update the "Bug Fixes" section if applicable
  6. Remove any sections that don't apply to this release
-->

## 📥 Installation on macOS

### ⚠️ Important Security Notice

This application is **not signed with an Apple Developer ID** or notarized by Apple. As an open-source project, the app is distributed without Apple code signing.

**The app is completely safe** - all source code is publicly available for inspection on GitHub.

### Quick Installation Steps

1. **Download** the DMG file below (`AzureKeyVaultManager-v{VERSION}.dmg`)
2. **Open the DMG** and drag "Azure Key Vault Manager" to your Applications folder
3. **Bypass macOS Gatekeeper** by opening Terminal and running:
   ```bash
   xattr -cr "/Applications/Azure Key Vault Manager.app"
   ```
4. **Launch** the app from your Applications folder

### Why Do I Need to Bypass Gatekeeper?

macOS blocks apps that aren't notarized by Apple. The command above is safe and simply tells macOS to trust this app.

📖 **Need help?** See the detailed [Installation Guide](../INSTALL.md) for troubleshooting and more information.

---

## 📦 Download

### Main Application

| File | Size | SHA256 Checksum |
|------|------|-----------------|
| [AzureKeyVaultManager-v{VERSION}.dmg](https://github.com/yourusername/keyvault-ui/releases/download/v{VERSION}/AzureKeyVaultManager-v{VERSION}.dmg) | {FILE_SIZE} | `{SHA256_HASH}` |

### Verification (Optional but Recommended)

Verify the downloaded file matches the official release:

```bash
# Download the DMG
# Then verify its checksum
shasum -a 256 ~/Downloads/AzureKeyVaultManager-v{VERSION}.dmg

# The output should match: {SHA256_HASH}
```

---

## ✨ What's New

### New Features

- 🎉 **[Feature Name]**: Brief description of the new feature
- 🆕 **[Another Feature]**: What it does and why it's useful
- ✨ **[Enhancement]**: Improvement to existing functionality

### Improvements

- 🚀 **Performance**: Describe any performance improvements
- 💡 **UI/UX**: User interface enhancements
- 🔐 **Security**: Security-related improvements

### Bug Fixes

- 🐛 Fixed issue where [describe the bug]
- 🔧 Resolved problem with [describe the problem]
- ✅ Corrected [describe the correction]

---

## 🔧 System Requirements

### Required

- **macOS**: 10.15 (Catalina) or later
  - Tested on macOS 11-15 (Big Sur through Sequoia)
  - Works on both Intel and Apple Silicon (M1/M2/M3)

- **Azure CLI**: Version 2.0 or later
  ```bash
  # Install via Homebrew
  brew install azure-cli

  # Or download from Microsoft
  # https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos
  ```

- **Azure Subscription**: With appropriate Key Vault permissions
  - Key Vault Contributor role or higher
  - Valid Azure AD credentials

### Recommended

- macOS 13 (Ventura) or later for best experience
- 8GB RAM minimum, 16GB recommended
- Active internet connection for Azure API communication

---

## 🚀 First-Time Setup

After installation:

1. **Ensure Azure CLI is installed**:
   ```bash
   az --version
   ```

2. **Login to Azure**:
   ```bash
   az login
   ```

3. **Verify your subscription**:
   ```bash
   az account show
   ```

4. **Launch Azure Key Vault Manager** from Applications

5. The app will automatically detect your Azure CLI authentication

---

## 📋 Known Issues

<!-- List any known issues or limitations in this release -->

- **macOS Sequoia 15.1**: The traditional right-click → Open method doesn't work. Use the `xattr -cr` command instead.
- **{Issue Description}**: {Workaround or expected fix version}

---

## 🔄 Upgrading from Previous Version

If you're upgrading from a previous version:

1. **Download** the new DMG
2. **Replace** the old app in Applications with the new one
3. **Run the Gatekeeper bypass command again**:
   ```bash
   xattr -cr "/Applications/Azure Key Vault Manager.app"
   ```
4. **Launch** the updated app

Your settings and authentication will be preserved.

---

## 🛠️ Building from Source

If you prefer to build the app yourself:

```bash
# Clone the repository
git clone https://github.com/yourusername/keyvault-ui
cd keyvault-ui

# Checkout this release
git checkout v{VERSION}

# Install dependencies
flutter pub get

# Build and package
./scripts/build_macos_release.sh

# The DMG will be in dist/
```

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed development setup.

---

## 📝 Full Changelog

<!-- Detailed changelog for developers and contributors -->

### Added
- Feature 1 with implementation details
- Feature 2 with implementation details
- New dependency: `package_name@version`

### Changed
- Modified behavior of X to Y
- Updated dependency: `package_name` from vX to vY
- Refactored component Z for better performance

### Fixed
- Issue #123: Description of the fix
- Issue #456: Another fix description

### Deprecated
- Feature or API that will be removed in future versions

### Removed
- Deprecated feature X (deprecated since v{PREVIOUS_VERSION})

### Security
- Security fix for [describe the security issue if publicly disclosed]
- Updated dependency to patch CVE-YYYY-XXXXX

---

## 🔐 Security

### Permissions Required

This app requires the following macOS permissions:

- ✅ **Network Access**: To communicate with Azure APIs
- ✅ **File Access**: Only for user-selected files (import/export)
- ✅ **Azure CLI Execution**: To run allow-listed Azure CLI commands

### What This App Does NOT Access

- ❌ Microphone or Camera
- ❌ Location Services
- ❌ Contacts or Calendar
- ❌ Background execution
- ❌ Analytics or tracking

### Security Features

- 🔐 Input validation for all user inputs
- 🔐 Command injection prevention
- 🔐 Output sanitization (sensitive data redacted)
- 🔐 Secure storage using macOS Keychain
- 🔐 Allow-list for Azure CLI commands

For more information, see [SECURITY.md](../SECURITY.md).

---

## 🆘 Troubleshooting

### Common Issues

#### "App is damaged and can't be opened"

This is a false positive from macOS Gatekeeper. Solution:

```bash
xattr -cr "/Applications/Azure Key Vault Manager.app"
```

#### "Azure CLI not found"

Install Azure CLI:

```bash
brew install azure-cli
```

#### "Azure CLI not authenticated"

Login to Azure:

```bash
az login
```

#### Other Issues

See the comprehensive [Installation Guide](../INSTALL.md) for more troubleshooting help.

---

## 💬 Feedback and Support

### Getting Help

- 📖 Check the [Installation Guide](../INSTALL.md)
- 🐛 [Report a bug](https://github.com/yourusername/keyvault-ui/issues/new?template=bug_report.md)
- 💡 [Request a feature](https://github.com/yourusername/keyvault-ui/issues/new?template=feature_request.md)
- 💬 [Ask a question](https://github.com/yourusername/keyvault-ui/discussions)

### Contributing

We welcome contributions! See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

## 📄 License

Azure Key Vault Manager is licensed under the Apache License 2.0.

See [LICENSE](../LICENSE) for the full license text.

---

## 🙏 Acknowledgments

Built with:
- [Flutter](https://flutter.dev/) - UI framework
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) - Azure command-line interface
- [Material Design 3](https://m3.material.io/) - Design system

---

## 📊 Release Information

- **Version**: {VERSION}
- **Build Number**: {BUILD_NUMBER}
- **Release Date**: {RELEASE_DATE}
- **Platform**: macOS 10.15+
- **Architecture**: Universal (Intel + Apple Silicon)
- **Signing**: Ad-hoc (unsigned by Apple Developer ID)
- **Source Code**: [View on GitHub](https://github.com/yourusername/keyvault-ui/tree/v{VERSION})

---

**Thank you for using Azure Key Vault Manager!** 🎉

If you find this project useful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting issues you encounter
- 💡 Suggesting improvements
- 🤝 Contributing code or documentation
- 📢 Sharing with others who might benefit

---

*This is an open-source project maintained by the community. Not affiliated with Microsoft or Azure.*
