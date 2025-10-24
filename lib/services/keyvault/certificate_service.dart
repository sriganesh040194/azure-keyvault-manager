import 'dart:convert';
import '../../core/logging/app_logger.dart';
import '../../core/security/input_validator.dart';
import '../azure_cli/platform_azure_cli_service.dart';
import 'certificate_models.dart';

class CertificateService {
  final UnifiedAzureCliService _cliService;

  CertificateService(this._cliService);

  /// Lists all certificates in the specified Key Vault
  Future<List<CertificateInfo>> listCertificates(String vaultName) async {
    try {
      final validationError = InputValidator.validateKeyVaultName(vaultName);
      if (validationError != null) {
        throw CertificateException('Invalid vault name: $validationError');
      }

      AppLogger.info('Fetching certificates list for vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault certificate list --vault-name "$vaultName" -o json',
        timeout: const Duration(minutes: 2),
      );

      if (!result.success) {
        throw CertificateException('Failed to list certificates: ${result.error}');
      }

      final certificatesJson = jsonDecode(result.output) as List;
      final certificates = certificatesJson.map((json) => _parseCertificateFromJson(json)).toList();
      
      AppLogger.info('Retrieved ${certificates.length} certificates from vault: $vaultName');
      return certificates;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list certificates', e, stackTrace);
      rethrow;
    }
  }

