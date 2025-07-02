import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // Security-specific logging
  static void securityEvent(String event, Map<String, dynamic> details) {
    _logger.w('SECURITY EVENT: $event', error: details);
  }

  // Authentication logging
  static void authEvent(String event, String userId) {
    _logger.i('AUTH EVENT: $event for user: ${_sanitizeUserId(userId)}');
  }

  // CLI command logging (sanitized)
  static void cliCommand(String command, String result) {
    final sanitizedCommand = _sanitizeCommand(command);
    final sanitizedResult = _sanitizeResult(result);
    _logger.i('CLI COMMAND: $sanitizedCommand | RESULT: $sanitizedResult');
  }

  // Sanitization helpers
  static String _sanitizeUserId(String userId) {
    if (userId.length <= 8) return userId;
    return '${userId.substring(0, 4)}***${userId.substring(userId.length - 4)}';
  }

  static String _sanitizeCommand(String command) {
    // Remove sensitive flags and parameters
    return command
        .replaceAll(RegExp(r'--password\s+\S+'), '--password ***')
        .replaceAll(RegExp(r'--secret\s+\S+'), '--secret ***')
        .replaceAll(RegExp(r'--key\s+\S+'), '--key ***');
  }

  static String _sanitizeResult(String result) {
    // Truncate long results and remove sensitive data
    if (result.length > 500) {
      result = '${result.substring(0, 500)}... [truncated]';
    }
    
    return result
        .replaceAll(RegExp(r'"value":\s*"[^"]*"'), '"value": "***"')
        .replaceAll(RegExp(r'"password":\s*"[^"]*"'), '"password": "***"')
        .replaceAll(RegExp(r'"secret":\s*"[^"]*"'), '"secret": "***"');
  }
}