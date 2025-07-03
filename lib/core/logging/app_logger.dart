import 'package:logger/logger.dart';

class AppLogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? category;
  final Map<String, dynamic>? details;
  final String? error;

  AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.category,
    this.details,
    this.error,
  });
}

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
  
  // Store app logs for display in audit tab
  static final List<AppLogEntry> _appLogs = [];
  static const int _maxLogEntries = 500; // Keep last 500 logs

  static void _addLogEntry(String level, String message, String? category, Map<String, dynamic>? details, String? error) {
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      category: category,
      details: details,
      error: error,
    );
    
    _appLogs.add(entry);
    
    // Keep only the last N entries to prevent memory issues
    if (_appLogs.length > _maxLogEntries) {
      _appLogs.removeAt(0);
    }
  }

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
    _addLogEntry('DEBUG', message, null, null, error?.toString());
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
    _addLogEntry('INFO', message, null, null, error?.toString());
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
    _addLogEntry('WARNING', message, null, null, error?.toString());
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    _addLogEntry('ERROR', message, null, null, error?.toString());
  }

  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    _addLogEntry('FATAL', message, null, null, error?.toString());
  }

  // Get all stored logs for audit display
  static List<AppLogEntry> getStoredLogs() {
    return List.unmodifiable(_appLogs);
  }

  // Security-specific logging
  static void securityEvent(String event, Map<String, dynamic> details) {
    _logger.w('SECURITY EVENT: $event', error: details);
    _addLogEntry('WARNING', 'SECURITY EVENT: $event', 'Security', details, null);
  }

  // Authentication logging
  static void authEvent(String event, String userId) {
    final sanitizedUserId = _sanitizeUserId(userId);
    final message = 'AUTH EVENT: $event for user: $sanitizedUserId';
    _logger.i(message);
    _addLogEntry('INFO', message, 'Authentication', {'userId': sanitizedUserId, 'event': event}, null);
  }

  // CLI command logging (sanitized)
  static void cliCommand(String command, String result) {
    final sanitizedCommand = _sanitizeCommand(command);
    final sanitizedResult = _sanitizeResult(result);
    final message = 'CLI COMMAND: $sanitizedCommand';
    _logger.i(message);
    _addLogEntry('INFO', message, 'CLI', {'command': sanitizedCommand, 'resultLength': sanitizedResult.length}, null);
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