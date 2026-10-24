import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageCropperService {
  const ImageCropperService();

  Future<Uint8List> encodeResult(
    Uint8List croppedBytes,
  ) async {
    final image = img.decodeImage(croppedBytes);

    if (image == null) {
      throw Exception(
        'Unable to process the cropped image.',
      );
    }

    final encoded = img.encodeJpg(
      image,
      quality: 95,
    );

    return Uint8List.fromList(encoded);
  }
}