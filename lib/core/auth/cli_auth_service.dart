import 'dart:async';
import 'dart:convert';
import '../logging/app_logger.dart';
import '../../services/azure_cli/azure_cli_service.dart';
import 'auth_models.dart';
import 'secure_storage_service.dart';

class CliAuthService {
  final AzureCliService _azureCliService;
  final SecureStorageService _secureStorage;
  final StreamController<AuthState> _authStateController = StreamController<AuthState>.broadcast();
  
  UserInfo? _currentUser;
  Timer? _sessionCheckTimer;
  
  CliAuthService({
    AzureCliService? azureCliService,
    SecureStorageService? secureStorage,
  }) : _azureCliService = azureCliService ?? AzureCliService(),
       _secureStorage = secureStorage ?? SecureStorageService() {
    _initializeAuth();
  }

  // Streams
  Stream<AuthState> get authStateStream => _authStateController.stream;
  
  // Getters
  UserInfo? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Initializes authentication state by checking Azure CLI login status
  Future<void> _initializeAuth() async {
    try {
      _authStateController.add(AuthState.loading);
      
      // Check if Azure CLI is authenticated
      final isAuthenticated = await _checkAzureCliAuthentication();
      
      if (isAuthenticated) {
        await _loadUserInfo();
        _setupSessionCheck();
        _authStateController.add(AuthState.authenticated);
        AppLogger.authEvent('User auto-authenticated via Azure CLI', _currentUser?.id ?? 'unknown');
      } else {
        _authStateController.add(AuthState.unauthenticated);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize CLI auth', e, stackTrace);
      _authStateController.add(AuthState.error);
    }
  }

  /// Checks if Azure CLI is authenticated
  Future<bool> _checkAzureCliAuthentication() async {
    try {
      final result = await _azureCliService.executeCommand('az account show');
      return result.success;
    } catch (e) {
      AppLogger.error('Error checking Azure CLI authentication', e);
      return false;
    }
  }

  /// Loads user information from Azure CLI
  Future<void> _loadUserInfo() async {
    try {
      // Get account information
      final accountResult = await _azureCliService.executeCommand('az account show');
      if (!accountResult.success) {
        throw Exception('Failed to get account information: ${accountResult.error}');
      }

      final accountData = json.decode(accountResult.output) as Map<String, dynamic>;
      
      // Get additional user information if possible
      final userResult = await _azureCliService.executeCommand('az ad signed-in-user show');
      Map<String, dynamic>? userData;
      
      if (userResult.success) {
        try {
          userData = json.decode(userResult.output) as Map<String, dynamic>;
        } catch (e) {
          AppLogger.warning('Could not parse user data, using account data only');
        }
      }

      // Create user info from available data
      _currentUser = UserInfo(
        id: userData?['id'] as String? ?? accountData['user']?['name'] as String? ?? 'unknown',
        email: userData?['mail'] as String? ?? 
               userData?['userPrincipalName'] as String? ?? 
               accountData['user']?['name'] as String? ?? 'unknown@unknown.com',
        name: userData?['displayName'] as String? ?? 
              userData?['givenName'] as String? ?? 
              accountData['user']?['name']?.split('@')[0] as String? ?? 'Unknown User',
        tenantId: accountData['tenantId'] as String? ?? '',
        roles: [], // Roles would need to be fetched separately if needed
        lastLogin: DateTime.now(),
      );

      // Store user info securely
      await _secureStorage.storeUserInfo(_currentUser!);
      await _secureStorage.generateSessionKey();
      
      AppLogger.authEvent('User info loaded from Azure CLI', _currentUser!.id);
      
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load user info from Azure CLI', e, stackTrace);
      throw Exception('Failed to load user information: $e');
    }
  }

  /// Performs Azure CLI interactive login
  Future<void> login() async {
    try {
      _authStateController.add(AuthState.loading);
      AppLogger.info('Starting Azure CLI interactive login');
      
      // Execute az login command
      final result = await _azureCliService.executeCommand(
        'az login',
        timeout: const Duration(minutes: 5), // Allow time for interactive login
      );

      if (result.success) {
        // Load user information after successful login
        await _loadUserInfo();
        _setupSessionCheck();
        _authStateController.add(AuthState.authenticated);
        AppLogger.authEvent('User logged in via Azure CLI', _currentUser?.id ?? 'unknown');
      } else {
        _authStateController.add(AuthState.error);
        AppLogger.error('Azure CLI login failed', result.error);
        throw Exception('Login failed: ${result.error}');
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('CLI login failed', e, stackTrace);
      _authStateController.add(AuthState.error);
      rethrow;
    }
  }

  /// Performs Azure CLI logout
  Future<void> logout() async {
    try {
      _sessionCheckTimer?.cancel();
      
      // Execute az logout command
      final result = await _azureCliService.executeCommand('az logout');
      
      if (!result.success) {
        AppLogger.warning('Azure CLI logout command failed, but continuing cleanup: ${result.error}');
      }
      
      // Clear stored data
      await _secureStorage.clearAuthData();
      
      _currentUser = null;
      _authStateController.add(AuthState.unauthenticated);
      
      AppLogger.authEvent('User logged out via Azure CLI', 'system');
      
    } catch (e, stackTrace) {
      AppLogger.error('CLI logout failed', e, stackTrace);
      _authStateController.add(AuthState.error);
    }
  }

  /// Checks if the current session is still valid
  Future<bool> checkSession() async {
    try {
      final isAuthenticated = await _checkAzureCliAuthentication();
      
      if (!isAuthenticated && _currentUser != null) {
        // Session expired
        _currentUser = null;
        await _secureStorage.clearAuthData();
        _authStateController.add(AuthState.sessionExpired);
        AppLogger.authEvent('Session expired', 'system');
        return false;
      }
      
      return isAuthenticated;
    } catch (e) {
      AppLogger.error('Error checking session', e);
      return false;
    }
  }

  /// Sets up periodic session validation
  void _setupSessionCheck() {
    _sessionCheckTimer?.cancel();
    
    // Check session every 5 minutes
    _sessionCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) async {
        await checkSession();
      },
    );
  }

