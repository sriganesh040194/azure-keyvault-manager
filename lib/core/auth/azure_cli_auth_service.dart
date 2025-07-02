import 'dart:async';
import 'dart:convert';
import '../logging/app_logger.dart';
import 'auth_models.dart';
import '../security/input_validator.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';

class AzureCliAuthService {
  final UnifiedAzureCliService _cliService;
  final StreamController<AuthState> _authStateController = StreamController<AuthState>.broadcast();
  
  UserInfo? _currentUser;
  Timer? _sessionCheckTimer;
  
  AzureCliAuthService(this._cliService) {
    _initializeAuth();
  }

  // Streams
  Stream<AuthState> get authStateStream => _authStateController.stream;
  
  // Getters
  UserInfo? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Initializes authentication state by checking existing Azure CLI session
  Future<void> _initializeAuth() async {
    try {
      _authStateController.add(AuthState.loading);
      
      // Check if Azure CLI is installed
      final cliVersion = await getAzureCliVersion();
      if (cliVersion == null) {
        AppLogger.error('Azure CLI not found on system');
        _authStateController.add(AuthState.error);
        return;
      }
      
      // Check if user is already logged in
      final authStatus = await getAuthStatus();
      if (authStatus['isAuthenticated'] == true) {
        await _loadCurrentUser();
        _setupSessionCheck();
        _authStateController.add(AuthState.authenticated);
      } else {
        _authStateController.add(AuthState.unauthenticated);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Azure CLI auth', e, stackTrace);
      _authStateController.add(AuthState.error);
    }
  }

  /// Performs Azure CLI login with interactive authentication
  Future<void> login() async {
    try {
      _authStateController.add(AuthState.loading);
      AppLogger.info('Starting Azure CLI authentication');
      
      // Execute az login with device code flow for better UX
      final loginResult = await _cliService.executeCommand(
        'az login --use-device-code',
        timeout: const Duration(minutes: 5),
      );
      
      if (!loginResult.success) {
        throw Exception('Azure CLI login failed: ${loginResult.error}');
      }
      
      // Load user information after successful login
      await _loadCurrentUser();
      
      // Validate that user has required permissions
      final hasPermissions = await validatePermissions();
      if (!hasPermissions) {
        AppLogger.securityEvent('User lacks required Key Vault permissions', {'userId': _currentUser?.id ?? 'unknown'});
        throw Exception('Insufficient permissions for Key Vault operations');
      }
      
      _setupSessionCheck();
      _authStateController.add(AuthState.authenticated);
      
      AppLogger.authEvent('User logged in via Azure CLI', _currentUser!.id);
      
    } catch (e, stackTrace) {
      AppLogger.error('Azure CLI login failed', e, stackTrace);
      _authStateController.add(AuthState.error);
      rethrow;
    }
  }

  /// Performs Azure CLI logout
  Future<void> logout() async {
    try {
      _sessionCheckTimer?.cancel();
      
      // Execute az logout
      final logoutResult = await _cliService.executeCommand('az logout');
      
      if (!logoutResult.success) {
        AppLogger.error('Azure CLI logout command failed: ${logoutResult.error}');
      }
      
      _currentUser = null;
      _authStateController.add(AuthState.unauthenticated);
      
      AppLogger.authEvent('User logged out via Azure CLI', 'system');
      
    } catch (e, stackTrace) {
      AppLogger.error('Azure logout failed', e, stackTrace);
      _authStateController.add(AuthState.error);
    }
  }

  /// Loads current user information from Azure CLI
  Future<void> _loadCurrentUser() async {
    try {
      // Get account information
      final accountResult = await _cliService.executeCommand('az account show');
      
      if (!accountResult.success) {
        throw Exception('Failed to get account info: ${accountResult.error}');
      }
      
      final accountData = jsonDecode(accountResult.output);
      
      // Get user profile information
      final profileResult = await _cliService.executeCommand('az ad signed-in-user show');
      Map<String, dynamic>? profileData;
      
      if (profileResult.success) {
        try {
          profileData = jsonDecode(profileResult.output);
        } catch (e) {
          AppLogger.warning('Could not parse user profile data');
        }
      }
      
      _currentUser = UserInfo(
        id: accountData['user']['name'] ?? accountData['id'],
        email: profileData?['mail'] ?? accountData['user']['name'] ?? 'unknown@domain.com',
        name: profileData?['displayName'] ?? accountData['user']['name'] ?? 'Unknown User',
        tenantId: accountData['tenantId'],
        roles: await _getUserRoles(),
        lastLogin: DateTime.now(),
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load user information', e, stackTrace);
      rethrow;
    }
  }

  /// Gets user roles and permissions
  Future<List<String>> _getUserRoles() async {
    try {
      // Get role assignments for the user
      final rolesResult = await _cliService.executeCommand(
        'az role assignment list --assignee @me --query "[].roleDefinitionName" -o json'
      );
      
      if (rolesResult.success) {
        final rolesJson = jsonDecode(rolesResult.output) as List;
        return rolesJson.cast<String>();
      }
    } catch (e) {
      AppLogger.warning('Could not retrieve user roles: $e');
    }
    
    return ['User']; // Default role
  }

  /// Checks if the current Azure CLI session is still valid
  Future<bool> checkSession() async {
    try {
      if (_currentUser == null) {
        return false;
      }

      // Try to get account info to verify session is still valid
      final result = await _cliService.executeCommand('az account show');
      
      if (!result.success) {
        AppLogger.warning('Azure CLI session expired');
        _currentUser = null;
        _authStateController.add(AuthState.sessionExpired);
        return false;
      }
      
      return true;
    } catch (e) {
      AppLogger.error('Error checking Azure CLI session', e);
      return false;
    }
  }

  /// Sets up periodic session validation
  void _setupSessionCheck() {
    _sessionCheckTimer?.cancel();
    
    // Check session every 15 minutes
    _sessionCheckTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) async {
        await checkSession();
      },
    );
  }

