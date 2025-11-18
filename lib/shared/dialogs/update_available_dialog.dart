/// Dialog for displaying available app updates
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:azure_key_vault_manager/services/update/update_models.dart';
import 'package:azure_key_vault_manager/services/update/update_storage.dart';
import 'package:azure_key_vault_manager/shared/widgets/app_theme.dart';
import 'package:azure_key_vault_manager/core/logging/app_logger.dart';
import 'package:intl/intl.dart';

/// Shows a dialog indicating an update is available
Future<void> showUpdateAvailableDialog({
  required BuildContext context,
  required UpdateInfo updateInfo,
  required String currentVersion,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return UpdateAvailableDialog(
        updateInfo: updateInfo,
        currentVersion: currentVersion,
      );
    },
  );
}

/// Dialog widget for displaying update information
class UpdateAvailableDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final String currentVersion;

  const UpdateAvailableDialog({
    super.key,
    required this.updateInfo,
    required this.currentVersion,
  });

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      title: Row(
        children: [
          Icon(
            AppIcons.info,
            color: AppTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text('Update Available'),
          ),
          IconButton(
            icon: const Icon(AppIcons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version comparison
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildVersionInfo(
                      'Current Version',
                      widget.currentVersion,
                      Colors.grey,
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppTheme.primaryColor,
                    ),
                    _buildVersionInfo(
                      'New Version',
                      widget.updateInfo.version,
                      AppTheme.successColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Release date
              if (widget.updateInfo.releaseDate != null) ...[
                Row(
                  children: [
                    const Icon(
                      AppIcons.calendar,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Released: ${_formatDate(widget.updateInfo.releaseDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Prerelease badge
              if (widget.updateInfo.isPrerelease) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.warning,
                        size: 16,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Pre-release version',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Release notes
              if (widget.updateInfo.releaseNotes != null &&
                  widget.updateInfo.releaseNotes!.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'What\'s New',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.updateInfo.releaseNotes!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        // Remind Me Later button
        TextButton(
          onPressed: _isDownloading
              ? null
              : () async {
                  await _handleRemindLater();
                },
          child: const Text('Remind Me Later'),
        ),

        // Download Update button
        FilledButton.icon(
          onPressed: _isDownloading ? null : () async => await _handleDownload(),
          icon: _isDownloading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(AppIcons.download),
          label: Text(_isDownloading ? 'Opening...' : 'Download Update'),
        ),
      ],
    );
  }

  Widget _buildVersionInfo(String label, String version, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'v$version',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(date);
  }

  Future<void> _handleRemindLater() async {
    try {
      final storage = UpdateStorage();
      await storage.setSkippedVersion(widget.updateInfo.version);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Update reminder set. You\'ll be notified on next app restart.',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error saving skip preference: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleDownload() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final url = Uri.parse(widget.updateInfo.downloadUrl);
      final canLaunch = await canLaunchUrl(url);

      if (canLaunch) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );

        AppLogger.info('Opened download page for version ${widget.updateInfo.version}');

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Download page opened in your browser. Please install the update.',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        throw Exception('Could not launch URL: ${widget.updateInfo.downloadUrl}');
      }
    } catch (e) {
      AppLogger.error('Error opening download page: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open download page: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }
}
