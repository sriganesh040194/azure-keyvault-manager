import 'dart:convert';
import '../../core/logging/app_logger.dart';
import '../../core/security/input_validator.dart';
import '../azure_cli/platform_azure_cli_service.dart';
import 'secret_models.dart';

class SecretService {
  final UnifiedAzureCliService _cliService;

  SecretService(this._cliService);

  /// Lists all secrets in the specified Key Vault
  Future<List<SecretInfo>> listSecrets(String vaultName) async {
    try {
      // Validate vault name
      if (!InputValidator.validateResourceName(vaultName)) {
        throw ArgumentError('Invalid vault name: $vaultName');
      }

      AppLogger.info('Listing secrets for vault: $vaultName');

      final result = await _cliService.executeCommand([
        'az', 'keyvault', 'secret', 'list',
        '--vault-name', vaultName,
        '--output', 'json'
      ]);

      if (!result.success) {
        throw Exception('Failed to list secrets: ${result.error}');
      }

      final List<dynamic> secretsJson = json.decode(result.output);
      final secrets = secretsJson
          .map((json) => _parseSecretInfo(json as Map<String, dynamic>))
          .toList();

      AppLogger.info('Successfully retrieved ${secrets.length} secrets');
      return secrets;
    } catch (e) {
      AppLogger.error('Failed to list secrets for vault: $vaultName', e);
      rethrow;
    }
  }

  /// Gets detailed information about a specific secret
  Future<SecretInfo> getSecret(String vaultName, String secretName) async {
    try {
      // Validate inputs
      if (!InputValidator.validateResourceName(vaultName)) {
        throw ArgumentError('Invalid vault name: $vaultName');
      }
      if (!InputValidator.validateSecretName(secretName)) {
        throw ArgumentError('Invalid secret name: $secretName');
      }

      AppLogger.info('Getting secret: $secretName from vault: $vaultName');

      final result = await _cliService.executeCommand([
        'az', 'keyvault', 'secret', 'show',
        '--vault-name', vaultName,
        '--name', secretName,
        '--output', 'json'
      ]);

      if (!result.success) {
        throw Exception('Failed to get secret: ${result.error}');
      }

      final Map<String, dynamic> secretJson = json.decode(result.output);
      final secret = _parseSecretInfo(secretJson);

      AppLogger.info('Successfully retrieved secret: $secretName');
      return secret;
    } catch (e) {
      AppLogger.error('Failed to get secret: $secretName from vault: $vaultName', e);
      rethrow;
    }
  }

  /// Gets the value of a specific secret
  Future<SecretValue> getSecretValue(String vaultName, String secretName, {String? version}) async {
    try {
      // Validate inputs
      if (!InputValidator.validateResourceName(vaultName)) {
        throw ArgumentError('Invalid vault name: $vaultName');
      }
      if (!InputValidator.validateSecretName(secretName)) {
        throw ArgumentError('Invalid secret name: $secretName');
      }

      AppLogger.securityEvent('Retrieving secret value', {
        'vaultName': vaultName,
        'secretName': secretName,
        'version': version ?? 'latest'
      });

      final command = [
        'az', 'keyvault', 'secret', 'show',
        '--vault-name', vaultName,
        '--name', secretName,
        '--output', 'json'
      ];

      if (version != null) {
        command.addAll(['--version', version]);
      }

      final result = await _cliService.executeCommand(command);

      if (!result.success) {
        throw Exception('Failed to get secret value: ${result.error}');
      }

      final Map<String, dynamic> secretJson = json.decode(result.output);
      final secretValue = SecretValue.fromJson({
        'id': secretJson['id'] ?? '',
        'value': secretJson['value'] ?? '',
        'contentType': secretJson['contentType'],
        'tags': secretJson['tags'] ?? {},
      });

      AppLogger.securityEvent('Secret value retrieved successfully', {
        'vaultName': vaultName,
        'secretName': secretName
      });
      
      return secretValue;
    } catch (e) {
      AppLogger.error('Failed to get secret value: $secretName from vault: $vaultName', e);
      rethrow;
    }
  }

