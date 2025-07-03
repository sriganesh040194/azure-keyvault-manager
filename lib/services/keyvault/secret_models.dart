import 'package:json_annotation/json_annotation.dart';

part 'secret_models.g.dart';

@JsonSerializable()
class SecretInfo {
  final String id;
  final String name;
  final String? contentType;
  final bool? enabled;
  final DateTime? created;
  final DateTime? updated;
  final DateTime? expires;
  final DateTime? notBefore;
  final String? recoveryLevel;
  final Map<String, String>? tags;

  const SecretInfo({
    required this.id,
    required this.name,
    this.contentType,
    this.enabled,
    this.created,
    this.updated,
    this.expires,
    this.notBefore,
    this.recoveryLevel,
    this.tags,
  });

  factory SecretInfo.fromJson(Map<String, dynamic> json) => _$SecretInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SecretInfoToJson(this);

  // Helper method to check if secret is expired
  bool get isExpired => expires != null && DateTime.now().isAfter(expires!);

  // Helper method to get days until expiration
  int? get daysUntilExpiration {
    if (expires == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expires!)) {
      return -now.difference(expires!).inDays;
    }
    return expires!.difference(now).inDays;
  }

  // Helper method to get status
  String get status {
    if (enabled == false) return 'Disabled';
    if (isExpired) return 'Expired';
    if (notBefore != null && DateTime.now().isBefore(notBefore!)) return 'Not Active';
    return 'Active';
  }
}

@JsonSerializable()
class SecretValue {
  final String id;
  final String value;
  final String? contentType;
  final Map<String, String>? tags;

  const SecretValue({
    required this.id,
    required this.value,
    this.contentType,
    this.tags,
  });

  factory SecretValue.fromJson(Map<String, dynamic> json) => _$SecretValueFromJson(json);
  Map<String, dynamic> toJson() => _$SecretValueToJson(this);
}

@JsonSerializable()
class CreateSecretRequest {
  final String name;
  final String value;
  final String? contentType;
  final bool? enabled;
  final DateTime? expires;
  final DateTime? notBefore;
  final Map<String, String>? tags;

  const CreateSecretRequest({
    required this.name,
    required this.value,
    this.contentType,
    this.enabled = true,
    this.expires,
    this.notBefore,
    this.tags,
  });

  factory CreateSecretRequest.fromJson(Map<String, dynamic> json) => _$CreateSecretRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateSecretRequestToJson(this);
}

@JsonSerializable()
class UpdateSecretRequest {
  final String? contentType;
  final bool? enabled;
  final DateTime? expires;
  final DateTime? notBefore;
  final Map<String, String>? tags;

  const UpdateSecretRequest({
    this.contentType,
    this.enabled,
    this.expires,
    this.notBefore,
    this.tags,
  });

  factory UpdateSecretRequest.fromJson(Map<String, dynamic> json) => _$UpdateSecretRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateSecretRequestToJson(this);
}

@JsonSerializable()
class SecretVersion {
  final String id;
  final String version;
  final DateTime? created;
  final DateTime? updated;
  final DateTime? expires;
  final DateTime? notBefore;
  final bool? enabled;
  final String? recoveryLevel;
  final Map<String, String>? tags;

  const SecretVersion({
    required this.id,
    required this.version,
    this.created,
    this.updated,
    this.expires,
    this.notBefore,
    this.enabled,
    this.recoveryLevel,
    this.tags,
  });

  factory SecretVersion.fromJson(Map<String, dynamic> json) => _$SecretVersionFromJson(json);
  Map<String, dynamic> toJson() => _$SecretVersionToJson(this);
}

// Enums for content types
enum SecretContentType {
  @JsonValue('text/plain')
  textPlain('text/plain'),
  @JsonValue('application/json')
  applicationJson('application/json'),
  @JsonValue('application/x-pkcs12')
  applicationPkcs12('application/x-pkcs12'),
  @JsonValue('application/x-pem-file')
  applicationPemFile('application/x-pem-file');

  const SecretContentType(this.value);
  final String value;

  static SecretContentType? fromString(String? value) {
    if (value == null) return null;
    for (final type in SecretContentType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}