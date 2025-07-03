import 'package:flutter/material.dart';
import '../../core/logging/app_logger.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';
import '../../services/keyvault/secret_service.dart';
import '../../services/keyvault/secret_models.dart';
import '../../shared/widgets/app_theme.dart';
import 'secret_create_dialog.dart';
import 'secret_details_screen.dart';

class SecretListScreen extends StatefulWidget {
  final String vaultName;
  final UnifiedAzureCliService cliService;

  const SecretListScreen({
    super.key,
    required this.vaultName,
    required this.cliService,
  });

  @override
  State<SecretListScreen> createState() => _SecretListScreenState();
}

class _SecretListScreenState extends State<SecretListScreen> {
  late SecretService _secretService;
  List<SecretInfo> _secrets = [];
  List<SecretInfo> _filteredSecrets = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _secretService = SecretService(widget.cliService);
    _searchController.addListener(_filterSecrets);
    _loadSecrets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSecrets() async {
    if (widget.vaultName.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final secrets = await _secretService.listSecrets(widget.vaultName);
      setState(() {
        _secrets = secrets;
        _filteredSecrets = secrets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      AppLogger.error('Failed to load secrets', e);
    }
  }

  void _filterSecrets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSecrets = _secrets.where((secret) {
        return secret.name.toLowerCase().contains(query) ||
               (secret.contentType?.toLowerCase().contains(query) ?? false) ||
               secret.status.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _createSecret() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SecretCreateDialog(
        vaultName: widget.vaultName,
        secretService: _secretService,
      ),
    );

    if (result == true) {
      await _loadSecrets();
    }
  }

  void _viewSecretDetails(SecretInfo secret) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecretDetailsScreen(
          vaultName: widget.vaultName,
          secretName: secret.name,
          cliService: widget.cliService,
        ),
      ),
    );
  }

  Future<void> _deleteSecret(SecretInfo secret) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Secret'),
        content: Text('Are you sure you want to delete the secret "${secret.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _secretService.deleteSecret(widget.vaultName, secret.name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Secret "${secret.name}" deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          await _loadSecrets();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete secret: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vaultName.isEmpty) {
      return const Center(
        child: Text('Please select a Key Vault to view secrets'),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
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
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: const Icon(
              AppIcons.secret,
              color: AppTheme.successColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secrets',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.vaultName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _loadSecrets,
            icon: const Icon(AppIcons.refresh),
            label: const Text('Refresh'),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: _createSecret,
            icon: const Icon(AppIcons.add),
            label: const Text('Create Secret'),
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
          hintText: 'Search secrets by name, content type, or status...',
          prefixIcon: const Icon(AppIcons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
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
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Loading secrets...'),
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
              'Failed to load secrets',
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
              onPressed: _loadSecrets,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredSecrets.isEmpty) {
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
                AppIcons.secret,
                size: 60,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _searchController.text.isNotEmpty ? 'No matching secrets found' : 'No secrets found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _searchController.text.isNotEmpty 
                  ? 'Try adjusting your search criteria'
                  : 'Create your first secret to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_searchController.text.isEmpty)
              FilledButton.icon(
                onPressed: _createSecret,
                icon: const Icon(AppIcons.add),
                label: const Text('Create Secret'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _filteredSecrets.length,
      itemBuilder: (context, index) {
        final secret = _filteredSecrets[index];
        return _buildSecretCard(secret);
      },
    );
  }

  Widget _buildSecretCard(SecretInfo secret) {
    final statusColor = _getStatusColor(secret.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _viewSecretDetails(secret),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(
                  AppIcons.secret,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      secret.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _buildStatusChip(secret.status, statusColor),
                        if (secret.contentType != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _buildContentTypeChip(secret.contentType!),
                        ],
                        if (secret.daysUntilExpiration != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _buildExpiryChip(secret.daysUntilExpiration!),
                        ],
                      ],
                    ),
                    if (secret.created != null || secret.updated != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _buildDateInfo(secret),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _viewSecretDetails(secret);
                      break;
                    case 'delete':
                      _deleteSecret(secret);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(AppIcons.visibility),
                      title: Text('View Details'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(AppIcons.delete, color: AppTheme.errorColor),
                      title: Text('Delete'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
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

  Widget _buildContentTypeChip(String contentType) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Text(
        contentType,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExpiryChip(int daysUntilExpiration) {
    Color color;
    String text;

    if (daysUntilExpiration < 0) {
      color = AppTheme.errorColor;
      text = 'Expired';
    } else if (daysUntilExpiration <= 30) {
      color = AppTheme.warningColor;
      text = 'Expires soon';
    } else {
      color = AppTheme.successColor;
      text = 'Valid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.successColor;
      case 'expired':
        return AppTheme.errorColor;
      case 'disabled':
        return AppTheme.warningColor;
      case 'not active':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _buildDateInfo(SecretInfo secret) {
    final parts = <String>[];
    
    if (secret.created != null) {
      parts.add('Created: ${_formatDate(secret.created!)}');
    }
    if (secret.updated != null) {
      parts.add('Updated: ${_formatDate(secret.updated!)}');
    }
    if (secret.expires != null) {
      parts.add('Expires: ${_formatDate(secret.expires!)}');
    }
    
    return parts.join(' • ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}