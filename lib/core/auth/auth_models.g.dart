// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  tenantId: json['tenantId'] as String,
  roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
  lastLogin: DateTime.parse(json['lastLogin'] as String),
);

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'tenantId': instance.tenantId,
  'roles': instance.roles,
  'lastLogin': instance.lastLogin.toIso8601String(),
};

AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => AuthTokens(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  tokenType: json['tokenType'] as String,
  scopes: (json['scopes'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$AuthTokensToJson(AuthTokens instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'tokenType': instance.tokenType,
      'scopes': instance.scopes,
    };

AzureAdConfig _$AzureAdConfigFromJson(Map<String, dynamic> json) =>
    AzureAdConfig(
      tenantId: json['tenantId'] as String,
      clientId: json['clientId'] as String,
      redirectUri: json['redirectUri'] as String,
      scopes: (json['scopes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      authorityUrl: json['authorityUrl'] as String,
    );

Map<String, dynamic> _$AzureAdConfigToJson(AzureAdConfig instance) =>
    <String, dynamic>{
      'tenantId': instance.tenantId,
      'clientId': instance.clientId,
      'redirectUri': instance.redirectUri,
      'scopes': instance.scopes,
      'authorityUrl': instance.authorityUrl,
    };
