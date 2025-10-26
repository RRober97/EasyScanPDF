import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_scanner/services/pdf_service.dart';

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
  });
}
