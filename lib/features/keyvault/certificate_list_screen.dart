import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/logging/app_logger.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';
import '../../services/keyvault/certificate_service.dart';
import '../../services/keyvault/certificate_models.dart';
import '../../shared/widgets/app_theme.dart';
import 'certificate_create_dialog.dart';
import 'certificate_details_screen.dart';

class CertificateListScreen extends StatefulWidget {
  final String vaultName;
  final UnifiedAzureCliService cliService;

  const CertificateListScreen({
    super.key,
    required this.vaultName,
    required this.cliService,
  });

  @override
  State<CertificateListScreen> createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<CertificateListScreen> {
  late CertificateService _certificateService;
  List<CertificateInfo> _certificates = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _certificateService = CertificateService(widget.cliService);
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    if (widget.vaultName.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final certificates = await _certificateService.listCertificates(widget.vaultName);
      setState(() {
        _certificates = certificates;
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

    if (confirmed == true && mounted) {
      try {
        await _certificateService.deleteCertificate(widget.vaultName, certificate.name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Certificate "${certificate.name}" deleted successfully')),
          );
          _loadCertificates();
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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CertificateCreateDialog(
        vaultName: widget.vaultName,
        certificateService: _certificateService,
      ),
    );

    if (result == true) {
      _loadCertificates();
    }
  }

  List<CertificateInfo> get _filteredCertificates {
    if (_searchQuery.isEmpty) return _certificates;
    return _certificates.where((cert) =>
        cert.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (cert.subject?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        (cert.issuer?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Certificates - ${widget.vaultName}'),
        actions: [
          IconButton(
            onPressed: _loadCertificates,
            icon: const Icon(AppIcons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _createCertificate,
            icon: const Icon(AppIcons.add),
            tooltip: 'Create Certificate',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search certificates...',
                prefixIcon: const Icon(AppIcons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(AppIcons.close),
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
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

    final filteredCertificates = _filteredCertificates;

    if (filteredCertificates.isEmpty) {
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
              _searchQuery.isEmpty ? 'No certificates found' : 'No certificates match your search',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _searchQuery.isEmpty
                  ? 'Create your first certificate to get started'
                  : 'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isEmpty) ...[
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
      itemCount: filteredCertificates.length,
      itemBuilder: (context, index) {
        final certificate = filteredCertificates[index];
        return _buildCertificateCard(certificate);
      },
    );
  }

  Widget _buildCertificateCard(CertificateInfo certificate) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CertificateDetailsScreen(
                vaultName: widget.vaultName,
                certificateName: certificate.name,
                cliService: widget.cliService,
              ),
            ),
          );
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