  /// Gets comprehensive authentication status
  Future<Map<String, dynamic>> getAuthStatus() async {
    try {
      final accountResult = await _cliService.executeCommand('az account show');
      
      if (!accountResult.success) {
        return {
          'isAuthenticated': false,
          'error': accountResult.error,
        };
      }
      
      final accountData = jsonDecode(accountResult.output);
      
      return {
        'isAuthenticated': true,
        'azureCliVersion': await getAzureCliVersion(),
        'currentSubscription': {
          'name': accountData['name'],
          'id': accountData['id'],
          'tenantId': accountData['tenantId'],
          'state': accountData['state'],
        },
        'user': {
          'name': accountData['user']['name'],
          'type': accountData['user']['type'],
        },
        'hasPermissions': await validatePermissions(),
      };
    } catch (e) {
      AppLogger.error('Failed to get auth status', e);
      return {
        'isAuthenticated': false,
        'error': e.toString(),
      };
    }
  }

  /// Gets current subscription information
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final result = await _cliService.executeCommand('az account show');
      
      if (result.success) {
        return jsonDecode(result.output);
      }
    } catch (e) {
      AppLogger.error('Failed to get current subscription', e);
    }
    
    return null;
  }

  /// Lists all available subscriptions
  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    try {
      final result = await _cliService.executeCommand('az account list');
      
      if (result.success) {
        final subscriptions = jsonDecode(result.output) as List;
        return subscriptions.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      AppLogger.error('Failed to get subscriptions', e);
    }
    
    return [];
  }

  /// Sets the active subscription
  Future<bool> setSubscription(String subscriptionId) async {
    try {
      // Validate subscription ID format
      final validationError = InputValidator.validateSubscriptionId(subscriptionId);
      if (validationError != null) {
        AppLogger.securityEvent('Invalid subscription ID format', {'subscriptionId': subscriptionId});
        return false;
      }
      
      final result = await _cliService.executeCommand('az account set --subscription "$subscriptionId"');
      
      if (result.success) {
        AppLogger.info('Switched to subscription: $subscriptionId');
        return true;
      } else {
        AppLogger.error('Failed to set subscription: ${result.error}');
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
      final result = await _cliService.executeCommand('az --version');
      
      if (result.success) {
        // Parse version from output
        final lines = result.output.split('\n');
        for (final line in lines) {
          if (line.startsWith('azure-cli')) {
            return line.trim();
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed to get Azure CLI version', e);
    }
    
    return null;
  }

  /// Checks if Azure CLI has required extensions
  Future<bool> checkRequiredExtensions() async {
    try {
      final result = await _cliService.executeCommand('az extension list -o json');
      
      if (result.success) {
        final extensions = jsonDecode(result.output) as List;
        final extensionNames = extensions.map((e) => e['name'] as String).toSet();
        
        // Check for commonly needed extensions
        const requiredExtensions = ['keyvault'];
        
        for (final required in requiredExtensions) {
          if (!extensionNames.contains(required)) {
            AppLogger.info('Missing Azure CLI extension: $required');
            // Auto-install missing extensions
            await _cliService.executeCommand('az extension add --name $required');
          }
        }
      }
      
      return true;
    } catch (e) {
      AppLogger.error('Failed to check Azure CLI extensions', e);
      return false;
    }
  }

  /// Validates that the user has necessary permissions for Key Vault operations
  Future<bool> validatePermissions() async {
    try {
      // Try to list key vaults to test permissions
      final result = await _cliService.executeCommand('az keyvault list --query "[0].name" -o tsv');
      
      // If command succeeds, user has at least read permissions
      return result.success;
    } catch (e) {
      AppLogger.error('Permission validation failed', e);
      return false;
    }
  }

  /// Forces a refresh of the current user session
  Future<void> refreshSession() async {
    try {
      if (_currentUser != null) {
        await _loadCurrentUser();
        AppLogger.info('User session refreshed');
      }
    } catch (e) {
      AppLogger.error('Failed to refresh session', e);
      _authStateController.add(AuthState.error);
    }
  }

  /// Disposes resources
  void dispose() {
    _sessionCheckTimer?.cancel();
    _authStateController.close();
  }
}