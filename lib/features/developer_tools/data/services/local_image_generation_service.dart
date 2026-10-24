import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as img;

import '../../domain/services/image_generation_service.dart';

typedef _InitContextNative = Bool Function(
  Pointer<Utf8> modelPath,
);

typedef _InitContextDart = bool Function(
  Pointer<Utf8> modelPath,
);

typedef _FreeContextNative = Void Function();
typedef _FreeContextDart = void Function();

typedef _IsReadyNative = Bool Function();
typedef _IsReadyDart = bool Function();

typedef _GenerateImageNative = Bool Function(
  Pointer<Utf8>,
  Pointer<Utf8>,
  Int32,
  Int32,
  Int32,
  Int64,
  Pointer<Int32>,
  Pointer<Int32>,
  Pointer<Int32>,
  Pointer<Pointer<Uint8>>,
);

typedef _GenerateImageDart = bool Function(
  Pointer<Utf8>,
  Pointer<Utf8>,
  int,
  int,
  int,
  int,
  Pointer<Int32>,
  Pointer<Int32>,
  Pointer<Int32>,
  Pointer<Pointer<Uint8>>,
);

typedef _FreeImageNative = Void Function(
  Pointer<Uint8>,
);

typedef _FreeImageDart = void Function(
  Pointer<Uint8>,
);

