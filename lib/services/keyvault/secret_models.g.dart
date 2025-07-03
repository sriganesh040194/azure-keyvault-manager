// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecretInfo _$SecretInfoFromJson(Map<String, dynamic> json) => SecretInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  contentType: json['contentType'] as String?,
  enabled: json['enabled'] as bool?,
  created: json['created'] == null
      ? null
      : DateTime.parse(json['created'] as String),
  updated: json['updated'] == null
      ? null
      : DateTime.parse(json['updated'] as String),
  expires: json['expires'] == null
      ? null
      : DateTime.parse(json['expires'] as String),
  notBefore: json['notBefore'] == null
      ? null
      : DateTime.parse(json['notBefore'] as String),
  recoveryLevel: json['recoveryLevel'] as String?,
  tags: (json['tags'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
);

Map<String, dynamic> _$SecretInfoToJson(SecretInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'contentType': instance.contentType,
      'enabled': instance.enabled,
      'created': instance.created?.toIso8601String(),
      'updated': instance.updated?.toIso8601String(),
      'expires': instance.expires?.toIso8601String(),
      'notBefore': instance.notBefore?.toIso8601String(),
      'recoveryLevel': instance.recoveryLevel,
      'tags': instance.tags,
    };

SecretValue _$SecretValueFromJson(Map<String, dynamic> json) => SecretValue(
  id: json['id'] as String,
  value: json['value'] as String,
  contentType: json['contentType'] as String?,
  tags: (json['tags'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
);

Map<String, dynamic> _$SecretValueToJson(SecretValue instance) =>
    <String, dynamic>{
      'id': instance.id,
      'value': instance.value,
      'contentType': instance.contentType,
      'tags': instance.tags,
    };

CreateSecretRequest _$CreateSecretRequestFromJson(Map<String, dynamic> json) =>
    CreateSecretRequest(
      name: json['name'] as String,
      value: json['value'] as String,
      contentType: json['contentType'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      expires: json['expires'] == null
          ? null
          : DateTime.parse(json['expires'] as String),
      notBefore: json['notBefore'] == null
          ? null
          : DateTime.parse(json['notBefore'] as String),
      tags: (json['tags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$CreateSecretRequestToJson(
  CreateSecretRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'value': instance.value,
  'contentType': instance.contentType,
  'enabled': instance.enabled,
  'expires': instance.expires?.toIso8601String(),
  'notBefore': instance.notBefore?.toIso8601String(),
  'tags': instance.tags,
};

UpdateSecretRequest _$UpdateSecretRequestFromJson(Map<String, dynamic> json) =>
    UpdateSecretRequest(
      contentType: json['contentType'] as String?,
      enabled: json['enabled'] as bool?,
      expires: json['expires'] == null
          ? null
          : DateTime.parse(json['expires'] as String),
      notBefore: json['notBefore'] == null
          ? null
          : DateTime.parse(json['notBefore'] as String),
      tags: (json['tags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$UpdateSecretRequestToJson(
  UpdateSecretRequest instance,
) => <String, dynamic>{
  'contentType': instance.contentType,
  'enabled': instance.enabled,
  'expires': instance.expires?.toIso8601String(),
  'notBefore': instance.notBefore?.toIso8601String(),
  'tags': instance.tags,
};

SecretVersion _$SecretVersionFromJson(Map<String, dynamic> json) =>
    SecretVersion(
      id: json['id'] as String,
      version: json['version'] as String,
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String),
      updated: json['updated'] == null
          ? null
          : DateTime.parse(json['updated'] as String),
      expires: json['expires'] == null
          ? null
          : DateTime.parse(json['expires'] as String),
      notBefore: json['notBefore'] == null
          ? null
          : DateTime.parse(json['notBefore'] as String),
      enabled: json['enabled'] as bool?,
      recoveryLevel: json['recoveryLevel'] as String?,
      tags: (json['tags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$SecretVersionToJson(SecretVersion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'created': instance.created?.toIso8601String(),
      'updated': instance.updated?.toIso8601String(),
      'expires': instance.expires?.toIso8601String(),
      'notBefore': instance.notBefore?.toIso8601String(),
      'enabled': instance.enabled,
      'recoveryLevel': instance.recoveryLevel,
      'tags': instance.tags,
    };
