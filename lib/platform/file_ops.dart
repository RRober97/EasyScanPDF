import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<File> saveBytesToAppDocs(String filename, List<int> bytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  return file.writeAsBytes(data, flush: true);
}

Future<void> shareFilePath(String path, {String? text}) async {
  await Share.shareXFiles([XFile(path)], text: text);
}

Future<void> openExternalUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'No se pudo abrir $url';
  }
}