  /// Gets detailed information about a specific certificate
  Future<CertificateInfo> getCertificate(String vaultName, String certificateName) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw CertificateException('Invalid vault name: $vaultValidationError');
      }

      final certValidationError = InputValidator.validateResourceName(certificateName);
      if (certValidationError != null) {
        throw CertificateException('Invalid certificate name: $certValidationError');
      }

      AppLogger.info('Fetching certificate details: $certificateName from vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault certificate show --vault-name "$vaultName" --name "$certificateName" -o json',
      );

      if (!result.success) {
        throw CertificateException('Failed to get certificate: ${result.error}');
      }

      final certificateJson = jsonDecode(result.output) as Map<String, dynamic>;
      final certificate = _parseCertificateFromJson(certificateJson);
      
      AppLogger.info('Retrieved certificate details: $certificateName');
      return certificate;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get certificate', e, stackTrace);
      rethrow;
    }
  }

  /// Creates a new certificate in the specified Key Vault
  Future<CertificateInfo> createCertificate(String vaultName, CreateCertificateRequest request) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw CertificateException('Invalid vault name: $vaultValidationError');
      }

      final certValidationError = InputValidator.validateResourceName(request.name);
      if (certValidationError != null) {
        throw CertificateException('Invalid certificate name: $certValidationError');
      }

      AppLogger.info('Creating certificate: ${request.name} in vault: $vaultName');
      
      // Build the command with policy
      var command = 'az keyvault certificate create --vault-name "$vaultName" --name "${request.name}"';
      
      // For simplicity, we'll use a basic policy. In production, you'd want to build this from the policy object
      command += ' --policy @-';
      
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
        throw CertificateException('Failed to create certificate: ${result.error}');
      }

      final certificateJson = jsonDecode(result.output) as Map<String, dynamic>;
      final certificate = _parseCertificateFromJson(certificateJson);
      
      AppLogger.info('Created certificate: ${request.name}');
      return certificate;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create certificate', e, stackTrace);
      rethrow;
    }
  }

  /// Updates an existing certificate in the specified Key Vault
  Future<CertificateInfo> updateCertificate(String vaultName, String certificateName, UpdateCertificateRequest request) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw CertificateException('Invalid vault name: $vaultValidationError');
      }

      final certValidationError = InputValidator.validateResourceName(certificateName);
      if (certValidationError != null) {
        throw CertificateException('Invalid certificate name: $certValidationError');
      }

      AppLogger.info('Updating certificate: $certificateName in vault: $vaultName');
      
      // Build the command with parameters
      var command = 'az keyvault certificate set-attributes --vault-name "$vaultName" --name "$certificateName"';
      
      if (request.enabled != null) {
        command += ' --enabled ${request.enabled!}';
      }
      
      if (request.tags != null && request.tags!.isNotEmpty) {
        final tagsString = request.tags!.entries.map((e) => '${e.key}=${e.value}').join(' ');
        command += ' --tags $tagsString';
      }
      
      command += ' -o json';

      final result = await _cliService.executeCommand(command);

      if (!result.success) {
        throw CertificateException('Failed to update certificate: ${result.error}');
      }

      final certificateJson = jsonDecode(result.output) as Map<String, dynamic>;
      final certificate = _parseCertificateFromJson(certificateJson);
      
      AppLogger.info('Updated certificate: $certificateName');
      return certificate;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update certificate', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes a certificate from the specified Key Vault
  Future<void> deleteCertificate(String vaultName, String certificateName) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw CertificateException('Invalid vault name: $vaultValidationError');
      }

      final certValidationError = InputValidator.validateResourceName(certificateName);
      if (certValidationError != null) {
        throw CertificateException('Invalid certificate name: $certValidationError');
      }

      AppLogger.securityEvent('Deleting certificate', {'vaultName': vaultName, 'certificateName': certificateName});
      
      final result = await _cliService.executeCommand(
        'az keyvault certificate delete --vault-name "$vaultName" --name "$certificateName"',
      );

      if (!result.success) {
        throw CertificateException('Failed to delete certificate: ${result.error}');
      }
      
      AppLogger.info('Deleted certificate: $certificateName from vault: $vaultName');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete certificate', e, stackTrace);
      rethrow;
    }
  }

  /// Imports a certificate into the specified Key Vault
  Future<CertificateInfo> importCertificate(String vaultName, ImportCertificateRequest request) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw CertificateException('Invalid vault name: $vaultValidationError');
      }

      final certValidationError = InputValidator.validateResourceName(request.name);
      if (certValidationError != null) {
        throw CertificateException('Invalid certificate name: $certValidationError');
      }

      AppLogger.info('Importing certificate: ${request.name} into vault: $vaultName');
      
      // Build the command
      var command = 'az keyvault certificate import --vault-name "$vaultName" --name "${request.name}"';
      
      // For security, certificate data should be passed via file or stdin
      command += ' --file /dev/stdin';
      
      if (request.password != null) {
        command += ' --password "${request.password}"';
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
        throw CertificateException('Failed to import certificate: ${result.error}');
      }

      final certificateJson = jsonDecode(result.output) as Map<String, dynamic>;
      final certificate = _parseCertificateFromJson(certificateJson);
      
      AppLogger.info('Imported certificate: ${request.name}');
      return certificate;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to import certificate', e, stackTrace);
      rethrow;
    }
  }

  /// Downloads a certificate in the specified format
  Future<String> downloadCertificate(String vaultName, String certificateName, {String format = 'PEM'}) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw CertificateException('Invalid vault name: $vaultValidationError');
      }

      final certValidationError = InputValidator.validateResourceName(certificateName);
      if (certValidationError != null) {
        throw CertificateException('Invalid certificate name: $certValidationError');
      }

      AppLogger.info('Downloading certificate: $certificateName from vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault certificate download --vault-name "$vaultName" --name "$certificateName" --encoding "$format" --file /dev/stdout',
      );

      if (!result.success) {
        throw CertificateException('Failed to download certificate: ${result.error}');
      }
      
      AppLogger.info('Downloaded certificate: $certificateName');
      return result.output;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to download certificate', e, stackTrace);
      rethrow;
    }
  }

  /// Gets the certificate policy
  Future<CertificatePolicy> getCertificatePolicy(String vaultName, String certificateName) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw CertificateException('Invalid vault name: $vaultValidationError');
      }

      final certValidationError = InputValidator.validateResourceName(certificateName);
      if (certValidationError != null) {
        throw CertificateException('Invalid certificate name: $certValidationError');
      }

      AppLogger.info('Fetching certificate policy: $certificateName from vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault certificate get-default-policy --vault-name "$vaultName" --name "$certificateName" -o json',
      );

      if (!result.success) {
        throw CertificateException('Failed to get certificate policy: ${result.error}');
      }

      final policyJson = jsonDecode(result.output) as Map<String, dynamic>;
      final policy = _parsePolicyFromJson(policyJson);
      
      AppLogger.info('Retrieved certificate policy: $certificateName');
      return policy;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get certificate policy', e, stackTrace);
      rethrow;
    }
  }

  /// Lists deleted certificates in the specified Key Vault (if soft delete is enabled)
  Future<List<CertificateInfo>> listDeletedCertificates(String vaultName) async {
    try {
      final validationError = InputValidator.validateKeyVaultName(vaultName);
      if (validationError != null) {
        throw CertificateException('Invalid vault name: $validationError');
      }

      AppLogger.info('Fetching deleted certificates list for vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault certificate list-deleted --vault-name "$vaultName" -o json',
        timeout: const Duration(minutes: 2),
      );

      if (!result.success) {
        throw CertificateException('Failed to list deleted certificates: ${result.error}');
      }

      final certificatesJson = jsonDecode(result.output) as List;
      final certificates = certificatesJson.map((json) => _parseCertificateFromJson(json)).toList();
      
      AppLogger.info('Retrieved ${certificates.length} deleted certificates from vault: $vaultName');
      return certificates;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list deleted certificates', e, stackTrace);
      rethrow;
    }
  }

  /// Recovers a deleted certificate (if soft delete is enabled)
  Future<CertificateInfo> recoverCertificate(String vaultName, String certificateName) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw CertificateException('Invalid vault name: $vaultValidationError');
      }

      final certValidationError = InputValidator.validateResourceName(certificateName);
      if (certValidationError != null) {
        throw CertificateException('Invalid certificate name: $certValidationError');
      }

      AppLogger.info('Recovering deleted certificate: $certificateName in vault: $vaultName');
      
      final result = await _cliService.executeCommand(
        'az keyvault certificate recover --vault-name "$vaultName" --name "$certificateName" -o json',
      );

      if (!result.success) {
        throw CertificateException('Failed to recover certificate: ${result.error}');
      }

      final certificateJson = jsonDecode(result.output) as Map<String, dynamic>;
      final certificate = _parseCertificateFromJson(certificateJson);
      
      AppLogger.info('Recovered certificate: $certificateName');
      return certificate;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to recover certificate', e, stackTrace);
      rethrow;
    }
  }

  /// Purges a deleted certificate permanently (if soft delete is enabled)
  Future<void> purgeCertificate(String vaultName, String certificateName) async {
    try {
      final vaultValidationError = InputValidator.validateKeyVaultName(vaultName);
      if (vaultValidationError != null) {
        throw CertificateException('Invalid vault name: $vaultValidationError');
      }

      final certValidationError = InputValidator.validateResourceName(certificateName);
      if (certValidationError != null) {
        throw CertificateException('Invalid certificate name: $certValidationError');
      }

      AppLogger.securityEvent('Purging certificate permanently', {'vaultName': vaultName, 'certificateName': certificateName});
      
      final result = await _cliService.executeCommand(
        'az keyvault certificate purge --vault-name "$vaultName" --name "$certificateName"',
      );

      if (!result.success) {
        throw CertificateException('Failed to purge certificate: ${result.error}');
      }
      
      AppLogger.info('Purged certificate permanently: $certificateName from vault: $vaultName');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to purge certificate', e, stackTrace);
      rethrow;
    }
  }

  /// Parses a certificate from JSON response
  CertificateInfo _parseCertificateFromJson(Map<String, dynamic> json) {
    try {
      return CertificateInfo(
        id: json['id'] ?? '',
        name: _extractNameFromId(json['id'] ?? ''),
        thumbprint: json['x5t'] ?? json['thumbprint'],
        subject: json['subject'],
        issuer: json['issuer'],
        created: json['created'] != null ? DateTime.fromMillisecondsSinceEpoch(json['created'] * 1000) : null,
        updated: json['updated'] != null ? DateTime.fromMillisecondsSinceEpoch(json['updated'] * 1000) : null,
        expires: json['expires'] != null ? DateTime.fromMillisecondsSinceEpoch(json['expires'] * 1000) : null,
        notBefore: json['nbf'] != null ? DateTime.fromMillisecondsSinceEpoch(json['nbf'] * 1000) : null,
        enabled: json['enabled'],
        tags: json['tags'] != null ? Map<String, String>.from(json['tags']) : null,
        version: _extractVersionFromId(json['id'] ?? ''),
        recoverable: json['recoverable'],
        recoverableDays: json['recoverableDays'],
        contentType: json['contentType'],
        keyUsage: json['key_usage'] != null ? List<String>.from(json['key_usage']) : null,
        enhancedKeyUsage: json['enhanced_key_usage'] != null ? List<String>.from(json['enhanced_key_usage']) : null,
        policy: json['policy'] != null ? _parsePolicyFromJson(json['policy']) : null,
      );
    } catch (e) {
      AppLogger.error('Failed to parse certificate JSON', e);
      throw CertificateException('Failed to parse certificate data: $e');
    }
  }

  /// Parses a certificate policy from JSON response
  CertificatePolicy _parsePolicyFromJson(Map<String, dynamic> json) {
    try {
      return CertificatePolicy(
        issuerName: json['issuer']?['name'],
        certificateType: json['certificate_type'],
        certificateTransparency: json['certificate_transparency'],
        contentType: json['content_type'],
        subject: json['subject'],
        subjectAlternativeNames: json['san'] != null ? List<String>.from(json['san']) : null,
        validityInMonths: json['validity_in_months'],
        keyProperties: json['key_props'] != null ? _parseKeyPropertiesFromJson(json['key_props']) : null,
        secretProperties: json['secret_props'] != null ? _parseSecretPropertiesFromJson(json['secret_props']) : null,
        x509CertificateProperties: json['x509_props'] != null ? _parseX509PropertiesFromJson(json['x509_props']) : null,
        lifetimeAction: json['lifetime_actions'] != null && (json['lifetime_actions'] as List).isNotEmpty 
            ? _parseLifetimeActionFromJson(json['lifetime_actions'][0]) : null,
      );
    } catch (e) {
      AppLogger.error('Failed to parse certificate policy JSON', e);
      throw CertificateException('Failed to parse certificate policy data: $e');
    }
  }

  /// Parses key properties from JSON
  KeyProperties _parseKeyPropertiesFromJson(Map<String, dynamic> json) {
    return KeyProperties(
      exportable: json['exportable'],
      keyType: json['kty'],
      keySize: json['key_size'],
      reuseKey: json['reuse_key'],
      curve: json['crv'],
    );
  }

  /// Parses secret properties from JSON
  SecretProperties _parseSecretPropertiesFromJson(Map<String, dynamic> json) {
    return SecretProperties(
      contentType: json['contentType'],
    );
  }

  /// Parses X.509 properties from JSON
  X509CertificateProperties _parseX509PropertiesFromJson(Map<String, dynamic> json) {
    return X509CertificateProperties(
      subject: json['subject'],
      subjectAlternativeNames: json['sans'] != null ? List<String>.from(json['sans']) : null,
      keyUsage: json['key_usage'] != null ? List<String>.from(json['key_usage']) : null,
      enhancedKeyUsage: json['ekus'] != null ? List<String>.from(json['ekus']) : null,
      validityInMonths: json['validity_months'],
    );
  }

  /// Parses lifetime action from JSON
  LifetimeAction _parseLifetimeActionFromJson(Map<String, dynamic> json) {
    return LifetimeAction(
      action: json['action']?['action_type'],
      daysBeforeExpiry: json['trigger']?['days_before_expiry'],
      lifetimePercentage: json['trigger']?['lifetime_percentage'],
    );
  }

  /// Extracts the certificate name from the full certificate ID
  String _extractNameFromId(String id) {
    if (id.isEmpty) return '';
    
    // Certificate ID format: https://vault.vault.azure.net/certificates/certname/version
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

  /// Extracts the version from the full certificate ID
  String? _extractVersionFromId(String id) {
    if (id.isEmpty) return null;
    
    // Certificate ID format: https://vault.vault.azure.net/certificates/certname/version
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