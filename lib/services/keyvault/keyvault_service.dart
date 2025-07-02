import 'dart:convert';
import '../../core/logging/app_logger.dart';
import '../../core/security/input_validator.dart';
import '../azure_cli/platform_azure_cli_service.dart';

class KeyVaultService {
  final UnifiedAzureCliService _cliService;

  KeyVaultService(this._cliService);

  /// Lists all Key Vaults accessible to the current user
  Future<List<KeyVaultInfo>> listKeyVaults() async {
    try {
      AppLogger.info('Fetching Key Vaults list');
      
      final result = await _cliService.executeCommand(
        'az keyvault list -o json',
        timeout: const Duration(minutes: 2),
      );

      if (!result.success) {
        throw KeyVaultException('Failed to list Key Vaults: ${result.error}');
      }

      final vaultsJson = jsonDecode(result.output) as List;
      final vaults = vaultsJson.map((json) => KeyVaultInfo.fromJson(json)).toList();
      
      AppLogger.info('Retrieved ${vaults.length} Key Vaults');
      return vaults;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list Key Vaults', e, stackTrace);
      rethrow;
    }
  }

  /// Gets detailed information about a specific Key Vault
  Future<KeyVaultInfo> getKeyVault(String vaultName) async {
    try {
      final validationError = InputValidator.validateKeyVaultName(vaultName);
      if (validationError != null) {
        throw KeyVaultException('Invalid vault name: $validationError');
      }

      AppLogger.info('Fetching Key Vault details: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault show --name "$vaultName" -o json',
      );

      if (!result.success) {
        throw KeyVaultException('Failed to get Key Vault $vaultName: ${result.error}');
      }

      final vaultJson = jsonDecode(result.output);
      return KeyVaultInfo.fromJson(vaultJson);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get Key Vault $vaultName', e, stackTrace);
      rethrow;
    }
  }

  /// Lists all secrets in a Key Vault
  Future<List<SecretInfo>> listSecrets(String vaultName) async {
    try {
      final validationError = InputValidator.validateKeyVaultName(vaultName);
      if (validationError != null) {
        throw KeyVaultException('Invalid vault name: $validationError');
      }

      AppLogger.info('Fetching secrets from vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault secret list --vault-name "$vaultName" -o json',
      );

      if (!result.success) {
        throw KeyVaultException('Failed to list secrets: ${result.error}');
      }

      final secretsJson = jsonDecode(result.output) as List;
      final secrets = secretsJson.map((json) => SecretInfo.fromJson(json)).toList();
      
      AppLogger.info('Retrieved ${secrets.length} secrets from $vaultName');
      return secrets;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list secrets from $vaultName', e, stackTrace);
      rethrow;
    }
  }

