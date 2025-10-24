// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyInfo _$KeyInfoFromJson(Map<String, dynamic> json) => KeyInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  keyType: json['keyType'] as String?,
  keySize: (json['keySize'] as num?)?.toInt(),
  keyOps: (json['keyOps'] as List<dynamic>?)?.map((e) => e as String).toList(),
  curve: json['curve'] as String?,
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
  tags: (json['tags'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  version: json['version'] as String?,
  recoverable: json['recoverable'] as bool?,
  recoverableDays: (json['recoverableDays'] as num?)?.toInt(),
);

Map<String, dynamic> _$KeyInfoToJson(KeyInfo instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'keyType': instance.keyType,
  'keySize': instance.keySize,
  'keyOps': instance.keyOps,
  'curve': instance.curve,
  'created': instance.created?.toIso8601String(),
  'updated': instance.updated?.toIso8601String(),
  'expires': instance.expires?.toIso8601String(),
  'notBefore': instance.notBefore?.toIso8601String(),
  'enabled': instance.enabled,
  'tags': instance.tags,
  'version': instance.version,
  'recoverable': instance.recoverable,
  'recoverableDays': instance.recoverableDays,
};

CreateKeyRequest _$CreateKeyRequestFromJson(Map<String, dynamic> json) =>
    CreateKeyRequest(
      name: json['name'] as String,
      keyType: json['keyType'] as String,
      keySize: (json['keySize'] as num?)?.toInt(),
      curve: json['curve'] as String?,
      keyOps: (json['keyOps'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      expires: json['expires'] == null
          ? null
          : DateTime.parse(json['expires'] as String),
      notBefore: json['notBefore'] == null
          ? null
          : DateTime.parse(json['notBefore'] as String),
      enabled: json['enabled'] as bool?,
      tags: (json['tags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$CreateKeyRequestToJson(CreateKeyRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'keyType': instance.keyType,
      'keySize': instance.keySize,
      'curve': instance.curve,
      'keyOps': instance.keyOps,
      'expires': instance.expires?.toIso8601String(),
      'notBefore': instance.notBefore?.toIso8601String(),
      'enabled': instance.enabled,
      'tags': instance.tags,
    };

UpdateKeyRequest _$UpdateKeyRequestFromJson(Map<String, dynamic> json) =>
    UpdateKeyRequest(
      keyOps: (json['keyOps'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      expires: json['expires'] == null
          ? null
          : DateTime.parse(json['expires'] as String),
      notBefore: json['notBefore'] == null
          ? null
          : DateTime.parse(json['notBefore'] as String),
      enabled: json['enabled'] as bool?,
      tags: (json['tags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$UpdateKeyRequestToJson(UpdateKeyRequest instance) =>
    <String, dynamic>{
      'keyOps': instance.keyOps,
      'expires': instance.expires?.toIso8601String(),
      'notBefore': instance.notBefore?.toIso8601String(),
      'enabled': instance.enabled,
      'tags': instance.tags,
    };
