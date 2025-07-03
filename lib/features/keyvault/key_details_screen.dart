import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/logging/app_logger.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';
import '../../services/keyvault/key_service.dart';
import '../../services/keyvault/key_models.dart';
import '../../shared/widgets/app_theme.dart';

class KeyDetailsScreen extends StatefulWidget {
  final String vaultName;
  final String keyName;
  final UnifiedAzureCliService cliService;

  const KeyDetailsScreen({
    super.key,
    required this.vaultName,
    required this.keyName,
    required this.cliService,
  });

  @override
  State<KeyDetailsScreen> createState() => _KeyDetailsScreenState();
}

class _KeyDetailsScreenState extends State<KeyDetailsScreen> {
  late KeyService _keyService;
  KeyInfo? _key;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _keyService = KeyService(widget.cliService);
    _loadKey();
  }

  Future<void> _loadKey() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final key = await _keyService.getKey(widget.vaultName, widget.keyName);
      setState(() {
        _key = key;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      AppLogger.error('Failed to load key details', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Key: ${widget.keyName}'),
        actions: [
          IconButton(
            onPressed: _loadKey,
            icon: const Icon(AppIcons.refresh),
            tooltip: 'Refresh',
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
            Text('Loading key details...'),
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
              'Failed to load key details',
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
              onPressed: _loadKey,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_key == null) {
      return const Center(
        child: Text('Key not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKeyHeader(),
          const SizedBox(height: AppSpacing.xl),
          _buildKeyProperties(),
          const SizedBox(height: AppSpacing.xl),
          _buildKeyOperations(),
          if (_key!.tags != null && _key!.tags!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildTags(),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getKeyTypeColor(_key!.keyType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: Icon(
                AppIcons.key,
                color: _getKeyTypeColor(_key!.keyType),
                size: 30,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _key!.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${_key!.keyType ?? 'Unknown'} ${_key!.keySize != null ? '${_key!.keySize}-bit' : ''}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatusChip(_key!.status),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _key!.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Key ID copied to clipboard')),
                    );
                  },
                  icon: const Icon(AppIcons.copy),
                  tooltip: 'Copy Key ID',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyProperties() {
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
              _PropertyItem('Key ID', _key!.id),
              _PropertyItem('Name', _key!.name),
              _PropertyItem('Type', _key!.keyType ?? 'Unknown'),
              if (_key!.keySize != null) _PropertyItem('Size', '${_key!.keySize} bits'),
              if (_key!.curve != null) _PropertyItem('Curve', _key!.curve!),
              _PropertyItem('Version', _key!.version ?? 'Unknown'),
              _PropertyItem('Enabled', _key!.enabled?.toString() ?? 'Unknown'),
              if (_key!.created != null) _PropertyItem('Created', _formatDate(_key!.created!)),
              if (_key!.updated != null) _PropertyItem('Updated', _formatDate(_key!.updated!)),
              if (_key!.expires != null) _PropertyItem('Expires', _formatDate(_key!.expires!)),
              if (_key!.notBefore != null) _PropertyItem('Not Before', _formatDate(_key!.notBefore!)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyOperations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permitted Operations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_key!.keyOps != null && _key!.keyOps!.isNotEmpty)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _key!.keyOps!.map((operation) {
                  return Chip(
                    label: Text(operation),
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  );
                }).toList(),
              )
            else
              Text(
                'No operations specified',
                style: TextStyle(color: Colors.grey[600]),
              ),
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
              children: _key!.tags!.entries.map((entry) {
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
                width: 120,
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
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PropertyItem {
  final String label;
  final String value;

  _PropertyItem(this.label, this.value);
}