  /// Gets a secret's value from Key Vault
  Future<String> getSecretValue(String vaultName, String secretName) async {
    try {
      final vaultValidation = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidation != null) {
        throw KeyVaultException('Invalid vault name: $vaultValidation');
      }

      final secretValidation = InputValidator.validateSecretName(secretName);
      if (secretValidation != null) {
        throw KeyVaultException('Invalid secret name: $secretValidation');
      }

      AppLogger.securityEvent('Accessing secret value', {
        'vault': vaultName,
        'secret': secretName,
      });
      
      final result = await _cliService.executeCommand(
        'az keyvault secret show --vault-name "$vaultName" --name "$secretName" --query "value" -o tsv',
      );

      if (!result.success) {
        throw KeyVaultException('Failed to get secret $secretName: ${result.error}');
      }

      return result.output.trim();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get secret $secretName from $vaultName', e, stackTrace);
      rethrow;
    }
  }

  /// Creates or updates a secret in Key Vault
  Future<void> setSecret(String vaultName, String secretName, String value, {Map<String, String>? tags}) async {
    try {
      final vaultValidation = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidation != null) {
        throw KeyVaultException('Invalid vault name: $vaultValidation');
      }

      final secretValidation = InputValidator.validateSecretName(secretName);
      if (secretValidation != null) {
        throw KeyVaultException('Invalid secret name: $secretValidation');
      }

      if (value.isEmpty) {
        throw KeyVaultException('Secret value cannot be empty');
      }

      AppLogger.securityEvent('Setting secret value', {
        'vault': vaultName,
        'secret': secretName,
      });

      String command = 'az keyvault secret set --vault-name "$vaultName" --name "$secretName" --value "$value"';
      
      if (tags != null && tags.isNotEmpty) {
        final tagsJson = jsonEncode(tags);
        command += ' --tags \'$tagsJson\'';
      }
      
      final result = await _cliService.executeCommand(command);

      if (!result.success) {
        throw KeyVaultException('Failed to set secret $secretName: ${result.error}');
      }

      AppLogger.info('Successfully set secret $secretName in $vaultName');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set secret $secretName in $vaultName', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes a secret from Key Vault
  Future<void> deleteSecret(String vaultName, String secretName) async {
    try {
      final vaultValidation = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidation != null) {
        throw KeyVaultException('Invalid vault name: $vaultValidation');
      }

      final secretValidation = InputValidator.validateSecretName(secretName);
      if (secretValidation != null) {
        throw KeyVaultException('Invalid secret name: $secretValidation');
      }

      AppLogger.securityEvent('Deleting secret', {
        'vault': vaultName,
        'secret': secretName,
      });
      
      final result = await _cliService.executeCommand(
        'az keyvault secret delete --vault-name "$vaultName" --name "$secretName"',
      );

      if (!result.success) {
        throw KeyVaultException('Failed to delete secret $secretName: ${result.error}');
      }

      AppLogger.info('Successfully deleted secret $secretName from $vaultName');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete secret $secretName from $vaultName', e, stackTrace);
      rethrow;
    }
  }

  /// Lists all keys in a Key Vault
  Future<List<KeyInfo>> listKeys(String vaultName) async {
    try {
      final validationError = InputValidator.validateKeyVaultName(vaultName);
      if (validationError != null) {
        throw KeyVaultException('Invalid vault name: $validationError');
      }

      AppLogger.info('Fetching keys from vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault key list --vault-name "$vaultName" -o json',
      );

      if (!result.success) {
        throw KeyVaultException('Failed to list keys: ${result.error}');
      }

      final keysJson = jsonDecode(result.output) as List;
      final keys = keysJson.map((json) => KeyInfo.fromJson(json)).toList();
      
      AppLogger.info('Retrieved ${keys.length} keys from $vaultName');
      return keys;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list keys from $vaultName', e, stackTrace);
      rethrow;
    }
  }

  /// Lists all certificates in a Key Vault
  Future<List<CertificateInfo>> listCertificates(String vaultName) async {
    try {
      final validationError = InputValidator.validateKeyVaultName(vaultName);
      if (validationError != null) {
        throw KeyVaultException('Invalid vault name: $validationError');
      }

      AppLogger.info('Fetching certificates from vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault certificate list --vault-name "$vaultName" -o json',
      );

      if (!result.success) {
        throw KeyVaultException('Failed to list certificates: ${result.error}');
      }

      final certsJson = jsonDecode(result.output) as List;
      final certificates = certsJson.map((json) => CertificateInfo.fromJson(json)).toList();
      
      AppLogger.info('Retrieved ${certificates.length} certificates from $vaultName');
      return certificates;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list certificates from $vaultName', e, stackTrace);
      rethrow;
    }
  }

  /// Creates a new Key Vault
  Future<KeyVaultInfo> createKeyVault(String vaultName, String resourceGroup, String location) async {
    try {
      final vaultValidation = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidation != null) {
        throw KeyVaultException('Invalid vault name: $vaultValidation');
      }

      final rgValidation = InputValidator.validateResourceGroupName(resourceGroup);
      if (rgValidation != null) {
        throw KeyVaultException('Invalid resource group name: $rgValidation');
      }

      if (location.isEmpty) {
        throw KeyVaultException('Location cannot be empty');
      }

      AppLogger.info('Creating Key Vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault create --name "$vaultName" --resource-group "$resourceGroup" --location "$location" -o json',
        timeout: const Duration(minutes: 5),
      );

      if (!result.success) {
        throw KeyVaultException('Failed to create Key Vault $vaultName: ${result.error}');
      }

      final vaultJson = jsonDecode(result.output);
      final vault = KeyVaultInfo.fromJson(vaultJson);
      
      AppLogger.info('Successfully created Key Vault: $vaultName');
      return vault;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create Key Vault $vaultName', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes a Key Vault
  Future<void> deleteKeyVault(String vaultName) async {
    try {
      final validationError = InputValidator.validateKeyVaultName(vaultName);
      if (validationError != null) {
        throw KeyVaultException('Invalid vault name: $validationError');
      }

      AppLogger.securityEvent('Deleting Key Vault', {'vault': vaultName});
      
      final result = await _cliService.executeCommand(
        'az keyvault delete --name "$vaultName"',
        timeout: const Duration(minutes: 3),
      );

      if (!result.success) {
        throw KeyVaultException('Failed to delete Key Vault $vaultName: ${result.error}');
      }

      AppLogger.info('Successfully deleted Key Vault: $vaultName');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete Key Vault $vaultName', e, stackTrace);
      rethrow;
    }
  }
}

