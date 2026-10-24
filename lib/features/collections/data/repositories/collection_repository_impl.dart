// ignore: unused_import
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/collection_entity.dart';
import '../../domain/repositories/collection_repository.dart';
import '../models/collection_model.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  CollectionRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<CollectionEntity>> getCollections() async {
    final rows = await _database.select(_database.collections).get();

    return rows
        .map(CollectionModel.fromDatabase)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<CollectionEntity?> getCollectionById(String id) async {
    final query = _database.select(_database.collections)
      ..where((table) => table.id.equals(id));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return CollectionModel.fromDatabase(row).toEntity();
  }

  @override
  Future<void> createCollection(CollectionEntity collection) async {
    final model = CollectionModel.fromEntity(collection);

    await _database.into(_database.collections).insert(model.toCompanion());
  }

  @override
  Future<void> updateCollection(CollectionEntity collection) async {
    final model = CollectionModel.fromEntity(collection);

    await (_database.update(_database.collections)
          ..where((table) => table.id.equals(collection.id)))
        .write(model.toCompanion());
  }

  @override
  Future<void> deleteCollection(String id) async {
    await (_database.delete(
      _database.collections,
    )..where((table) => table.id.equals(id))).go();
  }
}
