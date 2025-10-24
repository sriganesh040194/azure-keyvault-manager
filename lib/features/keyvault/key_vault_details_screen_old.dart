import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/azure_cli/azure_cli_service.dart';
import '../../shared/widgets/app_theme.dart';
import '../../core/logging/app_logger.dart';

class SecretInfo {
  final String name;
  final String id;
  final bool enabled;
  final DateTime? created;
  final DateTime? updated;
  final DateTime? expires;
  final Map<String, String> tags;

  SecretInfo({
    required this.name,
    required this.id,
    this.enabled = true,
    this.created,
    this.updated,
    this.expires,
    this.tags = const {},
  });

  factory SecretInfo.fromJson(Map<String, dynamic> json) {
    return SecretInfo(
      name: json['name'] as String? ?? '',
      id: json['id'] as String? ?? '',
      enabled: json['attributes']?['enabled'] as bool? ?? true,
      created: json['attributes']?['created'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['attributes']['created'] as int) * 1000)
          : null,
      updated: json['attributes']?['updated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['attributes']['updated'] as int) * 1000)
          : null,
      expires: json['attributes']?['expires'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['attributes']['expires'] as int) * 1000)
          : null,
      tags: Map<String, String>.from(json['tags'] as Map? ?? {}),
    );
  }
}

class KeyVaultDetailsScreen extends StatefulWidget {
  final String keyVaultName;
  final AzureCliService azureCliService;
  final VoidCallback onBack;

  const KeyVaultDetailsScreen({
    super.key,
    required this.keyVaultName,
    required this.azureCliService,
    required this.onBack,
  });

  @override State<KeyVaultDetailsScreen> createState() => _KeyVaultDetailsScreenState();
}

class _KeyVaultDetailsScreenState extends State<KeyVaultDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<SecretInfo> _secrets = [];
  bool _isLoadingSecrets = false;
  String? _secretsError;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSecrets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSecrets() async {
    setState(() {
      _isLoadingSecrets = true;
      _secretsError = null;
    });

    try {
      final result = await widget.azureCliService.listSecrets(widget.keyVaultName);
      
      if (result.success) {
        final List<dynamic> secretsJson = json.decode(result.output);
        setState(() {
          _secrets = secretsJson
              .map((json) => SecretInfo.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoadingSecrets = false;
        });
        
        AppLogger.info('Loaded ${_secrets.length} secrets for Key Vault: ${widget.keyVaultName}');
      } else {
        setState(() {
          _secretsError = 'Failed to load secrets: ${result.error}';
          _isLoadingSecrets = false;
        });
        AppLogger.error('Failed to load secrets for Key Vault: ${widget.keyVaultName}', result.error);
      }
    } catch (e) {
      setState(() {
        _secretsError = 'Error loading secrets: ${e.toString()}';
        _isLoadingSecrets = false;
      });
      AppLogger.error('Error loading secrets for Key Vault: ${widget.keyVaultName}', e);
    }
  }

  Future<void> _createSecret() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _CreateSecretDialog(),
    );

    if (result != null) {
      setState(() {
        _isLoadingSecrets = true;
      });

      try {
        final createResult = await widget.azureCliService.setSecret(
          keyVaultName: widget.keyVaultName,
          secretName: result['name']!,
          value: result['value']!,
        );

        if (createResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Secret "${result['name']}" created successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          await _loadSecrets();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create secret: ${createResult.error}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating secret: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        setState(() {
          _isLoadingSecrets = false;
        });
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Key Vaults',
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              AppIcons.keyVault,
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
                  widget.keyVaultName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Key Vault Details',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecretsTab() {
    if (_isLoadingSecrets) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_secretsError != null) {
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
              'Error Loading Secrets',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _secretsError!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _loadSecrets,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_secrets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                AppIcons.secret,
                size: 60,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Secrets Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create your first secret to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _createSecret,
              icon: const Icon(AppIcons.add),
              label: const Text('Create Secret'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Secrets header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Secrets (${_secrets.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loadSecrets,
                icon: const Icon(AppIcons.refresh),
                label: const Text('Refresh'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _createSecret,
                icon: const Icon(AppIcons.add),
                label: const Text('Create Secret'),
              ),
            ],
          ),
        ),
        
        // Secrets list
        Expanded(
          child: ListView.builder(
            itemCount: _secrets.length,
            itemBuilder: (context, index) {
              final secret = _secrets[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: secret.enabled
                          ? AppTheme.successColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      AppIcons.secret,
                      color: secret.enabled ? AppTheme.successColor : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    secret.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${secret.enabled ? 'Enabled' : 'Disabled'}'),
                      if (secret.created != null)
                        Text('Created: ${_formatDate(secret.created!)}'),
                      if (secret.expires != null)
                        Text('Expires: ${_formatDate(secret.expires!)}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      // Handle secret actions
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(AppIcons.visibility),
                          title: Text('View'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(AppIcons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(AppIcons.delete, color: AppTheme.errorColor),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: TabBar(
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
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSecretsTab(),
                const Center(child: Text('Keys management coming soon')),
                const Center(child: Text('Certificates management coming soon')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateSecretDialog extends StatefulWidget {
  @override
  State<_CreateSecretDialog> createState() => _CreateSecretDialogState();
}

class _CreateSecretDialogState extends State<_CreateSecretDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  bool _isValueVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Secret'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Secret Name *',
                  hintText: 'Enter secret name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Secret name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: 'Secret Value *',
                  hintText: 'Enter secret value',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isValueVisible = !_isValueVisible;
                      });
                    },
                    icon: Icon(
                      _isValueVisible ? AppIcons.visibilityOff : AppIcons.visibility,
                    ),
                  ),
                ),
                obscureText: !_isValueVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Secret value is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'value': _valueController.text,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}