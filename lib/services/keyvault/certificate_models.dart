import 'package:json_annotation/json_annotation.dart';

part 'certificate_models.g.dart';

/// Represents a certificate in Azure Key Vault
@JsonSerializable()
class CertificateInfo {
  final String id;
  final String name;
  final String? thumbprint;
  final String? subject;
  final String? issuer;
  final DateTime? created;
  final DateTime? updated;
  final DateTime? expires;
  final DateTime? notBefore;
  final bool? enabled;
  final Map<String, String>? tags;
  final String? version;
  final bool? recoverable;
  final int? recoverableDays;
  final String? contentType;
  final List<String>? keyUsage;
  final List<String>? enhancedKeyUsage;
  final CertificatePolicy? policy;

  const CertificateInfo({
    required this.id,
    required this.name,
    this.thumbprint,
    this.subject,
    this.issuer,
    this.created,
    this.updated,
    this.expires,
    this.notBefore,
    this.enabled,
    this.tags,
    this.version,
    this.recoverable,
    this.recoverableDays,
    this.contentType,
    this.keyUsage,
    this.enhancedKeyUsage,
    this.policy,
  });

  factory CertificateInfo.fromJson(Map<String, dynamic> json) => _$CertificateInfoFromJson(json);
  Map<String, dynamic> toJson() => _$CertificateInfoToJson(this);

  /// Creates a copy of this CertificateInfo with updated fields
  CertificateInfo copyWith({
    String? id,
    String? name,
    String? thumbprint,
    String? subject,
    String? issuer,
    DateTime? created,
    DateTime? updated,
    DateTime? expires,
    DateTime? notBefore,
    bool? enabled,
    Map<String, String>? tags,
    String? version,
    bool? recoverable,
    int? recoverableDays,
    String? contentType,
    List<String>? keyUsage,
    List<String>? enhancedKeyUsage,
    CertificatePolicy? policy,
  }) {
    return CertificateInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      thumbprint: thumbprint ?? this.thumbprint,
      subject: subject ?? this.subject,
      issuer: issuer ?? this.issuer,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      expires: expires ?? this.expires,
      notBefore: notBefore ?? this.notBefore,
      enabled: enabled ?? this.enabled,
      tags: tags ?? this.tags,
      version: version ?? this.version,
      recoverable: recoverable ?? this.recoverable,
      recoverableDays: recoverableDays ?? this.recoverableDays,
      contentType: contentType ?? this.contentType,
      keyUsage: keyUsage ?? this.keyUsage,
      enhancedKeyUsage: enhancedKeyUsage ?? this.enhancedKeyUsage,
      policy: policy ?? this.policy,
    );
  }

  /// Gets the status of the certificate (Active, Expired, etc.)
  String get status {
    if (enabled == false) return 'Disabled';
    if (expires != null && DateTime.now().isAfter(expires!)) return 'Expired';
    if (notBefore != null && DateTime.now().isBefore(notBefore!)) return 'Not Active';
    return 'Active';
  }

  /// Gets the key usage as a formatted string
  String get keyUsageString {
    if (keyUsage == null || keyUsage!.isEmpty) return 'None';
    return keyUsage!.join(', ');
  }

  /// Gets the enhanced key usage as a formatted string
  String get enhancedKeyUsageString {
    if (enhancedKeyUsage == null || enhancedKeyUsage!.isEmpty) return 'None';
    return enhancedKeyUsage!.join(', ');
  }

  /// Gets the days until expiration (negative if expired)
  int? get daysUntilExpiration {
    if (expires == null) return null;
    return expires!.difference(DateTime.now()).inDays;
  }
}

/// Represents certificate policy information
@JsonSerializable()
class CertificatePolicy {
  final String? issuerName;
  final String? certificateType;
  final bool? certificateTransparency;
  final String? contentType;
  final String? subject;
  final List<String>? subjectAlternativeNames;
  final int? validityInMonths;
  final KeyProperties? keyProperties;
  final SecretProperties? secretProperties;
  final X509CertificateProperties? x509CertificateProperties;
  final LifetimeAction? lifetimeAction;

  const CertificatePolicy({
    this.issuerName,
    this.certificateType,
    this.certificateTransparency,
    this.contentType,
    this.subject,
    this.subjectAlternativeNames,
    this.validityInMonths,
    this.keyProperties,
    this.secretProperties,
    this.x509CertificateProperties,
    this.lifetimeAction,
  });

  factory CertificatePolicy.fromJson(Map<String, dynamic> json) => _$CertificatePolicyFromJson(json);
  Map<String, dynamic> toJson() => _$CertificatePolicyToJson(this);
}

/// Represents key properties in certificate policy
@JsonSerializable()
class KeyProperties {
  final bool? exportable;
  final String? keyType;
  final int? keySize;
  final bool? reuseKey;
  final String? curve;

  const KeyProperties({
    this.exportable,
    this.keyType,
    this.keySize,
    this.reuseKey,
    this.curve,
  });

  factory KeyProperties.fromJson(Map<String, dynamic> json) => _$KeyPropertiesFromJson(json);
  Map<String, dynamic> toJson() => _$KeyPropertiesToJson(this);
}

