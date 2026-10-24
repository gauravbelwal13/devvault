import 'dart:io';
import 'dart:typed_data';

import '../../data/services/media_pdf_service.dart';

class CreateMediaPdf {
  const CreateMediaPdf(this._service);

  final MediaPdfService _service;

  Future<Uint8List> call({
    required List<File> images,
    required String pageSize,
  }) {
    return _service.createPdf(
      images: images,
      pageSize: pageSize,
    );
  }
}