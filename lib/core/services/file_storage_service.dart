import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class FileStorageService {
  const FileStorageService();

  Future<Directory> _getToolsDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final toolsDirectory = Directory(
      '${appDirectory.path}/devvault/tools',
    );

    if (!await toolsDirectory.exists()) {
      await toolsDirectory.create(
        recursive: true,
      );
    }

    return toolsDirectory;
  }

  Future<Directory> _getModelsDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final modelsDirectory = Directory(
      '${appDirectory.path}/devvault/models',
    );

    if (!await modelsDirectory.exists()) {
      await modelsDirectory.create(
        recursive: true,
      );
    }

    return modelsDirectory;
  }

  Future<File> getToolsFile({
    required String fileName,
  }) async {
    final directory = await _getToolsDirectory();

    return File(
      '${directory.path}/$fileName',
    );
  }

  Future<File> getModelFile({
    required String fileName,
  }) async {
    final directory = await _getModelsDirectory();

    return File(
      '${directory.path}/$fileName',
    );
  }

  Future<Directory> getModelsDirectory() {
    return _getModelsDirectory();
  }

  Future<Directory> getToolsDirectory() {
    return _getToolsDirectory();
  }

  Future<File> saveBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final file = await getToolsFile(
      fileName: fileName,
    );

    return file.writeAsBytes(
      bytes,
      flush: true,
    );
  }

  Future<bool> exists(String path) {
    return File(path).exists();
  }

  Future<void> delete(String path) async {
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> createFile({
    required String fileName,
  }) async {
    final directory = await _getToolsDirectory();

    return File(
      '${directory.path}/$fileName',
    );
  }
}