import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class UserInfo {
  final String id;
  final String email;
  final String name;
  final String tenantId;
  final List<String> roles;
  final DateTime lastLogin;

  UserInfo({
    required this.id,
    required this.email,
    required this.name,
    required this.tenantId,
    required this.roles,
    required this.lastLogin,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);

  UserInfo copyWith({
    String? id,
    String? email,
    String? name,
    String? tenantId,
    List<String>? roles,
    DateTime? lastLogin,
  }) {
    return UserInfo(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      tenantId: tenantId ?? this.tenantId,
      roles: roles ?? this.roles,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

@JsonSerializable()
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String tokenType;
  final List<String> scopes;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.tokenType,
    required this.scopes,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => _$AuthTokensFromJson(json);
  Map<String, dynamic> toJson() => _$AuthTokensToJson(this);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isExpiringSoon => DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? tokenType,
    List<String>? scopes,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      tokenType: tokenType ?? this.tokenType,
      scopes: scopes ?? this.scopes,
    );
  }
}

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  sessionExpired,
}

class AuthException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  AuthException({
    required this.message,
    required this.code,
    this.originalError,
  });

  @override
  String toString() => 'AuthException: $code - $message';
}

@JsonSerializable()
class AzureAdConfig {
  final String tenantId;
  final String clientId;
  final String redirectUri;
  final List<String> scopes;
  final String authorityUrl;

  AzureAdConfig({
    required this.tenantId,
    required this.clientId,
    required this.redirectUri,
    required this.scopes,
    required this.authorityUrl,
  });

  factory AzureAdConfig.fromJson(Map<String, dynamic> json) => _$AzureAdConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AzureAdConfigToJson(this);

  String get authorizationUrl => '$authorityUrl/$tenantId/oauth2/v2.0/authorize';
  String get tokenUrl => '$authorityUrl/$tenantId/oauth2/v2.0/token';
}