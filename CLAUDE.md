# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Azure Key Vault Manager is a secure Flutter web application that provides a user-friendly interface for managing Azure Key Vaults, secrets, keys, and certificates. The application integrates with Azure AD for authentication and uses Azure CLI for secure operations.

## Common Commands

### Development
```bash
# Install dependencies
flutter pub get

# Generate code (for JSON serialization)
dart run build_runner build --delete-conflicting-outputs

# Run in development mode
flutter run -d chrome --web-port 8080

# Run with hot reload
flutter run -d chrome --web-port 8080 --hot

# Enable Flutter web (if needed)
flutter config --enable-web
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/azure_cli_service_test.dart
flutter test test/input_validator_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests (requires Azure CLI setup)
flutter test integration_test/
```

### Building & Quality
```bash
# Build for production
flutter build web

# Analyze code for issues
flutter analyze

# Check for outdated dependencies
flutter pub outdated

# Update dependencies
flutter pub upgrade --major-versions
```

### macOS Specific (if building for desktop)
```bash
# Build macOS app
chmod +x scripts/build_macos.sh
./scripts/build_macos.sh
```

## Project Architecture

### Core Architecture Principles
- **Security First**: All operations are validated and sanitized
- **Defensive Design**: Multiple layers of security validation
- **Material Design 3**: Modern, responsive UI following Google's design system
- **Modular Structure**: Clean separation of concerns with feature-based organization

### Key Components

#### Authentication Layer (`lib/core/auth/`)
- **Multi-Strategy Authentication**: 6 different authentication services for various scenarios
  - `AuthService`: Primary OAuth 2.0 web authentication with Azure AD
  - `AzureCliAuthService`: Device code authentication flow using Azure CLI
  - `CliAuthService`: Interactive Azure CLI authentication (desktop)
  - `SimpleWebAuthService`: Basic web demo authentication (testing)
  - `WebCliAuthService`: Web-compatible CLI simulation
- **SecureStorageService**: Multi-platform encrypted storage (Keychain/SharedPreferences/IndexedDB)
- **AuthModels**: Comprehensive data models for user info, tokens, and Azure AD config

#### Security Layer (`lib/core/security/`)
- **InputValidator**: Multi-layer validation with 15+ validation methods
- **Command Injection Prevention**: Regex-based dangerous pattern detection
- **Output Sanitization**: Automatic redaction of sensitive CLI output
- **Shell Argument Escaping**: Safe parameter passing to CLI commands

#### Azure CLI Integration (`lib/services/azure_cli/`)
- **Platform-Aware Architecture**: Separate implementations for different platforms
  - `AzureCliService`: Core service for Windows/Linux
  - `MacOSAzureCliService`: macOS-specific implementation with path discovery
  - `PlatformAzureCliService`: Unified factory and abstraction layer
- **Command Allow-listing**: Strict whitelist of 25+ permitted Azure CLI commands
- **Process Management**: Concurrent operation limiting (max 5), timeout handling (300s)
- **Security Integration**: Deep integration with authentication and validation layers

#### UI Layer (`lib/features/`)
- **Authentication**: Multiple login screens supporting different auth strategies
- **Dashboard**: Feature-specific dashboards (production, web, simple web)
- **KeyVault**: Complete Key Vault management with create, list, and detail screens
- **Platform**: Web-specific platform compatibility notices

### State Management
- **Riverpod**: Primary state management for reactive data flows
- **Stream-based Architecture**: Real-time authentication state updates
- **Secure Persistence**: Encrypted storage for authentication state across sessions

## Security Considerations

### Critical Security Features
1. **Input Validation**: All inputs validated before processing
2. **Command Injection Prevention**: Azure CLI commands are strictly validated
3. **Output Sanitization**: Sensitive data automatically redacted
4. **Secure Storage**: Tokens encrypted with Flutter Secure Storage
5. **Session Management**: Automatic token refresh and timeout handling

### Security Validation Patterns
- Always validate resource names: `InputValidator.validateResourceName()`
- Escape shell arguments: `InputValidator.escapeShellArgument()`
- Check command permissions: Only allow-listed Azure CLI commands
- Sanitize outputs: `InputValidator.sanitizeOutput()`

### Never Do
- Execute arbitrary shell commands
- Store secrets in plain text
- Skip input validation
- Log sensitive information without redaction
- Allow direct user input to command execution

## Development Guidelines

### Code Organization
- Follow feature-based module structure
- Keep security concerns in `core/security/`
- Separate UI components by feature
- Use shared utilities in `shared/`

