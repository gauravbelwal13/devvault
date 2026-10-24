import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class MediaPdfService {
  const MediaPdfService();

  Future<Uint8List> createPdf({
    required List<File> images,
    required String pageSize,
  }) async {
    if (images.isEmpty) {
      throw Exception('Select at least one image.');
    }

    final pdf = pw.Document();

    final format = switch (pageSize) {
      'A4' => PdfPageFormat.a4,
      'Letter' => PdfPageFormat.letter,
      _ => PdfPageFormat.a4,
    };

    for (final file in images) {
      if (!await file.exists()) {
        throw Exception(
          'Image no longer exists: ${file.path}',
        );
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception(
          'Unable to read image: ${file.path}',
        );
      }

      final image = pw.MemoryImage(bytes);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}