class LocalImageGenerationService
    implements ImageGenerationService {
  LocalImageGenerationService();

  _NativeWorker? _worker;
  Future<void>? _startingWorker;
  bool _initialized = false;

  @override
  Future<bool> isAvailable() async {
    return _initialized;
  }

  Future<void> initialize({
    required String modelPath,
  }) async {
    if (_initialized) {
      return;
    }

    _startingWorker ??= _startWorker(modelPath);

    try {
      await _startingWorker;
      _initialized = true;
    } catch (_) {
      _startingWorker = null;
      _worker = null;
      rethrow;
    }
  }

  Future<void> _startWorker(String modelPath) async {
    final receivePort = ReceivePort();

    final isolate = await Isolate.spawn(
      _nativeWorkerEntryPoint,
      receivePort.sendPort,
    );

    final sendPort = await receivePort.first as SendPort;

    final worker = _NativeWorker(
      isolate: isolate,
      sendPort: sendPort,
      receivePort: receivePort,
    );

    _worker = worker;

    final result = await worker.initialize(modelPath);

    if (!result) {
      worker.dispose();

      _worker = null;

      throw Exception(
        'Failed to initialize the local image-generation model.',
      );
    }
  }

  @override
  Future<File> generate({
    required String prompt,
    String negativePrompt = '',
    int width = 512,
    int height = 512,
    int steps = 20,
    int seed = -1,
  }) async {
    if (!_initialized || _worker == null) {
      throw StateError(
        'Local image-generation model is not initialized.',
      );
    }

    final result = await _worker!.generate(
      prompt: prompt,
      negativePrompt: negativePrompt,
      width: width,
      height: height,
      steps: steps,
      seed: seed,
    );

    final directory = Directory(
      '${Directory.systemTemp.path}/devvault_images',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    final file = File(
      '${directory.path}/generated_'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(
      result,
      flush: true,
    );

    return file;
  }

  void dispose() {
  _worker?.dispose();
  _worker = null;
  _initialized = false;
  _startingWorker = null;
}
}

class _NativeWorker {
  _NativeWorker({
    required this.isolate,
    required this.sendPort,
    required this.receivePort,
  });

  final Isolate isolate;
  final SendPort sendPort;
  final ReceivePort receivePort;

  int _requestId = 0;

  Future<dynamic> _send(
    String command,
    Map<String, dynamic> data,
  ) async {
    final id = ++_requestId;

    final responsePort = ReceivePort();

    sendPort.send({
      'id': id,
      'command': command,
      'data': data,
      'replyPort': responsePort.sendPort,
    });

    try {
      final response = await responsePort.first;

      final map = Map<String, dynamic>.from(
        response as Map,
      );

      if (map['success'] != true) {
        throw Exception(
          map['error'] ??
              'Native worker operation failed.',
        );
      }

      return map['result'];
    } finally {
      responsePort.close();
    }
  }

  Future<bool> initialize(
    String modelPath,
  ) async {
    final result = await _send(
      'initialize',
      {
        'modelPath': modelPath,
      },
    );

    return result == true;
  }

  Future<Uint8List> generate({
    required String prompt,
    required String negativePrompt,
    required int width,
    required int height,
    required int steps,
    required int seed,
  }) async {
    final result = await _send(
      'generate',
      {
        'prompt': prompt,
        'negativePrompt': negativePrompt,
        'width': width,
        'height': height,
        'steps': steps,
        'seed': seed,
      },
    );

    return result as Uint8List;
  }

  void dispose() {
    sendPort.send({
      'id': ++_requestId,
      'command': 'dispose',
      'data': <String, dynamic>{},
    });

    receivePort.close();
    isolate.kill(
      priority: Isolate.immediate,
    );
  }
}

void _nativeWorkerEntryPoint(
  SendPort mainSendPort,
) {
  final commandPort = ReceivePort();

  mainSendPort.send(
    commandPort.sendPort,
  );

  DynamicLibrary? library;

  _InitContextDart? initContext;
  _FreeContextDart? freeContext;
  _IsReadyDart? isReady;
  _GenerateImageDart? generateImage;
  _FreeImageDart? freeImage;

  bool initialized = false;

  commandPort.listen(
    (message) {
      final map = Map<String, dynamic>.from(
        message as Map,
      );

      final command = map['command'] as String;
      final replyPort =
          map['replyPort'] as SendPort?;
      final data =
          Map<String, dynamic>.from(
        map['data'] as Map,
      );

      try {
        switch (command) {
          case 'initialize':
            library ??=
                DynamicLibrary.open(
              'libdevvault_sd.so',
            );

            initContext ??= library!
                .lookupFunction<
                    _InitContextNative,
                    _InitContextDart>(
              'devvault_init_context',
            );

            freeContext ??= library!
                .lookupFunction<
                    _FreeContextNative,
                    _FreeContextDart>(
              'devvault_free_context',
            );

            isReady ??= library!
                .lookupFunction<
                    _IsReadyNative,
                    _IsReadyDart>(
              'devvault_is_ready',
            );

            final modelPath =
                data['modelPath'] as String;

            final modelPointer =
                modelPath.toNativeUtf8();

            try {
              freeContext!();

              initialized =
                  initContext!(modelPointer) &&
                  isReady!();
            } finally {
              malloc.free(modelPointer);
            }

            replyPort?.send({
              'success': true,
              'result': initialized,
            });

            break;

          case 'generate':
            if (!initialized) {
              throw StateError(
                'Native model is not initialized.',
              );
            }

            generateImage ??= library!
                .lookupFunction<
                    _GenerateImageNative,
                    _GenerateImageDart>(
              'devvault_generate_image',
            );

            freeImage ??= library!
                .lookupFunction<
                    _FreeImageNative,
                    _FreeImageDart>(
              'devvault_free_image',
            );

            final prompt =
                data['prompt'] as String;

            final negativePrompt =
                data['negativePrompt'] as String;

            final width =
                data['width'] as int;

            final height =
                data['height'] as int;

            final steps =
                data['steps'] as int;

            final seed =
                data['seed'] as int;

            final promptPointer =
                prompt.toNativeUtf8();

            final negativePromptPointer =
                negativePrompt.toNativeUtf8();

            final outWidth = malloc<Int32>();
            final outHeight = malloc<Int32>();
            final outChannels = malloc<Int32>();
            final outData =
                malloc<Pointer<Uint8>>();

            outWidth.value = 0;
            outHeight.value = 0;
            outChannels.value = 0;
            outData.value = nullptr;

            try {
              final success = generateImage!(
                promptPointer,
                negativePromptPointer,
                width,
                height,
                steps,
                seed,
                outWidth,
                outHeight,
                outChannels,
                outData,
              );

              if (!success) {
                throw Exception(
                  'Local image generation failed.',
                );
              }

              final nativeData =
                  outData.value;

              if (nativeData == nullptr) {
                throw Exception(
                  'Generation returned no image data.',
                );
              }

              final generatedWidth =
                  outWidth.value;

              final generatedHeight =
                  outHeight.value;

              final channels =
                  outChannels.value;

              if (generatedWidth <= 0 ||
                  generatedHeight <= 0 ||
                  (channels != 3 &&
                      channels != 4)) {
                freeImage!(nativeData);

                throw Exception(
                  'Native runtime returned '
                  'invalid image data.',
                );
              }

              final byteCount =
                  generatedWidth *
                  generatedHeight *
                  channels;

              final rawBytes =
                  Uint8List.fromList(
                nativeData.asTypedList(
                  byteCount,
                ),
              );

              freeImage!(nativeData);

              final image = img.Image(
                width: generatedWidth,
                height: generatedHeight,
                numChannels: channels,
              );

              var offset = 0;

              for (
                var y = 0;
                y < generatedHeight;
                y++
              ) {
                for (
                  var x = 0;
                  x < generatedWidth;
                  x++
                ) {
                  final r =
                      rawBytes[offset++];

                  final g =
                      rawBytes[offset++];

                  final b =
                      rawBytes[offset++];

                  final a = channels == 4
                      ? rawBytes[offset++]
                      : 255;

                  image.setPixelRgba(
                    x,
                    y,
                    r,
                    g,
                    b,
                    a,
                  );
                }
              }

              final pngBytes =
                  Uint8List.fromList(
                img.encodePng(image),
              );

              replyPort?.send({
                'success': true,
                'result': pngBytes,
              });
            } finally {
              malloc.free(promptPointer);
              malloc.free(
                negativePromptPointer,
              );
              malloc.free(outWidth);
              malloc.free(outHeight);
              malloc.free(outChannels);
              malloc.free(outData);
            }

            break;

          case 'dispose':
            if (initialized &&
                freeContext != null) {
              freeContext!();
            }

            initialized = false;
            commandPort.close();
            break;
        }
      } catch (error) {
        replyPort?.send({
          'success': false,
          'error': error.toString(),
        });
      }
    },
  );
}