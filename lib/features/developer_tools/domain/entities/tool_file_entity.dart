class ToolFileEntity {
  const ToolFileEntity({
    required this.id,
    required this.name,
    required this.path,
    required this.extension,
    required this.mimeType,
    required this.sizeBytes,
    required this.toolType,
    required this.collectionId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String path;
  final String extension;
  final String? mimeType;
  final int sizeBytes;
  final String toolType;
  final String? collectionId;
  final DateTime createdAt;
  final DateTime updatedAt;
}