  /// Creates or updates a secret in the Key Vault
  Future<SecretInfo> setSecret(String vaultName, CreateSecretRequest request) async {
    try {
      // Validate inputs
      if (!InputValidator.validateResourceName(vaultName)) {
        throw ArgumentError('Invalid vault name: $vaultName');
      }
      if (!InputValidator.validateSecretName(request.name)) {
        throw ArgumentError('Invalid secret name: ${request.name}');
      }

      AppLogger.securityEvent('Creating/updating secret', {
        'vaultName': vaultName,
        'secretName': request.name
      });

      final command = [
        'az', 'keyvault', 'secret', 'set',
        '--vault-name', vaultName,
        '--name', request.name,
        '--value', request.value,
        '--output', 'json'
      ];

      // Add optional parameters
      if (request.contentType != null) {
        command.addAll(['--content-type', request.contentType!]);
      }
      if (request.enabled != null) {
        command.addAll(['--disabled', (!request.enabled!).toString()]);
      }
      if (request.expires != null) {
        command.addAll(['--expires', request.expires!.toIso8601String()]);
      }
      if (request.notBefore != null) {
        command.addAll(['--not-before', request.notBefore!.toIso8601String()]);
      }
      if (request.tags != null && request.tags!.isNotEmpty) {
        final tagsString = request.tags!.entries
            .map((e) => '${e.key}=${e.value}')
            .join(' ');
        command.addAll(['--tags', tagsString]);
      }

      final result = await _cliService.executeCommand(command);

      if (!result.success) {
        throw Exception('Failed to set secret: ${result.error}');
      }

      final Map<String, dynamic> secretJson = json.decode(result.output);
      final secret = _parseSecretInfo(secretJson);

      AppLogger.info('Successfully created/updated secret: ${request.name}');
      return secret;
    } catch (e) {
      AppLogger.error('Failed to set secret: ${request.name} in vault: $vaultName', e);
      rethrow;
    }
  }

  /// Updates secret attributes (not the value)
  Future<SecretInfo> updateSecret(String vaultName, String secretName, UpdateSecretRequest request) async {
    try {
      // Validate inputs
      if (!InputValidator.validateResourceName(vaultName)) {
        throw ArgumentError('Invalid vault name: $vaultName');
      }
      if (!InputValidator.validateSecretName(secretName)) {
        throw ArgumentError('Invalid secret name: $secretName');
      }

      AppLogger.info('Updating secret attributes: $secretName in vault: $vaultName');

      final command = [
        'az', 'keyvault', 'secret', 'set-attributes',
        '--vault-name', vaultName,
        '--name', secretName,
        '--output', 'json'
      ];

      // Add optional parameters
      if (request.contentType != null) {
        command.addAll(['--content-type', request.contentType!]);
      }
      if (request.enabled != null) {
        command.addAll(['--enabled', request.enabled!.toString()]);
      }
      if (request.expires != null) {
        command.addAll(['--expires', request.expires!.toIso8601String()]);
      }
      if (request.notBefore != null) {
        command.addAll(['--not-before', request.notBefore!.toIso8601String()]);
      }
      if (request.tags != null && request.tags!.isNotEmpty) {
        final tagsString = request.tags!.entries
            .map((e) => '${e.key}=${e.value}')
            .join(' ');
        command.addAll(['--tags', tagsString]);
      }

      final result = await _cliService.executeCommand(command);

      if (!result.success) {
        throw Exception('Failed to update secret: ${result.error}');
      }

      final Map<String, dynamic> secretJson = json.decode(result.output);
      final secret = _parseSecretInfo(secretJson);

      AppLogger.info('Successfully updated secret: $secretName');
      return secret;
    } catch (e) {
      AppLogger.error('Failed to update secret: $secretName in vault: $vaultName', e);
      rethrow;
    }
  }

  /// Deletes a secret from the Key Vault
  Future<void> deleteSecret(String vaultName, String secretName) async {
    try {
      // Validate inputs
      if (!InputValidator.validateResourceName(vaultName)) {
        throw ArgumentError('Invalid vault name: $vaultName');
      }
      if (!InputValidator.validateSecretName(secretName)) {
        throw ArgumentError('Invalid secret name: $secretName');
      }

      AppLogger.securityEvent('Deleting secret', {
        'vaultName': vaultName,
        'secretName': secretName
      });

      final result = await _cliService.executeCommand([
        'az', 'keyvault', 'secret', 'delete',
        '--vault-name', vaultName,
        '--name', secretName,
        '--output', 'json'
      ]);

      if (!result.success) {
        throw Exception('Failed to delete secret: ${result.error}');
      }

      AppLogger.info('Successfully deleted secret: $secretName');
    } catch (e) {
      AppLogger.error('Failed to delete secret: $secretName from vault: $vaultName', e);
      rethrow;
    }
  }

  /// Recovers a deleted secret
  Future<SecretInfo> recoverSecret(String vaultName, String secretName) async {
    try {
      // Validate inputs
      if (!InputValidator.validateResourceName(vaultName)) {
        throw ArgumentError('Invalid vault name: $vaultName');
      }
      if (!InputValidator.validateSecretName(secretName)) {
        throw ArgumentError('Invalid secret name: $secretName');
      }

      AppLogger.info('Recovering secret: $secretName in vault: $vaultName');

      final result = await _cliService.executeCommand([
        'az', 'keyvault', 'secret', 'recover',
        '--vault-name', vaultName,
        '--name', secretName,
        '--output', 'json'
      ]);

      if (!result.success) {
        throw Exception('Failed to recover secret: ${result.error}');
      }

      final Map<String, dynamic> secretJson = json.decode(result.output);
      final secret = _parseSecretInfo(secretJson);

      AppLogger.info('Successfully recovered secret: $secretName');
      return secret;
    } catch (e) {
      AppLogger.error('Failed to recover secret: $secretName in vault: $vaultName', e);
      rethrow;
    }
  }

