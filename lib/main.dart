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
import 'shared/widgets/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _cliService = UnifiedAzureCliService();
    _authService = AzureCliAuthService(_cliService);
    _keyVaultService = KeyVaultService(_cliService);
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
}