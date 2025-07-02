import 'dart:io';
import 'package:flutter/foundation.dart';
import 'azure_cli_service.dart';
import 'macos_azure_cli_service.dart';

/// Platform-aware Azure CLI service factory
class PlatformAzureCliService {
  static dynamic create() {
    if (kIsWeb) {
      // Web platform - return the standard service which will show web errors
      return AzureCliService();
    } else if (Platform.isMacOS) {
      // macOS platform - return macOS-specific service
      return MacOSAzureCliService();
    } else {
      // Other platforms (Windows, Linux) - return standard service
      return AzureCliService();
    }
  }
}

/// Unified result class that works with all platform services
class UnifiedAzureCliResult {
  final bool success;
  final String output;
  final String? error;
  final int exitCode;
  final Duration executionTime;

  const UnifiedAzureCliResult({
    required this.success,
    required this.output,
    this.error,
    required this.exitCode,
    required this.executionTime,
  });

  /// Creates from standard AzureCliResult
  factory UnifiedAzureCliResult.fromStandard(AzureCliResult result) {
    return UnifiedAzureCliResult(
      success: result.success,
      output: result.output,
      error: result.error,
      exitCode: result.exitCode,
      executionTime: result.executionTime,
    );
  }

  /// Creates from macOS AzureCliResult
  factory UnifiedAzureCliResult.fromMacOS(MacOSAzureCliResult result) {
    return UnifiedAzureCliResult(
      success: result.success,
      output: result.output,
      error: result.error,
      exitCode: result.exitCode,
      executionTime: result.executionTime,
    );
  }
}

/// Unified interface for Azure CLI operations across platforms
class UnifiedAzureCliService {
  final dynamic _service;

  UnifiedAzureCliService() : _service = PlatformAzureCliService.create();

  /// Executes an Azure CLI command with platform-specific handling
  Future<UnifiedAzureCliResult> executeCommand(
    String command, {
    Map<String, String>? environment,
    String? workingDirectory,
    Duration? timeout,
  }) async {
    final result = await _service.executeCommand(
      command,
      environment: environment,
      workingDirectory: workingDirectory,
      timeout: timeout,
    );

    if (!kIsWeb && Platform.isMacOS && _service is MacOSAzureCliService) {
      return UnifiedAzureCliResult.fromMacOS(result);
    } else {
      return UnifiedAzureCliResult.fromStandard(result);
    }
  }

  /// Checks if Azure CLI is available on this platform
  Future<bool> isAzureCliAvailable() async {
    if (!kIsWeb && _service is MacOSAzureCliService) {
      return await (_service as MacOSAzureCliService).isAzureCliAvailable();
    } else if (_service is AzureCliService) {
      // For standard service, try a simple version check
      final result = await executeCommand('az --version');
      return result.success;
    }
    return false;
  }

  /// Gets Azure CLI version information
  Future<String?> getVersion() async {
    if (!kIsWeb && _service is MacOSAzureCliService) {
      return await (_service as MacOSAzureCliService).getVersion();
    } else {
      final result = await executeCommand('az --version');
      if (result.success) {
        final lines = result.output.split('\n');
        for (final line in lines) {
          if (line.startsWith('azure-cli')) {
            return line.trim();
          }
        }
      }
      return null;
    }
  }

  /// Checks if user is logged in to Azure CLI
  Future<bool> isLoggedIn() async {
    if (!kIsWeb && _service is MacOSAzureCliService) {
      return await (_service as MacOSAzureCliService).isLoggedIn();
    } else {
      final result = await executeCommand('az account show');
      return result.success;
    }
  }
}