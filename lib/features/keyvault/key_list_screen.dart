import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/logging/app_logger.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';
import '../../services/keyvault/key_service.dart';
import '../../services/keyvault/key_models.dart';
import '../../services/keyvault/keyvault_service.dart' show KeyVaultService, KeyVaultInfo;
import '../../shared/widgets/app_theme.dart';
import 'key_create_dialog.dart';
import 'key_details_screen.dart';

class KeyListScreen extends StatefulWidget {
  final String? vaultName;
  final UnifiedAzureCliService cliService;

  const KeyListScreen({
    super.key,
    this.vaultName,
    required this.cliService,
  });

  @override
  State<KeyListScreen> createState() => _KeyListScreenState();
}

class _KeyListScreenState extends State<KeyListScreen> {
  late KeyService _keyService;
  late KeyVaultService _keyVaultService;
  List<KeyInfo> _keys = [];
  List<KeyInfo> _filteredKeys = [];
  List<KeyVaultInfo> _keyVaults = [];
  bool _isLoading = false;
  bool _isLoadingKeyVaults = false;
  String? _errorMessage;
  String? _selectedVaultName;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _keyService = KeyService(widget.cliService);
    _keyVaultService = KeyVaultService(widget.cliService);
    _searchController.addListener(_filterKeys);
    _selectedVaultName = widget.vaultName;
    _loadKeyVaults();
    if (_selectedVaultName != null && _selectedVaultName!.isNotEmpty) {
      _loadKeys();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKeyVaults() async {
    setState(() {
      _isLoadingKeyVaults = true;
    });

    try {
      final keyVaults = await _keyVaultService.listKeyVaults();
      setState(() {
        _keyVaults = keyVaults;
        _isLoadingKeyVaults = false;
        
        // If selected vault is no longer available, clear the selection
        if (_selectedVaultName != null && 
            !keyVaults.any((vault) => vault.name == _selectedVaultName)) {
          _selectedVaultName = null;
          _keys.clear();
          _filteredKeys.clear();
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingKeyVaults = false;
      });
      AppLogger.error('Failed to load key vaults', e);
    }
  }

  Future<void> _loadKeys() async {
    if (_selectedVaultName == null || _selectedVaultName!.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final keys = await _keyService.listKeys(_selectedVaultName!);
      setState(() {
        _keys = keys;
        _filteredKeys = keys;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      AppLogger.error('Failed to load keys', e);
    }
  }

  void _filterKeys() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredKeys = _keys;
      } else {
        _filteredKeys = _keys.where((key) =>
            key.name.toLowerCase().contains(query) ||
            (key.keyType?.toLowerCase().contains(query) ?? false)
        ).toList();
      }
    });
  }

  Future<void> _deleteKey(KeyInfo key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the key "${key.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _selectedVaultName != null) {
      try {
        await _keyService.deleteKey(_selectedVaultName!, key.name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Key "${key.name}" deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          await _loadKeys();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete key: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _createKey() async {
    if (_selectedVaultName == null) return;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => KeyCreateDialog(
        vaultName: _selectedVaultName!,
        keyService: _keyService,
      ),
    );

    if (result == true) {
      _loadKeys();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildKeyVaultSelector(),
        if (_selectedVaultName != null && _selectedVaultName!.isNotEmpty) _buildSearchBar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: const Icon(
              AppIcons.key,
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
                  'Keys',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedVaultName ?? 'No Key Vault selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _selectedVaultName != null ? _loadKeys : null,
            icon: const Icon(AppIcons.refresh),
            label: const Text('Refresh'),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: _selectedVaultName != null ? _createKey : null,
            icon: const Icon(AppIcons.add),
            label: const Text('Create Key'),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyVaultSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.keyVault),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _isLoadingKeyVaults
                ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Text('Loading Key Vaults...'),
                    ],
                  )
                : DropdownButton<String>(
                    hint: const Text('Select a Key Vault'),
                    value: _keyVaults.any((vault) => vault.name == _selectedVaultName) 
                        ? _selectedVaultName 
                        : null,
                    isExpanded: true,
                    items: _keyVaults.map((vault) {
                      return DropdownMenuItem<String>(
                        value: vault.name,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(vault.name),
                            ),
                            Text(
                              vault.location,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedVaultName = newValue;
                        _keys.clear();
                        _filteredKeys.clear();
                        _errorMessage = null;
                      });
                      if (newValue != null && newValue.isNotEmpty) {
                        _loadKeys();
                      }
                    },
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _loadKeyVaults,
            icon: const Icon(AppIcons.refresh),
            label: const Text('Refresh Vaults'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search keys...',
          prefixIcon: const Icon(AppIcons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(AppIcons.close),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedVaultName == null || _selectedVaultName!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.keyVault,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Select a Key Vault',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose a Key Vault from the dropdown above to view its keys',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Loading keys...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.error,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load keys',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.errorColor),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _loadKeys,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.key,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _searchController.text.isEmpty ? 'No keys found' : 'No keys match your search',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _searchController.text.isEmpty
                  ? 'Create your first key to get started'
                  : 'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _createKey,
                icon: const Icon(AppIcons.add),
                label: const Text('Create Key'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _filteredKeys.length,
      itemBuilder: (context, index) {
        final key = _filteredKeys[index];
        return _buildKeyCard(key);
      },
    );
  }

  Widget _buildKeyCard(KeyInfo key) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          if (_selectedVaultName != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => KeyDetailsScreen(
                  vaultName: _selectedVaultName!,
                  keyName: key.name,
                  cliService: widget.cliService,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getKeyTypeColor(key.keyType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Icon(
                      AppIcons.key,
                      color: _getKeyTypeColor(key.keyType),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${key.keyType ?? 'Unknown'} ${key.keySize != null ? '${key.keySize}-bit' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(key.status),
                  const SizedBox(width: AppSpacing.sm),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'copy_id':
                          Clipboard.setData(ClipboardData(text: key.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Key ID copied to clipboard')),
                          );
                          break;
                        case 'delete':
                          _deleteKey(key);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy_id',
                        child: Row(
                          children: [
                            Icon(AppIcons.copy),
                            SizedBox(width: AppSpacing.sm),
                            Text('Copy ID'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(AppIcons.delete, color: AppTheme.errorColor),
                            SizedBox(width: AppSpacing.sm),
                            Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Details
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  _buildDetailItem('Operations', key.operationsString),
                  if (key.curve != null) _buildDetailItem('Curve', key.curve!),
                  if (key.created != null)
                    _buildDetailItem('Created', _formatDate(key.created!)),
                  if (key.expires != null)
                    _buildDetailItem('Expires', _formatDate(key.expires!)),
                ],
              ),

              // Tags
              if (key.tags != null && key.tags!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: key.tags!.entries.map((entry) {
                    return Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      backgroundColor: Colors.grey[100],
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = AppTheme.successColor;
        break;
      case 'expired':
        color = AppTheme.errorColor;
        break;
      case 'disabled':
        color = AppTheme.warningColor;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getKeyTypeColor(String? keyType) {
    switch (keyType?.toLowerCase()) {
      case 'rsa':
      case 'rsa-hsm':
        return Colors.blue;
      case 'ec':
      case 'ec-hsm':
        return Colors.green;
      case 'oct':
      case 'oct-hsm':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}