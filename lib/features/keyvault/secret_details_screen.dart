import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/logging/app_logger.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';
import '../../services/keyvault/secret_service.dart';
import '../../services/keyvault/secret_models.dart';
import '../../shared/widgets/app_theme.dart';
import 'secret_update_dialog.dart';

class SecretDetailsScreen extends StatefulWidget {
  final String vaultName;
  final String secretName;
  final UnifiedAzureCliService cliService;

  const SecretDetailsScreen({
    super.key,
    required this.vaultName,
    required this.secretName,
    required this.cliService,
  });

  @override
  State<SecretDetailsScreen> createState() => _SecretDetailsScreenState();
}

class _SecretDetailsScreenState extends State<SecretDetailsScreen> {
  late SecretService _secretService;
  SecretInfo? _secret;
  SecretValue? _secretValue;
  bool _isLoading = false;
  bool _isLoadingValue = false;
  bool _isValueVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _secretService = SecretService(widget.cliService);
    _loadSecret();
  }

  Future<void> _loadSecret() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final secret = await _secretService.getSecret(widget.vaultName, widget.secretName);
      setState(() {
        _secret = secret;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      AppLogger.error('Failed to load secret details', e);
    }
  }

  Future<void> _loadSecretValue() async {
    if (_secretValue != null) {
      setState(() {
        _isValueVisible = !_isValueVisible;
      });
      return;
    }

    setState(() {
      _isLoadingValue = true;
    });

    try {
      final secretValue = await _secretService.getSecretValue(widget.vaultName, widget.secretName);
      setState(() {
        _secretValue = secretValue;
        _isValueVisible = true;
        _isLoadingValue = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingValue = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load secret value: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      AppLogger.error('Failed to load secret value', e);
    }
  }

  Future<void> _updateSecret() async {
    if (_secret == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SecretUpdateDialog(
        vaultName: widget.vaultName,
        secret: _secret!,
        secretService: _secretService,
      ),
    );

    if (result == true) {
      // Refresh the secret details after update
      await _loadSecret();
      // Clear the cached secret value to force re-fetch if needed
      setState(() {
        _secretValue = null;
        _isValueVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secret: ${widget.secretName}'),
        actions: [
          IconButton(
            onPressed: _loadSecret,
            icon: const Icon(AppIcons.refresh),
            tooltip: 'Refresh',
          ),
          if (_secret != null)
            IconButton(
              onPressed: _updateSecret,
              icon: const Icon(AppIcons.edit),
              tooltip: 'Update Secret',
            ),
        ],
      ),
      body: _buildContent(),
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
            Text('Loading secret details...'),
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
              'Failed to load secret details',
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
              onPressed: _loadSecret,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_secret == null) {
      return const Center(
        child: Text('Secret not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSecretHeader(),
          const SizedBox(height: AppSpacing.xl),
          _buildSecretValue(),
          const SizedBox(height: AppSpacing.xl),
          _buildSecretProperties(),
          if (_secret!.tags != null && _secret!.tags!.isNotEmpty) ...[ 
            const SizedBox(height: AppSpacing.xl),
            _buildTags(),
          ],
        ],
      ),
    );
  }

  Widget _buildSecretHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getStatusColor(_secret!.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: Icon(
                AppIcons.secret,
                color: _getStatusColor(_secret!.status),
                size: 30,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _secret!.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.vaultName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _buildStatusChip(_secret!.status),
                      if (_secret!.contentType != null) ...[ 
                        const SizedBox(width: AppSpacing.md),
                        _buildContentTypeChip(_secret!.contentType!),
                      ],
                      if (_secret!.daysUntilExpiration != null) ...[ 
                        const SizedBox(width: AppSpacing.md),
                        _buildExpiryChip(_secret!.daysUntilExpiration!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _secret!.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Secret ID copied to clipboard')),
                );
              },
              icon: const Icon(AppIcons.copy),
              tooltip: 'Copy Secret ID',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecretValue() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Secret Value',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_secretValue != null && _isValueVisible)
                  IconButton(
                    onPressed: () {
                      if (_secretValue != null) {
                        Clipboard.setData(ClipboardData(text: _secretValue!.value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Secret value copied to clipboard')),
                        );
                      }
                    },
                    icon: const Icon(AppIcons.copy),
                    tooltip: 'Copy Secret Value',
                  ),
                OutlinedButton.icon(
                  onPressed: _updateSecret,
                  icon: const Icon(AppIcons.edit),
                  label: const Text('Update'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _isLoadingValue ? null : _loadSecretValue,
                  icon: _isLoadingValue 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_isValueVisible ? AppIcons.visibilityOff : AppIcons.visibility),
                  label: Text(_isValueVisible ? 'Hide Value' : 'Show Value'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isValueVisible && _secretValue != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  _secretValue!.value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.lock,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Secret value is hidden for security',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecretProperties() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Properties',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildPropertyGrid([
              _PropertyItem('Secret ID', _secret!.id),
              _PropertyItem('Name', _secret!.name),
              if (_secret!.contentType != null) _PropertyItem('Content Type', _secret!.contentType!),
              _PropertyItem('Enabled', _secret!.enabled?.toString() ?? 'Unknown'),
              if (_secret!.created != null) _PropertyItem('Created', _formatDate(_secret!.created!)),
              if (_secret!.updated != null) _PropertyItem('Updated', _formatDate(_secret!.updated!)),
              if (_secret!.expires != null) _PropertyItem('Expires', _formatDate(_secret!.expires!)),
              if (_secret!.notBefore != null) _PropertyItem('Not Before', _formatDate(_secret!.notBefore!)),
              if (_secret!.recoveryLevel != null) _PropertyItem('Recovery Level', _secret!.recoveryLevel!),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _secret!.tags!.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key}: ${entry.value}'),
                  backgroundColor: Colors.grey[100],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyGrid(List<_PropertyItem> properties) {
    return Column(
      children: properties.map((property) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  property.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  property.value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContentTypeChip(String contentType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Text(
        contentType,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 14,
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
      text = 'Expired ${-daysUntilExpiration} days ago';
    } else if (daysUntilExpiration <= 30) {
      color = AppTheme.warningColor;
      text = 'Expires in $daysUntilExpiration days';
    } else {
      color = AppTheme.successColor;
      text = 'Expires in $daysUntilExpiration days';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PropertyItem {
  final String label;
  final String value;

  _PropertyItem(this.label, this.value);
}