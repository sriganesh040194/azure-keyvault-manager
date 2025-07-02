import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:process/process.dart';
import '../../core/logging/app_logger.dart';
import '../../core/security/input_validator.dart';
import '../../shared/constants/app_constants.dart';

class AzureCliResult {
  final bool success;
  final String output;
  final String error;
  final int exitCode;
  final Duration executionTime;

  AzureCliResult({
    required this.success,
    required this.output,
    required this.error,
    required this.exitCode,
    required this.executionTime,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'output': output,
    'error': error,
    'exitCode': exitCode,
    'executionTimeMs': executionTime.inMilliseconds,
  };
}

class AzureCliService {
  final ProcessManager _processManager;
  final Map<String, Completer<AzureCliResult>> _runningCommands = {};
  
  AzureCliService({ProcessManager? processManager})
      : _processManager = processManager ?? const LocalProcessManager();

  /// Executes an Azure CLI command with security validation
  Future<AzureCliResult> executeCommand(
    String command, {
    Map<String, String>? environment,
    String? workingDirectory,
    Duration? timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Check if running on web platform
      if (kIsWeb) {
        AppLogger.warning('Azure CLI commands cannot be executed in web environment');
        return AzureCliResult(
          success: false,
          output: '',
          error: 'Azure CLI commands are not supported in web browsers. Please run this application on a desktop platform (Windows, macOS, or Linux) with Azure CLI installed.',
          exitCode: -1,
          executionTime: stopwatch.elapsed,
        );
      }
      // Validate the command
      final validationError = InputValidator.validateCommand(command);
      if (validationError != null) {
        AppLogger.securityEvent('Command validation failed', {
          'command': command,
          'error': validationError,
        });
        return AzureCliResult(
          success: false,
          output: '',
          error: 'Security validation failed: $validationError',
          exitCode: -1,
          executionTime: stopwatch.elapsed,
        );
      }

      // Check if command is in allowed list
      if (!_isCommandAllowed(command)) {
        AppLogger.securityEvent('Unauthorized command attempted', {
          'command': command,
        });
        return AzureCliResult(
          success: false,
          output: '',
          error: 'Command not in allowed list',
          exitCode: -1,
          executionTime: stopwatch.elapsed,
        );
      }

      // Check for concurrent command limit
      if (_runningCommands.length >= AppConstants.maxConcurrentOperations) {
        return AzureCliResult(
          success: false,
          output: '',
          error: 'Maximum concurrent operations limit reached',
          exitCode: -1,
          executionTime: stopwatch.elapsed,
        );
      }

      // Generate unique command ID for tracking
      final commandId = DateTime.now().millisecondsSinceEpoch.toString();
      final completer = Completer<AzureCliResult>();
      _runningCommands[commandId] = completer;

      AppLogger.info('Executing Azure CLI command: $command');

      try {
        // Parse command into parts
        final commandParts = _parseCommand(command);
        
        // Set up environment
        final processEnvironment = <String, String>{
          ...Platform.environment,
          if (environment != null) ...environment,
        };

        // Execute the process
        final process = await _processManager.start(
          commandParts,
          environment: processEnvironment,
          workingDirectory: workingDirectory,
        );

        // Set up timeout
        final timeoutDuration = timeout ?? const Duration(seconds: AppConstants.cliTimeoutSeconds);
        final timeoutTimer = Timer(timeoutDuration, () {
          if (!completer.isCompleted) {
            process.kill();
            completer.complete(AzureCliResult(
              success: false,
              output: '',
              error: 'Command timed out after ${timeoutDuration.inSeconds} seconds',
              exitCode: -1,
              executionTime: stopwatch.elapsed,
            ));
          }
        });

        // Collect output
        final stdout = <int>[];
        final stderr = <int>[];

        process.stdout.listen(stdout.addAll);
        process.stderr.listen(stderr.addAll);

        final exitCode = await process.exitCode;
        timeoutTimer.cancel();

        final outputString = utf8.decode(stdout);
        final errorString = utf8.decode(stderr);

        final result = AzureCliResult(
          success: exitCode == 0,
          output: InputValidator.sanitizeOutput(outputString),
          error: errorString,
          exitCode: exitCode,
          executionTime: stopwatch.elapsed,
        );

        AppLogger.cliCommand(command, outputString);
        
        if (!completer.isCompleted) {
          completer.complete(result);
        }
        
        return result;
      } finally {
        _runningCommands.remove(commandId);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error executing Azure CLI command', e, stackTrace);
      return AzureCliResult(
        success: false,
        output: '',
        error: 'Execution error: $e',
        exitCode: -1,
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Lists all Key Vaults in the subscription
  Future<AzureCliResult> listKeyVaults({String? resourceGroup}) async {
    String command = 'az keyvault list --output json';
    if (resourceGroup != null) {
      final validation = InputValidator.validateResourceGroup(resourceGroup);
      if (validation != null) {
        throw ArgumentError('Invalid resource group: $validation');
      }
      command += ' --resource-group ${InputValidator.escapeShellArgument(resourceGroup)}';
    }
    return executeCommand(command);
  }

  /// Creates a new Key Vault
  Future<AzureCliResult> createKeyVault({
    required String name,
    required String resourceGroup,
    required String location,
    Map<String, String>? tags,
  }) async {
    // Validate inputs
    final nameValidation = InputValidator.validateResourceName(name);
    if (nameValidation != null) {
      throw ArgumentError('Invalid Key Vault name: $nameValidation');
    }

    final rgValidation = InputValidator.validateResourceGroup(resourceGroup);
    if (rgValidation != null) {
      throw ArgumentError('Invalid resource group: $rgValidation');
    }

    String command = 'az keyvault create'
        ' --name ${InputValidator.escapeShellArgument(name)}'
        ' --resource-group ${InputValidator.escapeShellArgument(resourceGroup)}'
        ' --location ${InputValidator.escapeShellArgument(location)}'
        ' --output json';

    if (tags != null && tags.isNotEmpty) {
      final tagString = tags.entries
          .map((e) => '${e.key}=${e.value}')
          .join(' ');
      command += ' --tags $tagString';
    }

    return executeCommand(command);
  }

  /// Deletes a Key Vault
  Future<AzureCliResult> deleteKeyVault(String name) async {
    final validation = InputValidator.validateResourceName(name);
    if (validation != null) {
      throw ArgumentError('Invalid Key Vault name: $validation');
    }

    final command = 'az keyvault delete'
        ' --name ${InputValidator.escapeShellArgument(name)}'
        ' --output json';

    return executeCommand(command);
  }

  /// Lists secrets in a Key Vault
  Future<AzureCliResult> listSecrets(String keyVaultName) async {
    final validation = InputValidator.validateResourceName(keyVaultName);
    if (validation != null) {
      throw ArgumentError('Invalid Key Vault name: $validation');
    }

    final command = 'az keyvault secret list'
        ' --vault-name ${InputValidator.escapeShellArgument(keyVaultName)}'
        ' --output json';

    return executeCommand(command);
  }

  /// Sets a secret in a Key Vault
  Future<AzureCliResult> setSecret({
    required String keyVaultName,
    required String secretName,
    required String value,
    Map<String, String>? tags,
  }) async {
    final kvValidation = InputValidator.validateResourceName(keyVaultName);
    if (kvValidation != null) {
      throw ArgumentError('Invalid Key Vault name: $kvValidation');
    }

    final secretValidation = InputValidator.validateResourceName(secretName);
    if (secretValidation != null) {
      throw ArgumentError('Invalid secret name: $secretValidation');
    }

    String command = 'az keyvault secret set'
        ' --vault-name ${InputValidator.escapeShellArgument(keyVaultName)}'
        ' --name ${InputValidator.escapeShellArgument(secretName)}'
        ' --value ${InputValidator.escapeShellArgument(value)}'
        ' --output json';

    if (tags != null && tags.isNotEmpty) {
      final tagString = tags.entries
          .map((e) => '${e.key}=${e.value}')
          .join(' ');
      command += ' --tags $tagString';
    }

    return executeCommand(command);
  }

  /// Checks if Azure CLI is installed and authenticated
  Future<bool> isAzureCliReady() async {
    try {
      final versionResult = await executeCommand('az --version');
      if (!versionResult.success) {
        AppLogger.warning('Azure CLI not found or not working');
        return false;
      }

      final accountResult = await executeCommand('az account show');
      if (!accountResult.success) {
        AppLogger.warning('Azure CLI not authenticated');
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.error('Error checking Azure CLI status', e);
      return false;
    }
  }

  /// Gets the number of currently running commands
  int get runningCommandsCount => _runningCommands.length;

  /// Cancels all running commands
  Future<void> cancelAllCommands() async {
    for (final completer in _runningCommands.values) {
      if (!completer.isCompleted) {
        completer.complete(AzureCliResult(
          success: false,
          output: '',
          error: 'Command cancelled',
          exitCode: -1,
          executionTime: Duration.zero,
        ));
      }
    }
    _runningCommands.clear();
  }

  /// Checks if a command is in the allowed list
  bool _isCommandAllowed(String command) {
    final normalizedCommand = command.trim().toLowerCase();
    
    return AppConstants.allowedAzCommands.any((allowedCommand) =>
        normalizedCommand.startsWith(allowedCommand.toLowerCase())
    );
  }

  /// Parses command string into parts for ProcessManager
  List<String> _parseCommand(String command) {
    // Simple command parsing - in production, consider using a more robust parser
    return command.split(' ').where((part) => part.isNotEmpty).toList();
  }
}