class AppConstants {
  static const String appName = 'Azure Key Vault Manager';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String userInfoKey = 'user_info';
  static const String sessionKeyKey = 'session_key';

  // CLI Configuration
  static const int cliTimeoutSeconds = 300;
  static const int maxConcurrentOperations = 5;
  static const int sessionCheckIntervalMinutes = 5;

  // UI Configuration
  static const Duration loadingDebounce = Duration(milliseconds: 500);
  static const Duration notificationDuration = Duration(seconds: 4);

  // Security Configuration
  static const int maxRetryAttempts = 3;
  static const Duration sessionTimeout = Duration(hours: 8);

  // Supported Azure CLI Commands
  static const List<String> allowedAzCommands = [
    // Authentication and account management
    'az login',
    'az logout',
    'az account',
    'az account show',
    'az account list',
    'az account set',
    'az --version',
    'az ad signed-in-user show',
    'az extension list',

    // Key Vault operations
    'az keyvault',
    'az keyvault list',
    'az keyvault create',
    'az keyvault delete',
    'az keyvault show',
    'az keyvault update',
    'az keyvault secret list',
    'az keyvault secret show',
    'az keyvault secret set',
    'az keyvault secret delete',
    'az keyvault key list',
    'az keyvault key show',
    'az keyvault key create',
    'az keyvault key delete',
    'az keyvault certificate list',
    'az keyvault certificate show',
    'az keyvault certificate create',
    'az keyvault certificate delete',
    'az keyvault set-policy',
    'az keyvault delete-policy',
  ];
}
