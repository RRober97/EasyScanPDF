import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_scanner/core/constants/limits.dart';
import 'package:pdf_scanner/services/storage_service.dart';

Future<File> _createDummyPdf(Directory dir, String name) async {
  final file = File(p.join(dir.path, name));
  await file.writeAsBytes(List<int>.generate(10, (index) => index));
  return file;
}

void main() {
  group('StorageService', () {
    late Directory tempDir;
    late StorageService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('storage_service_test');
      service = StorageService(documentsDirectoryProvider: () async => tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('rotates documents after ${Limits.normalMaxSavedPdfs} saves for normal plan', () async {
      for (var i = 0; i < Limits.normalMaxSavedPdfs + 1; i++) {
        final source = await _createDummyPdf(tempDir, 'source_$i.pdf');
        await service.savePdf(source,
            isPro: false, pageCount: 1);
      }
      final items = await service.listPdfs();
      expect(items.length, Limits.normalMaxSavedPdfs);
    });

    test('rotates documents after ${Limits.proMaxSavedPdfs} saves for pro plan', () async {
      for (var i = 0; i < Limits.proMaxSavedPdfs + 2; i++) {
        final source = await _createDummyPdf(tempDir, 'pro_source_$i.pdf');
        await service.savePdf(source,
            isPro: true, pageCount: 1);
      }
      final items = await service.listPdfs();
      expect(items.length, Limits.proMaxSavedPdfs);
    });
  });
}
