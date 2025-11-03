import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:easyscanpdf/services/pdf_service.dart';

Uint8List _samplePage() {
  final image = img.Image(width: 100, height: 100);
  return Uint8List.fromList(img.encodeJpg(image));
}

void main() {
  group('PdfService', () {
    late Directory tempDir;
    late PdfService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pdf_service_test');
      service = PdfService(tempDirectoryProvider: () async => tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('throws limit error for normal plan when exceeding 10 pages', () async {
      final pages = List.generate(11, (_) => _samplePage());
      expect(
        () => service.buildPdf(pages, isPro: false),
        throwsA(isA<PdfLimitExceededException>()),
      );
    });

    test('allows large documents for pro plan', () async {
      final pages = List.generate(20, (_) => _samplePage());
      final file = await service.buildPdf(pages, isPro: true);
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(0));
    });

    test('sanitizes provided filename to avoid invalid path characters', () async {
      final pages = [_samplePage()];
      final file = await service.buildPdf(
        pages,
        isPro: true,
        filename: 'Documento 26/10 17:57.pdf',
      );

      expect(p.basename(file.path), 'Documento_26_10_17_57.pdf');
      expect(await file.exists(), isTrue);
    });
  });
}
