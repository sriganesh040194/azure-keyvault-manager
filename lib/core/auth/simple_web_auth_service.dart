import 'dart:async';
import '../logging/app_logger.dart';
import 'auth_models.dart';

class SimpleWebAuthService {
  final StreamController<AuthState> _authStateController = StreamController<AuthState>.broadcast();
  
  UserInfo? _currentUser;
  Timer? _sessionCheckTimer;
  
  SimpleWebAuthService() {
    _initializeAuth();
  }

  // Streams
  Stream<AuthState> get authStateStream => _authStateController.stream;
  
  // Getters
  UserInfo? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Initializes authentication state 
  Future<void> _initializeAuth() async {
    try {
      _authStateController.add(AuthState.loading);
      
      // For web demo, start unauthenticated
      await Future.delayed(const Duration(milliseconds: 500));
      _authStateController.add(AuthState.unauthenticated);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize web auth', e, stackTrace);
      _authStateController.add(AuthState.error);
    }
  }

  /// Simulates Azure CLI login for web environment
  Future<void> login() async {
    try {
      _authStateController.add(AuthState.loading);
      AppLogger.info('Starting web demo authentication');
      
      // Simulate authentication delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Create a demo user for web testing
      _currentUser = UserInfo(
        id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
        email: 'demo@example.com',
        name: 'Demo User',
        tenantId: 'demo-tenant',
        roles: ['Key Vault User'],
        lastLogin: DateTime.now(),
      );

      _setupSessionCheck();
      _authStateController.add(AuthState.authenticated);
      
      AppLogger.authEvent('User logged in via web demo', _currentUser!.id);
      
    } catch (e, stackTrace) {
      AppLogger.error('Web demo login failed', e, stackTrace);
      _authStateController.add(AuthState.error);
      rethrow;
    }
  }

  /// Performs logout
  Future<void> logout() async {
    try {
      _sessionCheckTimer?.cancel();
      
      _currentUser = null;
      _authStateController.add(AuthState.unauthenticated);
      
      AppLogger.authEvent('User logged out via web demo', 'system');
      
    } catch (e, stackTrace) {
      AppLogger.error('Web logout failed', e, stackTrace);
      _authStateController.add(AuthState.error);
    }
  }

  /// Checks if the current session is still valid
  Future<bool> checkSession() async {
    try {
      if (_currentUser == null) {
        return false;
      }

      // Simple session check - in real app would validate token expiry etc
      return true;
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

  /// Gets authentication status for web environment
  Future<Map<String, dynamic>> getAuthStatus() async {
    return {
      'isAuthenticated': isAuthenticated,
      'azureCliVersion': 'Web Demo Mode',
      'currentSubscription': isAuthenticated ? {
        'name': 'Demo Subscription',
        'id': 'demo-subscription-id',
      } : null,
      'hasPermissions': isAuthenticated,
      'user': _currentUser?.toJson(),
      'webMode': true,
      'note': 'This is a web demo. In production, use Azure CLI desktop authentication.',
    };
  }

  /// Gets current subscription information (simulated)
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    if (!isAuthenticated) return null;
    
    return {
      'name': 'Demo Subscription',
      'id': 'demo-subscription-id',
      'tenantId': 'demo-tenant-id',
      'state': 'Enabled',
      'user': {
        'name': _currentUser?.email ?? 'demo@example.com',
        'type': 'user',
      },
    };
  }

  /// Lists available subscriptions (simulated)
  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    if (!isAuthenticated) return [];
    
    return [
      {
        'name': 'Demo Subscription',
        'id': 'demo-subscription-id',
        'tenantId': 'demo-tenant-id',
        'state': 'Enabled',
        'isDefault': true,
      },
      {
        'name': 'Test Subscription',
        'id': 'test-subscription-id',
        'tenantId': 'demo-tenant-id',
        'state': 'Enabled',
        'isDefault': false,
      },
    ];
  }

  /// Sets the active subscription (simulated)
  Future<bool> setSubscription(String subscriptionId) async {
    if (!isAuthenticated) return false;
    
    AppLogger.info('Demo: Switched to subscription: $subscriptionId');
    return true;
  }

  /// Gets Azure CLI version information (simulated)
  Future<String?> getAzureCliVersion() async {
    return 'Web Demo Mode - Azure CLI not available in browser';
  }

  /// Checks if Azure CLI has required extensions (simulated)
  Future<bool> checkRequiredExtensions() async {
    return true; // Always true in demo mode
  }

  /// Validates that the user has necessary permissions (simulated)
  Future<bool> validatePermissions() async {
    return isAuthenticated; // Always true if authenticated in demo mode
  }

  /// Disposes resources
  void dispose() {
    _sessionCheckTimer?.cancel();
    _authStateController.close();
  }
}