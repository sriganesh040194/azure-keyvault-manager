// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certificate_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CertificateInfo _$CertificateInfoFromJson(Map<String, dynamic> json) =>
    CertificateInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      thumbprint: json['thumbprint'] as String?,
      subject: json['subject'] as String?,
      issuer: json['issuer'] as String?,
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
      contentType: json['contentType'] as String?,
      keyUsage: (json['keyUsage'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      enhancedKeyUsage: (json['enhancedKeyUsage'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      policy: json['policy'] == null
          ? null
          : CertificatePolicy.fromJson(json['policy'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CertificateInfoToJson(CertificateInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'thumbprint': instance.thumbprint,
      'subject': instance.subject,
      'issuer': instance.issuer,
      'created': instance.created?.toIso8601String(),
      'updated': instance.updated?.toIso8601String(),
      'expires': instance.expires?.toIso8601String(),
      'notBefore': instance.notBefore?.toIso8601String(),
      'enabled': instance.enabled,
      'tags': instance.tags,
      'version': instance.version,
      'recoverable': instance.recoverable,
      'recoverableDays': instance.recoverableDays,
      'contentType': instance.contentType,
      'keyUsage': instance.keyUsage,
      'enhancedKeyUsage': instance.enhancedKeyUsage,
      'policy': instance.policy,
    };

CertificatePolicy _$CertificatePolicyFromJson(
  Map<String, dynamic> json,
) => CertificatePolicy(
  issuerName: json['issuerName'] as String?,
  certificateType: json['certificateType'] as String?,
  certificateTransparency: json['certificateTransparency'] as bool?,
  contentType: json['contentType'] as String?,
  subject: json['subject'] as String?,
  subjectAlternativeNames: (json['subjectAlternativeNames'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  validityInMonths: (json['validityInMonths'] as num?)?.toInt(),
  keyProperties: json['keyProperties'] == null
      ? null
      : KeyProperties.fromJson(json['keyProperties'] as Map<String, dynamic>),
  secretProperties: json['secretProperties'] == null
      ? null
      : SecretProperties.fromJson(
          json['secretProperties'] as Map<String, dynamic>,
        ),
  x509CertificateProperties: json['x509CertificateProperties'] == null
      ? null
      : X509CertificateProperties.fromJson(
          json['x509CertificateProperties'] as Map<String, dynamic>,
        ),
  lifetimeAction: json['lifetimeAction'] == null
      ? null
      : LifetimeAction.fromJson(json['lifetimeAction'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CertificatePolicyToJson(CertificatePolicy instance) =>
    <String, dynamic>{
      'issuerName': instance.issuerName,
      'certificateType': instance.certificateType,
      'certificateTransparency': instance.certificateTransparency,
      'contentType': instance.contentType,
      'subject': instance.subject,
      'subjectAlternativeNames': instance.subjectAlternativeNames,
      'validityInMonths': instance.validityInMonths,
      'keyProperties': instance.keyProperties,
      'secretProperties': instance.secretProperties,
      'x509CertificateProperties': instance.x509CertificateProperties,
      'lifetimeAction': instance.lifetimeAction,
    };

KeyProperties _$KeyPropertiesFromJson(Map<String, dynamic> json) =>
    KeyProperties(
      exportable: json['exportable'] as bool?,
      keyType: json['keyType'] as String?,
      keySize: (json['keySize'] as num?)?.toInt(),
      reuseKey: json['reuseKey'] as bool?,
      curve: json['curve'] as String?,
    );

Map<String, dynamic> _$KeyPropertiesToJson(KeyProperties instance) =>
    <String, dynamic>{
      'exportable': instance.exportable,
      'keyType': instance.keyType,
      'keySize': instance.keySize,
      'reuseKey': instance.reuseKey,
      'curve': instance.curve,
    };

SecretProperties _$SecretPropertiesFromJson(Map<String, dynamic> json) =>
    SecretProperties(contentType: json['contentType'] as String?);

Map<String, dynamic> _$SecretPropertiesToJson(SecretProperties instance) =>
    <String, dynamic>{'contentType': instance.contentType};

X509CertificateProperties _$X509CertificatePropertiesFromJson(
  Map<String, dynamic> json,
) => X509CertificateProperties(
  subject: json['subject'] as String?,
  subjectAlternativeNames: (json['subjectAlternativeNames'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  keyUsage: (json['keyUsage'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  enhancedKeyUsage: (json['enhancedKeyUsage'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  validityInMonths: (json['validityInMonths'] as num?)?.toInt(),
);

Map<String, dynamic> _$X509CertificatePropertiesToJson(
  X509CertificateProperties instance,
) => <String, dynamic>{
  'subject': instance.subject,
  'subjectAlternativeNames': instance.subjectAlternativeNames,
  'keyUsage': instance.keyUsage,
  'enhancedKeyUsage': instance.enhancedKeyUsage,
  'validityInMonths': instance.validityInMonths,
};

LifetimeAction _$LifetimeActionFromJson(Map<String, dynamic> json) =>
    LifetimeAction(
      action: json['action'] as String?,
      daysBeforeExpiry: (json['daysBeforeExpiry'] as num?)?.toInt(),
      lifetimePercentage: (json['lifetimePercentage'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LifetimeActionToJson(LifetimeAction instance) =>
    <String, dynamic>{
      'action': instance.action,
      'daysBeforeExpiry': instance.daysBeforeExpiry,
      'lifetimePercentage': instance.lifetimePercentage,
    };

CreateCertificateRequest _$CreateCertificateRequestFromJson(
  Map<String, dynamic> json,
) => CreateCertificateRequest(
  name: json['name'] as String,
  policy: CertificatePolicy.fromJson(json['policy'] as Map<String, dynamic>),
  tags: (json['tags'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  enabled: json['enabled'] as bool?,
);

Map<String, dynamic> _$CreateCertificateRequestToJson(
  CreateCertificateRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'policy': instance.policy,
  'tags': instance.tags,
  'enabled': instance.enabled,
};

UpdateCertificateRequest _$UpdateCertificateRequestFromJson(
  Map<String, dynamic> json,
) => UpdateCertificateRequest(
  tags: (json['tags'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  enabled: json['enabled'] as bool?,
  policy: json['policy'] == null
      ? null
      : CertificatePolicy.fromJson(json['policy'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UpdateCertificateRequestToJson(
  UpdateCertificateRequest instance,
) => <String, dynamic>{
  'tags': instance.tags,
  'enabled': instance.enabled,
  'policy': instance.policy,
};

ImportCertificateRequest _$ImportCertificateRequestFromJson(
  Map<String, dynamic> json,
) => ImportCertificateRequest(
  name: json['name'] as String,
  certificateData: json['certificateData'] as String,
  password: json['password'] as String?,
  policy: json['policy'] == null
      ? null
      : CertificatePolicy.fromJson(json['policy'] as Map<String, dynamic>),
  tags: (json['tags'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  enabled: json['enabled'] as bool?,
);

Map<String, dynamic> _$ImportCertificateRequestToJson(
  ImportCertificateRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'certificateData': instance.certificateData,
  'password': instance.password,
  'policy': instance.policy,
  'tags': instance.tags,
  'enabled': instance.enabled,
};
