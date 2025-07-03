import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/azure_cli_auth_service.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';
import '../../services/keyvault/keyvault_service.dart';
import '../../services/keyvault/secret_service.dart';
import '../../services/keyvault/secret_models.dart';
import '../../shared/widgets/app_theme.dart';
import '../../core/logging/app_logger.dart';
import '../keyvault/secret_list_screen.dart';

class ProductionDashboardScreen extends ConsumerStatefulWidget {
  final AzureCliAuthService authService;
  final KeyVaultService keyVaultService;

  const ProductionDashboardScreen({
    super.key,
    required this.authService,
    required this.keyVaultService,
  });

  @override ConsumerState<ProductionDashboardScreen> createState() => _ProductionDashboardScreenState();
}

class _ProductionDashboardScreenState extends ConsumerState<ProductionDashboardScreen> {
  int _selectedIndex = 0;
  List<KeyVaultInfo>? _keyVaults;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>>? _subscriptions;
  Map<String, dynamic>? _currentSubscription;
  bool _isLoadingSubscriptions = false;
  late UnifiedAzureCliService _unifiedCliService;

  final List<String> _tabTitles = [
    'Overview',
    'Key Vaults',
    'Secrets',
    'Keys',
    'Certificates',
    'Settings',
  ];

  final List<IconData> _tabIcons = [
    AppIcons.dashboard,
    AppIcons.keyVault,
    AppIcons.secret,
    AppIcons.key,
    AppIcons.certificate,
    AppIcons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _unifiedCliService = UnifiedAzureCliService();
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
            _buildDetailRow('State', _currentSubscription!['state'] ?? 'Unknown'),
            _buildDetailRow('Tenant ID', _currentSubscription!['tenantId'] ?? 'Unknown'),
            if (_currentSubscription!['isDefault'] == true)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(AppIcons.success, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Default Subscription', style: TextStyle(color: Colors.green)),
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
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
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
            child: const Icon(
              AppIcons.keyVault,
              color: Colors.white,
              size: 20,
            ),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
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
              'Error loading data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
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
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                    ? (_currentSubscription!['name'] as String? ?? 'Unknown').split(' ').first
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            ..._keyVaults!.take(5).map((vault) => Card(
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
                subtitle: Text('${vault.location} • ${vault.resourceGroup}'),
                trailing: IconButton(
                  onPressed: () {
                    setState(() => _selectedIndex = 1);
                  },
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            )),
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
                      content: Text('Create Key Vault functionality coming soon'),
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
                  Icon(
                    AppIcons.keyVault,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No Key Vaults found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Create your first Key Vault to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
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
                        // TODO: Navigate to vault details
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening ${vault.name} details'),
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
    return SecretListScreen(
      vaultName: '',
      cliService: _unifiedCliService,
    );
  }

  Widget _buildKeysTab() {
    return _buildComingSoonTab('Keys', AppIcons.key, 'Key management functionality coming soon');
  }

  Widget _buildCertificatesTab() {
    return _buildComingSoonTab('Certificates', AppIcons.certificate, 'Certificate management functionality coming soon');
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
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
                    'Account Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  if (widget.authService.currentUser != null) ...[
                    _buildSettingItem('Name', widget.authService.currentUser!.name),
                    _buildSettingItem('Email', widget.authService.currentUser!.email),
                    _buildSettingItem('Tenant ID', widget.authService.currentUser!.tenantId),
                    _buildSettingItem('User ID', widget.authService.currentUser!.id),
                    _buildSettingItem('Last Login', widget.authService.currentUser!.lastLogin.toString()),
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
                    subtitle: const Text('Reload user information and permissions'),
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
                    title: Text('Sign Out', style: TextStyle(color: AppTheme.errorColor)),
                    subtitle: const Text('End current session'),
                    onTap: _handleLogout,
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
            child: Icon(
              icon,
              size: 60,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
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
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
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