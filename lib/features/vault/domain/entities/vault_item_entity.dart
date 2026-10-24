class VaultItemEntity {
  const VaultItemEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,

    // Common
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    required this.collectionId,

    // Snippet
    required this.language,
    required this.content,

    // API
    required this.url,
    required this.method,
    required this.headers,
    required this.queryParameters,
    required this.body,

    // MQTT
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
  });

  // -------------------------
  // Common
  // -------------------------

  final String id;
  final String title;
  final String description;
  final VaultItemType type;

  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Null means the item is currently not assigned
  /// to any collection.
  final String? collectionId;

  // -------------------------
  // Snippet / Note
  // -------------------------

  /// Programming language for snippets.
  ///
  /// Example:
  /// Dart, JavaScript, Python, SQL
  final String? language;

  /// Used by:
  /// - Snippets: source code
  /// - Notes: note content
  final String content;

  // -------------------------
  // API
  // -------------------------

  /// HTTP request URL.
  ///
  /// Example:
  /// https://api.example.com/users
  final String? url;

  /// HTTP method.
  ///
  /// Example:
  /// GET, POST, PUT, PATCH, DELETE
  final String? method;

  /// JSON encoded HTTP headers.
  final String? headers;

  /// JSON encoded query parameters.
  final String? queryParameters;

  /// HTTP request body.
  ///
  /// Usually JSON for POST/PUT/PATCH requests.
  final String? body;

  // -------------------------
  // MQTT
  // -------------------------

  /// MQTT broker hostname or IP address.
  final String? broker;

  /// MQTT broker port.
  ///
  /// Common values:
  /// 1883  -> MQTT
  /// 8883  -> MQTT over TLS
  final int? port;

  /// MQTT username.
  final String? username;

  /// MQTT password.
  final String? password;

  /// MQTT client identifier.
  final String? clientId;

  /// Topic used when publishing messages.
  final String? publishTopic;

  /// Payload used when publishing messages.
  final String? publishPayload;

  /// Topic used when subscribing.
  final String? subscribeTopic;

  /// Stored/example payload for the subscribed topic.
  final String? subscribePayload;

  /// MQTT Quality of Service.
  ///
  /// Supported values:
  /// 0, 1, 2
  final int? qos;
}

enum VaultItemType {
  snippet,
  api,
  mqtt,
  note,
}