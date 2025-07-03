import 'package:flutter/material.dart';
import '../../core/logging/app_logger.dart';
import '../../services/keyvault/key_service.dart';
import '../../services/keyvault/key_models.dart';
import '../../shared/widgets/app_theme.dart';

class KeyCreateDialog extends StatefulWidget {
  final String vaultName;
  final KeyService keyService;

  const KeyCreateDialog({
    super.key,
    required this.vaultName,
    required this.keyService,
  });

  @override
  State<KeyCreateDialog> createState() => _KeyCreateDialogState();
}

class _KeyCreateDialogState extends State<KeyCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagsController = TextEditingController();
  
  KeyType _selectedKeyType = KeyType.rsa;
  int? _keySize = 2048;
  EllipticCurve? _selectedCurve;
  Set<KeyOperation> _selectedOperations = {
    KeyOperation.encrypt,
    KeyOperation.decrypt,
    KeyOperation.sign,
    KeyOperation.verify,
  };
  bool _enabled = true;
  DateTime? _expiryDate;
  DateTime? _notBeforeDate;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Map<String, int> get _rsaKeySizes => {
    '2048 bits': 2048,
    '3072 bits': 3072,
    '4096 bits': 4096,
  };

  List<KeyOperation> get _availableOperations => [
    KeyOperation.encrypt,
    KeyOperation.decrypt,
    KeyOperation.sign,
    KeyOperation.verify,
    KeyOperation.wrapKey,
    KeyOperation.unwrapKey,
  ];

  Future<void> _createKey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final request = CreateKeyRequest(
        name: _nameController.text.trim(),
        keyType: _selectedKeyType.value,
        keySize: _isRsaType ? _keySize : null,
        curve: _isEcType ? _selectedCurve?.value : null,
        keyOps: _selectedOperations.map((op) => op.value).toList(),
        expires: _expiryDate,
        notBefore: _notBeforeDate,
        enabled: _enabled,
        tags: _parseTags(_tagsController.text),
      );

      await widget.keyService.createKey(widget.vaultName, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Key "${_nameController.text}" created successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.error('Failed to create key', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create key: $e'),
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

  bool get _isRsaType => _selectedKeyType == KeyType.rsa || _selectedKeyType == KeyType.rsaHsm;
  bool get _isEcType => _selectedKeyType == KeyType.ec || _selectedKeyType == KeyType.ecHsm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 800),
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
                      AppIcons.key,
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
                          'Create Key',
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
                          labelText: 'Key Name *',
                          hintText: 'Enter a unique name for the key',
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

                      // Key Type
                      Text(
                        'Key Type *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: KeyType.values.map((type) {
                          return ChoiceChip(
                            label: Text(type.value),
                            selected: _selectedKeyType == type,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedKeyType = type;
                                  // Reset type-specific settings
                                  if (_isRsaType) {
                                    _keySize = 2048;
                                    _selectedCurve = null;
                                  } else if (_isEcType) {
                                    _keySize = null;
                                    _selectedCurve = EllipticCurve.p256;
                                  } else {
                                    _keySize = null;
                                    _selectedCurve = null;
                                  }
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // RSA Key Size
                      if (_isRsaType) ...[
                        Text(
                          'Key Size',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<int>(
                          value: _keySize,
                          decoration: const InputDecoration(
                            labelText: 'RSA Key Size',
                          ),
                          items: _rsaKeySizes.entries.map((entry) {
                            return DropdownMenuItem<int>(
                              value: entry.value,
                              child: Text(entry.key),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _keySize = value;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // EC Curve
                      if (_isEcType) ...[
                        Text(
                          'Elliptic Curve',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<EllipticCurve>(
                          value: _selectedCurve,
                          decoration: const InputDecoration(
                            labelText: 'Curve',
                          ),
                          items: EllipticCurve.values.map((curve) {
                            return DropdownMenuItem<EllipticCurve>(
                              value: curve,
                              child: Text(curve.value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCurve = value;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Key Operations
                      Text(
                        'Key Operations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _availableOperations.map((operation) {
                          return FilterChip(
                            label: Text(operation.value),
                            selected: _selectedOperations.contains(operation),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedOperations.add(operation);
                                } else {
                                  _selectedOperations.remove(operation);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Enabled
                      SwitchListTile(
                        title: const Text('Enabled'),
                        subtitle: const Text('Key will be active and usable'),
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
                        leading: const Icon(AppIcons.timer),
                        title: const Text('Expiry Date'),
                        subtitle: Text(_expiryDate?.toString() ?? 'No expiry set'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_expiryDate != null)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _expiryDate = null;
                                  });
                                },
                                icon: const Icon(AppIcons.close),
                              ),
                            IconButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _expiryDate = date;
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Tags
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags',
                          hintText: 'key1:value1, key2:value2',
                          helperText: 'Optional. Format: key:value pairs separated by commas',
                        ),
                        maxLines: 2,
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
                    onPressed: _isCreating ? null : _createKey,
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Key'),
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