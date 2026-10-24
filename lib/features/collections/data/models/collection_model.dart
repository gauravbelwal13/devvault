import '../../../../core/database/app_database.dart';
import '../../domain/entities/collection_entity.dart';

class CollectionModel {
  const CollectionModel({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CollectionModel.fromEntity(CollectionEntity collection) {
    return CollectionModel(
      id: collection.id,
      name: collection.name,
      color: collection.color,
      createdAt: collection.createdAt,
      updatedAt: collection.updatedAt,
    );
  }

  factory CollectionModel.fromDatabase(Collection data) {
    return CollectionModel(
      id: data.id,
      name: data.name,
      color: data.color,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  CollectionEntity toEntity() {
    return CollectionEntity(
      id: id,
      name: name,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CollectionsCompanion toCompanion() {
    return CollectionsCompanion.insert(
      id: id,
      name: name,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
