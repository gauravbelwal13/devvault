import 'package:drift/drift.dart';

import 'database_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Collections,
    VaultItems,
    ToolFiles,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },

        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(collections);

            await m.addColumn(
              vaultItems,
              vaultItems.collectionId,
            );
          }

          if (from < 3) {
            await m.addColumn(
              vaultItems,
              vaultItems.headers,
            );

            await m.addColumn(
              vaultItems,
              vaultItems.queryParameters,
            );

            await m.addColumn(
              vaultItems,
              vaultItems.broker,
            );

            await m.addColumn(
              vaultItems,
              vaultItems.port,
            );

            await m.addColumn(
              vaultItems,
              vaultItems.username,
            );

            await m.addColumn(
              vaultItems,
              vaultItems.password,
            );

            await m.addColumn(
              vaultItems,
              vaultItems.clientId,
            );

            await m.addColumn(
              vaultItems,
              vaultItems.qos,
            );
          }

          if (from < 4) {
            await m.addColumn(
              vaultItems,
              vaultItems.body,
            );

            await m.addColumn(
              vaultItems,
              vaultItems.publishTopic,
            );

            await m.addColumn(
              vaultItems,
              vaultItems.publishPayload,
            );

            await m.addColumn(
              vaultItems,
              vaultItems.subscribeTopic,
            );

            await m.addColumn(
              vaultItems,
              vaultItems.subscribePayload,
            );
          }

          if (from < 5) {
            await m.createTable(toolFiles);
          }
        },
      );
}