import 'package:flutter/material.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';
import '../../services/azure_cli/azure_cli_service.dart';
import '../../shared/widgets/app_theme.dart';
import 'key_list_screen.dart';
import 'certificate_list_screen.dart';
import 'secret_list_screen.dart';
import 'key_vault_details_screen.dart';

class KeyVaultTabbedScreen extends StatefulWidget {
  final String vaultName;
  final UnifiedAzureCliService cliService;

  const KeyVaultTabbedScreen({
    super.key,
    required this.vaultName,
    required this.cliService,
  });

  @override
  State<KeyVaultTabbedScreen> createState() => _KeyVaultTabbedScreenState();
}

class _KeyVaultTabbedScreenState extends State<KeyVaultTabbedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Default to Keys tab (index 1)
    _tabController.index = 1;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vaultName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(AppIcons.secret),
              text: 'Secrets',
            ),
            Tab(
              icon: Icon(AppIcons.key),
              text: 'Keys',
            ),
            Tab(
              icon: Icon(AppIcons.certificate),
              text: 'Certificates',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Secrets tab - use new dedicated screen
          SecretListScreen(
            vaultName: widget.vaultName,
            cliService: widget.cliService,
            showVaultSelector: false, // Hide dropdown when accessed from specific KeyVault
          ),
          // Keys tab
          KeyListScreen(
            vaultName: widget.vaultName,
            cliService: widget.cliService,
            showVaultSelector: false, // Hide dropdown when accessed from specific KeyVault
          ),
          // Certificates tab
          CertificateListScreen(
            vaultName: widget.vaultName,
            cliService: widget.cliService,
            showVaultSelector: false, // Hide dropdown when accessed from specific KeyVault
          ),
        ],
      ),
    );
  }
}