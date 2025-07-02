import 'package:flutter/material.dart';
import '../../services/azure_cli/azure_cli_service.dart';
import '../../core/security/input_validator.dart';
import '../../shared/widgets/app_theme.dart';
import '../../core/logging/app_logger.dart';

class KeyVaultCreateDialog extends StatefulWidget {
  final AzureCliService azureCliService;

  const KeyVaultCreateDialog({
    super.key,
    required this.azureCliService,
  });

  @override State<KeyVaultCreateDialog> createState() => _KeyVaultCreateDialogState();
}

class _KeyVaultCreateDialogState extends State<KeyVaultCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _resourceGroupController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagKeyController = TextEditingController();
  final _tagValueController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, String> _tags = {};
  
  final List<String> _commonLocations = [
    'eastus',
    'westus2',
    'centralus',
    'northeurope',
    'westeurope',
    'southeastasia',
    'eastasia',
    'australiaeast',
    'canadacentral',
    'uksouth',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _resourceGroupController.dispose();
    _locationController.dispose();
    _tagKeyController.dispose();
    _tagValueController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Key Vault name is required';
    }
    return InputValidator.validateResourceName(value);
  }

  String? _validateResourceGroup(String? value) {
    if (value == null || value.isEmpty) {
      return 'Resource group is required';
    }
    return InputValidator.validateResourceGroup(value);
  }

  String? _validateLocation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Location is required';
    }
    return null;
  }

  void _addTag() {
    final key = _tagKeyController.text.trim();
    final value = _tagValueController.text.trim();
    
    if (key.isNotEmpty && value.isNotEmpty) {
      setState(() {
        _tags[key] = value;
      });
      _tagKeyController.clear();
      _tagValueController.clear();
    }
  }

  void _removeTag(String key) {
    setState(() {
      _tags.remove(key);
    });
  }

  Future<void> _createKeyVault() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await widget.azureCliService.createKeyVault(
        name: _nameController.text.trim(),
        resourceGroup: _resourceGroupController.text.trim(),
        location: _locationController.text.trim(),
        tags: _tags.isNotEmpty ? _tags : null,
      );

      if (result.success) {
        AppLogger.info('Key Vault created successfully: ${_nameController.text}');
        
        if (mounted) {
          Navigator.of(context).pop({
            'name': _nameController.text.trim(),
            'resourceGroup': _resourceGroupController.text.trim(),
            'location': _locationController.text.trim(),
            'tags': _tags,
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Key Vault "${_nameController.text}" created successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        AppLogger.error('Failed to create Key Vault', result.error);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create Key Vault: ${result.error}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error creating Key Vault', e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating Key Vault: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        
        // Add tag form
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagKeyController,
                decoration: const InputDecoration(
                  labelText: 'Key',
                  hintText: 'e.g., Environment',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _tagValueController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  hintText: 'e.g., Production',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: _addTag,
              icon: const Icon(AppIcons.add),
              tooltip: 'Add Tag',
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Display existing tags
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _tags.entries.map((entry) {
              return Chip(
                label: Text('${entry.key}: ${entry.value}'),
                deleteIcon: const Icon(AppIcons.close, size: 16),
                onDeleted: () => _removeTag(entry.key),
              );
            }).toList(),
          ),
        ] else ...[
          Text(
            'No tags added',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              AppIcons.keyVault,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text('Create Key Vault'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Key Vault Name *',
                    hintText: 'Enter a unique name for your Key Vault',
                    helperText: '3-24 characters, letters, numbers, and hyphens only',
                  ),
                  validator: _validateName,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Resource Group field
                TextFormField(
                  controller: _resourceGroupController,
                  decoration: const InputDecoration(
                    labelText: 'Resource Group *',
                    hintText: 'Enter the resource group name',
                  ),
                  validator: _validateResourceGroup,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Location field
                DropdownButtonFormField<String>(
                  value: _locationController.text.isNotEmpty ? _locationController.text : null,
                  decoration: const InputDecoration(
                    labelText: 'Location *',
                    hintText: 'Select a location',
                  ),
                  validator: _validateLocation,
                  items: _commonLocations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: _isLoading ? null : (value) {
                    if (value != null) {
                      _locationController.text = value;
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Tags section
                _buildTagsSection(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _createKeyVault,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}