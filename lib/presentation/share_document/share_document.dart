import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../routes/app_routes.dart';
import '../../services/share_service.dart';
import '../../services/storage_service.dart';

class ShareDocument extends ConsumerStatefulWidget {
  const ShareDocument({super.key});

  @override
  ConsumerState<ShareDocument> createState() => _ShareDocumentState();
}

class _ShareDocumentState extends ConsumerState<ShareDocument> {
  StoredPdf? _document;
  bool _isSharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is StoredPdf) {
      _document = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _document;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartir documento'),
      ),
      body: doc == null
          ? const Center(child: Text('No se encontró el documento.'))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '${doc.pageCount} páginas · ${_formatSize(doc.sizeBytes)} · ${doc.createdAt.toLocal()}',
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _isSharing ? null : () => _share(doc),
                    icon: _isSharing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share),
                    label: Text(_isSharing ? 'Compartiendo...' : 'Compartir'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.library);
                    },
                    child: const Text('Ver en Library'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.popUntil(
                        context,
                        (route) =>
                            route.settings.name == AppRoutes.mainScanning ||
                            route.isFirst,
                      );
                    },
                    child: const Text('Volver al inicio'),
                  ),
                  const Spacer(),
                  Text(
                    'El documento está guardado en tu biblioteca. Puedes compartirlo en cualquier momento desde allí.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _share(StoredPdf doc) async {
    setState(() {
      _isSharing = true;
    });
    try {
      await ref.read(shareServiceProvider).share(File(doc.path));
      Fluttertoast.showToast(msg: 'Documento compartido');
    } catch (e) {
      Fluttertoast.showToast(msg: 'No se pudo compartir el documento');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
