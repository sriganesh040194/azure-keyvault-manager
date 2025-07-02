import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/azure_cli/azure_cli_service.dart';
import '../../shared/widgets/app_theme.dart';
import '../../core/logging/app_logger.dart';
import 'key_vault_create_dialog.dart';

class KeyVaultInfo {
  final String name;
  final String resourceGroup;
  final String location;
  final String subscriptionId;
  final Map<String, String> tags;
  final DateTime? createdDate;
  final String status;

  KeyVaultInfo({
    required this.name,
    required this.resourceGroup,
    required this.location,
    required this.subscriptionId,
    this.tags = const {},
    this.createdDate,
    required this.status,
  });

  factory KeyVaultInfo.fromJson(Map<String, dynamic> json) {
    return KeyVaultInfo(
      name: json['name'] as String? ?? '',
      resourceGroup: (json['resourceGroup'] as String?)?.split('/').last ?? '',
      location: json['location'] as String? ?? '',
      subscriptionId: json['subscriptionId'] as String? ?? '',
      tags: Map<String, String>.from(json['tags'] as Map? ?? {}),
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'] as String)
          : null,
      status: json['status'] as String? ?? 'Unknown',
    );
  }
}

class KeyVaultListScreen extends StatefulWidget {
  final AzureCliService azureCliService;
  final Function(String) onKeyVaultSelected;

  const KeyVaultListScreen({
    super.key,
    required this.azureCliService,
    required this.onKeyVaultSelected,
  });

  @override State<KeyVaultListScreen> createState() => _KeyVaultListScreenState();
}

class _KeyVaultListScreenState extends State<KeyVaultListScreen> {
  List<KeyVaultInfo> _keyVaults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedResourceGroup;
  bool _isAzureCliReady = false;

  @override
  void initState() {
    super.initState();
    _checkAzureCliAndLoadKeyVaults();
  }

  Future<void> _checkAzureCliAndLoadKeyVaults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if Azure CLI is ready
      _isAzureCliReady = await widget.azureCliService.isAzureCliReady();
      
      if (!_isAzureCliReady) {
        setState(() {
          _errorMessage = 'Azure CLI is not installed or not authenticated. Please install Azure CLI and run "az login" to authenticate.';
          _isLoading = false;
        });
        return;
      }

      await _loadKeyVaults();
    } catch (e) {
      AppLogger.error('Failed to check Azure CLI status', e);
      setState(() {
        _errorMessage = 'Failed to check Azure CLI status: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadKeyVaults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.azureCliService.listKeyVaults(
        resourceGroup: _selectedResourceGroup,
      );

      if (result.success) {
        final List<dynamic> keyVaultsJson = json.decode(result.output);
        setState(() {
          _keyVaults = keyVaultsJson
              .map((json) => KeyVaultInfo.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
        
        AppLogger.info('Loaded ${_keyVaults.length} Key Vaults');
      } else {
        setState(() {
          _errorMessage = 'Failed to load Key Vaults: ${result.error}';
          _isLoading = false;
        });
        AppLogger.error('Failed to load Key Vaults', result.error);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading Key Vaults: ${e.toString()}';
        _isLoading = false;
      });
      AppLogger.error('Error loading Key Vaults', e);
    }
  }

  Future<void> _createKeyVault() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => KeyVaultCreateDialog(
        azureCliService: widget.azureCliService,
      ),
    );

    if (result != null) {
      // Refresh the list after creating a new Key Vault
      await _loadKeyVaults();
    }
  }

  Future<void> _deleteKeyVault(KeyVaultInfo keyVault) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Key Vault'),
        content: Text(
          'Are you sure you want to delete the Key Vault "${keyVault.name}"?\n\n'
          'This action cannot be undone and will permanently delete all secrets, keys, and certificates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await widget.azureCliService.deleteKeyVault(keyVault.name);
        
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Key Vault "${keyVault.name}" deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          await _loadKeyVaults();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete Key Vault: ${result.error}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting Key Vault: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<KeyVaultInfo> get _filteredKeyVaults {
    if (_searchQuery.isEmpty) {
      return _keyVaults;
    }

    return _keyVaults.where((kv) {
      final query = _searchQuery.toLowerCase();
      return kv.name.toLowerCase().contains(query) ||
          kv.resourceGroup.toLowerCase().contains(query) ||
          kv.location.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Vaults',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Manage your Azure Key Vaults and their resources',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (_isAzureCliReady) ...[
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _loadKeyVaults,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Refresh'),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton.icon(
              onPressed: _isLoading ? null : _createKeyVault,
              icon: const Icon(AppIcons.add),
              label: const Text('Create Key Vault'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search Key Vaults...',
                prefixIcon: Icon(AppIcons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          DropdownButton<String?>(
            hint: const Text('All Resource Groups'),
            value: _selectedResourceGroup,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Resource Groups'),
              ),
              // Add more resource group options here
            ],
            onChanged: (value) {
              setState(() {
                _selectedResourceGroup = value;
              });
              _loadKeyVaults();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKeyVaultCard(KeyVaultInfo keyVault) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        onTap: () => widget.onKeyVaultSelected(keyVault.name),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      AppIcons.keyVault,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          keyVault.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${keyVault.resourceGroup} • ${keyVault.location}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'delete':
                          _deleteKeyVault(keyVault);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(AppIcons.delete, color: AppTheme.errorColor),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    child: const Icon(AppIcons.more),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Tags
              if (keyVault.tags.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: keyVault.tags.entries
                      .take(3)
                      .map((entry) => Chip(
                        label: Text('${entry.key}: ${entry.value}'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              AppIcons.keyVault,
              size: 60,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No Key Vaults Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _searchQuery.isNotEmpty
                ? 'No Key Vaults match your search criteria'
                : 'Create your first Key Vault to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isAzureCliReady && _searchQuery.isEmpty)
            FilledButton.icon(
              onPressed: _createKeyVault,
              icon: const Icon(AppIcons.add),
              label: const Text('Create Key Vault'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.error,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Error Loading Key Vaults',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _checkAzureCliAndLoadKeyVaults,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        
        if (_isAzureCliReady && !_isLoading && _errorMessage == null)
          _buildSearchAndFilters(),
        
        const SizedBox(height: AppSpacing.lg),
        
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorState()
                  : _filteredKeyVaults.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _filteredKeyVaults.length,
                          itemBuilder: (context, index) {
                            return _buildKeyVaultCard(_filteredKeyVaults[index]);
                          },
                        ),
        ),
      ],
    );
  }
}