### Adding New Features
1. Create feature module in `lib/features/`
2. Add any new Azure CLI commands to allow-list in `AppConstants`
3. Implement input validation for all user inputs
4. Add comprehensive error handling
5. Write unit tests for security-critical components

### Security Testing
- Always test input validation with malicious inputs
- Verify command injection prevention
- Test authentication flows thoroughly
- Validate output sanitization

### Dependencies Management
- Keep dependencies updated for security patches
- Prefer well-maintained packages with good security records
- Avoid packages that require extensive permissions

## Key Files and Their Purposes

### Security-Critical Files
- `lib/core/security/input_validator.dart` - Input validation and sanitization
- `lib/services/azure_cli/azure_cli_service.dart` - Secure CLI execution
- `lib/core/auth/auth_service.dart` - Authentication handling
- `lib/shared/constants/app_constants.dart` - Configuration and allow-lists

### UI Components
- `lib/shared/widgets/app_theme.dart` - Material Design 3 theme
- `lib/features/dashboard/dashboard_screen.dart` - Main application layout
- `lib/features/keyvault/` - Key Vault management screens

### Testing
- `test/azure_cli_service_test.dart` - Tests for CLI service security
- `test/input_validator_test.dart` - Tests for input validation

## Configuration Requirements

### Azure CLI Requirements (Primary)
- Azure CLI must be installed and authenticated (`az login`)
- User must have Key Vault Contributor role or appropriate permissions
- Application validates CLI availability and authentication before operations
- Supports multiple installation paths (especially on macOS via Homebrew)

### Azure AD Setup (Optional - for OAuth flows)
- Tenant ID and Client ID must be configured in `AppConstants`
- Redirect URI must match: `http://localhost:8080/auth/callback`
- Required permissions: `https://vault.azure.net/user_impersonation`
- Only needed for web-based OAuth authentication flows

### Platform-Specific Configuration
- **Web**: Limited to demo/simulation modes - full CLI functionality disabled
- **macOS**: Automatic path discovery for CLI installations
- **Windows/Linux**: Standard CLI integration with process management

## Common Issues and Solutions

### Authentication Issues
- Ensure Azure AD app registration is correctly configured
- Verify redirect URI matches exactly
- Check that required permissions are granted

### CLI Issues
- Verify Azure CLI is installed: `az --version`
- Ensure authenticated: `az account show`
- Check permissions on target Key Vaults

### Build Issues
- Run `flutter pub get` if dependencies are missing
- Use `dart run build_runner build --delete-conflicting-outputs` for JSON models
- Ensure Flutter web is enabled: `flutter config --enable-web`

## Security Best Practices for Contributors

1. **Always Validate Input**: Use `InputValidator` for all user inputs
2. **Never Skip Security Checks**: Don't bypass command validation
3. **Log Security Events**: Use `AppLogger.securityEvent()` for security-related events
4. **Test Security Features**: Write tests for all security-critical functionality
5. **Follow Principle of Least Privilege**: Only request necessary permissions
6. **Sanitize Outputs**: Always use `sanitizeOutput()` for displaying CLI results

## Performance Considerations

- Use lazy loading for large lists
- Implement pagination for Key Vault/secret lists
- Cache authentication tokens appropriately
- Limit concurrent CLI operations (max 5 by default)
- Use debouncing for search operations
- CLI command timeout set to 300 seconds (5 minutes)

## Understanding the Multi-Authentication Architecture

This application uses a **strategy pattern** for authentication to support different environments and use cases:

### Authentication Strategy Selection
- **Production Desktop**: Uses `AzureCliAuthService` (device code flow)
- **Development/Demo**: Uses `SimpleWebAuthService` or `WebCliAuthService`  
- **Web Production**: Limited to simulation modes (no real CLI access)
- **OAuth Testing**: Uses `AuthService` for full Azure AD integration

### Key Architectural Decisions
- **Security-First**: Every command validated through multiple layers
- **Platform-Aware**: Different CLI implementations per platform
- **Defensive**: Web platforms blocked from executing actual CLI commands
- **Concurrent**: Multiple CLI operations managed with process tracking
- **Reactive**: Stream-based authentication state for real-time UI updates

### CLI Command Flow
1. **Input Validation**: `InputValidator.validateCommand()`
2. **Allow-list Check**: Command verified against `AppConstants.allowedAzCommands`
3. **Platform Selection**: Appropriate CLI service chosen automatically
4. **Process Execution**: Managed execution with timeout and error handling
5. **Output Sanitization**: `InputValidator.sanitizeOutput()` removes sensitive data