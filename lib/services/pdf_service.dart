import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart' as pdf;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/constants/limits.dart';

class PdfLimitExceededException implements Exception {
  PdfLimitExceededException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef DirectoryProvider = Future<Directory> Function();

class PdfService {
  PdfService({DirectoryProvider? tempDirectoryProvider})
      : _tempDirectoryProvider =
            tempDirectoryProvider ?? getTemporaryDirectory;

  final DirectoryProvider _tempDirectoryProvider;

  Future<File> buildPdf(List<Uint8List> pages,
      {required bool isPro, String? filename}) async {
    if (!isPro && pages.length > Limits.normalMaxPagesPerPdf) {
      throw PdfLimitExceededException(
        'El plan Normal permite hasta ${Limits.normalMaxPagesPerPdf} páginas por documento.',
      );
    }

    final document = pw.Document();

    for (final pageBytes in pages) {
      final image = img.decodeImage(pageBytes);
      if (image == null) {
        continue;
      }
      final baked = img.bakeOrientation(image);
      final encoded = Uint8List.fromList(img.encodeJpg(baked, quality: 90));
      final memoryImage = pw.MemoryImage(encoded);
      document.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Image(memoryImage, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    final tempDir = await _tempDirectoryProvider();
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final name = filename ?? _generateFileName();
    final file = File(p.join(tempDir.path, name));
    final bytes = await document.save();
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _generateFileName() {
    final now = DateTime.now();
    final milliseconds = now.millisecond.toString().padLeft(3, '0');
    return 'Scan_${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}$milliseconds.pdf';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});
