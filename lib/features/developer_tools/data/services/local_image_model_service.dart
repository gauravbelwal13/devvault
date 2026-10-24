import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalImageModelService {
  const LocalImageModelService();

  static const String modelFileName =
      'v1-5-pruned-emaonly.safetensors';

  Future<Directory> _getModelDirectory() async {
    final appDirectory = await getApplicationSupportDirectory();

    final directory = Directory(
      '${appDirectory.path}/devvault/models',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<String> getModelPath() async {
    final directory = await _getModelDirectory();

    return '${directory.path}/$modelFileName';
  }

  Future<bool> isModelInstalled() async {
    final path = await getModelPath();
    final file = File(path);

    if (!await file.exists()) {
      return false;
    }

    return await file.length() == 4265146304;
  }

  Future<int> getModelSizeBytes() async {
    final path = await getModelPath();
    final file = File(path);

    if (!await file.exists()) {
      return 0;
    }

    return file.length();
  }

  Future<File> getModelFile() async {
    return File(await getModelPath());
  }

  Future<void> deleteModel() async {
    final file = await getModelFile();

    if (await file.exists()) {
      await file.delete();
    }
  }
}