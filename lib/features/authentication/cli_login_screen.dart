import 'package:flutter/material.dart';
import '../../core/auth/cli_auth_service.dart';
import '../../core/logging/app_logger.dart';
import '../../shared/widgets/app_theme.dart';

class CliLoginScreen extends StatefulWidget {
  final CliAuthService authService;
  final String? error;

  const CliLoginScreen({
    super.key,
    required this.authService,
    this.error,
  });

  @override State<CliLoginScreen> createState() => _CliLoginScreenState();
}

class _CliLoginScreenState extends State<CliLoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _authStatus;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.error;
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final status = await widget.authService.getAuthStatus();
      setState(() {
        _authStatus = status;
      });
    } catch (e) {
      AppLogger.error('Failed to check auth status', e);
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.login();
      AppLogger.info('User CLI login initiated');
    } catch (e) {
      AppLogger.error('CLI login failed', e);
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Azure Logo and Title
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              ),
              child: const Icon(
                AppIcons.keyVault,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'Azure Key Vault Manager',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            
            Text(
              'Secure management using Azure CLI',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Status Information
            if (_authStatus != null) ...[
              _buildStatusSection(),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Error Message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.error,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Login Instructions
            if (_authStatus?['isAuthenticated'] != true) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: Colors.blue[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          AppIcons.info,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Azure CLI Login Required',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This application uses Azure CLI for authentication. Click the button below to open your default browser and sign in with your Azure credentials.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _handleLogin,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.terminal),
                  label: Text(_isLoading ? 'Launching Azure CLI...' : 'Sign in with Azure CLI'),
                ),
              ),
            ] else ...[
              // Already authenticated
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: Colors.green[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.success,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'You are already signed in with Azure CLI',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Prerequisites Notice
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(
                  color: Colors.orange[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.warning,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Prerequisites',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '• Azure CLI must be installed on your system\n'
                    '• You need Key Vault access permissions\n'
                    '• Internet connection required for authentication',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
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

  Widget _buildStatusSection() {
    final status = _authStatus!;
    final isAuth = status['isAuthenticated'] as bool? ?? false;
    final version = status['azureCliVersion'] as String?;
    final subscription = status['currentSubscription'] as Map<String, dynamic>?;
    final hasPermissions = status['hasPermissions'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Azure CLI Status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        
        // Authentication Status
        _buildStatusItem(
          'Authentication',
          isAuth ? 'Signed In' : 'Not Signed In',
          isAuth ? AppIcons.success : AppIcons.error,
          isAuth ? Colors.green : Colors.red,
        ),
        
        // CLI Version
        if (version != null)
          _buildStatusItem(
            'Azure CLI Version',
            version,
            AppIcons.info,
            Colors.blue,
          ),
        
        // Current Subscription
        if (subscription != null)
          _buildStatusItem(
            'Subscription',
            subscription['name'] as String? ?? 'Unknown',
            AppIcons.account,
            Colors.blue,
          ),
        
        // Permissions
        if (isAuth)
          _buildStatusItem(
            'Key Vault Access',
            hasPermissions ? 'Available' : 'Limited',
            hasPermissions ? AppIcons.success : AppIcons.warning,
            hasPermissions ? Colors.green : Colors.orange,
          ),
      ],
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeatures() {
    final features = [
      {
        'icon': AppIcons.security,
        'title': 'CLI Authentication',
        'description': 'Uses your existing Azure CLI credentials',
      },
      {
        'icon': AppIcons.keyVault,
        'title': 'Direct Access',
        'description': 'No app registration required',
      },
      {
        'icon': AppIcons.audit,
        'title': 'Secure Operations',
        'description': 'All operations validated and logged',
      },
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benefits of CLI Authentication',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
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
                        feature['title'] as String,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature['description'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              Colors.white,
              AppTheme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    // Desktop layout
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSecurityFeatures(),
                        const SizedBox(width: AppSpacing.xxl * 2),
                        _buildLoginCard(),
                      ],
                    );
                  } else {
                    // Mobile layout
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLoginCard(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSecurityFeatures(),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}