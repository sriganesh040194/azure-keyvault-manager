import 'dart:convert';
import '../../core/logging/app_logger.dart';
import '../../core/security/input_validator.dart';
import '../azure_cli/platform_azure_cli_service.dart';
import 'key_models.dart';

class KeyService {
  final UnifiedAzureCliService _cliService;

  KeyService(this._cliService);

  /// Lists all keys in the specified Key Vault
  Future<List<KeyInfo>> listKeys(String vaultName) async {
    try {
      final validationError = InputValidator.validateKeyVaultName(vaultName);
      if (validationError != null) {
        throw KeyException('Invalid vault name: $validationError');
      }

      AppLogger.info('Fetching keys list for vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault key list --vault-name "$vaultName" -o json',
        timeout: const Duration(minutes: 2),
      );

      if (!result.success) {
        throw KeyException('Failed to list keys: ${result.error}');
      }

      final keysJson = jsonDecode(result.output) as List;
      final keys = keysJson.map((json) => _parseKeyFromJson(json)).toList();
      
      AppLogger.info('Retrieved ${keys.length} keys from vault: $vaultName');
      return keys;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list keys', e, stackTrace);
      rethrow;
    }
  }

  /// Gets detailed information about a specific key
  Future<KeyInfo> getKey(String vaultName, String keyName) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw KeyException('Invalid vault name: $vaultValidationError');
      }

      final keyValidationError = InputValidator.validateResourceName(keyName);
      if (keyValidationError != null) {
        throw KeyException('Invalid key name: $keyValidationError');
      }

      AppLogger.info('Fetching key details: $keyName from vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault key show --vault-name "$vaultName" --name "$keyName" -o json',
      );

      if (!result.success) {
        throw KeyException('Failed to get key: ${result.error}');
      }

      final keyJson = jsonDecode(result.output) as Map<String, dynamic>;
      final key = _parseKeyFromJson(keyJson);
      
      AppLogger.info('Retrieved key details: $keyName');
      return key;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get key', e, stackTrace);
      rethrow;
    }
  }

  /// Creates a new key in the specified Key Vault
  Future<KeyInfo> createKey(String vaultName, CreateKeyRequest request) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw KeyException('Invalid vault name: $vaultValidationError');
      }

      final keyValidationError = InputValidator.validateResourceName(request.name);
      if (keyValidationError != null) {
        throw KeyException('Invalid key name: $keyValidationError');
      }

      AppLogger.info('Creating key: ${request.name} in vault: $vaultName');
      
      // Build the command with parameters
      var command = 'az keyvault key create --vault-name "$vaultName" --name "${request.name}" --kty "${request.keyType}"';
      
      if (request.keySize != null) {
        command += ' --size ${request.keySize}';
      }
      
      if (request.curve != null) {
        command += ' --curve "${request.curve}"';
      }
      
      if (request.keyOps != null && request.keyOps!.isNotEmpty) {
        command += ' --ops ${request.keyOps!.join(' ')}';
      }
      
      if (request.expires != null) {
        command += ' --expires "${request.expires!.toIso8601String()}"';
      }
      
      if (request.notBefore != null) {
        command += ' --not-before "${request.notBefore!.toIso8601String()}"';
      }
      
      if (request.enabled != null) {
        command += ' --disabled ${!request.enabled!}';
      }
      
      if (request.tags != null && request.tags!.isNotEmpty) {
        final tagsString = request.tags!.entries.map((e) => '${e.key}=${e.value}').join(' ');
        command += ' --tags $tagsString';
      }
      
      command += ' -o json';

      final result = await _cliService.executeCommand(command);

      if (!result.success) {
        throw KeyException('Failed to create key: ${result.error}');
      }

      final keyJson = jsonDecode(result.output) as Map<String, dynamic>;
      final key = _parseKeyFromJson(keyJson);
      
      AppLogger.info('Created key: ${request.name}');
      return key;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create key', e, stackTrace);
      rethrow;
    }
  }

  /// Updates an existing key in the specified Key Vault
  Future<KeyInfo> updateKey(String vaultName, String keyName, UpdateKeyRequest request) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw KeyException('Invalid vault name: $vaultValidationError');
      }

      final keyValidationError = InputValidator.validateResourceName(keyName);
      if (keyValidationError != null) {
        throw KeyException('Invalid key name: $keyValidationError');
      }

      AppLogger.info('Updating key: $keyName in vault: $vaultName');
      
      // Build the command with parameters
      var command = 'az keyvault key set-attributes --vault-name "$vaultName" --name "$keyName"';
      
      if (request.keyOps != null && request.keyOps!.isNotEmpty) {
        command += ' --ops ${request.keyOps!.join(' ')}';
      }
      
      if (request.expires != null) {
        command += ' --expires "${request.expires!.toIso8601String()}"';
      }
      
      if (request.notBefore != null) {
        command += ' --not-before "${request.notBefore!.toIso8601String()}"';
      }
      
      if (request.enabled != null) {
        command += ' --enabled ${request.enabled!}';
      }
      
      command += ' -o json';

      final result = await _cliService.executeCommand(command);

      if (!result.success) {
        throw KeyException('Failed to update key: ${result.error}');
      }

      final keyJson = jsonDecode(result.output) as Map<String, dynamic>;
      final key = _parseKeyFromJson(keyJson);
      
      AppLogger.info('Updated key: $keyName');
      return key;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update key', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes a key from the specified Key Vault
  Future<void> deleteKey(String vaultName, String keyName) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw KeyException('Invalid vault name: $vaultValidationError');
      }

      final keyValidationError = InputValidator.validateResourceName(keyName);
      if (keyValidationError != null) {
        throw KeyException('Invalid key name: $keyValidationError');
      }

      AppLogger.securityEvent('Deleting key', {'vaultName': vaultName, 'keyName': keyName});
      
      final result = await _cliService.executeCommand(
        'az keyvault key delete --vault-name "$vaultName" --name "$keyName"',
      );

      if (!result.success) {
        throw KeyException('Failed to delete key: ${result.error}');
      }
      
      AppLogger.info('Deleted key: $keyName from vault: $vaultName');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete key', e, stackTrace);
      rethrow;
    }
  }

  /// Recovers a deleted key (if soft delete is enabled)
  Future<KeyInfo> recoverKey(String vaultName, String keyName) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw KeyException('Invalid vault name: $vaultValidationError');
      }

      final keyValidationError = InputValidator.validateResourceName(keyName);
      if (keyValidationError != null) {
        throw KeyException('Invalid key name: $keyValidationError');
      }

      AppLogger.info('Recovering deleted key: $keyName in vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault key recover --vault-name "$vaultName" --name "$keyName" -o json',
      );

      if (!result.success) {
        throw KeyException('Failed to recover key: ${result.error}');
      }

      final keyJson = jsonDecode(result.output) as Map<String, dynamic>;
      final key = _parseKeyFromJson(keyJson);
      
      AppLogger.info('Recovered key: $keyName');
      return key;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to recover key', e, stackTrace);
      rethrow;
    }
  }

  /// Purges a deleted key permanently (if soft delete is enabled)
  Future<void> purgeKey(String vaultName, String keyName) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw KeyException('Invalid vault name: $vaultValidationError');
      }

      final keyValidationError = InputValidator.validateResourceName(keyName);
      if (keyValidationError != null) {
        throw KeyException('Invalid key name: $keyValidationError');
      }

      AppLogger.securityEvent('Purging key permanently', {'vaultName': vaultName, 'keyName': keyName});
      
      final result = await _cliService.executeCommand(
        'az keyvault key purge --vault-name "$vaultName" --name "$keyName"',
      );

      if (!result.success) {
        throw KeyException('Failed to purge key: ${result.error}');
      }
      
      AppLogger.info('Purged key permanently: $keyName from vault: $vaultName');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to purge key', e, stackTrace);
      rethrow;
    }
  }

  /// Lists deleted keys in the specified Key Vault (if soft delete is enabled)
  Future<List<KeyInfo>> listDeletedKeys(String vaultName) async {
    try {
      final validationError = InputValidator.validateKeyVaultName(vaultName);
      if (validationError != null) {
        throw KeyException('Invalid vault name: $validationError');
      }

      AppLogger.info('Fetching deleted keys list for vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault key list-deleted --vault-name "$vaultName" -o json',
        timeout: const Duration(minutes: 2),
      );

      if (!result.success) {
        throw KeyException('Failed to list deleted keys: ${result.error}');
      }

      final keysJson = jsonDecode(result.output) as List;
      final keys = keysJson.map((json) => _parseKeyFromJson(json)).toList();
      
      AppLogger.info('Retrieved ${keys.length} deleted keys from vault: $vaultName');
      return keys;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list deleted keys', e, stackTrace);
      rethrow;
    }
  }

  /// Backs up a key to a file (returns base64 encoded backup data)
  Future<String> backupKey(String vaultName, String keyName) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw KeyException('Invalid vault name: $vaultValidationError');
      }

      final keyValidationError = InputValidator.validateResourceName(keyName);
      if (keyValidationError != null) {
        throw KeyException('Invalid key name: $keyValidationError');
      }

      AppLogger.info('Backing up key: $keyName from vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault key backup --vault-name "$vaultName" --name "$keyName"',
      );

      if (!result.success) {
        throw KeyException('Failed to backup key: ${result.error}');
      }
      
      AppLogger.info('Backed up key: $keyName');
      return result.output.trim();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to backup key', e, stackTrace);
      rethrow;
    }
  }

  /// Restores a key from backup data
  Future<KeyInfo> restoreKey(String vaultName, String backupData) async {
    try {
      final validationError = InputValidator.validateKeyVaultName(vaultName);
      if (validationError != null) {
        throw KeyException('Invalid vault name: $validationError');
      }

      if (backupData.isEmpty) {
        throw KeyException('Backup data cannot be empty');
      }

      AppLogger.info('Restoring key to vault: $vaultName');
      
      // For security, we'll create a temporary file for the backup data
      final result = await _cliService.executeCommand(
        'az keyvault key restore --vault-name "$vaultName" --file-path-'
        // Note: This would require handling file operations securely
      );

      if (!result.success) {
        throw KeyException('Failed to restore key: ${result.error}');
      }

      final keyJson = jsonDecode(result.output) as Map<String, dynamic>;
      final key = _parseKeyFromJson(keyJson);
      
      AppLogger.info('Restored key to vault: $vaultName');
      return key;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to restore key', e, stackTrace);
      rethrow;
    }
  }

  /// Parses a key from JSON response
  KeyInfo _parseKeyFromJson(Map<String, dynamic> json) {
    try {
      return KeyInfo(
        id: json['id'] ?? json['kid'] ?? '',
        name: _extractNameFromId(json['id'] ?? json['kid'] ?? ''),
        type: json['type'] ?? 'unknown',
        keyType: json['kty'] ?? json['key']?['kty'],
        keySize: json['key_size'] ?? json['key']?['key_size'],
        keyOps: json['key_ops'] != null ? List<String>.from(json['key_ops']) : 
                json['key']?['key_ops'] != null ? List<String>.from(json['key']['key_ops']) : null,
        curve: json['crv'] ?? json['key']?['crv'],
        created: json['created'] != null ? DateTime.fromMillisecondsSinceEpoch(json['created'] * 1000) : null,
        updated: json['updated'] != null ? DateTime.fromMillisecondsSinceEpoch(json['updated'] * 1000) : null,
        expires: json['expires'] != null ? DateTime.fromMillisecondsSinceEpoch(json['expires'] * 1000) : null,
        notBefore: json['nbf'] != null ? DateTime.fromMillisecondsSinceEpoch(json['nbf'] * 1000) : null,
        enabled: json['enabled'],
        tags: json['tags'] != null ? Map<String, String>.from(json['tags']) : null,
        version: _extractVersionFromId(json['id'] ?? json['kid'] ?? ''),
        recoverable: json['recoverable'],
        recoverableDays: json['recoverableDays'],
      );
    } catch (e) {
      AppLogger.error('Failed to parse key JSON', e);
      throw KeyException('Failed to parse key data: $e');
    }
  }

  /// Extracts the key name from the full key ID
  String _extractNameFromId(String id) {
    if (id.isEmpty) return '';
    
    // Key ID format: https://vault.vault.azure.net/keys/keyname/version
    final uri = Uri.tryParse(id);
    if (uri != null && uri.pathSegments.length >= 2) {
      return uri.pathSegments[1];
    }
    
    // Fallback: try to extract from the end of the path
    final parts = id.split('/');
    if (parts.length >= 2) {
      return parts[parts.length - 2];
    }
    
    return id;
  }

  /// Extracts the version from the full key ID
  String? _extractVersionFromId(String id) {
    if (id.isEmpty) return null;
    
    // Key ID format: https://vault.vault.azure.net/keys/keyname/version
    final uri = Uri.tryParse(id);
    if (uri != null && uri.pathSegments.length >= 3) {
      return uri.pathSegments[2];
    }
    
    // Fallback: try to extract from the end of the path
    final parts = id.split('/');
    if (parts.length >= 1) {
      return parts.last;
    }
    
    return null;
  }
}