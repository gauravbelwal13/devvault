import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/vault_item_entity.dart';

class VaultItemModel {
  const VaultItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.content,
    required this.language,
    required this.url,
    required this.method,
    required this.headers,
    required this.queryParameters,
    required this.body,
    required this.broker,
    required this.port,
    required this.username,
    required this.password,
    required this.clientId,
    required this.publishTopic,
    required this.publishPayload,
    required this.subscribeTopic,
    required this.subscribePayload,
    required this.qos,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    required this.collectionId,
  });

  // -------------------------
  // Common
  // -------------------------

  final String id;
  final String title;
  final String description;
  final VaultItemType type;

  final String content;
  final String? language;

  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? collectionId;

  // -------------------------
  // API
  // -------------------------

  final String? url;
  final String? method;
  final String? headers;
  final String? queryParameters;
  final String? body;

  // -------------------------
  // MQTT
  // -------------------------

  final String? broker;
  final int? port;
  final String? username;
  final String? password;
  final String? clientId;

  final String? publishTopic;
  final String? publishPayload;

  final String? subscribeTopic;
  final String? subscribePayload;

  final int? qos;

  // -------------------------
  // -------------------------

  factory VaultItemModel.fromEntity(VaultItemEntity item) {
    return VaultItemModel(
      id: item.id,
      title: item.title,
      description: item.description,
      type: item.type,

      content: item.content,
      language: item.language,

      url: item.url,
      method: item.method,
      headers: item.headers,
      queryParameters: item.queryParameters,
      body: item.body,

      broker: item.broker,
      port: item.port,
      username: item.username,
      password: item.password,
      clientId: item.clientId,

      publishTopic: item.publishTopic,
      publishPayload: item.publishPayload,
      subscribeTopic: item.subscribeTopic,
      subscribePayload: item.subscribePayload,
      qos: item.qos,

      isFavorite: item.isFavorite,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      collectionId: item.collectionId,
    );
  }

  // -------------------------
  // Database -> Model
  // -------------------------

  factory VaultItemModel.fromDatabase(VaultItem data) {
    return VaultItemModel(
      id: data.id,
      title: data.title,
      description: data.description,
      type: VaultItemType.values.byName(data.type),

      content: data.content,
      language: data.language,

      url: data.url,
      method: data.method,
      headers: data.headers,
      queryParameters: data.queryParameters,
      body: data.body,

      broker: data.broker,
      port: data.port,
      username: data.username,
      password: data.password,
      clientId: data.clientId,

      publishTopic: data.publishTopic,
      publishPayload: data.publishPayload,
      subscribeTopic: data.subscribeTopic,
      subscribePayload: data.subscribePayload,
      qos: data.qos,

      isFavorite: data.isFavorite,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      collectionId: data.collectionId,
    );
  }

  // -------------------------
  // Model -> Entity
  // -------------------------

  VaultItemEntity toEntity() {
    return VaultItemEntity(
      id: id,
      title: title,
      description: description,
      type: type,

      content: content,
      language: language,

      url: url,
      method: method,
      headers: headers,
      queryParameters: queryParameters,
      body: body,

      broker: broker,
      port: port,
      username: username,
      password: password,
      clientId: clientId,

      publishTopic: publishTopic,
      publishPayload: publishPayload,
      subscribeTopic: subscribeTopic,
      subscribePayload: subscribePayload,
      qos: qos,

      isFavorite: isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt,
      collectionId: collectionId,
    );
  }

  // -------------------------
  // Model -> Drift Companion
  // -------------------------

  VaultItemsCompanion toCompanion() {
    return VaultItemsCompanion.insert(
      id: id,
      title: title,
      description: Value(description),
      type: type.name,

      content: Value(content),
      language: Value(language),

      url: Value(url),
      method: Value(method),
      headers: Value(headers),
      queryParameters: Value(queryParameters),
      body: Value(body),

      broker: Value(broker),
      port: Value(port),
      username: Value(username),
      password: Value(password),
      clientId: Value(clientId),

      publishTopic: Value(publishTopic),
      publishPayload: Value(publishPayload),
      subscribeTopic: Value(subscribeTopic),
      subscribePayload: Value(subscribePayload),
      qos: Value(qos),

      isFavorite: Value(isFavorite),
      createdAt: createdAt,
      updatedAt: updatedAt,
      collectionId: Value(collectionId),
    );
  }
}