import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/azure_cli_auth_service.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';
import '../../services/keyvault/keyvault_service.dart';
import '../../shared/widgets/app_theme.dart';
import '../../core/logging/app_logger.dart';
import '../keyvault/secret_list_screen.dart';
import '../keyvault/key_vault_details_screen.dart';
import '../keyvault/certificate_list_screen.dart';
import '../keyvault/key_list_screen.dart';
import '../../services/audit/audit_service.dart';
import '../../services/audit/audit_models.dart';

class ProductionDashboardScreen extends ConsumerStatefulWidget {
  final AzureCliAuthService authService;
  final KeyVaultService keyVaultService;

  const ProductionDashboardScreen({
    super.key,
    required this.authService,
    required this.keyVaultService,
  });

  @override
  ConsumerState<ProductionDashboardScreen> createState() =>
      _ProductionDashboardScreenState();
}

class _ProductionDashboardScreenState
    extends ConsumerState<ProductionDashboardScreen> {
  int _selectedIndex = 0;
  List<KeyVaultInfo>? _keyVaults;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>>? _subscriptions;
  Map<String, dynamic>? _currentSubscription;
  bool _isLoadingSubscriptions = false;
  late UnifiedAzureCliService _unifiedCliService;
  late AuditService _auditService;

  // Audit state
  List<AuditLogEntry> _auditLogs = [];
  AuditSummary? _auditSummary;
  bool _isLoadingAudit = false;
  String? _auditError;
  AuditFilter _auditFilter = AuditFilter(
    startTime: DateTime.now().subtract(const Duration(hours: 24)),
    endTime: DateTime.now(),
  );

  final List<String> _tabTitles = [
    'Overview',
    'Key Vaults',
    'Secrets',
    'Keys',
    'Certificates',
    'Activity',
    'Settings',
  ];

  final List<IconData> _tabIcons = [
    AppIcons.dashboard,
    AppIcons.keyVault,
    AppIcons.secret,
    AppIcons.key,
    AppIcons.certificate,
    AppIcons.activity,
    AppIcons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _unifiedCliService = UnifiedAzureCliService();
    _auditService = AuditService(_unifiedCliService);
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      setState(() {
        _isLoadingSubscriptions = true;
        _error = null;
      });

      // Load subscriptions and current subscription in parallel
      final results = await Future.wait([
        widget.authService.getSubscriptions(),
        widget.authService.getCurrentSubscription(),
      ]);

      final subscriptions = results[0] as List<Map<String, dynamic>>;
      final currentSub = results[1] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _subscriptions = subscriptions;
          _currentSubscription = currentSub;
          _isLoadingSubscriptions = false;
        });

        // Load Key Vaults after subscription info is loaded
        _loadKeyVaults();

        // Log subscription selection
        _auditService.logOperation(
          operationName: 'Microsoft.Subscription/subscriptions/read',
          resourceName: currentSub?['name'] ?? 'Unknown',
          resourceType: 'Microsoft.Subscription/subscriptions',
          resourceGroup: 'subscription-level',
          status: AuditStatus.success,
          userPrincipalName: widget.authService.currentUser?.email,
          clientIP: '192.168.1.100',
        );
      }

      AppLogger.info('Loaded ${subscriptions.length} subscriptions');
    } catch (e) {
      AppLogger.error('Failed to load subscriptions', e);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingSubscriptions = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadKeyVaults() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final vaults = await widget.keyVaultService.listKeyVaults();

      if (mounted) {
        setState(() {
          _keyVaults = vaults;
          _isLoading = false;
        });
      }

      // Log Key Vault list operation
      _auditService.logOperation(
        operationName: 'Microsoft.KeyVault/vaults/read',
        resourceName: 'Key Vaults',
        resourceType: 'Microsoft.KeyVault/vaults',
        resourceGroup: _currentSubscription?['name'] ?? 'unknown',
        status: AuditStatus.success,
        userPrincipalName: widget.authService.currentUser?.email,
        clientIP: '192.168.1.100',
        properties: {'vaultCount': vaults.length},
      );

      AppLogger.info('Loaded ${vaults.length} Key Vaults');
    } catch (e) {
      AppLogger.error('Failed to load Key Vaults', e);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.authService.logout();
    }
  }

  Future<void> _handleRefresh() async {
    await _loadSubscriptions();
    if (_selectedIndex == 5) {
      // Audit tab
      await _loadAuditData();
    }
  }

  Future<void> _loadAuditData() async {
    setState(() {
      _isLoadingAudit = true;
      _auditError = null;
    });

    try {
      // Load audit logs and summary in parallel
      final results = await Future.wait([
        _auditService.getAuditLogs(filter: _auditFilter, maxRecords: 50),
        _auditService.getAuditSummary(filter: _auditFilter, maxRecords: 200),
      ]);

      if (mounted) {
        setState(() {
          _auditLogs = results[0] as List<AuditLogEntry>;
          _auditSummary = results[1] as AuditSummary;
          _isLoadingAudit = false;
        });
      }

      AppLogger.info('Loaded ${_auditLogs.length} audit entries');
    } catch (e) {
      AppLogger.error('Failed to load audit data', e);
      if (mounted) {
        setState(() {
          _auditError = e.toString();
          _isLoadingAudit = false;
        });
      }
    }
  }

  Future<void> _exportAuditLogs() async {
    try {
      final csvData = await _auditService.exportAuditLogsToCSV(_auditLogs);
      // In a real implementation, you would save this to a file
      // For now, we'll just show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${_auditLogs.length} audit entries to CSV'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export audit logs: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showSubscriptionDetails() {
    if (_currentSubscription == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', _currentSubscription!['name'] ?? 'Unknown'),
            _buildDetailRow('ID', _currentSubscription!['id'] ?? 'Unknown'),
            _buildDetailRow(
              'State',
              _currentSubscription!['state'] ?? 'Unknown',
            ),
            _buildDetailRow(
              'Tenant ID',
              _currentSubscription!['tenantId'] ?? 'Unknown',
            ),
            if (_currentSubscription!['isDefault'] == true)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(AppIcons.success, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Default Subscription',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubscriptionChange(String subscriptionId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await widget.authService.setSubscription(subscriptionId);
      if (success) {
        // Reload current subscription and Key Vaults
        final currentSub = await widget.authService.getCurrentSubscription();

        if (mounted) {
          setState(() {
            _currentSubscription = currentSub;
          });

          // Reload Key Vaults for the new subscription
          await _loadKeyVaults();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription changed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to change subscription'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to change subscription', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(AppIcons.keyVault, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          const Text('Azure Key Vault Manager'),
        ],
      ),
      actions: [
        // Subscription selector
        if (_subscriptions != null && _subscriptions!.isNotEmpty)
          _buildSubscriptionSelector(),

        const SizedBox(width: AppSpacing.md),

        // Refresh button
        IconButton(
          onPressed: _handleRefresh,
          icon: const Icon(AppIcons.refresh),
          tooltip: 'Refresh',
        ),

        // User info
        if (widget.authService.currentUser != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    widget.authService.currentUser!.name.isNotEmpty
                        ? widget.authService.currentUser!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.authService.currentUser!.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.authService.currentUser!.email,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Logout button
        IconButton(
          onPressed: _handleLogout,
          icon: const Icon(AppIcons.logout),
          tooltip: 'Sign Out',
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });

        // Load audit data when switching to audit tab
        if (index == 5 && _auditLogs.isEmpty && !_isLoadingAudit) {
          _loadAuditData();
        }
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).colorScheme.surface,
      destinations: List.generate(_tabTitles.length, (index) {
        return NavigationRailDestination(
          icon: Icon(_tabIcons[index]),
          label: Text(_tabTitles[index]),
        );
      }),
    );
  }

  Widget _buildSubscriptionSelector() {
    if (_subscriptions == null || _subscriptions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentSubscription?['id'],
          hint: const Text('Select Subscription'),
          isExpanded: true,
          items: _subscriptions!.map((subscription) {
            final name = subscription['name'] ?? 'Unknown';
            final id = subscription['id'] ?? '';
            final isDefault = subscription['isDefault'] == true;

            return DropdownMenuItem<String>(
              value: id,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          id.split('/').last,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _currentSubscription?['id']) {
              _handleSubscriptionChange(newValue);
            }
          },
          dropdownColor: Theme.of(context).cardColor,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading || _isLoadingSubscriptions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.error, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildKeyVaultsTab();
      case 2:
        return _buildSecretsTab();
      case 3:
        return _buildKeysTab();
      case 4:
        return _buildCertificatesTab();
      case 5:
        return _buildAuditTab();
      case 6:
        return _buildSettingsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    final vaultCount = _keyVaults?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stats cards
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              _buildStatCard(
                'Key Vaults',
                vaultCount.toString(),
                AppIcons.keyVault,
                AppTheme.primaryColor,
                () => setState(() => _selectedIndex = 1),
              ),
              _buildStatCard(
                'Active Session',
                '1',
                AppIcons.success,
                Colors.green,
                null,
              ),
              _buildStatCard(
                'Subscription',
                _currentSubscription != null
                    ? (_currentSubscription!['name'] as String? ?? 'Unknown')
                          .split(' ')
                          .first
                    : 'N/A',
                AppIcons.account,
                Colors.blue,
                () => _showSubscriptionDetails(),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Recent Key Vaults
          if (_keyVaults != null && _keyVaults!.isNotEmpty) ...[
            Text(
              'Recent Key Vaults',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),

            ..._keyVaults!
                .take(5)
                .map(
                  (vault) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          AppIcons.keyVault,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(
                        vault.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${vault.location} • ${vault.resourceGroup}',
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KeyVaultDetailsScreen(
                                vaultName: vault.name,
                                cliService: _unifiedCliService,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyVaultsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Key Vaults',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  // TODO: Implement create Key Vault
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Create Key Vault functionality coming soon',
                      ),
                    ),
                  );
                },
                icon: const Icon(AppIcons.add),
                label: const Text('Create Key Vault'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          if (_keyVaults == null || _keyVaults!.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  Icon(AppIcons.keyVault, size: 64, color: Colors.grey),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No Key Vaults found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Create your first Key Vault to get started',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _keyVaults!.length,
                itemBuilder: (context, index) {
                  final vault = _keyVaults![index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          AppIcons.keyVault,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(
                        vault.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${vault.location} • ${vault.resourceGroup}'),
                          Text(
                            'Created: ${vault.createdTime.toString().split(' ')[0]}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KeyVaultDetailsScreen(
                              vaultName: vault.name,
                              cliService: _unifiedCliService,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecretsTab() {
    return SecretListScreen(vaultName: '', cliService: _unifiedCliService);
  }

  Widget _buildKeysTab() {
    return KeyListScreen(vaultName: '', cliService: _unifiedCliService);
  }

  Widget _buildCertificatesTab() {
    return CertificateListScreen(vaultName: '', cliService: _unifiedCliService);
  }

  Widget _buildAuditTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audit & Activity',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Summary cards - show real audit data
          _buildAuditSummaryCards(),

          const SizedBox(height: AppSpacing.xl),

          // Audit controls and filters
          _buildAuditControls(),

          const SizedBox(height: AppSpacing.lg),

          // Recent activity section
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(AppIcons.audit),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Recent Activity',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _auditLogs.isNotEmpty
                              ? _exportAuditLogs
                              : null,
                          icon: const Icon(AppIcons.download),
                          label: const Text('Export CSV'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _loadAuditData,
                          icon: const Icon(AppIcons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Expanded(child: _buildRealActivityList()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSummaryCards() {
    if (_isLoadingAudit) {
      return const Row(
        children: [Expanded(child: Center(child: CircularProgressIndicator()))],
      );
    }

    if (_auditSummary == null) {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Operations',
              '0',
              AppIcons.activity,
              Colors.blue,
              null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              'Successful',
              '0',
              AppIcons.success,
              Colors.green,
              null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              'Failed',
              '0',
              AppIcons.error,
              Colors.red,
              null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              'Key Vault Ops',
              '0',
              AppIcons.keyVault,
              Colors.orange,
              null,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Operations',
            _auditSummary!.totalEntries.toString(),
            AppIcons.activity,
            Colors.blue,
            null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Successful',
            _auditSummary!.successfulOperations.toString(),
            AppIcons.success,
            Colors.green,
            null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Failed',
            _auditSummary!.failedOperations.toString(),
            AppIcons.error,
            Colors.red,
            null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Key Vault Ops',
            _auditSummary!.keyVaultOperations.toString(),
            AppIcons.keyVault,
            Colors.orange,
            null,
          ),
        ),
      ],
    );
  }

  Widget _buildAuditControls() {
    return Row(
      children: [
        // Key Vault filter toggle
        FilterChip(
          label: const Text('Key Vault Only'),
          selected: _auditFilter.keyVaultOnly,
          onSelected: (selected) {
            setState(() {
              _auditFilter = _auditFilter.copyWith(keyVaultOnly: selected);
            });
            _loadAuditData();
          },
        ),
        const SizedBox(width: AppSpacing.md),

        // Time range selector
        OutlinedButton.icon(
          onPressed: _selectTimeRange,
          icon: const Icon(AppIcons.calendar),
          label: Text(_formatTimeRange()),
        ),
      ],
    );
  }

  void _selectTimeRange() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Time Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Last 24 Hours'),
              onTap: () {
                setState(() {
                  _auditFilter = _auditFilter.copyWith(
                    startTime: DateTime.now().subtract(
                      const Duration(hours: 24),
                    ),
                    endTime: DateTime.now(),
                  );
                });
                Navigator.pop(context);
                _loadAuditData();
              },
            ),
            ListTile(
              title: const Text('Last 7 Days'),
              onTap: () {
                setState(() {
                  _auditFilter = _auditFilter.copyWith(
                    startTime: DateTime.now().subtract(const Duration(days: 7)),
                    endTime: DateTime.now(),
                  );
                });
                Navigator.pop(context);
                _loadAuditData();
              },
            ),
            ListTile(
              title: const Text('Last 30 Days'),
              onTap: () {
                setState(() {
                  _auditFilter = _auditFilter.copyWith(
                    startTime: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    endTime: DateTime.now(),
                  );
                });
                Navigator.pop(context);
                _loadAuditData();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatTimeRange() {
    if (_auditFilter.startTime == null) return 'All Time';

    final now = DateTime.now();
    final diff = now.difference(_auditFilter.startTime!);

    if (diff.inHours <= 24) {
      return 'Last 24 Hours';
    } else if (diff.inDays <= 7) {
      return 'Last 7 Days';
    } else if (diff.inDays <= 30) {
      return 'Last 30 Days';
    } else {
      return 'Custom Range';
    }
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.lg),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (widget.authService.currentUser != null) ...[
                    _buildSettingItem(
                      'Name',
                      widget.authService.currentUser!.name,
                    ),
                    _buildSettingItem(
                      'Email',
                      widget.authService.currentUser!.email,
                    ),
                    _buildSettingItem(
                      'Tenant ID',
                      widget.authService.currentUser!.tenantId,
                    ),
                    _buildSettingItem(
                      'User ID',
                      widget.authService.currentUser!.id,
                    ),
                    _buildSettingItem(
                      'Last Login',
                      widget.authService.currentUser!.lastLogin.toString(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  ListTile(
                    leading: const Icon(AppIcons.refresh),
                    title: const Text('Refresh Session'),
                    subtitle: const Text(
                      'Reload user information and permissions',
                    ),
                    onTap: () async {
                      await widget.authService.refreshSession();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Session refreshed')),
                        );
                      }
                    },
                  ),

                  ListTile(
                    leading: Icon(AppIcons.logout, color: AppTheme.errorColor),
                    title: Text(
                      'Sign Out',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                    subtitle: const Text('End current session'),
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildSettingItem('Application', 'Azure Key Vault Manager'),
                  _buildSettingItem('Version', '0.1.0'),
                  _buildSettingItem('Developer', 'Sriganesh Karuppannan'),
                  _buildSettingItem('License', 'Apache License 2.0'),
                  _buildSettingItem(
                    'Github',
                    'https://github.com/sriganesh040194/azure-keyvault-manager/releases',
                  ),

                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Made with ❤️ by Sriganesh Karuppannan.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonTab(String title, IconData icon, String description) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: 100),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(icon, size: 60, color: Colors.grey),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildRealActivityList() {
    if (_isLoadingAudit) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Loading audit logs...'),
          ],
        ),
      );
    }

    if (_auditError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.error, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load audit logs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _auditError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _loadAuditData,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_auditLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.audit, size: 64, color: Colors.grey),
            SizedBox(height: AppSpacing.lg),
            Text(
              'No audit logs found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Try adjusting the time range or filters',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount: _auditLogs.length,
      itemBuilder: (context, index) {
        final entry = _auditLogs[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          elevation: 1,
          child: InkWell(
            onTap: () => _showAuditEntryDetails(entry),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with icon, title, and status
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getAuditStatusColor(
                            entry.status,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.md,
                          ),
                          border: Border.all(
                            color: _getAuditStatusColor(
                              entry.status,
                            ).withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _getAuditStatusIcon(entry),
                          color: _getAuditStatusColor(entry.status),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (entry.isKeyVaultRelated)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppBorderRadius.sm,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          AppIcons.keyVault,
                                          size: 12,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'KeyVault',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  AppIcons.clock,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatActivityTime(entry.time),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getAuditStatusColor(
                                      entry.status,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.sm,
                                    ),
                                    border: Border.all(
                                      color: _getAuditStatusColor(
                                        entry.status,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    entry.resultType,
                                    style: TextStyle(
                                      color: _getAuditStatusColor(entry.status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Details section
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Resource information row
                        Row(
                          children: [
                            Icon(
                              AppIcons.link,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Resource:',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                entry.resourceName,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Category and operation row
                        Row(
                          children: [
                            Icon(
                              AppIcons.info,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Category:',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                entry.category,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // User information if available
                        if (entry.callerInfo?.displayName != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Icon(
                                AppIcons.account,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'User:',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  entry.callerInfo!.displayName,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // IP Address if available and not local
                        if (entry.callerInfo?.clientIP != null &&
                            entry.callerInfo!.clientIP != '127.0.0.1') ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Icon(
                                AppIcons.security,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'IP:',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  entry.callerInfo!.clientIP!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Description or message if available
                  if (entry.description != null &&
                      entry.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                AppIcons.info,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Message:',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Footer with action hint
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Tap for full details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        AppIcons.openInNew,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAuditEntryDetails(AuditLogEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Time', entry.time.toString()),
              _buildDetailRow('Resource', entry.resourceName),
              _buildDetailRow('Resource Group', entry.resourceGroup),
              _buildDetailRow('Status', entry.resultType),
              _buildDetailRow('Level', entry.level),
              if (entry.callerInfo?.displayName != null)
                _buildDetailRow('User', entry.callerInfo!.displayName),
              if (entry.callerInfo?.clientIP != null)
                _buildDetailRow('IP Address', entry.callerInfo!.clientIP!),
              if (entry.correlationId != null)
                _buildDetailRow('Correlation ID', entry.correlationId!),
              _buildDetailRow('Full Operation', entry.operationName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getAuditStatusIcon(AuditLogEntry entry) {
    if (entry.isKeyVaultRelated) {
      return AppIcons.keyVault;
    }

    switch (entry.status) {
      case AuditStatus.success:
        return AppIcons.success;
      case AuditStatus.failed:
        return AppIcons.error;
      case AuditStatus.started:
        return AppIcons.clock;
      default:
        return AppIcons.activity;
    }
  }

  Color _getAuditStatusColor(AuditStatus status) {
    switch (status) {
      case AuditStatus.success:
        return AppTheme.successColor;
      case AuditStatus.failed:
        return AppTheme.errorColor;
      case AuditStatus.started:
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }

  Color _getActivityStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return AppTheme.successColor;
      case 'error':
      case 'failed':
        return AppTheme.errorColor;
      case 'warning':
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }

  String _formatActivityTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatDetailedTime(DateTime time) {
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return SizedBox(
      width: 200,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildAppBar(),
      ),
      body: Row(
        children: [
          _buildNavigationRail(),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String action;
  final String resource;
  final DateTime time;
  final String status;
  final IconData icon;

  _ActivityItem({
    required this.action,
    required this.resource,
    required this.time,
    required this.status,
    required this.icon,
  });
}
