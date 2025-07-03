import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/logging/app_logger.dart';
import '../../services/azure_cli/platform_azure_cli_service.dart';
import '../../services/keyvault/certificate_service.dart';
import '../../services/keyvault/certificate_models.dart';
import '../../shared/widgets/app_theme.dart';

class CertificateDetailsScreen extends StatefulWidget {
  final String vaultName;
  final String certificateName;
  final UnifiedAzureCliService cliService;

  const CertificateDetailsScreen({
    super.key,
    required this.vaultName,
    required this.certificateName,
    required this.cliService,
  });

  @override
  State<CertificateDetailsScreen> createState() => _CertificateDetailsScreenState();
}

class _CertificateDetailsScreenState extends State<CertificateDetailsScreen> {
  late CertificateService _certificateService;
  CertificateInfo? _certificate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _certificateService = CertificateService(widget.cliService);
    _loadCertificate();
  }

  Future<void> _loadCertificate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final certificate = await _certificateService.getCertificate(widget.vaultName, widget.certificateName);
      setState(() {
        _certificate = certificate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      AppLogger.error('Failed to load certificate details', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Certificate: ${widget.certificateName}'),
        actions: [
          IconButton(
            onPressed: _loadCertificate,
            icon: const Icon(AppIcons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildContent(),
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
            Text('Loading certificate details...'),
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
              'Failed to load certificate details',
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
              onPressed: _loadCertificate,
              icon: const Icon(AppIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_certificate == null) {
      return const Center(
        child: Text('Certificate not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCertificateHeader(),
          const SizedBox(height: AppSpacing.xl),
          _buildCertificateProperties(),
          const SizedBox(height: AppSpacing.xl),
          _buildSubjectAndIssuer(),
          if (_certificate!.keyUsage != null && _certificate!.keyUsage!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildKeyUsage(),
          ],
          if (_certificate!.tags != null && _certificate!.tags!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildTags(),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificateHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getCertificateStatusColor(_certificate!.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: Icon(
                AppIcons.certificate,
                color: _getCertificateStatusColor(_certificate!.status),
                size: 30,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _certificate!.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_certificate!.subject != null)
                    Text(
                      _certificate!.subject!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _buildStatusChip(_certificate!.status),
                      if (_certificate!.daysUntilExpiration != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        _buildExpiryChip(_certificate!.daysUntilExpiration!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _certificate!.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Certificate ID copied to clipboard')),
                    );
                  },
                  icon: const Icon(AppIcons.copy),
                  tooltip: 'Copy Certificate ID',
                ),
                if (_certificate!.thumbprint != null)
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _certificate!.thumbprint!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thumbprint copied to clipboard')),
                      );
                    },
                    icon: const Icon(AppIcons.copy),
                    tooltip: 'Copy Thumbprint',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateProperties() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Properties',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildPropertyGrid([
              _PropertyItem('Certificate ID', _certificate!.id),
              _PropertyItem('Name', _certificate!.name),
              if (_certificate!.thumbprint != null) _PropertyItem('Thumbprint', _certificate!.thumbprint!),
              if (_certificate!.version != null) _PropertyItem('Version', _certificate!.version!),
              _PropertyItem('Enabled', _certificate!.enabled?.toString() ?? 'Unknown'),
              if (_certificate!.contentType != null) _PropertyItem('Content Type', _certificate!.contentType!),
              if (_certificate!.created != null) _PropertyItem('Created', _formatDate(_certificate!.created!)),
              if (_certificate!.updated != null) _PropertyItem('Updated', _formatDate(_certificate!.updated!)),
              if (_certificate!.expires != null) _PropertyItem('Expires', _formatDate(_certificate!.expires!)),
              if (_certificate!.notBefore != null) _PropertyItem('Not Before', _formatDate(_certificate!.notBefore!)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectAndIssuer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject & Issuer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildPropertyGrid([
              if (_certificate!.subject != null) _PropertyItem('Subject', _certificate!.subject!),
              if (_certificate!.issuer != null) _PropertyItem('Issuer', _certificate!.issuer!),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyUsage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Usage',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _certificate!.keyUsage!.map((usage) {
                return Chip(
                  label: Text(usage),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
            if (_certificate!.enhancedKeyUsage != null && _certificate!.enhancedKeyUsage!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Enhanced Key Usage',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _certificate!.enhancedKeyUsage!.map((usage) {
                  return Chip(
                    label: Text(usage),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _certificate!.tags!.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key}: ${entry.value}'),
                  backgroundColor: Colors.grey[100],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyGrid(List<_PropertyItem> properties) {
    return Column(
      children: properties.map((property) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  property.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  property.value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getCertificateStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExpiryChip(int daysUntilExpiration) {
    Color color;
    String text;

    if (daysUntilExpiration < 0) {
      color = AppTheme.errorColor;
      text = 'Expired ${-daysUntilExpiration} days ago';
    } else if (daysUntilExpiration <= 30) {
      color = AppTheme.warningColor;
      text = 'Expires in $daysUntilExpiration days';
    } else {
      color = AppTheme.successColor;
      text = 'Expires in $daysUntilExpiration days';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
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
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PropertyItem {
  final String label;
  final String value;

  _PropertyItem(this.label, this.value);
}