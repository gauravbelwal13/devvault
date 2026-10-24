import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';

import '../../domain/entities/vault_item_entity.dart';

import '../providers/vault_items_provider.dart';
import '../providers/vault_providers.dart';

class EditVaultItemScreen extends ConsumerStatefulWidget {
  const EditVaultItemScreen({
    required this.itemId,
    super.key,
  });

  final String itemId;

  @override
  ConsumerState<EditVaultItemScreen> createState() =>
      _EditVaultItemScreenState();
}

class _EditVaultItemScreenState
    extends ConsumerState<EditVaultItemScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Snippet / Note
  final _contentController = TextEditingController();
  final _languageController = TextEditingController();

  // API
  final _urlController = TextEditingController();
  final _methodController = TextEditingController();
  final _headersController = TextEditingController();
  final _queryParametersController = TextEditingController();
  final _bodyController = TextEditingController();

  // MQTT
  final _brokerController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _publishTopicController = TextEditingController();
  final _publishPayloadController = TextEditingController();
  final _subscribeTopicController = TextEditingController();
  final _subscribePayloadController = TextEditingController();
  final _qosController = TextEditingController();

  VaultItemType _selectedType = VaultItemType.snippet;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFavorite = false;

  VaultItemEntity? _originalItem;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    try {
      final item = await ref
          .read(vaultRepositoryProvider)
          .getItemById(widget.itemId);

      if (!mounted) {
        return;
      }

      if (item == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _originalItem = item;

      // Common
      _titleController.text = item.title;
      _descriptionController.text = item.description;

      // Snippet / Note
      _contentController.text = item.content;
      _languageController.text = item.language ?? '';

      // API
      _urlController.text = item.url ?? '';
      _methodController.text = item.method ?? '';
      _headersController.text = item.headers ?? '';
      _queryParametersController.text = item.queryParameters ?? '';
      _bodyController.text = item.body ?? '';

      // MQTT
      _brokerController.text = item.broker ?? '';
      _portController.text = item.port?.toString() ?? '';
      _usernameController.text = item.username ?? '';
      _passwordController.text = item.password ?? '';
      _clientIdController.text = item.clientId ?? '';
      _publishTopicController.text = item.publishTopic ?? '';
      _publishPayloadController.text = item.publishPayload ?? '';
      _subscribeTopicController.text = item.subscribeTopic ?? '';
      _subscribePayloadController.text = item.subscribePayload ?? '';
      _qosController.text = item.qos?.toString() ?? '';

      setState(() {
        _selectedType = item.type;
        _isFavorite = item.isFavorite;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load item: $error',
          ),
        ),
      );
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _clearTypeSpecificFields(VaultItemType type) {
    switch (type) {
      case VaultItemType.note:
        _languageController.clear();

        _urlController.clear();
        _methodController.clear();
        _headersController.clear();
        _queryParametersController.clear();
        _bodyController.clear();

        _brokerController.clear();
        _portController.clear();
        _usernameController.clear();
        _passwordController.clear();
        _clientIdController.clear();
        _publishTopicController.clear();
        _publishPayloadController.clear();
        _subscribeTopicController.clear();
        _subscribePayloadController.clear();
        _qosController.clear();

      case VaultItemType.snippet:
        _urlController.clear();
        _methodController.clear();
        _headersController.clear();
        _queryParametersController.clear();
        _bodyController.clear();

        _brokerController.clear();
        _portController.clear();
        _usernameController.clear();
        _passwordController.clear();
        _clientIdController.clear();
        _publishTopicController.clear();
        _publishPayloadController.clear();
        _subscribeTopicController.clear();
        _subscribePayloadController.clear();
        _qosController.clear();

      case VaultItemType.api:
        _languageController.clear();

        _brokerController.clear();
        _portController.clear();
        _usernameController.clear();
        _passwordController.clear();
        _clientIdController.clear();
        _publishTopicController.clear();
        _publishPayloadController.clear();
        _subscribeTopicController.clear();
        _subscribePayloadController.clear();
        _qosController.clear();

      case VaultItemType.mqtt:
        _languageController.clear();

        _urlController.clear();
        _methodController.clear();
        _headersController.clear();
        _queryParametersController.clear();
        _bodyController.clear();
    }
  }

  void _changeType(VaultItemType? value) {
    if (value == null || value == _selectedType) {
      return;
    }

    _clearTypeSpecificFields(value);

    setState(() {
      _selectedType = value;
    });
  }

  Future<void> _updateItem() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final originalItem = _originalItem;

    if (originalItem == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedItem = VaultItemEntity(
      id: originalItem.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,

      // Snippet / Note
      content: _contentController.text.trim(),
      language: _selectedType == VaultItemType.snippet
          ? _emptyToNull(_languageController.text)
          : null,

      // API
      url: _selectedType == VaultItemType.api
          ? _emptyToNull(_urlController.text)
          : null,
      method: _selectedType == VaultItemType.api
          ? _emptyToNull(_methodController.text)
          : null,
      headers: _selectedType == VaultItemType.api
          ? _emptyToNull(_headersController.text)
          : null,
      queryParameters: _selectedType == VaultItemType.api
          ? _emptyToNull(_queryParametersController.text)
          : null,
      body: _selectedType == VaultItemType.api
          ? _emptyToNull(_bodyController.text)
          : null,

      // MQTT
      broker: _selectedType == VaultItemType.mqtt
          ? _emptyToNull(_brokerController.text)
          : null,
      port: _selectedType == VaultItemType.mqtt
          ? int.tryParse(_portController.text.trim())
          : null,
      username: _selectedType == VaultItemType.mqtt
          ? _emptyToNull(_usernameController.text)
          : null,
      password: _selectedType == VaultItemType.mqtt
          ? _emptyToNull(_passwordController.text)
          : null,
      clientId: _selectedType == VaultItemType.mqtt
          ? _emptyToNull(_clientIdController.text)
          : null,
      publishTopic: _selectedType == VaultItemType.mqtt
          ? _emptyToNull(_publishTopicController.text)
          : null,
      publishPayload: _selectedType == VaultItemType.mqtt
          ? _emptyToNull(_publishPayloadController.text)
          : null,
      subscribeTopic: _selectedType == VaultItemType.mqtt
          ? _emptyToNull(_subscribeTopicController.text)
          : null,
      subscribePayload: _selectedType == VaultItemType.mqtt
          ? _emptyToNull(_subscribePayloadController.text)
          : null,
      qos: _selectedType == VaultItemType.mqtt
          ? int.tryParse(_qosController.text.trim())
          : null,

      // Common
      isFavorite: _isFavorite,
      createdAt: originalItem.createdAt,
      updatedAt: DateTime.now(),
      collectionId: originalItem.collectionId,
    );

    try {
      await ref
          .read(updateVaultItemProvider)
          .call(updatedItem);

      ref.invalidate(vaultItemsProvider);
      ref.invalidate(vaultItemByIdProvider(updatedItem.id));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update item: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    _contentController.dispose();
    _languageController.dispose();

    _urlController.dispose();
    _methodController.dispose();
    _headersController.dispose();
    _queryParametersController.dispose();
    _bodyController.dispose();

    _brokerController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _clientIdController.dispose();
    _publishTopicController.dispose();
    _publishPayloadController.dispose();
    _subscribeTopicController.dispose();
    _subscribePayloadController.dispose();
    _qosController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_originalItem == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text('Edit Item'),
        ),
        body: const Center(
          child: Text('Item not found.'),
        ),
      );
    }

    final showApiFields = _selectedType == VaultItemType.api;
    final showMqttFields = _selectedType == VaultItemType.mqtt;
    final showLanguage = _selectedType == VaultItemType.snippet;
    final showContent =
        _selectedType == VaultItemType.snippet ||
        _selectedType == VaultItemType.note;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Item'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<VaultItemType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                ),
                items: VaultItemType.values.map((type) {
                  return DropdownMenuItem<VaultItemType>(
                    value: type,
                    child: Text(
                      type.name.toUpperCase(),
                    ),
                  );
                }).toList(),
                onChanged: _isSaving ? null : _changeType,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter a title';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // API
              // --------------------------------------------------

              if (showApiFields) ...[
                TextFormField(
                  controller: _methodController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'HTTP Method',
                    hintText: 'GET, POST, PUT...',
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _urlController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://api.example.com/users',
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (_selectedType != VaultItemType.api) {
                      return null;
                    }

                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter a URL';
                    }

                    final uri = Uri.tryParse(
                      value.trim(),
                    );

                    if (uri == null ||
                        !uri.hasScheme ||
                        (uri.scheme != 'http' &&
                            uri.scheme != 'https') ||
                        uri.host.isEmpty) {
                      return 'Enter a valid HTTP or HTTPS URL';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _headersController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Headers',
                    hintText:
                        '{"Authorization": "Bearer token"}',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 6,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _queryParametersController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Query Parameters',
                    hintText:
                        '{"page": "1", "limit": "20"}',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 6,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _bodyController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Request Body',
                    hintText: '{"name": "John"}',
                    alignLabelWithHint: true,
                  ),
                  minLines: 5,
                  maxLines: 10,
                ),

                const SizedBox(height: 16),
              ],

              // --------------------------------------------------
              // MQTT
              // --------------------------------------------------

              if (showMqttFields) ...[
                TextFormField(
                  controller: _brokerController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Broker',
                    hintText: 'mqtt.example.com',
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _portController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: '1883',
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _usernameController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Optional',
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Optional',
                  ),
                  obscureText: true,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _clientIdController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Client ID',
                    hintText: 'Optional',
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Publish',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _publishTopicController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Publish Topic',
                    hintText: 'home/device/command',
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _publishPayloadController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Publish Payload',
                    hintText: '{"command": "on"}',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 8,
                ),

                const SizedBox(height: 24),

                Text(
                  'Subscribe',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _subscribeTopicController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Subscribe Topic',
                    hintText: 'home/device/status',
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _subscribePayloadController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Subscribe Payload',
                    hintText: '{"status": "online"}',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 8,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _qosController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'QoS',
                    hintText: '0, 1 or 2',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedType != VaultItemType.mqtt) {
                      return null;
                    }

                    if (value == null ||
                        value.trim().isEmpty) {
                      return null;
                    }

                    final qos = int.tryParse(
                      value.trim(),
                    );

                    if (qos == null ||
                        qos < 0 ||
                        qos > 2) {
                      return 'QoS must be 0, 1 or 2';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),
              ],

              // --------------------------------------------------
              // Snippet
              // --------------------------------------------------

              if (showLanguage) ...[
                TextFormField(
                  controller: _languageController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    hintText:
                        'Dart, JavaScript, Python...',
                  ),
                ),

                const SizedBox(height: 16),
              ],

              // --------------------------------------------------
              // Note / Snippet Content
              // --------------------------------------------------

              if (showContent)
                TextFormField(
                  controller: _contentController,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText:
                        _selectedType == VaultItemType.note
                            ? 'Note'
                            : 'Code',
                    alignLabelWithHint: true,
                  ),
                  minLines: 8,
                  maxLines: 15,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return _selectedType ==
                              VaultItemType.note
                          ? 'Enter your note'
                          : 'Enter some code';
                    }

                    return null;
                  },
                ),

              if (showContent)
                const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Favorite'),
                subtitle: const Text(
                  'Keep this item easy to find.',
                ),
                value: _isFavorite,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _isFavorite = value;
                        });
                      },
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed:
                      _isSaving ? null : _updateItem,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Update Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}