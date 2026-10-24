import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageCompressionService {
  const ImageCompressionService();

  Future<Uint8List> compress({
    required File file,
    required int quality,
  }) async {
    final input = await file.readAsBytes();

    final image = img.decodeImage(input);

    if (image == null) {
      throw Exception('Unable to decode the selected image.');
    }

    final encoded = img.encodeJpg(
      image,
      quality: quality,
    );

    return Uint8List.fromList(encoded);
  }
}