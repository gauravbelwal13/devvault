import 'dart:io';

abstract interface class ImageGenerationService {
  Future<bool> isAvailable();

  Future<File> generate({
    required String prompt,
    String negativePrompt = '',
    int width = 512,
    int height = 512,
    int steps = 20,
    int seed = -1,
  });
}