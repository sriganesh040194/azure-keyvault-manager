// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditLogEntry _$AuditLogEntryFromJson(Map<String, dynamic> json) =>
    AuditLogEntry(
      id: json['id'] as String,
      operationName: json['operationName'] as String,
      operationVersion: json['operationVersion'] as String,
      category: json['category'] as String,
      resultType: json['resultType'] as String,
      resultSignature: json['resultSignature'] as String,
      time: DateTime.parse(json['time'] as String),
      resourceId: json['resourceId'] as String,
      resourceType: json['resourceType'] as String,
      resourceGroup: json['resourceGroup'] as String,
      subscriptionId: json['subscriptionId'] as String,
      tenantId: json['tenantId'] as String,
      level: json['level'] as String,
      location: json['location'] as String,
      properties: json['properties'] as Map<String, dynamic>?,
      callerInfo: json['callerInfo'] == null
          ? null
          : CallerInfo.fromJson(json['callerInfo'] as Map<String, dynamic>),
      correlationId: json['correlationId'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$AuditLogEntryToJson(AuditLogEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'operationName': instance.operationName,
      'operationVersion': instance.operationVersion,
      'category': instance.category,
      'resultType': instance.resultType,
      'resultSignature': instance.resultSignature,
      'time': instance.time.toIso8601String(),
      'resourceId': instance.resourceId,
      'resourceType': instance.resourceType,
      'resourceGroup': instance.resourceGroup,
      'subscriptionId': instance.subscriptionId,
      'tenantId': instance.tenantId,
      'level': instance.level,
      'location': instance.location,
      'properties': instance.properties,
      'callerInfo': instance.callerInfo,
      'correlationId': instance.correlationId,
      'description': instance.description,
    };

CallerInfo _$CallerInfoFromJson(Map<String, dynamic> json) => CallerInfo(
  userId: json['userId'] as String?,
  userPrincipalName: json['userPrincipalName'] as String?,
  applicationId: json['applicationId'] as String?,
  clientIP: json['clientIP'] as String?,
  userAgent: json['userAgent'] as String?,
);

Map<String, dynamic> _$CallerInfoToJson(CallerInfo instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'userPrincipalName': instance.userPrincipalName,
      'applicationId': instance.applicationId,
      'clientIP': instance.clientIP,
      'userAgent': instance.userAgent,
    };
