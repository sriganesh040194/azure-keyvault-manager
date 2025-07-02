import 'package:flutter/material.dart';
import '../../shared/widgets/app_theme.dart';

class WebPlatformNoticeScreen extends StatelessWidget {
  const WebPlatformNoticeScreen({super.key});

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
              child: Card(
                elevation: 4,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700),
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
                        'Desktop Platform Required',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Web Platform Notice
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
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
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Web Platform Limitation',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'This Azure Key Vault Manager requires Azure CLI integration, which cannot run in web browsers due to security restrictions. '
                              'Web browsers cannot execute system processes or access local Azure CLI installations.',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Solutions
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
                                    'How to Use This Application',
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
                              'To use this Azure Key Vault Manager with real Azure resources:',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...const [
                              '1. Download and install this app on a desktop platform:',
                              '   • Windows (Flutter Windows app)',
                              '   • macOS (Flutter macOS app)',
                              '   • Linux (Flutter Linux app)',
                              '',
                              '2. Install Azure CLI on your system:',
                              '   • Windows: Download from aka.ms/installazurecliwindows',
                              '   • macOS: brew install azure-cli',
                              '     (or download from aka.ms/installazureclimac)',
                              '   • Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash',
                              '',
                              '3. Authenticate with Azure:',
                              '   • Run: az login',
                              '   • Follow the authentication prompts',
                              '',
                              '4. Ensure Key Vault permissions:',
                              '   • Verify you have access to Key Vaults in your subscription',
                              '   • Test with: az keyvault list',
                            ].map((step) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                step,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 13,
                                  fontFamily: step.startsWith('   •') || step.startsWith('   ') ? 'Courier' : null,
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Alternative Solutions
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          border: Border.all(
                            color: Colors.green[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  AppIcons.success,
                                  color: Colors.green[700],
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Alternative Solutions',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'If you need web-based Key Vault management:',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...const [
                              '• Use the Azure Portal (portal.azure.com)',
                              '• Use Azure CLI directly in Azure Cloud Shell',
                              '• Build a web API backend that wraps Azure CLI commands',
                              '• Use Azure REST APIs directly with proper authentication',
                            ].map((solution) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                solution,
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 13,
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Download Links (placeholder)
                      FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Desktop applications would be available for download from your release repository'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        },
                        icon: const Icon(AppIcons.download),
                        label: const Text('Download Desktop Application'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}