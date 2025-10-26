import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/limits.dart';

typedef DocumentsDirectoryProvider = Future<Directory> Function();

class StoredPdf {
  StoredPdf({
    required this.id,
    required this.name,
    required this.path,
    required this.pageCount,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String path;
  final int pageCount;
  final int sizeBytes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'pageCount': pageCount,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StoredPdf.fromJson(Map<String, dynamic> json) {
    return StoredPdf(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      pageCount: json['pageCount'] as int,
      sizeBytes: json['sizeBytes'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class StorageService {
  StorageService({DocumentsDirectoryProvider? documentsDirectoryProvider})
      : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final DocumentsDirectoryProvider _documentsDirectoryProvider;

  Future<Directory> _ensurePdfDirectory() async {
    final baseDir = await _documentsDirectoryProvider();
    final pdfDir = Directory(p.join(baseDir.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }

  Future<File> _indexFile() async {
    final pdfDir = await _ensurePdfDirectory();
    return File(p.join(pdfDir.path, 'index.json'));
  }

  Future<List<StoredPdf>> listPdfs() async {
    final indexFile = await _indexFile();
    if (!await indexFile.exists()) {
      return [];
    }
    final content = await indexFile.readAsString();
    if (content.isEmpty) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(content) as List<dynamic>;
    final items = jsonList
        .map((entry) => StoredPdf.fromJson(entry as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<StoredPdf> savePdf(File file,
      {required bool isPro, required int pageCount}) async {
    final pdfDir = await _ensurePdfDirectory();
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final milliseconds = now.millisecond.toString().padLeft(3, '0');
    final name =
        'Scan_${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}$milliseconds.pdf';
    final destination = File(p.join(pdfDir.path, name));
    await file.copy(destination.path);

    final sizeBytes = await destination.length();
    final stored = StoredPdf(
      id: id,
      name: name,
      path: destination.path,
      pageCount: pageCount,
      sizeBytes: sizeBytes,
      createdAt: now,
    );

    final items = await listPdfs();
    items.add(stored);
    await _applyRotationPolicy(items, isPro);
    await _writeIndex(items);
    return stored;
  }

  Future<void> deletePdf(String id) async {
    final items = await listPdfs();
    final remaining = <StoredPdf>[];
    for (final item in items) {
      if (item.id == id) {
        final file = File(item.path);
        if (await file.exists()) {
          await file.delete();
        }
      } else {
        remaining.add(item);
      }
    }
    await _writeIndex(remaining);
  }

  Future<void> _writeIndex(List<StoredPdf> items) async {
    final indexFile = await _indexFile();
    final jsonList = items.map((item) => item.toJson()).toList();
    await indexFile.writeAsString(json.encode(jsonList), flush: true);
  }

  Future<void> _applyRotationPolicy(
      List<StoredPdf> items, bool isPro) async {
    final limit =
        isPro ? Limits.proMaxSavedPdfs : Limits.normalMaxSavedPdfs;
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (items.length <= limit) {
      return;
    }
    final overflow = items.sublist(limit);
    for (final item in overflow) {
      final file = File(item.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    items.removeRange(limit, items.length);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