/// Represents secret properties in certificate policy
@JsonSerializable()
class SecretProperties {
  final String? contentType;

  const SecretProperties({
    this.contentType,
  });

  factory SecretProperties.fromJson(Map<String, dynamic> json) => _$SecretPropertiesFromJson(json);
  Map<String, dynamic> toJson() => _$SecretPropertiesToJson(this);
}

/// Represents X.509 certificate properties
@JsonSerializable()
class X509CertificateProperties {
  final String? subject;
  final List<String>? subjectAlternativeNames;
  final List<String>? keyUsage;
  final List<String>? enhancedKeyUsage;
  final int? validityInMonths;

  const X509CertificateProperties({
    this.subject,
    this.subjectAlternativeNames,
    this.keyUsage,
    this.enhancedKeyUsage,
    this.validityInMonths,
  });

  factory X509CertificateProperties.fromJson(Map<String, dynamic> json) => _$X509CertificatePropertiesFromJson(json);
  Map<String, dynamic> toJson() => _$X509CertificatePropertiesToJson(this);
}

/// Represents lifetime action in certificate policy
@JsonSerializable()
class LifetimeAction {
  final String? action;
  final int? daysBeforeExpiry;
  final int? lifetimePercentage;

  const LifetimeAction({
    this.action,
    this.daysBeforeExpiry,
    this.lifetimePercentage,
  });

  factory LifetimeAction.fromJson(Map<String, dynamic> json) => _$LifetimeActionFromJson(json);
  Map<String, dynamic> toJson() => _$LifetimeActionToJson(this);
}

/// Represents the parameters for creating a new certificate
@JsonSerializable()
class CreateCertificateRequest {
  final String name;
  final CertificatePolicy policy;
  final Map<String, String>? tags;
  final bool? enabled;

  const CreateCertificateRequest({
    required this.name,
    required this.policy,
    this.tags,
    this.enabled,
  });

  factory CreateCertificateRequest.fromJson(Map<String, dynamic> json) => _$CreateCertificateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCertificateRequestToJson(this);
}

/// Represents the parameters for updating an existing certificate
@JsonSerializable()
class UpdateCertificateRequest {
  final Map<String, String>? tags;
  final bool? enabled;
  final CertificatePolicy? policy;

  const UpdateCertificateRequest({
    this.tags,
    this.enabled,
    this.policy,
  });

  factory UpdateCertificateRequest.fromJson(Map<String, dynamic> json) => _$UpdateCertificateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateCertificateRequestToJson(this);
}

/// Represents the parameters for importing a certificate
@JsonSerializable()
class ImportCertificateRequest {
  final String name;
  final String certificateData;
  final String? password;
  final CertificatePolicy? policy;
  final Map<String, String>? tags;
  final bool? enabled;

  const ImportCertificateRequest({
    required this.name,
    required this.certificateData,
    this.password,
    this.policy,
    this.tags,
    this.enabled,
  });

  factory ImportCertificateRequest.fromJson(Map<String, dynamic> json) => _$ImportCertificateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ImportCertificateRequestToJson(this);
}

/// Exception thrown when certificate operations fail
class CertificateException implements Exception {
  final String message;
  final String? errorCode;
  final dynamic originalError;

  const CertificateException(this.message, [this.errorCode, this.originalError]);

  @override
  String toString() => 'CertificateException: $message${errorCode != null ? ' ($errorCode)' : ''}';
}

/// Enum for certificate content types
enum CertificateContentType {
  pkcs12('application/x-pkcs12'),
  pem('application/x-pem-file');

  const CertificateContentType(this.value);
  final String value;

  static CertificateContentType fromString(String value) {
    return CertificateContentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown content type: $value'),
    );
  }
}

/// Enum for certificate key usage
enum CertificateKeyUsage {
  digitalSignature('digitalSignature'),
  nonRepudiation('nonRepudiation'),
  keyEncipherment('keyEncipherment'),
  dataEncipherment('dataEncipherment'),
  keyAgreement('keyAgreement'),
  keyCertSign('keyCertSign'),
  crlSign('crlSign'),
  encipherOnly('encipherOnly'),
  decipherOnly('decipherOnly');

  const CertificateKeyUsage(this.value);
  final String value;

  static CertificateKeyUsage fromString(String value) {
    return CertificateKeyUsage.values.firstWhere(
      (usage) => usage.value == value,
      orElse: () => throw ArgumentError('Unknown key usage: $value'),
    );
  }
}

/// Enum for enhanced key usage
enum EnhancedKeyUsage {
  serverAuthentication('1.3.6.1.5.5.7.3.1'),
  clientAuthentication('1.3.6.1.5.5.7.3.2'),
  codeSigning('1.3.6.1.5.5.7.3.3'),
  emailProtection('1.3.6.1.5.5.7.3.4'),
  timeStamping('1.3.6.1.5.5.7.3.8'),
  ocspSigning('1.3.6.1.5.5.7.3.9');

  const EnhancedKeyUsage(this.value);
  final String value;

  static EnhancedKeyUsage fromString(String value) {
    return EnhancedKeyUsage.values.firstWhere(
      (usage) => usage.value == value,
      orElse: () => throw ArgumentError('Unknown enhanced key usage: $value'),
    );
  }
}