# Azure Key Vault Manager

A secure Flutter web application that provides a user-friendly interface for managing Azure Key Vaults, secrets, keys, and certificates. Built with security best practices and comprehensive Azure CLI integration.

## 🚀 Features

### Core Features

- **CLI Authentication**: Uses your existing Azure CLI credentials - no app registration required
- **Key Vault Management**: Complete CRUD operations for Azure Key Vaults
- **Secrets Management**: Create, view, update, and delete secrets securely
- **Keys Management**: Manage cryptographic keys (coming soon)
- **Certificates Management**: Handle SSL/TLS certificates (coming soon)
- **Audit Logging**: Comprehensive activity tracking and security event logging

### Security Features

- **Input Validation**: Comprehensive validation and sanitization of all user inputs
- **Command Injection Prevention**: Secure Azure CLI command execution with allow-lists
- **Secure Storage**: Encrypted local storage for session information
- **Output Sanitization**: Automatic redaction of sensitive information in logs and UI
- **Session Management**: Automatic session validation and timeout
- **Permission Validation**: Automatic validation of Key Vault access permissions

### UI/UX Features

- **Material Design 3**: Modern, responsive design following Google's latest design system
- **Responsive Layout**: Works seamlessly on desktop, tablet, and mobile browsers
- **Dark/Light Theme**: Automatic theme switching based on system preferences
- **Loading States**: Comprehensive loading indicators for all operations
- **Error Handling**: User-friendly error messages and recovery options
- **Real-time Updates**: Live status updates for long-running operations

## 📥 Installation (macOS Desktop App)

### Quick Install for macOS Users

Azure Key Vault Manager is available as a native macOS application.

⚠️ **Important:** This app is not notarized by Apple (requires $99/year Developer Program). It's completely safe - the code is open source and available for inspection.

**Installation Steps:**

