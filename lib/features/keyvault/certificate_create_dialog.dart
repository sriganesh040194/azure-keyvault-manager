import 'package:flutter/material.dart';
import '../../core/logging/app_logger.dart';
import '../../services/keyvault/certificate_service.dart';
import '../../services/keyvault/certificate_models.dart';
import '../../shared/widgets/app_theme.dart';

class CertificateCreateDialog extends StatefulWidget {
  final String vaultName;
  final CertificateService certificateService;

  const CertificateCreateDialog({
    super.key,
    required this.vaultName,
    required this.certificateService,
  });

  @override
  State<CertificateCreateDialog> createState() => _CertificateCreateDialogState();
}

class _CertificateCreateDialogState extends State<CertificateCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _selectedKeyType = 'RSA';
  int _keySize = 2048;
  int _validityMonths = 12;
  bool _enabled = true;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _createCertificate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // Create a basic policy for demonstration
      final policy = CertificatePolicy(
        issuerName: 'Self',
        subject: _subjectController.text.trim(),
        validityInMonths: _validityMonths,
        keyProperties: KeyProperties(
          exportable: true,
          keyType: _selectedKeyType,
          keySize: _keySize,
          reuseKey: false,
        ),
        secretProperties: const SecretProperties(
          contentType: 'application/x-pkcs12',
        ),
        x509CertificateProperties: X509CertificateProperties(
          subject: _subjectController.text.trim(),
          keyUsage: ['digitalSignature', 'keyEncipherment'],
          validityInMonths: _validityMonths,
        ),
      );

      final request = CreateCertificateRequest(
        name: _nameController.text.trim(),
        policy: policy,
        enabled: _enabled,
        tags: _parseTags(_tagsController.text),
      );

      await widget.certificateService.createCertificate(widget.vaultName, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certificate "${_nameController.text}" creation initiated')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.error('Failed to create certificate', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create certificate: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Map<String, String>? _parseTags(String input) {
    if (input.trim().isEmpty) return null;

    final tags = <String, String>{};
    final pairs = input.split(',');

    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        tags[parts[0].trim()] = parts[1].trim();
      }
    }

    return tags.isEmpty ? null : tags;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppBorderRadius.lg),
                  topRight: Radius.circular(AppBorderRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: const Icon(
                      AppIcons.certificate,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Certificate',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Vault: ${widget.vaultName}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(AppIcons.close),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Certificate Name *',
                          hintText: 'Enter a unique name for the certificate',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          if (value.length < 3 || value.length > 127) {
                            return 'Name must be between 3 and 127 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(value)) {
                            return 'Name can only contain letters, numbers, and hyphens';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Subject
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject *',
                          hintText: 'CN=example.com, O=MyOrg, C=US',
                          helperText: 'Distinguished name for the certificate',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Subject is required';
                          }
                          if (!value.contains('CN=')) {
                            return 'Subject must contain at least a Common Name (CN=)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Key Type
                      DropdownButtonFormField<String>(
                        value: _selectedKeyType,
                        decoration: const InputDecoration(
                          labelText: 'Key Type',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'RSA', child: Text('RSA')),
                          DropdownMenuItem(value: 'EC', child: Text('Elliptic Curve (EC)')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedKeyType = value!;
                            if (_selectedKeyType == 'EC') {
                              _keySize = 256; // Default for EC
                            } else {
                              _keySize = 2048; // Default for RSA
                            }
                          });
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Key Size
                      DropdownButtonFormField<int>(
                        value: _keySize,
                        decoration: const InputDecoration(
                          labelText: 'Key Size',
                        ),
                        items: _selectedKeyType == 'RSA'
                            ? const [
                                DropdownMenuItem(value: 2048, child: Text('2048 bits')),
                                DropdownMenuItem(value: 3072, child: Text('3072 bits')),
                                DropdownMenuItem(value: 4096, child: Text('4096 bits')),
                              ]
                            : const [
                                DropdownMenuItem(value: 256, child: Text('P-256 (256 bits)')),
                                DropdownMenuItem(value: 384, child: Text('P-384 (384 bits)')),
                                DropdownMenuItem(value: 521, child: Text('P-521 (521 bits)')),
                              ],
                        onChanged: (value) {
                          setState(() {
                            _keySize = value!;
                          });
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Validity Period
                      DropdownButtonFormField<int>(
                        value: _validityMonths,
                        decoration: const InputDecoration(
                          labelText: 'Validity Period',
                        ),
                        items: const [
                          DropdownMenuItem(value: 6, child: Text('6 months')),
                          DropdownMenuItem(value: 12, child: Text('1 year')),
                          DropdownMenuItem(value: 24, child: Text('2 years')),
                          DropdownMenuItem(value: 36, child: Text('3 years')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _validityMonths = value!;
                          });
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Enabled
                      SwitchListTile(
                        title: const Text('Enabled'),
                        subtitle: const Text('Certificate will be active and usable'),
                        value: _enabled,
                        onChanged: (value) {
                          setState(() {
                            _enabled = value;
                          });
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Tags
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags',
                          hintText: 'environment:prod, department:IT',
                          helperText: 'Optional. Format: key:value pairs separated by commas',
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.info,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'This will create a self-signed certificate. For production use, consider using a trusted Certificate Authority.',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isCreating ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton(
                    onPressed: _isCreating ? null : _createCertificate,
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Certificate'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}