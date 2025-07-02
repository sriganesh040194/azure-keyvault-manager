import 'package:flutter/material.dart';
import '../../core/auth/cli_auth_service.dart';
import '../../services/azure_cli/azure_cli_service.dart';
import '../../shared/widgets/app_theme.dart';
import '../keyvault/key_vault_list_screen.dart';
import '../keyvault/key_vault_details_screen.dart';

enum DashboardTab {
  overview,
  keyVaults,
  secrets,
  keys,
  certificates,
  audit,
  settings,
}

class DashboardScreen extends StatefulWidget {
  final CliAuthService authService;

  const DashboardScreen({
    super.key,
    required this.authService,
  });

  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardTab _selectedTab = DashboardTab.overview;
  late final AzureCliService _azureCliService;
  String? _selectedKeyVault;

  @override
  void initState() {
    super.initState();
    _azureCliService = AzureCliService();
  }

  void _onTabSelected(DashboardTab tab) {
    setState(() {
      _selectedTab = tab;
      if (tab != DashboardTab.keyVaults) {
        _selectedKeyVault = null;
      }
    });
  }

  void _onKeyVaultSelected(String keyVaultName) {
    setState(() {
      _selectedKeyVault = keyVaultName;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
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

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedTab.index,
      onDestinationSelected: (index) => _onTabSelected(DashboardTab.values[index]),
      labelType: NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).colorScheme.surface,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(AppIcons.dashboard),
          label: Text('Overview'),
        ),
        NavigationRailDestination(
          icon: Icon(AppIcons.keyVault),
          label: Text('Key Vaults'),
        ),
        NavigationRailDestination(
          icon: Icon(AppIcons.secret),
          label: Text('Secrets'),
        ),
        NavigationRailDestination(
          icon: Icon(AppIcons.key),
          label: Text('Keys'),
        ),
        NavigationRailDestination(
          icon: Icon(AppIcons.certificate),
          label: Text('Certificates'),
        ),
        NavigationRailDestination(
          icon: Icon(AppIcons.audit),
          label: Text('Audit'),
        ),
        NavigationRailDestination(
          icon: Icon(AppIcons.settings),
          label: Text('Settings'),
        ),
      ],
    );
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

  Widget _buildBody() {
    switch (_selectedTab) {
      case DashboardTab.overview:
        return _buildOverviewTab();
      case DashboardTab.keyVaults:
        return _selectedKeyVault == null
            ? KeyVaultListScreen(
                azureCliService: _azureCliService,
                onKeyVaultSelected: _onKeyVaultSelected,
              )
            : KeyVaultDetailsScreen(
                keyVaultName: _selectedKeyVault!,
                azureCliService: _azureCliService,
                onBack: () => _onKeyVaultSelected(''),
              );
      case DashboardTab.secrets:
        return _buildSecretsTab();
      case DashboardTab.keys:
        return _buildKeysTab();
      case DashboardTab.certificates:
        return _buildCertificatesTab();
      case DashboardTab.audit:
        return _buildAuditTab();
      case DashboardTab.settings:
        return _buildSettingsTab();
    }
  }

  Widget _buildOverviewTab() {
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
          
          // Quick stats cards
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              _buildStatCard(
                'Key Vaults',
                '0',
                AppIcons.keyVault,
                AppTheme.primaryColor,
                () => _onTabSelected(DashboardTab.keyVaults),
              ),
              _buildStatCard(
                'Secrets',
                '0',
                AppIcons.secret,
                AppTheme.successColor,
                () => _onTabSelected(DashboardTab.secrets),
              ),
              _buildStatCard(
                'Keys',
                '0',
                AppIcons.key,
                AppTheme.warningColor,
                () => _onTabSelected(DashboardTab.keys),
              ),
              _buildStatCard(
                'Certificates',
                '0',
                AppIcons.certificate,
                Colors.purple,
                () => _onTabSelected(DashboardTab.certificates),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Recent activity section
          Card(
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Center(
                    child: Text(
                      'No recent activity to display',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
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
    VoidCallback onTap,
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

  Widget _buildSecretsTab() {
    return const Center(
      child: Text('Secrets management coming soon'),
    );
  }

  Widget _buildKeysTab() {
    return const Center(
      child: Text('Keys management coming soon'),
    );
  }

  Widget _buildCertificatesTab() {
    return const Center(
      child: Text('Certificates management coming soon'),
    );
  }

  Widget _buildAuditTab() {
    return const Center(
      child: Text('Audit logs coming soon'),
    );
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
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
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
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}