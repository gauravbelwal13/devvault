import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/local_image_generation_service.dart';
import '../../data/services/local_image_model_service.dart';
import '../../domain/services/image_generation_service.dart';

final localImageModelServiceProvider =
    Provider<LocalImageModelService>((ref) {
  return const LocalImageModelService();
});

final localImageGenerationServiceProvider =
    Provider<LocalImageGenerationService>((ref) {
  return LocalImageGenerationService();
});

final imageGenerationServiceProvider =
    Provider<ImageGenerationService>((ref) {
  return ref.watch(localImageGenerationServiceProvider);
});

final imageModelInstalledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(localImageModelServiceProvider);
  return service.isModelInstalled();
});

final imageModelSizeProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(localImageModelServiceProvider);
  return service.getModelSizeBytes();
});