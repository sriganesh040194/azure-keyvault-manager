import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/azure_cli_auth_service.dart';
import 'core/auth/auth_models.dart';
import 'features/authentication/login_screen.dart';
import 'features/dashboard/production_dashboard_screen.dart';
import 'features/platform/web_platform_notice_screen.dart';
import 'services/azure_cli/platform_azure_cli_service.dart';
import 'services/keyvault/keyvault_service.dart';
import 'services/update/update_service.dart';
import 'services/update/update_storage.dart';
import 'shared/dialogs/update_available_dialog.dart';
import 'shared/widgets/app_theme.dart';
import 'shared/constants/app_constants.dart';
import 'core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging
  AppLogger.info('Azure Key Vault Manager starting up');
  
  runApp(
    const ProviderScope(
      child: KeyVaultApp(),
    ),
  );
}

class KeyVaultApp extends ConsumerWidget {
  const KeyVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Azure Key Vault Manager',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: kIsWeb ? const WebPlatformNoticeScreen() : const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  late final UnifiedAzureCliService _cliService;
  late final AzureCliAuthService _authService;
  late final KeyVaultService _keyVaultService;
  late final UpdateService _updateService;
  late final UpdateStorage _updateStorage;
  bool _hasCheckedForUpdates = false;

  @override
  void initState() {
    super.initState();
    _cliService = UnifiedAzureCliService();
    _authService = AzureCliAuthService(_cliService);
    _keyVaultService = KeyVaultService(_cliService);
    _updateService = UpdateService(
      githubOwner: AppConstants.githubOwner,
      githubRepo: AppConstants.githubRepo,
    );
    _updateStorage = UpdateStorage();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.authStateStream,
      builder: (context, snapshot) {
        final authState = snapshot.data ?? AuthState.initial;

        // Check for updates once when authenticated
        if (authState == AuthState.authenticated && !_hasCheckedForUpdates) {
          _hasCheckedForUpdates = true;
          _checkForUpdates(context);
        }

        switch (authState) {
          case AuthState.initial:
          case AuthState.loading:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );

          case AuthState.authenticated:
            return ProductionDashboardScreen(
              authService: _authService,
              keyVaultService: _keyVaultService,
            );

          case AuthState.unauthenticated:
          case AuthState.error:
          case AuthState.sessionExpired:
            return LoginScreen(
              authService: _authService,
              error: authState == AuthState.error ? 'Authentication error occurred' : null,
            );
        }
      },
    );
  }

  /// Checks for app updates in the background
  Future<void> _checkForUpdates(BuildContext context) async {
    try {
      AppLogger.info('Checking for app updates...');

      final result = await _updateService.checkForUpdates();

      if (!mounted) return;

      if (result.updateAvailable && result.updateInfo != null) {
        // Check if user has skipped this version
        final hasSkipped = await _updateStorage.hasSkippedVersion(
          result.updateInfo!.version,
        );

        if (hasSkipped) {
          AppLogger.info(
            'Update ${result.updateInfo!.version} available but user has skipped it',
          );
          return;
        }

        // Show update dialog
        AppLogger.info('Showing update dialog for version ${result.updateInfo!.version}');

        // Use Future.delayed to avoid showing dialog during build
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            showUpdateAvailableDialog(
              context: context,
              updateInfo: result.updateInfo!,
              currentVersion: result.currentVersion,
            );
          }
        });
      } else if (result.error != null) {
        AppLogger.warning('Update check failed: ${result.error}');
      } else {
        AppLogger.info('App is up to date');
      }
    } catch (e) {
      AppLogger.error('Error checking for updates: $e');
      // Silently fail - don't interrupt user experience
    }
  }
}