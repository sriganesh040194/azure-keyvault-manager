import 'package:flutter/material.dart';
import '../../core/auth/web_cli_auth_service.dart';
import '../../shared/widgets/app_theme.dart';

class WebDashboardScreen extends StatefulWidget {
  final WebCliAuthService authService;

  const WebDashboardScreen({
    super.key,
    required this.authService,
  });

  @override State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  int _selectedIndex = 0;

  final List<String> _tabTitles = [
    'Overview',
    'Key Vaults',
    'Secrets',
    'Keys',
    'Certificates',
    'Demo Info',
  ];

  final List<IconData> _tabIcons = [
    AppIcons.dashboard,
    AppIcons.keyVault,
    AppIcons.secret,
    AppIcons.key,
    AppIcons.certificate,
    AppIcons.info,
  ];

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Demo Session'),
        content: const Text('Are you sure you want to end the demo session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.authService.logout();
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
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Text(
              'DEMO',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
          tooltip: 'End Demo Session',
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

  Widget _buildContent() {
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
        return _buildDemoInfoTab();
      default:
        return _buildOverviewTab();
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
          
          // Demo stats cards
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              _buildStatCard(
                'Demo Key Vaults',
                '3',
                AppIcons.keyVault,
                AppTheme.primaryColor,
                () => setState(() => _selectedIndex = 1),
              ),
              _buildStatCard(
                'Demo Secrets',
                '12',
                AppIcons.secret,
                AppTheme.successColor,
                () => setState(() => _selectedIndex = 2),
              ),
              _buildStatCard(
                'Demo Keys',
                '5',
                AppIcons.key,
                AppTheme.warningColor,
                () => setState(() => _selectedIndex = 3),
              ),
              _buildStatCard(
                'Demo Certificates',
                '2',
                AppIcons.certificate,
                Colors.purple,
                () => setState(() => _selectedIndex = 4),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Demo notice
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.info,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Demo Environment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'This is a demonstration of the Azure Key Vault Manager interface. '
                    'All data shown is simulated and no real Azure resources are accessed. '
                    'In a production environment, this application would connect to your actual Azure Key Vaults.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 5),
                    icon: const Icon(AppIcons.info),
                    label: const Text('Learn More About Production Setup'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyVaultsTab() {
    final demoKeyVaults = [
      {'name': 'demo-keyvault-prod', 'location': 'East US', 'secrets': 8},
      {'name': 'demo-keyvault-dev', 'location': 'West US 2', 'secrets': 3},
      {'name': 'demo-keyvault-test', 'location': 'Central US', 'secrets': 1},
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Demo Key Vaults',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demo: Create Key Vault functionality would be here'),
                    ),
                  );
                },
                icon: const Icon(AppIcons.add),
                label: const Text('Create Key Vault'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          ...demoKeyVaults.map((kv) => Card(
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
                kv['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${kv['location']} • ${kv['secrets']} secrets'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Demo: Opening ${kv['name']} details'),
                  ),
                );
              },
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSecretsTab() {
    return _buildDemoTab('Secrets', AppIcons.secret, 'Demo secrets would be listed here');
  }

  Widget _buildKeysTab() {
    return _buildDemoTab('Keys', AppIcons.key, 'Demo keys would be listed here');
  }

  Widget _buildCertificatesTab() {
    return _buildDemoTab('Certificates', AppIcons.certificate, 'Demo certificates would be listed here');
  }

  Widget _buildDemoTab(String title, IconData icon, String description) {
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

  Widget _buildDemoInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Production Setup Information',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            _buildInfoCard(
              'Desktop Application',
              'For production use, deploy this application to a desktop environment where Azure CLI can be installed and executed.',
              AppIcons.settings,
              Colors.blue,
            ),
            
            _buildInfoCard(
              'Azure CLI Setup',
              'Install Azure CLI on the target system and authenticate using "az login". The application will automatically detect and use existing CLI credentials.',
              Icons.terminal,
              Colors.green,
            ),
            
            _buildInfoCard(
              'Permissions Required',
              'Ensure the authenticated user has Key Vault Contributor role or appropriate access policies on the target Key Vaults.',
              AppIcons.security,
              Colors.orange,
            ),
            
            _buildInfoCard(
              'Security Features',
              'The application includes comprehensive input validation, command injection prevention, output sanitization, and secure session management.',
              AppIcons.security,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
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