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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<StoredPdf>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _LibraryMessage(
                  icon: Icons.history_toggle_off,
                  title: 'Cargando biblioteca',
                  description:
                      'Estamos buscando tus PDF almacenados. Esto puede tardar unos segundos.',
                );
              }
              if (snapshot.hasError) {
                return _LibraryMessage(
                  icon: Icons.error_outline,
                  title: 'Error al cargar la biblioteca',
                  description: '${snapshot.error}',
                  iconColor: Theme.of(context).colorScheme.error,
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return _LibraryMessage(
                  icon: Icons.folder_open_outlined,
                  title: 'No hay documentos guardados',
                  description:
                      'Tus PDF generados aparecerán aquí. Escanea o importa para empezar.',
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _LibraryDocumentTile(
                    document: item,
                    sizeLabel: _formatSize(item.sizeBytes),
                    dateLabel: _formatDate(item.createdAt),
                    onOpen: () {
                      _open(item);
                    },
                    onShare: () {
                      _share(item);
                    },
                    onDelete: () {
                      _delete(item);
                    },
                  );
                },
              );
            },
          ),
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

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }
}

class _LibraryDocumentTile extends StatelessWidget {
  const _LibraryDocumentTile({
    required this.document,
    required this.sizeLabel,
    required this.dateLabel,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
  });

  final StoredPdf document;
  final String sizeLabel;
  final String dateLabel;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.picture_as_pdf_outlined, color: colorScheme.primary),
        ),
        title: Text(
          document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${document.pageCount} páginas · $sizeLabel · $dateLabel',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.outline),
          ),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Acciones del documento',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'share':
                onShare();
                break;
              case 'open':
                onOpen();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'open',
              child: Text('Abrir'),
            ),
            PopupMenuItem(
              value: 'share',
              child: Text('Compartir'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({
    required this.icon,
    required this.title,
    this.description,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: (iconColor ?? colorScheme.primary)
                    .withValues(alpha: 0.12),
                child: Icon(icon, size: 28, color: iconColor ?? colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
