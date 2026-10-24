import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/repositories/tool_file_repository_impl.dart';
import '../../domain/entities/tool_file_entity.dart';
import '../../domain/repositories/tool_file_repository.dart';
import '../../domain/usecases/get_tool_files.dart';
import '../../domain/usecases/get_tool_files_by_collection.dart';
import '../../domain/usecases/save_tool_file.dart';
import '../../domain/usecases/delete_tool_file.dart';

final toolFileRepositoryProvider = Provider<ToolFileRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return ToolFileRepositoryImpl(database);
});

final getToolFilesProvider = Provider<GetToolFiles>((ref) {
  return GetToolFiles(
    ref.watch(toolFileRepositoryProvider),
  );
});

final getToolFilesByCollectionProvider =
    Provider<GetToolFilesByCollection>((ref) {
  return GetToolFilesByCollection(
    ref.watch(toolFileRepositoryProvider),
  );
});

final saveToolFileProvider = Provider<SaveToolFile>((ref) {
  return SaveToolFile(
    ref.watch(toolFileRepositoryProvider),
  );
});

final deleteToolFileProvider = Provider<DeleteToolFile>((ref) {
  return DeleteToolFile(
    ref.watch(toolFileRepositoryProvider),
  );
});

final toolFilesProvider =
    FutureProvider<List<ToolFileEntity>>((ref) {
  return ref.read(getToolFilesProvider).call();
});

final toolFilesByCollectionProvider =
    FutureProvider.family<List<ToolFileEntity>, String>(
  (ref, collectionId) {
    return ref
        .read(getToolFilesByCollectionProvider)
        .call(collectionId);
  },
);