import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/vault_item_entity.dart';
import '../providers/vault_items_provider.dart';
import '../providers/vault_providers.dart';

class CreateVaultItemScreen extends ConsumerStatefulWidget {
  const CreateVaultItemScreen({super.key});

  @override
  ConsumerState<CreateVaultItemScreen> createState() =>
      _CreateVaultItemScreenState();
}

class _CreateVaultItemScreenState
    extends ConsumerState<CreateVaultItemScreen> {
  final _formKey = GlobalKey<FormState>();

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

  bool _isSaving = false;
  bool _isFavorite = false;

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

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _createItem() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();

    final item = VaultItemEntity(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,

      // Snippet / Note
      content: _contentController.text.trim(),
      language: _emptyToNull(_languageController.text),

      // API
      url: _emptyToNull(_urlController.text),
      method: _emptyToNull(_methodController.text),
      headers: _emptyToNull(_headersController.text),
      queryParameters: _emptyToNull(
        _queryParametersController.text,
      ),
      body: _emptyToNull(_bodyController.text),

      // MQTT
      broker: _emptyToNull(_brokerController.text),
      port: int.tryParse(_portController.text.trim()),
      username: _emptyToNull(_usernameController.text),
      password: _emptyToNull(_passwordController.text),
      clientId: _emptyToNull(_clientIdController.text),
      publishTopic: _emptyToNull(
        _publishTopicController.text,
      ),
      publishPayload: _emptyToNull(
        _publishPayloadController.text,
      ),
      subscribeTopic: _emptyToNull(
        _subscribeTopicController.text,
      ),
      subscribePayload: _emptyToNull(
        _subscribePayloadController.text,
      ),
      qos: int.tryParse(_qosController.text.trim()),

      isFavorite: _isFavorite,
      createdAt: now,
      updatedAt: now,
      collectionId: null,
    );

    try {
      await ref.read(createVaultItemProvider).call(item);

      ref.invalidate(vaultItemsProvider);

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
            'Unable to create item: $error',
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
  Widget build(BuildContext context) {
    final showApiFields = _selectedType == VaultItemType.api;
    final showMqttFields = _selectedType == VaultItemType.mqtt;
    final showLanguage = _selectedType == VaultItemType.snippet;
    final showContent = _selectedType == VaultItemType.snippet ||
        _selectedType == VaultItemType.note;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Item'),
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
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedType = value;
                        });
                      },
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
              // Snippet / Note content
              // --------------------------------------------------

              if (showContent)
                TextFormField(
                  controller: _contentController,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText:
                        _selectedType ==
                                VaultItemType.note
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
                  onPressed: _isSaving
                      ? null
                      : _createItem,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Create Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}