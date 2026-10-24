import 'package:drift/drift.dart';

class Collections extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  IntColumn get color => integer()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class VaultItems extends Table {
  // -------------------------
  // Common
  // -------------------------

  TextColumn get id => text()();

  TextColumn get title => text()();

  TextColumn get description =>
      text().withDefault(const Constant(''))();

  TextColumn get type => text()();

  TextColumn get content =>
      text().withDefault(const Constant(''))();

  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get collectionId =>
      text().nullable().references(Collections, #id)();

  // -------------------------
  // Snippet
  // -------------------------

  TextColumn get language => text().nullable()();

  // -------------------------
  // API
  // -------------------------

  TextColumn get url => text().nullable()();

  TextColumn get method => text().nullable()();

  TextColumn get headers => text().nullable()();

  TextColumn get queryParameters => text().nullable()();

  TextColumn get body => text().nullable()();

  // -------------------------
  // MQTT
  // -------------------------

  TextColumn get broker => text().nullable()();

  IntColumn get port => integer().nullable()();

  TextColumn get username => text().nullable()();

  TextColumn get password => text().nullable()();

  TextColumn get clientId => text().nullable()();

  TextColumn get publishTopic => text().nullable()();

  TextColumn get publishPayload => text().nullable()();

  TextColumn get subscribeTopic => text().nullable()();

  TextColumn get subscribePayload => text().nullable()();

  IntColumn get qos => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
class ToolFiles extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get path => text()();

  TextColumn get extension => text()();

  TextColumn get mimeType => text().nullable()();

  IntColumn get sizeBytes => integer()();

  TextColumn get toolType => text()();

  TextColumn get collectionId =>
      text().nullable().references(Collections, #id)();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}