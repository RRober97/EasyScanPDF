import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<void> share(File file) async {
    if (!await file.exists()) {
      throw Exception('El archivo no existe.');
    }
    await Share.shareXFiles([XFile(file.path)]);
  }
}

final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService();
});
