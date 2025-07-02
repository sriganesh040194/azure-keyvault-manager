import 'dart:convert';

class InputValidator {
  // Command injection patterns to detect and prevent
  static final List<RegExp> _dangerousPatterns = [
    RegExp(r'[;&|`$(){}[\]<>]'),  // Shell metacharacters
    RegExp(r'\\[rnt]'),           // Escape sequences
    RegExp(r'\.\./'),             // Path traversal
    RegExp(r'--\w*=.*[;&|`]'),    // Parameter injection
    RegExp(r'^\s*sudo\s'),        // Sudo commands
    RegExp(r'^\s*rm\s'),          // Delete commands
    RegExp(r'^\s*chmod\s'),       // Permission changes
    RegExp(r'^\s*chown\s'),       // Ownership changes
  ];

  // Allowed characters for different input types
  static final RegExp _azureResourceNamePattern = RegExp(r'^[a-zA-Z0-9-_]+$');
  static final RegExp _subscriptionIdPattern = RegExp(r'^[0-9a-fA-F-]{36}$');
  static final RegExp _resourceGroupPattern = RegExp(r'^[a-zA-Z0-9-_().]+$');

  /// Validates and sanitizes Azure CLI command parameters
  static String? validateCommand(String command) {
    if (command.isEmpty) {
      return 'Command cannot be empty';
    }

    // Check for dangerous patterns
    for (final pattern in _dangerousPatterns) {
      if (pattern.hasMatch(command)) {
        return 'Command contains potentially dangerous characters';
      }
    }

    // Ensure command starts with 'az'
    if (!command.trim().startsWith('az ')) {
      return 'Only Azure CLI commands are allowed';
    }

    return null; // Valid command
  }

  /// Validates Azure resource names
  static String? validateResourceName(String name) {
    if (name.isEmpty) {
      return 'Resource name cannot be empty';
    }

    if (name.length < 3 || name.length > 24) {
      return 'Resource name must be between 3 and 24 characters';
    }

    if (!_azureResourceNamePattern.hasMatch(name)) {
      return 'Resource name can only contain letters, numbers, hyphens, and underscores';
    }

    if (name.startsWith('-') || name.endsWith('-')) {
      return 'Resource name cannot start or end with a hyphen';
    }

    return null;
  }

  /// Validates Azure subscription ID
  static String? validateSubscriptionId(String subscriptionId) {
    if (subscriptionId.isEmpty) {
      return 'Subscription ID cannot be empty';
    }

    if (!_subscriptionIdPattern.hasMatch(subscriptionId)) {
      return 'Invalid subscription ID format';
    }

    return null;
  }

  /// Validates resource group name
  static String? validateResourceGroup(String resourceGroup) {
    if (resourceGroup.isEmpty) {
      return 'Resource group cannot be empty';
    }

    if (resourceGroup.length > 90) {
      return 'Resource group name cannot exceed 90 characters';
    }

    if (!_resourceGroupPattern.hasMatch(resourceGroup)) {
      return 'Resource group name contains invalid characters';
    }

    if (resourceGroup.endsWith('.')) {
      return 'Resource group name cannot end with a period';
    }

    return null;
  }

  /// Validates JSON input
  static String? validateJson(String jsonString) {
    if (jsonString.isEmpty) {
      return 'JSON cannot be empty';
    }

    try {
      json.decode(jsonString);
      return null; // Valid JSON
    } catch (e) {
      return 'Invalid JSON format: $e';
    }
  }

  /// Sanitizes command output for display
  static String sanitizeOutput(String output) {
    // Remove potentially sensitive information from output
    return output
        .replaceAll(RegExp(r'"value":\s*"[^"]*"'), '"value": "[REDACTED]"')
        .replaceAll(RegExp(r'"password":\s*"[^"]*"'), '"password": "[REDACTED]"')
        .replaceAll(RegExp(r'"connectionString":\s*"[^"]*"'), '"connectionString": "[REDACTED]"')
        .replaceAll(RegExp(r'"key":\s*"[^"]*"'), '"key": "[REDACTED]"')
        .replaceAll(RegExp(r'"secret":\s*"[^"]*"'), '"secret": "[REDACTED]"');
  }

  /// Escapes shell arguments
  static String escapeShellArgument(String argument) {
    // Escape special characters for shell safety
    return "'${argument.replaceAll("'", "'\"'\"'")}'";
  }

  /// Validates email format
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email cannot be empty';
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }

    return null;
  }

  /// Validates URL format
  static String? validateUrl(String url) {
    if (url.isEmpty) {
      return 'URL cannot be empty';
    }

    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'Invalid URL format';
      }
      return null;
    } catch (e) {
      return 'Invalid URL format';
    }
  }

  /// Validates Key Vault name
  static String? validateKeyVaultName(String name) {
    if (name.isEmpty) {
      return 'Key Vault name cannot be empty';
    }

    if (name.length < 3 || name.length > 24) {
      return 'Key Vault name must be between 3 and 24 characters';
    }

    final keyVaultPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$');
    if (!keyVaultPattern.hasMatch(name)) {
      return 'Key Vault name must start with a letter, end with a letter or number, and contain only letters, numbers, and hyphens';
    }

    return null;
  }

  /// Validates secret name
  static String? validateSecretName(String name) {
    if (name.isEmpty) {
      return 'Secret name cannot be empty';
    }

    if (name.length > 127) {
      return 'Secret name cannot exceed 127 characters';
    }

    final secretPattern = RegExp(r'^[a-zA-Z0-9-]+$');
    if (!secretPattern.hasMatch(name)) {
      return 'Secret name can only contain letters, numbers, and hyphens';
    }

    return null;
  }

  /// Validates resource group name
  static String? validateResourceGroupName(String name) {
    if (name.isEmpty) {
      return 'Resource group name cannot be empty';
    }

    if (name.length > 90) {
      return 'Resource group name cannot exceed 90 characters';
    }

    final rgPattern = RegExp(r'^[a-zA-Z0-9-_().]+$');
    if (!rgPattern.hasMatch(name)) {
      return 'Resource group name contains invalid characters';
    }

    if (name.endsWith('.')) {
      return 'Resource group name cannot end with a period';
    }

    return null;
  }
}