  /// Permanently deletes a secret (purge)
  Future<void> purgeSecret(String vaultName, String secretName) async {
    try {
      // Validate inputs
      if (!InputValidator.validateResourceName(vaultName)) {
        throw ArgumentError('Invalid vault name: $vaultName');
      }
      if (!InputValidator.validateSecretName(secretName)) {
        throw ArgumentError('Invalid secret name: $secretName');
      }

      AppLogger.securityEvent('Purging secret (permanent deletion)', {
        'vaultName': vaultName,
        'secretName': secretName
      });

      final result = await _cliService.executeCommand([
        'az', 'keyvault', 'secret', 'purge',
        '--vault-name', vaultName,
        '--name', secretName,
        '--output', 'json'
      ]);

      if (!result.success) {
        throw Exception('Failed to purge secret: ${result.error}');
      }

      AppLogger.info('Successfully purged secret: $secretName');
    } catch (e) {
      AppLogger.error('Failed to purge secret: $secretName from vault: $vaultName', e);
      rethrow;
    }
  }

  /// Lists all versions of a secret
  Future<List<SecretVersion>> listSecretVersions(String vaultName, String secretName) async {
    try {
      // Validate inputs
      if (!InputValidator.validateResourceName(vaultName)) {
        throw ArgumentError('Invalid vault name: $vaultName');
      }
      if (!InputValidator.validateSecretName(secretName)) {
        throw ArgumentError('Invalid secret name: $secretName');
      }

      AppLogger.info('Listing versions for secret: $secretName in vault: $vaultName');

      final result = await _cliService.executeCommand([
        'az', 'keyvault', 'secret', 'list-versions',
        '--vault-name', vaultName,
        '--name', secretName,
        '--output', 'json'
      ]);

      if (!result.success) {
        throw Exception('Failed to list secret versions: ${result.error}');
      }

      final List<dynamic> versionsJson = json.decode(result.output);
      final versions = versionsJson
          .map((json) => _parseSecretVersion(json as Map<String, dynamic>))
          .toList();

      AppLogger.info('Successfully retrieved ${versions.length} versions for secret: $secretName');
      return versions;
    } catch (e) {
      AppLogger.error('Failed to list versions for secret: $secretName in vault: $vaultName', e);
      rethrow;
    }
  }

  /// Helper method to parse SecretInfo from JSON
  SecretInfo _parseSecretInfo(Map<String, dynamic> json) {
    return SecretInfo(
      id: json['id'] ?? '',
      name: _extractSecretNameFromId(json['id'] ?? ''),
      contentType: json['contentType'],
      enabled: json['attributes']?['enabled'],
      created: _parseTimestamp(json['attributes']?['created']),
      updated: _parseTimestamp(json['attributes']?['updated']),
      expires: _parseTimestamp(json['attributes']?['expires']),
      notBefore: _parseTimestamp(json['attributes']?['notBefore']),
      recoveryLevel: json['attributes']?['recoveryLevel'],
      tags: json['tags'] != null 
          ? Map<String, String>.from(json['tags'] as Map)
          : null,
    );
  }

  /// Helper method to parse SecretVersion from JSON
  SecretVersion _parseSecretVersion(Map<String, dynamic> json) {
    return SecretVersion(
      id: json['id'] ?? '',
      version: _extractVersionFromId(json['id'] ?? ''),
      created: _parseTimestamp(json['attributes']?['created']),
      updated: _parseTimestamp(json['attributes']?['updated']),
      expires: _parseTimestamp(json['attributes']?['expires']),
      notBefore: _parseTimestamp(json['attributes']?['notBefore']),
      enabled: json['attributes']?['enabled'],
      recoveryLevel: json['attributes']?['recoveryLevel'],
      tags: json['tags'] != null 
          ? Map<String, String>.from(json['tags'] as Map)
          : null,
    );
  }

  /// Helper method to parse timestamp from Azure CLI output
  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }
    if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// Helper method to extract secret name from ID
  String _extractSecretNameFromId(String id) {
    final uri = Uri.tryParse(id);
    if (uri != null) {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'secrets') {
        return segments[1];
      }
    }
    return id.split('/').last;
  }

  /// Helper method to extract version from ID
  String _extractVersionFromId(String id) {
    final uri = Uri.tryParse(id);
    if (uri != null) {
      final segments = uri.pathSegments;
      if (segments.length >= 3 && segments[0] == 'secrets') {
        return segments[2];
      }
    }
    return id.split('/').last;
  }
}