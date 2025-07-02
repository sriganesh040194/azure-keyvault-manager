import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/azure_cli_auth_service.dart';
import '../../core/logging/app_logger.dart';
import '../../shared/widgets/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final AzureCliAuthService authService;
  final String? error;

  const LoginScreen({
    super.key,
    required this.authService,
    this.error,
  });

  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _authStatus;
  DeviceCodeInfo? _deviceCodeInfo;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.error;
    _checkInitialStatus();
    _listenToDeviceCode();
  }
  
  void _listenToDeviceCode() {
    widget.authService.deviceCodeStream.listen((deviceCode) {
      if (mounted) {
        setState(() {
          _deviceCodeInfo = deviceCode;
        });
      }
    });
  }

  Future<void> _checkInitialStatus() async {
    try {
      final status = await widget.authService.getAuthStatus();
      if (mounted) {
        setState(() {
          _authStatus = status;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to check initial auth status', e);
    }
  }

  Future<void> _handleLogin() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.login();
      AppLogger.info('User authentication completed successfully');
    } catch (e) {
      AppLogger.error('Authentication failed', e);
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getLoginButtonText() {
    if (_deviceCodeInfo != null) {
      return 'Waiting for authentication...';
    } else if (_isLoading) {
      return 'Starting authentication...';
    } else {
      return 'Sign in with Azure CLI';
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Azure CLI')) {
      return 'Azure CLI not found. Please install Azure CLI and try again.';
    } else if (error.contains('login')) {
      return 'Login failed. Please check your credentials and try again.';
    } else if (error.contains('permissions')) {
      return 'Insufficient permissions. Please contact your administrator.';
    } else if (error.contains('timed out')) {
      return 'Authentication timed out. Please try again.';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }

  Widget _buildDeviceCodeSection() {
    final deviceCode = _deviceCodeInfo!;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 2,
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
              Text(
                'Complete Authentication',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          Text(
            '1. Click the link below to open your browser:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          
          InkWell(
            onTap: () => _openVerificationUrl(deviceCode.verificationUrl),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.link,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      deviceCode.verificationUrl,
                      style: TextStyle(
                        color: Colors.blue[600],
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    AppIcons.openInNew,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Text(
            '2. Enter this code when prompted:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  deviceCode.userCode,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    letterSpacing: 2,
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(deviceCode.userCode),
                  icon: const Icon(AppIcons.copy),
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Row(
            children: [
              Icon(
                AppIcons.timer,
                color: Colors.orange[600],
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Code expires in ${(deviceCode.expiresIn / 60).round()} minutes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          const LinearProgressIndicator(
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
  
  Future<void> _openVerificationUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open browser. Please copy the URL: $url'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to open verification URL', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open browser. Please copy the URL manually.'),
          ),
        );
      }
    }
  }
  
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to copy to clipboard', e);
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
              'Secure Key Vault Management Interface',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Azure CLI Status
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

            // Device Code Section
            if (_deviceCodeInfo != null) ...[
              _buildDeviceCodeSection(),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Login Button or Status
            if (_authStatus?['isAuthenticated'] != true) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: (_isLoading || _deviceCodeInfo != null) ? null : _handleLogin,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(AppIcons.login),
                  label: Text(_getLoginButtonText()),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _deviceCodeInfo != null 
                    ? 'Complete authentication in your browser to continue'
                    : 'Uses Azure CLI device code authentication',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
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
                        'Already authenticated with Azure CLI',
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

            // Requirements Notice
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                        'Requirements',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '• Azure CLI installed on this system\n'
                    '• Valid Azure subscription\n'
                    '• Key Vault access permissions\n'
                    '• Network connectivity to Azure',
                    style: TextStyle(
                      color: Colors.blue[700],
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

  Widget _buildSecurityFeatures() {
    final features = [
      {
        'icon': AppIcons.security,
        'title': 'Secure Authentication',
        'description': 'OAuth 2.0 with Azure AD integration',
      },
      {
        'icon': AppIcons.keyVault,
        'title': 'Key Vault Management',
        'description': 'Complete CRUD operations for Key Vaults',
      },
      {
        'icon': AppIcons.audit,
        'title': 'Audit Logging',
        'description': 'Comprehensive activity tracking',
      },
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Features',
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

  Widget _buildStatusSection() {
    final status = _authStatus!;
    final isAuth = status['isAuthenticated'] as bool? ?? false;
    final version = status['azureCliVersion'] as String?;
    final subscription = status['currentSubscription'] as Map<String, dynamic>?;

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
          isAuth ? 'Authenticated' : 'Not authenticated',
          isAuth ? AppIcons.success : AppIcons.error,
          isAuth ? Colors.green : Colors.red,
        ),
        
        // CLI Version
        if (version != null)
          _buildStatusItem(
            'Azure CLI',
            version,
            AppIcons.terminal,
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
        _buildStatusItem(
          'Key Vault Access',
          status['hasPermissions'] == true ? 'Available' : 'Checking...',
          status['hasPermissions'] == true ? AppIcons.success : AppIcons.warning,
          status['hasPermissions'] == true ? Colors.green : Colors.orange,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    // Desktop layout
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
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