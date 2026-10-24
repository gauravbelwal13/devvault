import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageResizeService {
  const ImageResizeService();

  Future<Uint8List> resize({
    required File file,
    required int width,
    required int height,
  }) async {
    final input = await file.readAsBytes();

    final image = img.decodeImage(input);

    if (image == null) {
      throw Exception('Unable to decode the selected image.');
    }

    final resized = img.copyResize(
      image,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );

    final encoded = img.encodeJpg(
      resized,
      quality: 95,
    );

    return Uint8List.fromList(encoded);
  }
}