# Azure Key Vault Manager v0.1.0

## 📥 Installation on macOS

### ⚠️ Important Security Notice

This application is **not signed with an Apple Developer ID** or notarized by Apple. As an open-source project, the app is distributed without Apple code signing.

**The app is completely safe** - all source code is publicly available for inspection on GitHub.

### Quick Installation Steps

1. **Download** the DMG file below (`AzureKeyVaultManager-v0.1.0.dmg`)
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

| File                                                                                                                                                  | Size | SHA256 Checksum |
| ----------------------------------------------------------------------------------------------------------------------------------------------------- | ---- | --------------- |
| [AzureKeyVaultManager-v0.1.0.dmg](https://github.com/sriganesh040194/azure-keyvault-manager/releases/download/v0.1.0/AzureKeyVaultManager-v0.1.0.dmg) | TBD  | `TBD`           |

### Verification (Optional but Recommended)

Verify the downloaded file matches the official release:

```bash
# Download the DMG
# Then verify its checksum
shasum -a 256 ~/Downloads/AzureKeyVaultManager-v0.1.0.dmg

# The output should match: TBD
```

---

## ✨ What's New

### 🎉 Initial Release

This is the first public release of Azure Key Vault Manager - a secure, user-friendly macOS application for managing Azure Key Vaults, secrets, keys, and certificates.

### New Features

- 🔐 **Azure CLI Authentication**: Seamless integration with your existing Azure CLI credentials - no app registration required
- 🗄️ **Key Vault Management**: Complete CRUD operations for Azure Key Vaults (create, list, view, update, delete)
- 🔑 **Secrets Management**: Full lifecycle management for secrets (create, view, update, delete) with secure handling
- 📊 **Activity Dashboard**: Real-time view of recent Key Vault operations and activity tracking
- 🔍 **Key Vault Details**: Comprehensive view of Key Vault properties, permissions, and configurations
- 🎨 **Material Design 3**: Modern, beautiful UI following Google's latest design system
- 🌓 **Dark/Light Mode**: Automatic theme switching based on system preferences
- 📝 **Audit Logging**: Comprehensive activity tracking and security event logging

### Security Features

- 🛡️ **Input Validation**: Multi-layer validation with 15+ validation methods to prevent malicious inputs
- 🚫 **Command Injection Prevention**: Regex-based detection of dangerous patterns and command allow-listing
- 🔒 **Secure Storage**: Multi-platform encrypted storage using macOS Keychain
- 🔍 **Output Sanitization**: Automatic redaction of sensitive data in logs and CLI output
- ⏱️ **Session Management**: Automatic token validation and session timeout handling
- ✅ **Permission Validation**: Automatic validation of Key Vault access permissions before operations

### Platform Support

- ✅ **macOS Native**: Universal binary supporting both Intel and Apple Silicon (M1/M2/M3/M4)
- ✅ **macOS Versions**: Tested on macOS 10.15 (Catalina) through macOS 15 (Sequoia)
- 🌐 **Web Support**: Demo/simulation mode available for web browsers

---

## 🔧 System Requirements

### Required

- **macOS**: 10.15 (Catalina) or later

  - Tested on macOS 11-15 (Big Sur through Sequoia)
  - Works on both Intel and Apple Silicon (M1/M2/M3/M4)

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

- **macOS Sequoia 15.1**: The traditional right-click → Open method doesn't work. Use the `xattr -cr` command instead.
- **First Launch Delay**: Initial launch may take 5-10 seconds while the app initializes and verifies Azure CLI authentication.
- **Keys & Certificates**: Full management features for Keys and Certificates are planned for v0.2.0. Currently, these sections show a "coming soon" notice.

---

## 🔄 Upgrading from Previous Version

This is the first release - no upgrade needed!

---

## 🛠️ Building from Source

If you prefer to build the app yourself:

```bash
# Clone the repository
git clone https://github.com/sriganesh040194/azure-keyvault-manager
cd azure-keyvault-manager

# Checkout this release
git checkout v0.1.0

# Install dependencies
flutter pub get

# Build and package
./scripts/build_macos_release.sh

# The DMG will be in dist/
```

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed development setup.

---

## 📝 Full Changelog

### Added

#### Core Features

- Device code authentication flow using Azure CLI
- Multiple authentication strategies for different environments (production, web, development)
- Secure storage service with multi-platform support (macOS Keychain, SharedPreferences, IndexedDB)
- Platform-aware Azure CLI service with macOS-specific path discovery
- Key Vault management screens (list, create, details, update, delete)
- Secret management screens (list, create, view, update, delete)
- Activity dashboard with real-time Key Vault operation tracking
- Key Vault selector component for easy vault switching

#### Security Implementation

- Input validator with 15+ validation methods
- Command injection prevention with dangerous pattern detection
- Allow-list of 25+ permitted Azure CLI commands
- Output sanitization with automatic sensitive data redaction
- Shell argument escaping for safe CLI parameter passing
- Audit logging service for security events and activity tracking

#### UI/UX Components

- Material Design 3 theme with dark/light mode support
- Responsive layout for desktop, tablet, and mobile
- Loading states and progress indicators for all operations
- Error handling with user-friendly messages
- Web platform compatibility notices
- Custom app bar with subscription and account information
- Navigation drawer with feature sections
- Empty state screens with helpful guidance

#### Development Tools

- Comprehensive unit tests for security components
- Build scripts for macOS release packaging
- Release template and releasing guide
- Apache License 2.0 licensing
- Project documentation (README, CLAUDE.md, INSTALL.md)

### Technical Details

#### Dependencies

- Flutter SDK 3.8.1+
- Material Symbols Icons for modern iconography
- Riverpod for state management
- Flutter Secure Storage for encrypted data persistence
- OAuth2 and JWT decoder for authentication
- Logger for comprehensive logging
- Process execution for Azure CLI integration

#### Architecture

- Feature-based module structure
- Multi-strategy authentication pattern
- Platform-aware CLI service abstraction
- Stream-based authentication state management
- Defensive security design with multiple validation layers

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
- 🐛 [Report a bug](https://github.com/sriganesh040194/azure-keyvault-manager/issues/new?template=bug_report.md)
- 💡 [Request a feature](https://github.com/sriganesh040194/azure-keyvault-manager/issues/new?template=feature_request.md)
- 💬 [Ask a question](https://github.com/sriganesh040194/azure-keyvault-manager/discussions)

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

- **Version**: 0.1.0
- **Build Number**: 1
- **Release Date**: 2025-01-18
- **Platform**: macOS 10.15+
- **Architecture**: Universal (Intel + Apple Silicon)
- **Signing**: Ad-hoc (unsigned by Apple Developer ID)
- **Source Code**: [View on GitHub](https://github.com/sriganesh040194/azure-keyvault-manager/tree/v0.1.0)

---

**Thank you for using Azure Key Vault Manager!** 🎉

If you find this project useful, please consider:

- ⭐ Starring the repository
- 🐛 Reporting issues you encounter
- 💡 Suggesting improvements
- 🤝 Contributing code or documentation
- 📢 Sharing with others who might benefit

---

_This is an open-source project maintained by the community. Not affiliated with Microsoft or Azure._
