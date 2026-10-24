import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageConverterService {
  const ImageConverterService();

  Future<Uint8List> convert({
    required File file,
    required String outputFormat,
  }) async {
    final input = await file.readAsBytes();

    final image = img.decodeImage(input);

    if (image == null) {
      throw Exception('Unable to decode the selected image.');
    }

    switch (outputFormat.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return Uint8List.fromList(
          img.encodeJpg(
            image,
            quality: 95,
          ),
        );

      case 'png':
        return Uint8List.fromList(
          img.encodePng(image),
        );

      case 'webp':
        return Uint8List.fromList(
          img.encodeWebP(image),
        );

      default:
        throw Exception(
          'Unsupported output format: $outputFormat',
        );
    }
  }
}