import 'dart:convert';
import '../../core/logging/app_logger.dart';
import '../azure_cli/platform_azure_cli_service.dart';
import 'audit_models.dart';

class AuditService {
  final UnifiedAzureCliService _cliService;

  AuditService(this._cliService);

  /// Retrieves application logs converted to audit format
  Future<List<AuditLogEntry>> getAuditLogs({
    AuditFilter? filter,
    int maxRecords = 100,
  }) async {
    try {
      AppLogger.info('Fetching application logs');

      // Get real application logs from AppLogger
      final appLogs = AppLogger.getStoredLogs();

      // Convert app logs to audit format
      List<AuditLogEntry> auditEntries = appLogs
          .map((appLog) => _convertAppLogToAuditEntry(appLog))
          .toList();

      // Apply filtering if needed
      if (filter != null) {
        auditEntries = _applyClientSideFiltering(auditEntries, filter);
      }

      // Sort by time (newest first)
      auditEntries.sort((a, b) => b.time.compareTo(a.time));

      // Limit results
      if (auditEntries.length > maxRecords) {
        auditEntries = auditEntries.take(maxRecords).toList();
      }

      AppLogger.info(
        'Retrieved ${auditEntries.length} application log entries',
      );
      return auditEntries;
    } catch (e) {
      AppLogger.error('Failed to get application logs', e);
      rethrow;
    }
  }

  /// Get audit logs for a specific Key Vault
  Future<List<AuditLogEntry>> getKeyVaultAuditLogs(
    String keyVaultName, {
    DateTime? startTime,
    DateTime? endTime,
    int maxRecords = 50,
  }) async {
    final filter = AuditFilter(
      startTime: startTime ?? DateTime.now().subtract(const Duration(days: 7)),
      endTime: endTime ?? DateTime.now(),
      keyVaultOnly: true,
      searchQuery: keyVaultName,
    );

    final allLogs = await getAuditLogs(filter: filter, maxRecords: maxRecords);

    // Filter for this specific Key Vault
    return allLogs
        .where(
          (log) =>
              log.operationName.toLowerCase().contains(
                keyVaultName.toLowerCase(),
              ) ||
              log.resourceName.toLowerCase().contains(
                keyVaultName.toLowerCase(),
              ) ||
              (log.properties != null &&
                  log.properties.toString().toLowerCase().contains(
                    keyVaultName.toLowerCase(),
                  )),
        )
        .toList();
  }

  /// Get audit summary statistics
  Future<AuditSummary> getAuditSummary({
    AuditFilter? filter,
    int maxRecords = 200,
  }) async {
    final entries = await getAuditLogs(filter: filter, maxRecords: maxRecords);
    return AuditSummary.fromEntries(entries);
  }

  /// Get recent Key Vault operations across all vaults
  Future<List<AuditLogEntry>> getRecentKeyVaultOperations({
    int maxRecords = 20,
  }) async {
    final filter = AuditFilter(
      startTime: DateTime.now().subtract(const Duration(hours: 24)),
      endTime: DateTime.now(),
      keyVaultOnly: true,
    );

    return await getAuditLogs(filter: filter, maxRecords: maxRecords);
  }

  /// Convert AppLogEntry to AuditLogEntry format
  AuditLogEntry _convertAppLogToAuditEntry(AppLogEntry appLog) {
    final now = DateTime.now();
    return AuditLogEntry(
      id: appLog.timestamp.millisecondsSinceEpoch.toString(),
      operationName:
          'Application.${appLog.category ?? 'General'}/${appLog.level}',
      operationVersion: appLog.level,
      category: appLog.category ?? 'Application',
      resultType: _getResultTypeFromLevel(appLog.level),
      resultSignature: appLog.level,
      time: appLog.timestamp,
      resourceId:
          '/applications/azure-keyvault-manager/logs/${appLog.category ?? 'general'}',
      resourceType: 'Application.Logs',
      resourceGroup: 'azure-keyvault-manager-app',
      subscriptionId: 'local-application',
      tenantId: 'local-tenant',
      level: _getAuditLevelFromLogLevel(appLog.level),
      location: 'local',
      properties: appLog.details,
      callerInfo: CallerInfo(
        userId: 'local-user',
        userPrincipalName: 'local-application',
        clientIP: '127.0.0.1',
      ),
      correlationId: appLog.timestamp.millisecondsSinceEpoch.toString(),
      description: appLog.message,
    );
  }

