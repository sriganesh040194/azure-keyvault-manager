import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:uuid/uuid.dart';
import '../logging/app_logger.dart';
import '../../shared/constants/app_constants.dart';
import 'auth_models.dart';
import 'secure_storage_service.dart';

class AuthService {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  final StreamController<AuthState> _authStateController = StreamController<AuthState>.broadcast();
  
  UserInfo? _currentUser;
  AuthTokens? _currentTokens;
  Timer? _tokenRefreshTimer;
  
  AuthService({
    Dio? dio,
    SecureStorageService? secureStorage,
  }) : _dio = dio ?? Dio(),
       _secureStorage = secureStorage ?? SecureStorageService() {
    _setupInterceptors();
    _initializeAuth();
  }

  // Streams
  Stream<AuthState> get authStateStream => _authStateController.stream;
  
  // Getters
  UserInfo? get currentUser => _currentUser;
  AuthTokens? get currentTokens => _currentTokens;
  bool get isAuthenticated => _currentUser != null && _currentTokens != null && !_currentTokens!.isExpired;

  /// Initializes authentication state from stored data
  Future<void> _initializeAuth() async {
    try {
      _authStateController.add(AuthState.loading);
      
      // Check if user is already logged in
      final isLoggedIn = await _secureStorage.isLoggedIn();
      if (!isLoggedIn) {
        _authStateController.add(AuthState.unauthenticated);
        return;
      }

      // Load stored user info and tokens
      final storedTokens = await _secureStorage.getAuthTokens();
      final storedUser = await _secureStorage.getUserInfo();

      if (storedTokens != null && storedUser != null) {
        _currentTokens = storedTokens;
        _currentUser = storedUser;

        // Check if tokens need refresh
        if (storedTokens.isExpiringSoon) {
          await _refreshTokens();
        }

        _setupTokenRefreshTimer();
        _authStateController.add(AuthState.authenticated);
        AppLogger.authEvent('User auto-logged in', storedUser.id);
      } else {
        _authStateController.add(AuthState.unauthenticated);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize auth', e, stackTrace);
      _authStateController.add(AuthState.error);
    }
  }

  /// Starts the OAuth 2.0 login flow
  Future<void> login() async {
    try {
      _authStateController.add(AuthState.loading);
      
      final config = _getAzureAdConfig();
      final state = const Uuid().v4();
      final nonce = const Uuid().v4();
      
      // Build authorization URL
      final authUrl = Uri.parse(config.authorizationUrl).replace(
        queryParameters: {
          'client_id': config.clientId,
          'redirect_uri': config.redirectUri,
          'response_type': 'code',
          'scope': config.scopes.join(' '),
          'state': state,
          'nonce': nonce,
          'response_mode': 'query',
        },
      );

      AppLogger.info('Starting OAuth login flow');
      
      // Store state for validation
      await _secureStorage.storeAccessToken(state); // Temporary storage
      
      // Open authorization URL in a popup
      final popup = html.window.open(
        authUrl.toString(),
        'oauth_login',
        'width=500,height=600,scrollbars=yes,resizable=yes',
      );

      // Listen for popup completion
      await _listenForAuthorizationCode(popup, state);
      
    } catch (e, stackTrace) {
      AppLogger.error('Login failed', e, stackTrace);
      _authStateController.add(AuthState.error);
      throw AuthException(
        message: 'Login failed: ${e.toString()}',
        code: 'LOGIN_ERROR',
        originalError: e,
      );
    }
  }

  /// Listens for the authorization code from the popup
  Future<void> _listenForAuthorizationCode(html.WindowBase popup, String expectedState) async {
    final completer = Completer<void>();
    Timer? timeoutTimer;
    Timer? pollTimer;

    timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (!completer.isCompleted) {
        popup.close();
        completer.completeError(AuthException(
          message: 'Login timeout',
          code: 'LOGIN_TIMEOUT',
        ));
      }
    });

    pollTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      try {
        if (popup.closed!) {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.completeError(AuthException(
              message: 'Login cancelled by user',
              code: 'LOGIN_CANCELLED',
            ));
          }
          return;
        }

