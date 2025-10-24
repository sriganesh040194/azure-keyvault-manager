import 'package:json_annotation/json_annotation.dart';

part 'audit_models.g.dart';

@JsonSerializable()
class AuditLogEntry {
  final String id;
  final String operationName;
  final String operationVersion;
  final String category;
  final String resultType;
  final String resultSignature;
  final DateTime time;
  final String resourceId;
  final String resourceType;
  final String resourceGroup;
  final String subscriptionId;
  final String tenantId;
  final String level;
  final String location;
  final Map<String, dynamic>? properties;
  final CallerInfo? callerInfo;
  final String? correlationId;
  final String? description;

  AuditLogEntry({
    required this.id,
    required this.operationName,
    required this.operationVersion,
    required this.category,
    required this.resultType,
    required this.resultSignature,
    required this.time,
    required this.resourceId,
    required this.resourceType,
    required this.resourceGroup,
    required this.subscriptionId,
    required this.tenantId,
    required this.level,
    required this.location,
    this.properties,
    this.callerInfo,
    this.correlationId,
    this.description,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditLogEntryFromJson(json);

  Map<String, dynamic> toJson() => _$AuditLogEntryToJson(this);

  // Helper getters for UI display
  String get displayName {
    // Extract readable operation name from the full operation name
    final parts = operationName.split('/');
    if (parts.length >= 2) {
      return parts.last;
    }
    return operationName;
  }

  String get resourceName {
    // Extract resource name from resource ID
    final parts = resourceId.split('/');
    return parts.isNotEmpty ? parts.last : 'Unknown';
  }

  AuditSeverity get severity {
    switch (level.toLowerCase()) {
      case 'error':
        return AuditSeverity.error;
      case 'warning':
        return AuditSeverity.warning;
      case 'informational':
      case 'information':
        return AuditSeverity.info;
      default:
        return AuditSeverity.info;
    }
  }

  AuditStatus get status {
    switch (resultType.toLowerCase()) {
      case 'success':
      case 'succeeded':
        return AuditStatus.success;
      case 'failure':
      case 'failed':
        return AuditStatus.failed;
      case 'start':
      case 'started':
        return AuditStatus.started;
      default:
        return AuditStatus.unknown;
    }
  }

  bool get isKeyVaultRelated {
    return resourceType.toLowerCase().contains('keyvault') ||
           operationName.toLowerCase().contains('keyvault') ||
           category.toLowerCase().contains('keyvault');
  }
}

@JsonSerializable()
class CallerInfo {
  final String? userId;
  final String? userPrincipalName;
  final String? applicationId;
  final String? clientIP;
  final String? userAgent;

  CallerInfo({
    this.userId,
    this.userPrincipalName,
    this.applicationId,
    this.clientIP,
    this.userAgent,
  });

  factory CallerInfo.fromJson(Map<String, dynamic> json) =>
      _$CallerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CallerInfoToJson(this);

  String get displayName {
    return userPrincipalName ?? 
           userId ?? 
           applicationId ?? 
           'Unknown User';
  }
}

enum AuditSeverity {
  info,
  warning,
  error,
}

enum AuditStatus {
  success,
  failed,
  started,
  unknown,
}

class AuditFilter {
  final DateTime? startTime;
  final DateTime? endTime;
  final String? resourceGroup;
  final String? operationName;
  final AuditSeverity? severity;
  final AuditStatus? status;
  final bool keyVaultOnly;
  final String? searchQuery;

  AuditFilter({
    this.startTime,
    this.endTime,
    this.resourceGroup,
    this.operationName,
    this.severity,
    this.status,
    this.keyVaultOnly = false,
    this.searchQuery,
  });

  AuditFilter copyWith({
    DateTime? startTime,
    DateTime? endTime,
    String? resourceGroup,
    String? operationName,
    AuditSeverity? severity,
    AuditStatus? status,
    bool? keyVaultOnly,
    String? searchQuery,
  }) {
    return AuditFilter(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      resourceGroup: resourceGroup ?? this.resourceGroup,
      operationName: operationName ?? this.operationName,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      keyVaultOnly: keyVaultOnly ?? this.keyVaultOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class AuditSummary {
  final int totalEntries;
  final int successfulOperations;
  final int failedOperations;
  final int keyVaultOperations;
  final Map<String, int> operationCounts;
  final Map<String, int> resourceGroupCounts;
  final DateTime? oldestEntry;
  final DateTime? newestEntry;

  AuditSummary({
    required this.totalEntries,
    required this.successfulOperations,
    required this.failedOperations,
    required this.keyVaultOperations,
    required this.operationCounts,
    required this.resourceGroupCounts,
    this.oldestEntry,
    this.newestEntry,
  });

  factory AuditSummary.fromEntries(List<AuditLogEntry> entries) {
    if (entries.isEmpty) {
      return AuditSummary(
        totalEntries: 0,
        successfulOperations: 0,
        failedOperations: 0,
        keyVaultOperations: 0,
        operationCounts: {},
        resourceGroupCounts: {},
      );
    }

    final operationCounts = <String, int>{};
    final resourceGroupCounts = <String, int>{};
    int successCount = 0;
    int failedCount = 0;
    int keyVaultCount = 0;

    DateTime? oldest;
    DateTime? newest;

    for (final entry in entries) {
      // Count operations
      final opName = entry.displayName;
      operationCounts[opName] = (operationCounts[opName] ?? 0) + 1;

      // Count resource groups
      resourceGroupCounts[entry.resourceGroup] = 
          (resourceGroupCounts[entry.resourceGroup] ?? 0) + 1;

      // Count statuses
      if (entry.status == AuditStatus.success) {
        successCount++;
      } else if (entry.status == AuditStatus.failed) {
        failedCount++;
      }

      // Count KeyVault operations
      if (entry.isKeyVaultRelated) {
        keyVaultCount++;
      }

      // Track time range
      if (oldest == null || entry.time.isBefore(oldest)) {
        oldest = entry.time;
      }
      if (newest == null || entry.time.isAfter(newest)) {
        newest = entry.time;
      }
    }

    return AuditSummary(
      totalEntries: entries.length,
      successfulOperations: successCount,
      failedOperations: failedCount,
      keyVaultOperations: keyVaultCount,
      operationCounts: operationCounts,
      resourceGroupCounts: resourceGroupCounts,
      oldestEntry: oldest,
      newestEntry: newest,
    );
  }
}