  /// Gets current Azure subscription information
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final result = await _azureCliService.executeCommand('az account show');
      
      if (result.success) {
        return json.decode(result.output) as Map<String, dynamic>;
      } else {
        AppLogger.error('Failed to get current subscription', result.error);
        return null;
      }
    } catch (e) {
      AppLogger.error('Error getting current subscription', e);
      return null;
    }
  }

  /// Lists available subscriptions
  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    try {
      final result = await _azureCliService.executeCommand('az account list');
      
      if (result.success) {
        final subscriptions = json.decode(result.output) as List;
        return subscriptions.cast<Map<String, dynamic>>();
      } else {
        AppLogger.error('Failed to get subscriptions', result.error);
        return [];
      }
    } catch (e) {
      AppLogger.error('Error getting subscriptions', e);
      return [];
    }
  }

  /// Sets the active subscription
  Future<bool> setSubscription(String subscriptionId) async {
    try {
      final result = await _azureCliService.executeCommand(
        'az account set --subscription "$subscriptionId"'
      );
      
      if (result.success) {
        AppLogger.info('Switched to subscription: $subscriptionId');
        return true;
      } else {
        AppLogger.error('Failed to set subscription', result.error);
        return false;
      }
    } catch (e) {
      AppLogger.error('Error setting subscription', e);
      return false;
    }
  }

  /// Gets Azure CLI version information
  Future<String?> getAzureCliVersion() async {
    try {
      final result = await _azureCliService.executeCommand('az --version');
      
      if (result.success) {
        // Extract version from output
        final lines = result.output.split('\n');
        final versionLine = lines.firstWhere(
          (line) => line.startsWith('azure-cli'),
          orElse: () => '',
        );
        
        if (versionLine.isNotEmpty) {
          final parts = versionLine.split(' ');
          return parts.length > 1 ? parts[1] : null;
        }
      }
      
      return null;
    } catch (e) {
      AppLogger.error('Error getting Azure CLI version', e);
      return null;
    }
  }

  /// Checks if Azure CLI has required extensions
  Future<bool> checkRequiredExtensions() async {
    try {
      final result = await _azureCliService.executeCommand('az extension list');
      
      if (result.success) {
        final extensions = json.decode(result.output) as List;
        
        // Check for any required extensions here
        // For now, just return true as basic Key Vault operations don't require extensions
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Error checking extensions', e);
      return false;
    }
  }

  /// Validates that the user has necessary permissions
  Future<bool> validatePermissions() async {
    try {
      // Try to list Key Vaults as a permission check
      final result = await _azureCliService.listKeyVaults();
      
      if (result.success) {
        return true;
      } else if (result.error.contains('Forbidden') || result.error.contains('insufficient')) {
        AppLogger.warning('User may not have sufficient Key Vault permissions');
        return false;
      }
      
      // Other errors might be temporary, so we'll assume permissions are OK
      return true;
    } catch (e) {
      AppLogger.error('Error validating permissions', e);
      return false;
    }
  }

  /// Gets authentication status details
  Future<Map<String, dynamic>> getAuthStatus() async {
    final isAuthenticated = await _checkAzureCliAuthentication();
    final version = await getAzureCliVersion();
    final subscription = await getCurrentSubscription();
    final hasPermissions = isAuthenticated ? await validatePermissions() : false;
    
    return {
      'isAuthenticated': isAuthenticated,
      'azureCliVersion': version,
      'currentSubscription': subscription,
      'hasPermissions': hasPermissions,
      'user': _currentUser?.toJson(),
    };
  }

  /// Disposes resources
  void dispose() {
    _sessionCheckTimer?.cancel();
    _authStateController.close();
  }
}