1. **Download** the latest DMG from [Releases](https://github.com/yourusername/azure-keyvault-manager/releases)
2. **Open DMG** and drag app to Applications folder
3. **Bypass Gatekeeper** by running this command:
   ```bash
   xattr -cr "/Applications/Azure Key Vault Manager.app"
   ```
4. **Launch** the app from Applications

**Why this step?** Since we distribute this app free without Apple Developer Program membership, macOS can't verify it automatically. The command above tells macOS to trust the app.

📖 **Detailed installation guide:** See [INSTALL.md](INSTALL.md) for comprehensive instructions, troubleshooting, and security information.

---

## 📋 Prerequisites

Before setting up the application, ensure you have the following installed:

### Required Software

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (version 2.0 or later)
- A modern web browser (Chrome, Firefox, Safari, or Edge)

### Azure Requirements

- Azure subscription with appropriate permissions
- Key Vault Contributor role or higher on target subscriptions/resource groups
- Azure CLI installed and authenticated on your system

## 🛠️ Installation and Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd azure-keyvault-manager
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Set Up Azure CLI

Ensure Azure CLI is installed and authenticated:

```bash
# Install Azure CLI (if not already installed)
# See: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Login to Azure
az login

# Verify your subscription
az account show

# Set default subscription (if needed)
az account set --subscription "Your Subscription Name"
```

### 4. Generate Code (if needed)

If you make changes to models with JSON serialization:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 🚀 Running the Application

### Development Mode

```bash
# Start the development server
flutter run -d chrome --web-port 8080

# Or for hot reload during development
flutter run -d chrome --web-port 8080 --hot
```

### Production Build

```bash
# Build for production
flutter build web

# Serve the built application
cd build/web
python -m http.server 8080  # or use any web server
```

The application will be available at `http://localhost:8080`

## 🧪 Testing

### Run Unit Tests

```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/azure_cli_service_test.dart
flutter test test/input_validator_test.dart

# Run tests with coverage
flutter test --coverage
```

### Run Integration Tests

```bash
# Run integration tests (ensure Azure CLI is set up)
flutter test integration_test/
```

## 📁 Project Structure

```
lib/
├── core/                          # Core functionality
│   ├── auth/                      # Authentication services
│   │   ├── auth_models.dart       # Authentication data models
│   │   ├── auth_service.dart      # OAuth 2.0 implementation
│   │   └── secure_storage_service.dart # Secure token storage
│   ├── logging/                   # Logging and monitoring
│   │   └── app_logger.dart        # Centralized logging
│   ├── networking/                # HTTP and API clients
│   └── security/                  # Security utilities
│       └── input_validator.dart   # Input validation and sanitization
├── features/                      # Feature modules
│   ├── authentication/            # Login/logout screens
│   ├── dashboard/                 # Main dashboard
│   └── keyvault/                  # Key Vault management
├── services/                      # External services
│   └── azure_cli/                 # Azure CLI wrapper
│       └── azure_cli_service.dart # Secure CLI execution
├── shared/                        # Shared utilities
│   ├── constants/                 # App-wide constants
│   ├── utils/                     # Utility functions
│   └── widgets/                   # Reusable UI components
└── main.dart                      # Application entry point

test/                              # Unit and integration tests
docs/                              # Additional documentation
```

## 🔐 Security Considerations

### Authentication Security

- **CLI Integration**: Uses existing Azure CLI authentication - no additional tokens required
- **Session Management**: Automatic session validation and timeout handling
- **Secure Transmission**: All CLI operations use Azure's secure authentication

### Input Security

- **Validation**: All user inputs are validated before processing
- **Sanitization**: Command injection prevention through input sanitization
- **Allow-lists**: Only pre-approved Azure CLI commands are executed

### Data Security

- **Output Redaction**: Sensitive information is automatically redacted from logs and UI
- **Secure Logging**: Security events are logged separately with appropriate detail levels
- **Memory Protection**: Sensitive data is cleared from memory when no longer needed

### Network Security

- **HTTPS Only**: All network communications use HTTPS
- **CORS Protection**: Proper Cross-Origin Resource Sharing configuration
- **Token Validation**: JWT tokens are properly validated and verified

## 🎯 Implemented Azure CLI Commands

The application currently supports the following Azure CLI operations:

### Key Vault Operations

- `az keyvault list` - List Key Vaults
- `az keyvault create` - Create new Key Vault
- `az keyvault delete` - Delete Key Vault
- `az keyvault show` - Get Key Vault details
- `az keyvault update` - Update Key Vault properties

### Secret Operations

- `az keyvault secret list` - List secrets in a Key Vault
- `az keyvault secret show` - Get secret details
- `az keyvault secret set` - Create or update a secret
- `az keyvault secret delete` - Delete a secret

### Key Operations (Coming Soon)

- `az keyvault key list` - List keys
- `az keyvault key create` - Create new key
- `az keyvault key delete` - Delete key

### Certificate Operations (Coming Soon)

- `az keyvault certificate list` - List certificates
- `az keyvault certificate create` - Create certificate
- `az keyvault certificate delete` - Delete certificate

### Access Policy Operations (Coming Soon)

- `az keyvault set-policy` - Set access policies
- `az keyvault delete-policy` - Delete access policies

## 🐛 Troubleshooting

### Common Issues

#### Authentication Issues

- **Problem**: "Azure CLI not authenticated"
- **Solution**: Run `az login` and ensure you're signed in to the correct tenant

#### Permission Issues

- **Problem**: "Insufficient permissions to access Key Vault"
- **Solution**: Ensure your account has Key Vault Contributor role or appropriate access policies

#### CLI Issues

- **Problem**: "Azure CLI not found"
- **Solution**: Install Azure CLI from the official Microsoft documentation
- **Problem**: "Azure CLI command failed"
- **Solution**: Verify Azure CLI is installed and updated to the latest version

### Debug Mode

Enable debug logging by setting the log level in `lib/core/logging/app_logger.dart`:

```dart
static final Logger _logger = Logger(
  level: Level.debug, // Add this line for debug output
  printer: PrettyPrinter(
    // ... existing configuration
  ),
);
```

### Check Application Health

The application includes built-in health checks:

1. **Azure CLI Status**: Dashboard shows if Azure CLI is installed and authenticated
2. **Authentication Status**: Clear indicators for login status and session validity
3. **Permission Checks**: Automatic validation of Key Vault access permissions
4. **Subscription Info**: Display current Azure subscription and tenant information

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Flutter/Dart style guidelines
- Add unit tests for new functionality
- Update documentation for any API changes
- Ensure all security validations are in place
- Test thoroughly with different Azure configurations

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Sriganesh Karuppannan**

Vibe coded with passion for secure Azure Key Vault management. This application combines robust security practices with modern UI/UX design to make Azure Key Vault management accessible and safe.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - The UI framework
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) - Azure command-line interface
- [Material Design](https://material.io/) - Design system
- [Azure Key Vault](https://azure.microsoft.com/en-us/services/key-vault/) - Secure key management service

## 📞 Support

For support and questions:

1. Check the [troubleshooting section](#troubleshooting) above
2. Review [Azure Key Vault documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
3. Check [Flutter web documentation](https://flutter.dev/web)
4. Open an issue in this repository

## 🔄 Version History

- **v1.0.0** - Initial release with core Key Vault and Secrets management
- **v1.1.0** - (Planned) Keys and Certificates management
- **v1.2.0** - (Planned) Advanced RBAC and audit features
- **v2.0.0** - (Planned) Multi-tenant support and enhanced security features
