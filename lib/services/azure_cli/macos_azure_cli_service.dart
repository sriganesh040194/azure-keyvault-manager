import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:process/process.dart';
import '../../core/logging/app_logger.dart';
import '../../core/security/input_validator.dart';
import '../../shared/constants/app_constants.dart';

class MacOSAzureCliResult {
  final bool success;
  final String output;
  final String? error;
  final int exitCode;
  final Duration executionTime;

  const MacOSAzureCliResult({
    required this.success,
    required this.output,
    this.error,
    required this.exitCode,
    required this.executionTime,
  });
}

class MacOSAzureCliService {
  final ProcessManager _processManager;

  MacOSAzureCliService({ProcessManager? processManager})
      : _processManager = processManager ?? const LocalProcessManager();

  /// Executes an Azure CLI command with macOS-specific handling
  Future<MacOSAzureCliResult> executeCommand(
    String command, {
    Map<String, String>? environment,
    String? workingDirectory,
    Duration? timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      AppLogger.info('Executing Azure CLI command on macOS: $command');

      // Validate the command
      final validationError = InputValidator.validateCommand(command);
      if (validationError != null) {
        AppLogger.securityEvent('Command validation failed', {
          'command': command,
          'error': validationError,
        });
        return MacOSAzureCliResult(
          success: false,
          output: '',
          error: 'Security validation failed: $validationError',
          exitCode: -1,
          executionTime: stopwatch.elapsed,
        );
      }

      // Check if command is in allowed list
      final baseCommand = _extractBaseCommand(command);
      if (!AppConstants.allowedAzCommands.any((allowed) => baseCommand.startsWith(allowed))) {
        AppLogger.securityEvent('Unauthorized command attempted', {
          'command': baseCommand,
        });
        return MacOSAzureCliResult(
          success: false,
          output: '',
          error: 'Command not authorized: $baseCommand',
          exitCode: -1,
          executionTime: stopwatch.elapsed,
        );
      }

      // Check if Azure CLI is available
      final azPath = await _findAzureCLI();
      if (azPath == null) {
        return MacOSAzureCliResult(
          success: false,
          output: '',
          error: 'Azure CLI not found. Please install Azure CLI using: brew install azure-cli',
          exitCode: -1,
          executionTime: stopwatch.elapsed,
        );
      }

      // Prepare command execution
      final effectiveTimeout = timeout ?? const Duration(seconds: AppConstants.cliTimeoutSeconds);
      
      // Parse command into components and replace 'az' with full path
      final commandParts = _parseCommand(command);
      if (commandParts.isNotEmpty && commandParts[0] == 'az') {
        commandParts[0] = azPath;
      }
      
      // Set up environment
      final processEnvironment = <String, String>{
        'PATH': '/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:${Platform.environment['PATH'] ?? ''}',
        'HOME': Platform.environment['HOME'] ?? '',
        if (environment != null) ...environment,
      };

      // Execute the process
      final process = await _processManager.start(
        commandParts,
        environment: processEnvironment,
        workingDirectory: workingDirectory,
      );

      // Set up timeout
      Timer? timeoutTimer;
      if (effectiveTimeout.inMilliseconds > 0) {
        timeoutTimer = Timer(effectiveTimeout, () {
          process.kill();
        });
      }

      // Collect output
      final stdout = StringBuffer();
      final stderr = StringBuffer();
      
      final stdoutSubscription = process.stdout
          .transform(utf8.decoder)
          .listen(stdout.write);
      
      final stderrSubscription = process.stderr
          .transform(utf8.decoder)
          .listen(stderr.write);

      // Wait for completion
      final exitCode = await process.exitCode;
      
      // Clean up
      timeoutTimer?.cancel();
      await stdoutSubscription.cancel();
      await stderrSubscription.cancel();

      // Process results
      final outputString = stdout.toString();
      final errorString = stderr.toString();
      
      final result = MacOSAzureCliResult(
        success: exitCode == 0,
        output: outputString,
        error: errorString.isNotEmpty ? errorString : null,
        exitCode: exitCode,
        executionTime: stopwatch.elapsed,
      );

      if (result.success) {
        AppLogger.cliCommand(command, 'SUCCESS');
      } else {
        AppLogger.error('Azure CLI command failed: $command', result.error);
      }

      return result;

    } catch (e, stackTrace) {
      AppLogger.error('Error executing Azure CLI command on macOS', e, stackTrace);
      return MacOSAzureCliResult(
        success: false,
        output: '',
        error: 'Execution error: $e',
        exitCode: -1,
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Finds the Azure CLI executable on macOS
  Future<String?> _findAzureCLI() async {
    final possiblePaths = [
      '/opt/homebrew/bin/az',  // Apple Silicon Homebrew
      '/usr/local/bin/az',     // Intel Homebrew
      '/usr/bin/az',           // System install
      '/bin/az',               // Alternative system install
    ];

    for (final path in possiblePaths) {
      final file = File(path);
      if (await file.exists()) {
        AppLogger.info('Found Azure CLI at: $path');
        return path;
      }
    }

    // Try using 'which' command
    try {
      final process = await _processManager.start(
        ['which', 'az'],
        environment: {
          'PATH': '/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:${Platform.environment['PATH'] ?? ''}',
        },
      );
      final exitCode = await process.exitCode;
      if (exitCode == 0) {
        final stdout = await process.stdout.transform(utf8.decoder).join();
        final azPath = stdout.trim();
        if (azPath.isNotEmpty) {
          AppLogger.info('Found Azure CLI using which: $azPath');
          return azPath;
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to find Azure CLI using which command: $e');
    }

    AppLogger.error('Azure CLI not found in any standard location');
    return null;
  }

  /// Extracts base command from full command string
  String _extractBaseCommand(String command) {
    final parts = command.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts.isNotEmpty ? parts[0] : '';
  }

  /// Parses command string into list of arguments
  List<String> _parseCommand(String command) {
    final parts = <String>[];
    final regex = RegExp(r'''(['"])((?:(?!\1)[^\\]|\\.)*)(\1)|(\S+)''');
    
    for (final match in regex.allMatches(command)) {
      if (match.group(1) != null) {
        // Quoted string
        parts.add(match.group(2)!.replaceAll(r'\"', '"').replaceAll(r"\'", "'"));
      } else {
        // Unquoted string
        parts.add(match.group(4)!);
      }
    }
    
    return parts;
  }

  /// Checks if Azure CLI is available and properly configured
  Future<bool> isAzureCliAvailable() async {
    try {
      final result = await executeCommand('az --version');
      return result.success;
    } catch (e) {
      return false;
    }
  }

  /// Gets Azure CLI version information
  Future<String?> getVersion() async {
    try {
      final result = await executeCommand('az --version');
      if (result.success) {
        final lines = result.output.split('\n');
        for (final line in lines) {
          if (line.startsWith('azure-cli')) {
            return line.trim();
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed to get Azure CLI version', e);
    }
    return null;
  }

  /// Checks if user is logged in to Azure CLI
  Future<bool> isLoggedIn() async {
    try {
      final result = await executeCommand('az account show');
      return result.success;
    } catch (e) {
      return false;
    }
  }
}