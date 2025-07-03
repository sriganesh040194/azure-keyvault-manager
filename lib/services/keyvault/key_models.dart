import 'package:json_annotation/json_annotation.dart';

part 'key_models.g.dart';

/// Represents a cryptographic key in Azure Key Vault
@JsonSerializable()
class KeyInfo {
  final String id;
  final String name;
  final String type;
  final String? keyType;
  final int? keySize;
  final List<String>? keyOps;
  final String? curve;
  final DateTime? created;
  final DateTime? updated;
  final DateTime? expires;
  final DateTime? notBefore;
  final bool? enabled;
  final Map<String, String>? tags;
  final String? version;
  final bool? recoverable;
  final int? recoverableDays;

  const KeyInfo({
    required this.id,
    required this.name,
    required this.type,
    this.keyType,
    this.keySize,
    this.keyOps,
    this.curve,
    this.created,
    this.updated,
    this.expires,
    this.notBefore,
    this.enabled,
    this.tags,
    this.version,
    this.recoverable,
    this.recoverableDays,
  });

  factory KeyInfo.fromJson(Map<String, dynamic> json) => _$KeyInfoFromJson(json);
  Map<String, dynamic> toJson() => _$KeyInfoToJson(this);

  /// Creates a copy of this KeyInfo with updated fields
  KeyInfo copyWith({
    String? id,
    String? name,
    String? type,
    String? keyType,
    int? keySize,
    List<String>? keyOps,
    String? curve,
    DateTime? created,
    DateTime? updated,
    DateTime? expires,
    DateTime? notBefore,
    bool? enabled,
    Map<String, String>? tags,
    String? version,
    bool? recoverable,
    int? recoverableDays,
  }) {
    return KeyInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      keyType: keyType ?? this.keyType,
      keySize: keySize ?? this.keySize,
      keyOps: keyOps ?? this.keyOps,
      curve: curve ?? this.curve,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      expires: expires ?? this.expires,
      notBefore: notBefore ?? this.notBefore,
      enabled: enabled ?? this.enabled,
      tags: tags ?? this.tags,
      version: version ?? this.version,
      recoverable: recoverable ?? this.recoverable,
      recoverableDays: recoverableDays ?? this.recoverableDays,
    );
  }

  /// Gets the status of the key (Active, Expired, etc.)
  String get status {
    if (enabled == false) return 'Disabled';
    if (expires != null && DateTime.now().isAfter(expires!)) return 'Expired';
    if (notBefore != null && DateTime.now().isBefore(notBefore!)) return 'Not Active';
    return 'Active';
  }

  /// Gets the key operations as a formatted string
  String get operationsString {
    if (keyOps == null || keyOps!.isEmpty) return 'None';
    return keyOps!.join(', ');
  }
}

/// Represents the parameters for creating a new key
@JsonSerializable()
class CreateKeyRequest {
  final String name;
  final String keyType;
  final int? keySize;
  final String? curve;
  final List<String>? keyOps;
  final DateTime? expires;
  final DateTime? notBefore;
  final bool? enabled;
  final Map<String, String>? tags;

  const CreateKeyRequest({
    required this.name,
    required this.keyType,
    this.keySize,
    this.curve,
    this.keyOps,
    this.expires,
    this.notBefore,
    this.enabled,
    this.tags,
  });

  factory CreateKeyRequest.fromJson(Map<String, dynamic> json) => _$CreateKeyRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateKeyRequestToJson(this);
}

/// Represents the parameters for updating an existing key
@JsonSerializable()
class UpdateKeyRequest {
  final List<String>? keyOps;
  final DateTime? expires;
  final DateTime? notBefore;
  final bool? enabled;
  final Map<String, String>? tags;

  const UpdateKeyRequest({
    this.keyOps,
    this.expires,
    this.notBefore,
    this.enabled,
    this.tags,
  });

  factory UpdateKeyRequest.fromJson(Map<String, dynamic> json) => _$UpdateKeyRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateKeyRequestToJson(this);
}

/// Exception thrown when key operations fail
class KeyException implements Exception {
  final String message;
  final String? errorCode;
  final dynamic originalError;

  const KeyException(this.message, [this.errorCode, this.originalError]);

  @override
  String toString() => 'KeyException: $message${errorCode != null ? ' ($errorCode)' : ''}';
}

/// Enum for supported key types
enum KeyType {
  rsa('RSA'),
  rsaHsm('RSA-HSM'),
  ec('EC'),
  ecHsm('EC-HSM'),
  oct('oct'),
  octHsm('oct-HSM');

  const KeyType(this.value);
  final String value;

  static KeyType fromString(String value) {
    return KeyType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown key type: $value'),
    );
  }
}

/// Enum for supported key operations
enum KeyOperation {
  encrypt('encrypt'),
  decrypt('decrypt'),
  sign('sign'),
  verify('verify'),
  wrapKey('wrapKey'),
  unwrapKey('unwrapKey'),
  import('import');

  const KeyOperation(this.value);
  final String value;

  static KeyOperation fromString(String value) {
    return KeyOperation.values.firstWhere(
      (op) => op.value == value,
      orElse: () => throw ArgumentError('Unknown key operation: $value'),
    );
  }
}

/// Enum for supported elliptic curves
enum EllipticCurve {
  p256('P-256'),
  p384('P-384'),
  p521('P-521'),
  p256k('P-256K');

  const EllipticCurve(this.value);
  final String value;

  static EllipticCurve fromString(String value) {
    return EllipticCurve.values.firstWhere(
      (curve) => curve.value == value,
      orElse: () => throw ArgumentError('Unknown curve: $value'),
    );
  }
}