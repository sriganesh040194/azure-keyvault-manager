import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/logging/app_logger.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';
import '../../services/keyvault/certificate_service.dart';
import '../../services/keyvault/certificate_models.dart';
import '../../services/keyvault/keyvault_service.dart' show KeyVaultService, KeyVaultInfo;
import '../../shared/widgets/app_theme.dart';
import 'certificate_create_dialog.dart';
import 'certificate_details_screen.dart';

class CertificateListScreen extends StatefulWidget {
  final String? vaultName;
  final UnifiedAzureCliService cliService;
  final bool showVaultSelector;

  const CertificateListScreen({
    super.key,
    this.vaultName,
    required this.cliService,
    this.showVaultSelector = true,
  });

  @override
  State<CertificateListScreen> createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<CertificateListScreen> {
  late CertificateService _certificateService;
  late KeyVaultService _keyVaultService;
  List<CertificateInfo> _certificates = [];
  List<CertificateInfo> _filteredCertificates = [];
  List<KeyVaultInfo> _keyVaults = [];
  bool _isLoading = false;
  bool _isLoadingKeyVaults = false;
  String? _errorMessage;
  String? _selectedVaultName;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _certificateService = CertificateService(widget.cliService);
    _keyVaultService = KeyVaultService(widget.cliService);
    _searchController.addListener(_filterCertificates);
    _selectedVaultName = widget.vaultName;
    
    if (widget.showVaultSelector) {
      _loadKeyVaults();
    }
    
    if (_selectedVaultName != null && _selectedVaultName!.isNotEmpty) {
      _loadCertificates();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKeyVaults() async {
    setState(() {
      _isLoadingKeyVaults = true;
    });

    try {
      final keyVaults = await _keyVaultService.listKeyVaults();
      setState(() {
        _keyVaults = keyVaults;
        _isLoadingKeyVaults = false;
        
        // If selected vault is no longer available, clear the selection
        if (_selectedVaultName != null && 
            !keyVaults.any((vault) => vault.name == _selectedVaultName)) {
          _selectedVaultName = null;
          _certificates.clear();
          _filteredCertificates.clear();
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingKeyVaults = false;
      });
      AppLogger.error('Failed to load key vaults', e);
    }
  }

  Future<void> _loadCertificates() async {
    if (_selectedVaultName == null || _selectedVaultName!.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final certificates = await _certificateService.listCertificates(_selectedVaultName!);
      setState(() {
        _certificates = certificates;
        _filteredCertificates = certificates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      AppLogger.error('Failed to load certificates', e);
    }
  }

  void _filterCertificates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCertificates = _certificates;
      } else {
        _filteredCertificates = _certificates.where((cert) =>
            cert.name.toLowerCase().contains(query) ||
            (cert.issuer?.toLowerCase().contains(query) ?? false) ||
            (cert.subject?.toLowerCase().contains(query) ?? false)
        ).toList();
      }
    });
  }

  Future<void> _deleteCertificate(CertificateInfo certificate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the certificate "${certificate.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _selectedVaultName != null) {
      try {
        await _certificateService.deleteCertificate(_selectedVaultName!, certificate.name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Certificate "${certificate.name}" deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          await _loadCertificates();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete certificate: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _createCertificate() async {
    if (_selectedVaultName == null) return;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CertificateCreateDialog(
        vaultName: _selectedVaultName!,
        certificateService: _certificateService,
      ),
    );

    if (result == true) {
      _loadCertificates();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        if (widget.showVaultSelector) _buildKeyVaultSelector(),
        if (_selectedVaultName != null && _selectedVaultName!.isNotEmpty) _buildSearchBar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: const Icon(
              AppIcons.certificate,
              color: AppTheme.warningColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certificates',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedVaultName ?? 'No Key Vault selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _selectedVaultName != null ? _loadCertificates : null,
            icon: const Icon(AppIcons.refresh),
            label: const Text('Refresh'),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: _selectedVaultName != null ? _createCertificate : null,
            icon: const Icon(AppIcons.add),
            label: const Text('Create Certificate'),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyVaultSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.keyVault),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _isLoadingKeyVaults
                ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Text('Loading Key Vaults...'),
                    ],
                  )
                : DropdownButton<String>(
                    hint: const Text('Select a Key Vault'),
                    value: _keyVaults.any((vault) => vault.name == _selectedVaultName) 
                        ? _selectedVaultName 
                        : null,
                    isExpanded: true,
                    items: _keyVaults.map((vault) {
                      return DropdownMenuItem<String>(
                        value: vault.name,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(vault.name),
                            ),
                            Text(
                              vault.location,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedVaultName = newValue;
                        _certificates.clear();
                        _filteredCertificates.clear();
                        _errorMessage = null;
                      });
                      if (newValue != null && newValue.isNotEmpty) {
                        _loadCertificates();
                      }
                    },
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _loadKeyVaults,
            icon: const Icon(AppIcons.refresh),
            label: const Text('Refresh Vaults'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search certificates...',
          prefixIcon: const Icon(AppIcons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(AppIcons.close),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedVaultName == null || _selectedVaultName!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.keyVault,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Select a Key Vault',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose a Key Vault from the dropdown above to view its certificates',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Loading certificates...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.error,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load certificates',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.errorColor),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _loadCertificates,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }


    if (_filteredCertificates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.certificate,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _searchController.text.isEmpty ? 'No certificates found' : 'No certificates match your search',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _searchController.text.isEmpty
                  ? 'Create your first certificate to get started'
                  : 'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _createCertificate,
                icon: const Icon(AppIcons.add),
                label: const Text('Create Certificate'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _filteredCertificates.length,
      itemBuilder: (context, index) {
        final certificate = _filteredCertificates[index];
        return _buildCertificateCard(certificate);
      },
    );
  }

  Widget _buildCertificateCard(CertificateInfo certificate) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          if (_selectedVaultName != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CertificateDetailsScreen(
                  vaultName: _selectedVaultName!,
                  certificateName: certificate.name,
                  cliService: widget.cliService,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCertificateStatusColor(certificate.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Icon(
                      AppIcons.certificate,
                      color: _getCertificateStatusColor(certificate.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certificate.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (certificate.subject != null)
                          Text(
                            certificate.subject!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(certificate.status),
                  const SizedBox(width: AppSpacing.sm),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'copy_id':
                          Clipboard.setData(ClipboardData(text: certificate.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Certificate ID copied to clipboard')),
                          );
                          break;
                        case 'copy_thumbprint':
                          if (certificate.thumbprint != null) {
                            Clipboard.setData(ClipboardData(text: certificate.thumbprint!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Thumbprint copied to clipboard')),
                            );
                          }
                          break;
                        case 'delete':
                          _deleteCertificate(certificate);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy_id',
                        child: Row(
                          children: [
                            Icon(AppIcons.copy),
                            SizedBox(width: AppSpacing.sm),
                            Text('Copy ID'),
                          ],
                        ),
                      ),
                      if (certificate.thumbprint != null)
                        const PopupMenuItem(
                          value: 'copy_thumbprint',
                          child: Row(
                            children: [
                              Icon(AppIcons.copy),
                              SizedBox(width: AppSpacing.sm),
                              Text('Copy Thumbprint'),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(AppIcons.delete, color: AppTheme.errorColor),
                            SizedBox(width: AppSpacing.sm),
                            Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Details
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  if (certificate.issuer != null)
                    _buildDetailItem('Issuer', certificate.issuer!),
                  if (certificate.thumbprint != null)
                    _buildDetailItem('Thumbprint', certificate.thumbprint!.substring(0, 8) + '...'),
                  if (certificate.created != null)
                    _buildDetailItem('Created', _formatDate(certificate.created!)),
                  if (certificate.expires != null)
                    _buildDetailItem('Expires', _formatDate(certificate.expires!)),
                  if (certificate.daysUntilExpiration != null)
                    _buildDetailItem(
                      'Days Until Expiry',
                      certificate.daysUntilExpiration! >= 0
                          ? '${certificate.daysUntilExpiration}'
                          : 'Expired ${-certificate.daysUntilExpiration!} days ago',
                    ),
                ],
              ),

              // Key Usage
              if (certificate.keyUsage != null && certificate.keyUsage!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Key Usage:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: certificate.keyUsage!.map((usage) {
                    return Chip(
                      label: Text(usage),
                      backgroundColor: Colors.grey[100],
                    );
                  }).toList(),
                ),
              ],

              // Tags
              if (certificate.tags != null && certificate.tags!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: certificate.tags!.entries.map((entry) {
                    return Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getCertificateStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getCertificateStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.successColor;
      case 'expired':
        return AppTheme.errorColor;
      case 'disabled':
        return AppTheme.warningColor;
      case 'not active':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}