// Data models
class KeyVaultInfo {
  final String name;
  final String id;
  final String location;
  final String resourceGroup;
  final String vaultUri;
  final DateTime createdTime;
  final Map<String, String> tags;

  KeyVaultInfo({
    required this.name,
    required this.id,
    required this.location,
    required this.resourceGroup,
    required this.vaultUri,
    required this.createdTime,
    required this.tags,
  });

  factory KeyVaultInfo.fromJson(Map<String, dynamic> json) {
    return KeyVaultInfo(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      location: json['location'] ?? '',
      resourceGroup: _extractResourceGroup(json['id'] ?? ''),
      vaultUri: json['properties']?['vaultUri'] ?? '',
      createdTime: DateTime.tryParse(json['properties']?['createdDateTime'] ?? '') ?? DateTime.now(),
      tags: Map<String, String>.from(json['tags'] ?? {}),
    );
  }

  static String _extractResourceGroup(String resourceId) {
    final parts = resourceId.split('/');
    final rgIndex = parts.indexOf('resourceGroups');
    return rgIndex != -1 && rgIndex + 1 < parts.length ? parts[rgIndex + 1] : '';
  }
}

class SecretInfo {
  final String name;
  final String id;
  final DateTime createdTime;
  final DateTime updatedTime;
  final bool enabled;
  final Map<String, String> tags;

  SecretInfo({
    required this.name,
    required this.id,
    required this.createdTime,
    required this.updatedTime,
    required this.enabled,
    required this.tags,
  });

  factory SecretInfo.fromJson(Map<String, dynamic> json) {
    return SecretInfo(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      createdTime: DateTime.tryParse(json['attributes']?['created'] ?? '') ?? DateTime.now(),
      updatedTime: DateTime.tryParse(json['attributes']?['updated'] ?? '') ?? DateTime.now(),
      enabled: json['attributes']?['enabled'] ?? true,
      tags: Map<String, String>.from(json['tags'] ?? {}),
    );
  }
}

class KeyInfo {
  final String name;
  final String id;
  final String keyType;
  final DateTime createdTime;
  final DateTime updatedTime;
  final bool enabled;
  final Map<String, String> tags;

  KeyInfo({
    required this.name,
    required this.id,
    required this.keyType,
    required this.createdTime,
    required this.updatedTime,
    required this.enabled,
    required this.tags,
  });

  factory KeyInfo.fromJson(Map<String, dynamic> json) {
    return KeyInfo(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      keyType: json['kty'] ?? '',
      createdTime: DateTime.tryParse(json['attributes']?['created'] ?? '') ?? DateTime.now(),
      updatedTime: DateTime.tryParse(json['attributes']?['updated'] ?? '') ?? DateTime.now(),
      enabled: json['attributes']?['enabled'] ?? true,
      tags: Map<String, String>.from(json['tags'] ?? {}),
    );
  }
}

class CertificateInfo {
  final String name;
  final String id;
  final DateTime createdTime;
  final DateTime updatedTime;
  final DateTime? expiresOn;
  final bool enabled;
  final Map<String, String> tags;

  CertificateInfo({
    required this.name,
    required this.id,
    required this.createdTime,
    required this.updatedTime,
    this.expiresOn,
    required this.enabled,
    required this.tags,
  });

  factory CertificateInfo.fromJson(Map<String, dynamic> json) {
    return CertificateInfo(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      createdTime: DateTime.tryParse(json['attributes']?['created'] ?? '') ?? DateTime.now(),
      updatedTime: DateTime.tryParse(json['attributes']?['updated'] ?? '') ?? DateTime.now(),
      expiresOn: DateTime.tryParse(json['attributes']?['expires'] ?? ''),
      enabled: json['attributes']?['enabled'] ?? true,
      tags: Map<String, String>.from(json['tags'] ?? {}),
    );
  }
}

class KeyVaultException implements Exception {
  final String message;
  KeyVaultException(this.message);

  @override
  String toString() => 'KeyVaultException: $message';
}