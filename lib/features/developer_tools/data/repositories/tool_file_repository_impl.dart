import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

import '../../domain/entities/tool_file_entity.dart';

import '../../domain/repositories/tool_file_repository.dart';

import '../models/tool_file_model.dart';

class ToolFileRepositoryImpl implements ToolFileRepository {
  ToolFileRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<ToolFileEntity>> getFiles() async {
    final rows = await _database.select(_database.toolFiles).get();

    return rows
        .map(ToolFileModel.fromDatabase)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<ToolFileEntity?> getFileById(String id) async {
    final query = _database.select(_database.toolFiles)
      ..where((table) => table.id.equals(id));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return ToolFileModel.fromDatabase(row).toEntity();
  }

  @override
  Future<List<ToolFileEntity>> getFilesByCollection(
    String collectionId,
  ) async {
    final query = _database.select(_database.toolFiles)
      ..where(
        (table) => table.collectionId.equals(collectionId),
      )
      ..orderBy([
        (table) => OrderingTerm(
              expression: table.updatedAt,
              mode: OrderingMode.desc,
            ),
      ]);

    final rows = await query.get();

    return rows
        .map(ToolFileModel.fromDatabase)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> saveFile(ToolFileEntity file) async {
    final model = ToolFileModel.fromEntity(file);

    await _database
        .into(_database.toolFiles)
        .insertOnConflictUpdate(model.toCompanion());
  }

  @override
  Future<void> deleteFile(String id) async {
    await (_database.delete(
      _database.toolFiles,
    )..where((table) => table.id.equals(id)))
        .go();
  }
}