        // Check if popup has navigated to redirect URI
        final location = popup.location?.href;
        if (location != null && location.startsWith(AppConstants.azureAdRedirectUri)) {
          timer.cancel();
          popup.close();
          
          // Parse the URL for authorization code
          final uri = Uri.parse(location);
          final code = uri.queryParameters['code'];
          final state = uri.queryParameters['state'];
          final error = uri.queryParameters['error'];

          if (error != null) {
            completer.completeError(AuthException(
              message: 'Authorization error: $error',
              code: 'AUTH_ERROR',
            ));
            return;
          }

          if (code == null || state == null) {
            completer.completeError(AuthException(
              message: 'Missing authorization code or state',
              code: 'INVALID_RESPONSE',
            ));
            return;
          }

          if (state != expectedState) {
            completer.completeError(AuthException(
              message: 'Invalid state parameter',
              code: 'INVALID_STATE',
            ));
            return;
          }

          // Exchange code for tokens
          _exchangeCodeForTokens(code).then((_) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          }).catchError((e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          });
        }
      } catch (e) {
        // Ignore errors from accessing popup properties when it's closed
      }
    });

    try {
      await completer.future;
    } finally {
      timeoutTimer?.cancel();
      pollTimer?.cancel();
    }
  }

  /// Exchanges authorization code for access tokens
  Future<void> _exchangeCodeForTokens(String code) async {
    try {
      final config = _getAzureAdConfig();
      
      final response = await _dio.post(
        config.tokenUrl,
        data: {
          'client_id': config.clientId,
          'code': code,
          'redirect_uri': config.redirectUri,
          'grant_type': 'authorization_code',
          'scope': config.scopes.join(' '),
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      final tokenData = response.data as Map<String, dynamic>;
      
      // Parse tokens
      final accessToken = tokenData['access_token'] as String;
      final refreshToken = tokenData['refresh_token'] as String?;
      final expiresIn = tokenData['expires_in'] as int;
      final tokenType = tokenData['token_type'] as String? ?? 'Bearer';
      final scope = tokenData['scope'] as String? ?? '';

      // Create AuthTokens object
      final tokens = AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        tokenType: tokenType,
        scopes: scope.split(' ').where((s) => s.isNotEmpty).toList(),
      );

      // Parse user info from token
      final userInfo = _parseUserInfoFromToken(accessToken);
      
      // Store tokens and user info
      await _secureStorage.storeAuthTokens(tokens);
      await _secureStorage.storeUserInfo(userInfo);
      await _secureStorage.generateSessionKey();

      _currentTokens = tokens;
      _currentUser = userInfo;

      _setupTokenRefreshTimer();
      _authStateController.add(AuthState.authenticated);
      
      AppLogger.authEvent('User logged in successfully', userInfo.id);
      
    } catch (e, stackTrace) {
      AppLogger.error('Token exchange failed', e, stackTrace);
      throw AuthException(
        message: 'Failed to exchange authorization code for tokens',
        code: 'TOKEN_EXCHANGE_ERROR',
        originalError: e,
      );
    }
  }

  /// Refreshes the access token using the refresh token
  Future<void> _refreshTokens() async {
    if (_currentTokens?.refreshToken.isEmpty ?? true) {
      throw AuthException(
        message: 'No refresh token available',
        code: 'NO_REFRESH_TOKEN',
      );
    }

    try {
      final config = _getAzureAdConfig();
      
      final response = await _dio.post(
        config.tokenUrl,
        data: {
          'client_id': config.clientId,
          'refresh_token': _currentTokens!.refreshToken,
          'grant_type': 'refresh_token',
          'scope': config.scopes.join(' '),
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      final tokenData = response.data as Map<String, dynamic>;
      
      final accessToken = tokenData['access_token'] as String;
      final refreshToken = tokenData['refresh_token'] as String? ?? _currentTokens!.refreshToken;
      final expiresIn = tokenData['expires_in'] as int;
      final tokenType = tokenData['token_type'] as String? ?? 'Bearer';
      final scope = tokenData['scope'] as String? ?? '';

      final newTokens = AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        tokenType: tokenType,
        scopes: scope.split(' ').where((s) => s.isNotEmpty).toList(),
      );

      await _secureStorage.storeAuthTokens(newTokens);
      _currentTokens = newTokens;

      AppLogger.info('Tokens refreshed successfully');
      
    } catch (e, stackTrace) {
      AppLogger.error('Token refresh failed', e, stackTrace);
      await logout();
      throw AuthException(
        message: 'Failed to refresh tokens',
        code: 'TOKEN_REFRESH_ERROR',
        originalError: e,
      );
    }
  }

  /// Sets up automatic token refresh
  void _setupTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    
    if (_currentTokens != null && !_currentTokens!.isExpired) {
      // Refresh token 5 minutes before expiry
      final refreshTime = _currentTokens!.expiresAt.subtract(const Duration(minutes: 5));
      final delay = refreshTime.difference(DateTime.now());
      
      if (delay.isNegative) {
        // Token is already expiring soon, refresh immediately
        _refreshTokens().catchError((e) {
          AppLogger.error('Automatic token refresh failed', e);
        });
      } else {
        _tokenRefreshTimer = Timer(delay, () {
          _refreshTokens().catchError((e) {
            AppLogger.error('Automatic token refresh failed', e);
          });
        });
      }
    }
  }

  /// Logs out the user
  Future<void> logout() async {
    try {
      _tokenRefreshTimer?.cancel();
      
      await _secureStorage.clearAuthData();
      
      _currentUser = null;
      _currentTokens = null;
      
      _authStateController.add(AuthState.unauthenticated);
      
      AppLogger.authEvent('User logged out', 'system');
      
    } catch (e, stackTrace) {
      AppLogger.error('Logout failed', e, stackTrace);
      _authStateController.add(AuthState.error);
    }
  }

  /// Gets the current access token, refreshing if necessary
  Future<String?> getAccessToken() async {
    if (_currentTokens == null) {
      return null;
    }

    if (_currentTokens!.isExpiringSoon) {
      try {
        await _refreshTokens();
      } catch (e) {
        AppLogger.error('Failed to refresh token when getting access token', e);
        return null;
      }
    }

    return _currentTokens!.accessToken;
  }

  /// Parses user information from JWT token
  UserInfo _parseUserInfoFromToken(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      
      return UserInfo(
        id: decodedToken['oid'] as String? ?? decodedToken['sub'] as String,
        email: decodedToken['email'] as String? ?? decodedToken['preferred_username'] as String,
        name: decodedToken['name'] as String? ?? 'Unknown User',
        tenantId: decodedToken['tid'] as String? ?? '',
        roles: (decodedToken['roles'] as List<dynamic>?)?.cast<String>() ?? [],
        lastLogin: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('Failed to parse user info from token', e);
      throw AuthException(
        message: 'Failed to parse user information',
        code: 'TOKEN_PARSE_ERROR',
        originalError: e,
      );
    }
  }

  /// Gets Azure AD configuration
  AzureAdConfig _getAzureAdConfig() {
    return AzureAdConfig(
      tenantId: AppConstants.azureAdTenantId,
      clientId: AppConstants.azureAdClientId,
      redirectUri: AppConstants.azureAdRedirectUri,
      scopes: [AppConstants.azureAdScope],
      authorityUrl: AppConstants.azureAdAuthorizeUrl,
    );
  }

  /// Sets up HTTP interceptors for automatic token attachment
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token might be expired, try refresh
          try {
            await _refreshTokens();
            final newToken = await getAccessToken();
            if (newToken != null) {
              // Retry the request with new token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await _dio.fetch(opts);
              handler.resolve(retryResponse);
              return;
            }
          } catch (e) {
            AppLogger.error('Failed to refresh token in interceptor', e);
          }
          
          // If refresh failed, logout user
          await logout();
          _authStateController.add(AuthState.sessionExpired);
        }
        handler.next(error);
      },
    ));
  }

  /// Disposes resources
  void dispose() {
    _tokenRefreshTimer?.cancel();
    _authStateController.close();
  }
}