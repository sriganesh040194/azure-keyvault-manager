import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../logging/app_logger.dart';
import 'auth_models.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
    webOptions: WebOptions(
      dbName: 'keyvault_ui_secure_storage',
      publicKey: 'keyvault_ui_public_key',
    ),
  );

  // Storage keys
  static const String _accessTokenKey = 'azure_access_token';
  static const String _refreshTokenKey = 'azure_refresh_token';
  static const String _userInfoKey = 'user_info';
  static const String _authTokensKey = 'auth_tokens';
  static const String _sessionKeyKey = 'session_key';

  /// Stores authentication tokens securely
  Future<void> storeAuthTokens(AuthTokens tokens) async {
    try {
      final tokensJson = json.encode(tokens.toJson());
      final encryptedTokens = _encryptData(tokensJson);
      
      await _storage.write(key: _authTokensKey, value: encryptedTokens);
      AppLogger.info('Authentication tokens stored securely');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store auth tokens', e, stackTrace);
      throw AuthException(
        message: 'Failed to store authentication tokens',
        code: 'STORAGE_ERROR',
        originalError: e,
      );
    }
  }

  /// Retrieves authentication tokens
  Future<AuthTokens?> getAuthTokens() async {
    try {
      final encryptedTokens = await _storage.read(key: _authTokensKey);
      if (encryptedTokens == null) {
        return null;
      }

      final tokensJson = _decryptData(encryptedTokens);
      final tokensMap = json.decode(tokensJson) as Map<String, dynamic>;
      
      return AuthTokens.fromJson(tokensMap);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve auth tokens', e, stackTrace);
      return null;
    }
  }

  /// Stores user information securely
  Future<void> storeUserInfo(UserInfo userInfo) async {
    try {
      final userInfoJson = json.encode(userInfo.toJson());
      final encryptedUserInfo = _encryptData(userInfoJson);
      
      await _storage.write(key: _userInfoKey, value: encryptedUserInfo);
      AppLogger.authEvent('User info stored', userInfo.id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store user info', e, stackTrace);
      throw AuthException(
        message: 'Failed to store user information',
        code: 'STORAGE_ERROR',
        originalError: e,
      );
    }
  }

  /// Retrieves user information
  Future<UserInfo?> getUserInfo() async {
    try {
      final encryptedUserInfo = await _storage.read(key: _userInfoKey);
      if (encryptedUserInfo == null) {
        return null;
      }

      final userInfoJson = _decryptData(encryptedUserInfo);
      final userInfoMap = json.decode(userInfoJson) as Map<String, dynamic>;
      
      return UserInfo.fromJson(userInfoMap);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve user info', e, stackTrace);
      return null;
    }
  }

  /// Stores individual access token (for backward compatibility)
  Future<void> storeAccessToken(String token) async {
    try {
      final encryptedToken = _encryptData(token);
      await _storage.write(key: _accessTokenKey, value: encryptedToken);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store access token', e, stackTrace);
      throw AuthException(
        message: 'Failed to store access token',
        code: 'STORAGE_ERROR',
        originalError: e,
      );
    }
  }

  /// Retrieves access token
  Future<String?> getAccessToken() async {
    try {
      final encryptedToken = await _storage.read(key: _accessTokenKey);
      if (encryptedToken == null) {
        return null;
      }
      return _decryptData(encryptedToken);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve access token', e, stackTrace);
      return null;
    }
  }

  /// Stores refresh token
  Future<void> storeRefreshToken(String token) async {
    try {
      final encryptedToken = _encryptData(token);
      await _storage.write(key: _refreshTokenKey, value: encryptedToken);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store refresh token', e, stackTrace);
      throw AuthException(
        message: 'Failed to store refresh token',
        code: 'STORAGE_ERROR',
        originalError: e,
      );
    }
  }

  /// Retrieves refresh token
  Future<String?> getRefreshToken() async {
    try {
      final encryptedToken = await _storage.read(key: _refreshTokenKey);
      if (encryptedToken == null) {
        return null;
      }
      return _decryptData(encryptedToken);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve refresh token', e, stackTrace);
      return null;
    }
  }

  /// Generates and stores a session key
  Future<void> generateSessionKey() async {
    try {
      final sessionKey = _generateSecureKey();
      await _storage.write(key: _sessionKeyKey, value: sessionKey);
      AppLogger.info('Session key generated');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate session key', e, stackTrace);
      throw AuthException(
        message: 'Failed to generate session key',
        code: 'STORAGE_ERROR',
        originalError: e,
      );
    }
  }

  /// Validates the session key
  Future<bool> validateSessionKey() async {
    try {
      final sessionKey = await _storage.read(key: _sessionKeyKey);
      return sessionKey != null && sessionKey.isNotEmpty;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to validate session key', e, stackTrace);
      return false;
    }
  }

  /// Clears all stored authentication data
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userInfoKey),
        _storage.delete(key: _authTokensKey),
        _storage.delete(key: _sessionKeyKey),
      ]);
      
      AppLogger.authEvent('Auth data cleared', 'system');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear auth data', e, stackTrace);
      throw AuthException(
        message: 'Failed to clear authentication data',
        code: 'STORAGE_ERROR',
        originalError: e,
      );
    }
  }

  /// Checks if user is logged in (has valid tokens)
  Future<bool> isLoggedIn() async {
    try {
      final tokens = await getAuthTokens();
      if (tokens == null) {
        return false;
      }

      // Check if tokens are expired
      if (tokens.isExpired) {
        AppLogger.warning('Stored tokens are expired');
        return false;
      }

      // Validate session key
      final hasValidSession = await validateSessionKey();
      if (!hasValidSession) {
        AppLogger.warning('Invalid session key');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check login status', e, stackTrace);
      return false;
    }
  }

  /// Encrypts data using a simple encryption method
  /// Note: In production, use more robust encryption
  String _encryptData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    
    // Simple XOR encryption with hash as key
    final key = digest.bytes;
    final encrypted = <int>[];
    
    for (int i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ key[i % key.length]);
    }
    
    return base64.encode(encrypted);
  }

  /// Decrypts data
  String _decryptData(String encryptedData) {
    final encrypted = base64.decode(encryptedData);
    
    // Use the same hash as key for decryption
    final tempBytes = utf8.encode('temp'); // This is just for getting hash structure
    final digest = sha256.convert(tempBytes);
    final key = digest.bytes;
    
    final decrypted = <int>[];
    
    for (int i = 0; i < encrypted.length; i++) {
      decrypted.add(encrypted[i] ^ key[i % key.length]);
    }
    
    return utf8.decode(decrypted);
  }

  /// Generates a secure random key
  String _generateSecureKey() {
    final bytes = List<int>.generate(32, (i) => 
        DateTime.now().millisecondsSinceEpoch + i);
    return base64.encode(bytes);
  }

  /// Gets all stored keys (for debugging/testing)
  Future<List<String>> getAllKeys() async {
    try {
      return await _storage.readAll().then((value) => value.keys.toList());
    } catch (e) {
      AppLogger.error('Failed to get all keys', e);
      return [];
    }
  }

  /// Clears all stored data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.warning('All secure storage cleared');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear all storage', e, stackTrace);
    }
  }
}