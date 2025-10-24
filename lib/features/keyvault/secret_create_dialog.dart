import 'package:flutter/material.dart';
import '../../core/logging/app_logger.dart';
import '../../services/keyvault/secret_service.dart';
import '../../services/keyvault/secret_models.dart';
import '../../shared/widgets/app_theme.dart';

class SecretCreateDialog extends StatefulWidget {
  final String vaultName;
  final SecretService secretService;

  const SecretCreateDialog({
    super.key,
    required this.vaultName,
    required this.secretService,
  });

  @override
  State<SecretCreateDialog> createState() => _SecretCreateDialogState();
}

class _SecretCreateDialogState extends State<SecretCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String? _selectedContentType;
  bool _enabled = true;
  bool _isValueVisible = false;
  bool _isCreating = false;
  DateTime? _expiryDate;
  DateTime? _notBeforeDate;

  final List<String> _contentTypes = [
    'text/plain',
    'application/json',
    'application/x-pkcs12',
    'application/x-pem-file',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _createSecret() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final request = CreateSecretRequest(
        name: _nameController.text.trim(),
        value: _valueController.text,
        contentType: _selectedContentType,
        enabled: _enabled,
        expires: _expiryDate,
        notBefore: _notBeforeDate,
        tags: _parseTags(_tagsController.text),
      );

      await widget.secretService.setSecret(widget.vaultName, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Secret "${_nameController.text}" created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.error('Failed to create secret', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create secret: $e'),
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

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
    );

    if (date != null) {
      setState(() {
        _expiryDate = date;
      });
    }
  }

  Future<void> _selectNotBeforeDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _notBeforeDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _notBeforeDate = date;
      });
    }
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
                color: AppTheme.successColor.withValues(alpha: 0.1),
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
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: const Icon(
                      AppIcons.secret,
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
                          'Create Secret',
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
                          labelText: 'Secret Name *',
                          hintText: 'Enter a unique name for the secret',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          if (value.length < 1 || value.length > 127) {
                            return 'Name must be between 1 and 127 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(value)) {
                            return 'Name can only contain letters, numbers, and hyphens';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Value
                      TextFormField(
                        controller: _valueController,
                        decoration: InputDecoration(
                          labelText: 'Secret Value *',
                          hintText: 'Enter the secret value',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isValueVisible = !_isValueVisible;
                              });
                            },
                            icon: Icon(
                              _isValueVisible ? AppIcons.visibilityOff : AppIcons.visibility,
                            ),
                          ),
                        ),
                        obscureText: !_isValueVisible,
                        maxLines: _isValueVisible ? 3 : 1,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Secret value is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Content Type
                      DropdownButtonFormField<String>(
                        value: _selectedContentType,
                        decoration: const InputDecoration(
                          labelText: 'Content Type',
                          helperText: 'Optional. Specify the type of content stored',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._contentTypes.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedContentType = value;
                          });
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Enabled
                      SwitchListTile(
                        title: const Text('Enabled'),
                        subtitle: const Text('Secret will be active and accessible'),
                        value: _enabled,
                        onChanged: (value) {
                          setState(() {
                            _enabled = value;
                          });
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Expiry Date
                      ListTile(
                        title: const Text('Expiry Date'),
                        subtitle: Text(_expiryDate != null 
                            ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                            : 'No expiry date set'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _selectExpiryDate,
                              icon: const Icon(AppIcons.calendar),
                            ),
                            if (_expiryDate != null)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _expiryDate = null;
                                  });
                                },
                                icon: const Icon(AppIcons.close),
                              ),
                          ],
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),

                      // Not Before Date
                      ListTile(
                        title: const Text('Not Before Date'),
                        subtitle: Text(_notBeforeDate != null 
                            ? '${_notBeforeDate!.day}/${_notBeforeDate!.month}/${_notBeforeDate!.year}'
                            : 'Active immediately'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _selectNotBeforeDate,
                              icon: const Icon(AppIcons.calendar),
                            ),
                            if (_notBeforeDate != null)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _notBeforeDate = null;
                                  });
                                },
                                icon: const Icon(AppIcons.close),
                              ),
                          ],
                        ),
                        contentPadding: EdgeInsets.zero,
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
                                'Secret values are encrypted and stored securely in Azure Key Vault. Access is logged and audited.',
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
                    onPressed: _isCreating ? null : _createSecret,
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Secret'),
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