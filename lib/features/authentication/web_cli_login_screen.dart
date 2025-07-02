import 'package:flutter/material.dart';
import '../../core/auth/web_cli_auth_service.dart';
import '../../core/logging/app_logger.dart';
import '../../shared/widgets/app_theme.dart';

class WebCliLoginScreen extends StatefulWidget {
  final WebCliAuthService authService;
  final String? error;

  const WebCliLoginScreen({
    super.key,
    required this.authService,
    this.error,
  });

  @override State<WebCliLoginScreen> createState() => _WebCliLoginScreenState();
}

class _WebCliLoginScreenState extends State<WebCliLoginScreen> {
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
      AppLogger.info('User web demo login completed');
    } catch (e) {
      AppLogger.error('Web demo login failed', e);
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
        constraints: const BoxConstraints(maxWidth: 600),
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
              'Web Demo Mode',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Web Mode Notice
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Web Demo Mode',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'This is a demonstration of the Azure Key Vault Manager interface. '
                    'In a real deployment, this application would integrate with a backend service '
                    'that handles Azure CLI authentication securely.',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Features demonstrated:',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...const [
                    '• Secure authentication flow simulation',
                    '• Key Vault management interface',
                    '• Secret management capabilities',
                    '• Security validation and input sanitization',
                    '• Responsive Material Design 3 UI',
                  ].map((feature) => Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md, bottom: 4),
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
                      ),
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

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

            // Status Information
            if (_authStatus != null) ...[
              _buildStatusSection(),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Login Button
            if (_authStatus?['isAuthenticated'] != true) ...[
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
                      : const Icon(Icons.play_arrow),
                  label: Text(_isLoading ? 'Starting Demo...' : 'Start Demo'),
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
                        'Demo session is active',
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

            // Production Notice
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
                        'For Production Use',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'To use this application with real Azure resources:\n'
                    '• Deploy to a desktop environment\n'
                    '• Install Azure CLI on the system\n'
                    '• Run "az login" for authentication\n'
                    '• Ensure Key Vault access permissions',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Demo Status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        
        // Authentication Status
        _buildStatusItem(
          'Authentication',
          isAuth ? 'Demo Active' : 'Demo Inactive',
          isAuth ? AppIcons.success : AppIcons.error,
          isAuth ? Colors.green : Colors.red,
        ),
        
        // Mode
        if (version != null)
          _buildStatusItem(
            'Mode',
            version,
            AppIcons.info,
            Colors.blue,
          ),
        
        // Demo Subscription
        if (subscription != null)
          _buildStatusItem(
            'Demo Subscription',
            subscription['name'] as String? ?? 'Unknown',
            AppIcons.account,
            Colors.blue,
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
              child: _buildLoginCard(),
            ),
          ),
        ),
      ),
    );
  }
}