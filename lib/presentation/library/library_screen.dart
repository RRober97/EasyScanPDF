import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_filex/open_filex.dart';

import '../../services/share_service.dart';
import '../../services/storage_service.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late Future<List<StoredPdf>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<StoredPdf>> _load() {
    return ref.read(storageServiceProvider).listPdfs();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<StoredPdf>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error al cargar la biblioteca: ${snapshot.error}'),
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(
                child: Text('No hay documentos guardados todavía.'),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                      '${item.pageCount} páginas · ${_formatSize(item.sizeBytes)} · ${item.createdAt.toLocal()}'),
                  onTap: () => _open(item),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'share':
                          await _share(item);
                          break;
                        case 'open':
                          await _open(item);
                          break;
                        case 'delete':
                          await _delete(item);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Text('Abrir'),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Text('Compartir'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _open(StoredPdf item) async {
    final result = await OpenFilex.open(item.path);
    if (result.type != ResultType.done) {
      Fluttertoast.showToast(msg: 'No se pudo abrir el documento');
    }
  }

  Future<void> _share(StoredPdf item) async {
    final file = File(item.path);
    await ref.read(shareServiceProvider).share(file);
    Fluttertoast.showToast(msg: 'Documento compartido');
  }

  Future<void> _delete(StoredPdf item) async {
    await ref.read(storageServiceProvider).deletePdf(item.id);
    Fluttertoast.showToast(msg: 'Documento eliminado');
    await _refresh();
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
