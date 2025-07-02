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
```

### Building
```bash
# Build for production
flutter build web

# Analyze code
flutter analyze
```

## Project Architecture

### Core Architecture Principles
- **Security First**: All operations are validated and sanitized
- **Defensive Design**: Multiple layers of security validation
- **Material Design 3**: Modern, responsive UI following Google's design system
- **Modular Structure**: Clean separation of concerns with feature-based organization

### Key Components

#### Authentication Layer (`lib/core/auth/`)
- **AuthService**: Handles Azure AD OAuth 2.0 flow with PKCE
- **SecureStorageService**: Encrypts and stores authentication tokens
- **AuthModels**: Data models for user info and tokens

#### Security Layer (`lib/core/security/`)
- **InputValidator**: Validates and sanitizes all user inputs
- **Command Injection Prevention**: Protects against shell injection attacks
- **Output Sanitization**: Redacts sensitive information from logs/UI

#### Azure CLI Integration (`lib/services/azure_cli/`)
- **AzureCliService**: Secure wrapper for Azure CLI commands
- **Command Allow-listing**: Only approved commands can be executed
- **Process Management**: Handles timeouts and concurrent operations

#### UI Layer (`lib/features/`)
- **Authentication**: Login/logout screens with Azure AD integration
- **Dashboard**: Main navigation and overview
- **KeyVault**: Key Vault management and operations

### State Management
- Uses Riverpod for reactive state management
- Flutter's built-in state management for UI components
- Secure storage for persistent authentication state

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

### Azure AD Setup Required
- Tenant ID and Client ID must be configured in `AppConstants`
- Redirect URI must match: `http://localhost:8080/auth/callback`
- Required permissions: `https://vault.azure.net/user_impersonation`

### Azure CLI Requirements
- Azure CLI must be installed and authenticated
- User must have appropriate Key Vault permissions
- Application validates CLI availability before operations

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