  String _getResultTypeFromLevel(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
      case 'FATAL':
        return 'Failed';
      case 'WARNING':
        return 'Warning';
      default:
        return 'Success';
    }
  }

  String _getAuditLevelFromLogLevel(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
      case 'FATAL':
        return 'Error';
      case 'WARNING':
        return 'Warning';
      default:
        return 'Informational';
    }
  }

  /// Log an operation directly to AppLogger (which will appear in audit)
  void logOperation({
    required String operationName,
    required String resourceName,
    required String resourceType,
    required String resourceGroup,
    required AuditStatus status,
    String? userId,
    String? userPrincipalName,
    String? clientIP,
    Map<String, dynamic>? properties,
  }) {
    final message = '$operationName on $resourceName ($resourceType)';
    final details = {
      'resourceName': resourceName,
      'resourceType': resourceType,
      'resourceGroup': resourceGroup,
      'status': status.toString(),
      if (properties != null) ...properties,
    };

    switch (status) {
      case AuditStatus.failed:
        AppLogger.error(message, details);
        break;
      case AuditStatus.success:
        AppLogger.info(message);
        break;
      default:
        AppLogger.debug(message);
        break;
    }
  }

  List<AuditLogEntry> _applyClientSideFiltering(
    List<AuditLogEntry> entries,
    AuditFilter filter,
  ) {
    var filtered = entries;

    // Filter by search query
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      filtered = filtered
          .where(
            (entry) =>
                entry.operationName.toLowerCase().contains(query) ||
                entry.resourceName.toLowerCase().contains(query) ||
                entry.resourceGroup.toLowerCase().contains(query) ||
                entry.callerInfo?.displayName.toLowerCase().contains(query) ==
                    true ||
                (entry.description?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    // Filter by severity
    if (filter.severity != null) {
      filtered = filtered
          .where((entry) => entry.severity == filter.severity)
          .toList();
    }

    // Filter by status
    if (filter.status != null) {
      filtered = filtered
          .where((entry) => entry.status == filter.status)
          .toList();
    }

    // Filter by Key Vault operations only
    if (filter.keyVaultOnly) {
      filtered = filtered
          .where(
            (entry) =>
                entry.isKeyVaultRelated ||
                entry.category.toLowerCase().contains('keyvault') ||
                entry.operationName.toLowerCase().contains('keyvault'),
          )
          .toList();
    }

    // Filter by operation name
    if (filter.operationName != null && filter.operationName!.isNotEmpty) {
      filtered = filtered
          .where(
            (entry) => entry.operationName.toLowerCase().contains(
              filter.operationName!.toLowerCase(),
            ),
          )
          .toList();
    }

    return filtered;
  }

  /// Export audit logs to CSV format
  Future<String> exportAuditLogsToCSV(List<AuditLogEntry> entries) async {
    final buffer = StringBuffer();

    // CSV header
    buffer.writeln(
      'Timestamp,Operation,Resource,Resource Group,Status,Level,User,IP Address',
    );

    // CSV rows
    for (final entry in entries) {
      final timestamp = entry.time.toIso8601String();
      final operation = _escapeCsvField(entry.displayName);
      final resource = _escapeCsvField(entry.resourceName);
      final resourceGroup = _escapeCsvField(entry.resourceGroup);
      final status = _escapeCsvField(entry.resultType);
      final level = _escapeCsvField(entry.level);
      final user = _escapeCsvField(entry.callerInfo?.displayName ?? 'Unknown');
      final ip = _escapeCsvField(entry.callerInfo?.clientIP ?? '');

      buffer.writeln(
        '$timestamp,$operation,$resource,$resourceGroup,$status,$level,$user,$ip',
      );
    }

    return buffer.toString();
  }

  String _escapeCsvField(String field) {
    // Escape CSV fields that contain commas, quotes, or newlines
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
