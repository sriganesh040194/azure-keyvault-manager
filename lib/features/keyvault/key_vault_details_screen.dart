import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/logging/app_logger.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';
import '../../services/keyvault/keyvault_service.dart';
import '../../services/keyvault/secret_service.dart';
import '../../services/keyvault/key_service.dart';
import '../../services/keyvault/certificate_service.dart';
import '../../shared/widgets/app_theme.dart';
import 'key_vault_tabbed_screen.dart';

class KeyVaultDetailsScreen extends StatefulWidget {
  final String vaultName;
  final UnifiedAzureCliService cliService;

  const KeyVaultDetailsScreen({
    super.key,
    required this.vaultName,
    required this.cliService,
  });

  @override
  State<KeyVaultDetailsScreen> createState() => _KeyVaultDetailsScreenState();
}

class _KeyVaultDetailsScreenState extends State<KeyVaultDetailsScreen> {
  late KeyVaultService _keyVaultService;
  late SecretService _secretService;
  late KeyService _keyService;
  late CertificateService _certificateService;

  KeyVaultInfo? _vaultInfo;
  bool _isLoadingVault = false;
  String? _vaultError;

  // Statistics
  int _secretCount = 0;
  int _keyCount = 0;
  int _certificateCount = 0;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _keyVaultService = KeyVaultService(widget.cliService);
    _secretService = SecretService(widget.cliService);
    _keyService = KeyService(widget.cliService);
    _certificateService = CertificateService(widget.cliService);
    _loadVaultDetails();
    _loadStatistics();
  }

  Future<void> _loadVaultDetails() async {
    setState(() {
      _isLoadingVault = true;
      _vaultError = null;
    });

    try {
      final vaultInfo = await _keyVaultService.getKeyVault(widget.vaultName);
      setState(() {
        _vaultInfo = vaultInfo;
        _isLoadingVault = false;
      });
    } catch (e) {
      setState(() {
        _vaultError = e.toString();
        _isLoadingVault = false;
      });
      AppLogger.error('Failed to load vault details: ${widget.vaultName}', e);
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final results = await Future.wait([
        _secretService.listSecrets(widget.vaultName).then((secrets) => secrets.length),
        _keyService.listKeys(widget.vaultName).then((keys) => keys.length),
        _certificateService.listCertificates(widget.vaultName).then((certs) => certs.length),
      ]);

      setState(() {
        _secretCount = results[0];
        _keyCount = results[1];
        _certificateCount = results[2];
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      AppLogger.error('Failed to load vault statistics: ${widget.vaultName}', e);
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadVaultDetails(),
      _loadStatistics(),
    ]);
  }

  void _navigateToTabbed(int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KeyVaultTabbedScreen(
          vaultName: widget.vaultName,
          cliService: widget.cliService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KeyVault: ${widget.vaultName}'),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(AppIcons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoadingVault) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Loading KeyVault details...'),
          ],
        ),
      );
    }

    if (_vaultError != null) {
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
              'Failed to load KeyVault details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _vaultError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.errorColor),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _loadVaultDetails,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_vaultInfo == null) {
      return const Center(
        child: Text('KeyVault not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVaultHeader(),
          const SizedBox(height: AppSpacing.xl),
          _buildStatisticsCards(),
          const SizedBox(height: AppSpacing.xl),
          _buildQuickActions(),
          const SizedBox(height: AppSpacing.xl),
          _buildVaultProperties(),
          if (_vaultInfo!.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildTags(),
          ],
        ],
      ),
    );
  }

  Widget _buildVaultHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: const Icon(
                AppIcons.keyVault,
                color: AppTheme.primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _vaultInfo!.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _vaultInfo!.location,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Chip(
                    label: Text(_vaultInfo!.resourceGroup),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _vaultInfo!.vaultUri));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vault URI copied to clipboard')),
                    );
                  },
                  icon: const Icon(AppIcons.copy),
                  tooltip: 'Copy Vault URI',
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _vaultInfo!.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Resource ID copied to clipboard')),
                    );
                  },
                  icon: const Icon(AppIcons.link),
                  tooltip: 'Copy Resource ID',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resources',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Secrets',
                count: _secretCount,
                icon: AppIcons.secret,
                color: AppTheme.successColor,
                onTap: () => _navigateToTabbed(0),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                title: 'Keys',
                count: _keyCount,
                icon: AppIcons.key,
                color: AppTheme.primaryColor,
                onTap: () => _navigateToTabbed(1),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                title: 'Certificates',
                count: _certificateCount,
                icon: AppIcons.certificate,
                color: AppTheme.warningColor,
                onTap: () => _navigateToTabbed(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_isLoadingStats)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildActionButton(
              label: 'Manage Secrets',
              icon: AppIcons.secret,
              color: AppTheme.successColor,
              onPressed: () => _navigateToTabbed(0),
            ),
            _buildActionButton(
              label: 'Manage Keys',
              icon: AppIcons.key,
              color: AppTheme.primaryColor,
              onPressed: () => _navigateToTabbed(1),
            ),
            _buildActionButton(
              label: 'Manage Certificates',
              icon: AppIcons.certificate,
              color: AppTheme.warningColor,
              onPressed: () => _navigateToTabbed(2),
            ),
            _buildActionButton(
              label: 'Access Policies',
              icon: AppIcons.security,
              color: Colors.purple,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Access Policies feature coming soon')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  Widget _buildVaultProperties() {
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
              _PropertyItem('Name', _vaultInfo!.name),
              _PropertyItem('Resource ID', _vaultInfo!.id),
              _PropertyItem('Vault URI', _vaultInfo!.vaultUri),
              _PropertyItem('Location', _vaultInfo!.location),
              _PropertyItem('Resource Group', _vaultInfo!.resourceGroup),
              _PropertyItem('Created', _formatDateTime(_vaultInfo!.createdTime)),
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
              children: _vaultInfo!.tags.entries.map((entry) {
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
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: property.value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${property.label} copied to clipboard')),
                  );
                },
                icon: const Icon(AppIcons.copy, size: 16),
                iconSize: 16,
                tooltip: 'Copy ${property.label}',
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _PropertyItem {
  final String label;
  final String value;

  _PropertyItem(this.label, this.value);
}