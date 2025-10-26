import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'scan_session.dart';

typedef DraftsDirectoryProvider = Future<Directory> Function();

class DraftPage {
  DraftPage({
    required this.id,
    required this.bytes,
  });

  final String id;
  final Uint8List bytes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bytes': base64Encode(bytes),
    };
  }

  factory DraftPage.fromJson(Map<String, dynamic> json) {
    return DraftPage(
      id: json['id'] as String,
      bytes: base64Decode(json['bytes'] as String),
    );
  }
}

class DraftSession {
  DraftSession({
    required this.id,
    required this.name,
    required this.pages,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<DraftPage> pages;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'updatedAt': updatedAt.toIso8601String(),
      'pages': pages.map((page) => page.toJson()).toList(),
    };
  }

  factory DraftSession.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'] as List<dynamic>? ?? [];
    return DraftSession(
      id: json['id'] as String,
      name: json['name'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pages: rawPages
          .map((dynamic entry) =>
              DraftPage.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DraftStorageService {
  DraftStorageService({DraftsDirectoryProvider? draftsDirectoryProvider})
      : _draftsDirectoryProvider =
            draftsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final DraftsDirectoryProvider _draftsDirectoryProvider;

  Future<Directory> _ensureDraftDirectory() async {
    final baseDir = await _draftsDirectoryProvider();
    final draftDir = Directory(p.join(baseDir.path, 'drafts'));
    if (!await draftDir.exists()) {
      await draftDir.create(recursive: true);
    }
    return draftDir;
  }

  Future<File> _draftFile(String id) async {
    final dir = await _ensureDraftDirectory();
    return File(p.join(dir.path, '$id.json'));
  }

  Future<List<DraftSession>> listDrafts() async {
    final dir = await _ensureDraftDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
    final drafts = <DraftSession>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        if (content.isEmpty) continue;
        final jsonMap = json.decode(content) as Map<String, dynamic>;
        drafts.add(DraftSession.fromJson(jsonMap));
      } catch (_) {
        continue;
      }
    }
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return drafts;
  }

  Future<void> deleteDraft(String id) async {
    final file = await _draftFile(id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> saveDraft({
    required String id,
    required String name,
    required List<ScanPage> pages,
  }) async {
    final file = await _draftFile(id);
    final draft = DraftSession(
      id: id,
      name: name,
      updatedAt: DateTime.now(),
      pages: pages
          .map((page) => DraftPage(id: page.id, bytes: page.bytes))
          .toList(),
    );
    await file.writeAsString(json.encode(draft.toJson()), flush: true);
  }

  Future<DraftSession?> loadDraft(String id) async {
    final file = await _draftFile(id);
    if (!await file.exists()) {
      return null;
    }
    final content = await file.readAsString();
    if (content.isEmpty) {
      return null;
    }
    final jsonMap = json.decode(content) as Map<String, dynamic>;
    return DraftSession.fromJson(jsonMap);
  }
}

final draftStorageServiceProvider = Provider<DraftStorageService>((ref) {
  return DraftStorageService();
});
