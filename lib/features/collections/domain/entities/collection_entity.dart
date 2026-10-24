class CollectionEntity {
  const CollectionEntity({
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
}
