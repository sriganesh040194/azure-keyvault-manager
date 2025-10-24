import 'package:flutter/material.dart';
import '../../core/logging/app_logger.dart';
import '../../services/keyvault/secret_service.dart';
import '../../services/keyvault/secret_models.dart';
import '../../shared/widgets/app_theme.dart';

class SecretUpdateDialog extends StatefulWidget {
  final String vaultName;
  final SecretInfo secret;
  final SecretService secretService;

  const SecretUpdateDialog({
    super.key,
    required this.vaultName,
    required this.secret,
    required this.secretService,
  });

  @override
  State<SecretUpdateDialog> createState() => _SecretUpdateDialogState();
}

class _SecretUpdateDialogState extends State<SecretUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _valueController;
  late TextEditingController _contentTypeController;
  late TextEditingController _tagsController;
  
  bool _enabled = true;
  DateTime? _expiresDate;
  DateTime? _notBeforeDate;
  bool _isLoading = false;
  bool _showValue = false;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController();
    _contentTypeController = TextEditingController(text: widget.secret.contentType ?? '');
    _enabled = widget.secret.enabled ?? true;
    _expiresDate = widget.secret.expires;
    _notBeforeDate = widget.secret.notBefore;
    
    // Format tags for editing
    if (widget.secret.tags != null && widget.secret.tags!.isNotEmpty) {
      final tagsString = widget.secret.tags!.entries
          .map((e) => '${e.key}=${e.value}')
          .join('\n');
      _tagsController = TextEditingController(text: tagsString);
    } else {
      _tagsController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _contentTypeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _updateSecret() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse tags
      Map<String, String>? tags;
      if (_tagsController.text.trim().isNotEmpty) {
        tags = {};
        final lines = _tagsController.text.trim().split('\n');
        for (final line in lines) {
          if (line.trim().isNotEmpty && line.contains('=')) {
            final parts = line.split('=');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts.sublist(1).join('=').trim();
              if (key.isNotEmpty) {
                tags[key] = value;
              }
            }
          }
        }
      }

      // If value is provided, use setSecret to update both value and attributes
      if (_valueController.text.trim().isNotEmpty) {
        final request = CreateSecretRequest(
          name: widget.secret.name,
          value: _valueController.text.trim(),
          contentType: _contentTypeController.text.trim().isNotEmpty 
              ? _contentTypeController.text.trim() 
              : null,
          enabled: _enabled,
          expires: _expiresDate,
          notBefore: _notBeforeDate,
          tags: tags,
        );

        await widget.secretService.setSecret(widget.vaultName, request);
      } else {
        // Only update attributes
        final request = UpdateSecretRequest(
          contentType: _contentTypeController.text.trim().isNotEmpty 
              ? _contentTypeController.text.trim() 
              : null,
          enabled: _enabled,
          expires: _expiresDate,
          notBefore: _notBeforeDate,
          tags: tags,
        );

        await widget.secretService.updateSecret(widget.vaultName, widget.secret.name, request);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Secret "${widget.secret.name}" updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update secret: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      AppLogger.error('Failed to update secret: ${widget.secret.name}', e);
    }
  }

  Future<void> _selectDate(bool isExpires) async {
    final initialDate = isExpires ? _expiresDate : _notBeforeDate;
    final firstDate = DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 365 * 10));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate != null) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
      );

      if (selectedTime != null) {
        final combinedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        setState(() {
          if (isExpires) {
            _expiresDate = combinedDateTime;
          } else {
            _notBeforeDate = combinedDateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Secret: ${widget.secret.name}'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Value section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Secret Value',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showValue = !_showValue;
                                });
                              },
                              icon: Icon(_showValue ? AppIcons.visibilityOff : AppIcons.visibility),
                              label: Text(_showValue ? 'Hide' : 'Show'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _valueController,
                          decoration: const InputDecoration(
                            labelText: 'New Value (leave empty to keep current)',
                            hintText: 'Enter new secret value...',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: !_showValue,
                          maxLines: _showValue ? 3 : 1,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.md),

                // Properties section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Properties',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        TextFormField(
                          controller: _contentTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Content Type',
                            hintText: 'e.g., text/plain, application/json',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        SwitchListTile(
                          title: const Text('Enabled'),
                          subtitle: const Text('Whether the secret is active'),
                          value: _enabled,
                          onChanged: (value) {
                            setState(() {
                              _enabled = value;
                            });
                          },
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Expires date
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Expires: ${_expiresDate != null ? _formatDateTime(_expiresDate!) : 'Not set'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _selectDate(true),
                              child: const Text('Set'),
                            ),
                            if (_expiresDate != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _expiresDate = null;
                                  });
                                },
                                child: const Text('Clear'),
                              ),
                          ],
                        ),

                        // Not before date
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Not Before: ${_notBeforeDate != null ? _formatDateTime(_notBeforeDate!) : 'Not set'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _selectDate(false),
                              child: const Text('Set'),
                            ),
                            if (_notBeforeDate != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _notBeforeDate = null;
                                  });
                                },
                                child: const Text('Clear'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Tags section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tags',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags (one per line)',
                            hintText: 'key1=value1\nkey2=value2',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _updateSecret,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}