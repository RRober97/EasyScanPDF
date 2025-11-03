import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routes/app_routes.dart';
import '../../services/draft_service.dart';
import '../../services/scan_session.dart';
import '../../services/storage_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<List<StoredPdf>> _documentsFuture;
  late Future<List<DraftSession>> _draftsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _documentsFuture = _loadDocuments();
    _draftsFuture = _loadDrafts();
  }

  Future<List<StoredPdf>> _loadDocuments() {
    return ref.read(storageServiceProvider).listPdfs();
  }

  Future<List<DraftSession>> _loadDrafts() {
    return ref.read(draftStorageServiceProvider).listDrafts();
  }

  Future<void> _refresh() async {
    setState(() {
      _documentsFuture = _loadDocuments();
      _draftsFuture = _loadDrafts();
    });
    await Future.wait([_documentsFuture, _draftsFuture]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          edgeOffset: 100,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                backgroundColor: colorScheme.surface,
                titleSpacing: 0,
                surfaceTintColor: Colors.transparent,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 24,
                    bottom: 16,
                  ),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tus documentos',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu cámara, tu escáner, tu PDF.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Configuración',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                  icon: const Icon(Icons.settings_outlined),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Buscar por nombre o fecha',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _query = value.toLowerCase();
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildDraftsSection(),
                        const SizedBox(height: 24),
                        _buildDocumentsSection(),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.12),
            colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuevo documento',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Captura desde la cámara o importa varias imágenes para generar un PDF.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(context, AppRoutes.mainScanning);
                      if (!mounted) return;
                      _refresh();
                    },
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Nuevo escaneo'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(context, AppRoutes.library);
                      if (!mounted) return;
                      _refresh();
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Ver todo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftsSection() {
    return FutureBuilder<List<DraftSession>>(
      future: _draftsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoading(title: 'Borradores recientes');
        }
        final drafts = snapshot.data ?? [];
        if (drafts.isEmpty) {
          return const SizedBox.shrink();
        }
        return _SectionSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: 'Borradores',
                subtitle: 'Continúa donde lo dejaste',
              ),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: drafts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final draft = drafts[index];
                    return _DraftCard(
                      draft: draft,
                      onOpen: () => _openDraft(draft),
                      onDelete: () async {
                        await ref
                            .read(draftStorageServiceProvider)
                            .deleteDraft(draft.id);
                        _refresh();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentsSection() {
    return FutureBuilder<List<StoredPdf>>(
      future: _documentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoading(title: 'Documentos recientes');
        }
        if (snapshot.hasError) {
          return _ErrorTile(
            message: 'No se pudieron cargar los documentos',
            onRetry: _refresh,
          );
        }
        final items = (snapshot.data ?? [])
            .where((doc) => doc.name.toLowerCase().contains(_query))
            .toList();
        if (items.isEmpty) {
          return _EmptyTile(
            title: 'No hay documentos guardados',
            description:
                _query.isEmpty ? 'Genera tu primer PDF para verlo aquí.' : 'No encontramos documentos que coincidan con tu búsqueda.',
          );
        }
        return _SectionSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: 'Recientes',
                subtitle: 'Tus últimos PDF listos para compartir',
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _DocumentTile(document: item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDraft(DraftSession draft) async {
    final controller = ref.read(scanSessionProvider.notifier);
    controller.loadPages(
      draft.pages
          .map(
            (page) => ScanPage(
              id: page.id,
              bytes: page.bytes,
              createdAt: draft.updatedAt,
            ),
          )
          .toList(),
    );
    if (!mounted) return;
    await Navigator.pushNamed(context, AppRoutes.mainScanning, arguments: {'draftId': draft.id, 'draftName': draft.name});
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colorScheme.outline),
        ),
        const SizedBox(height: 14),
        Divider(color: colorScheme.outlineVariant, height: 1),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.onOpen,
    required this.onDelete,
  });

  final DraftSession draft;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: Material(
        elevation: 3,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers_outlined, color: colorScheme.primary),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: colorScheme.error,
                      tooltip: 'Eliminar borrador',
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  draft.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${draft.pages.length} páginas · ${_formatDate(draft.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.document});

  final StoredPdf document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${document.pageCount} páginas · ${_formatSize(document.sizeBytes)}',
        ),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.picture_as_pdf_outlined, color: colorScheme.primary),
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.shareDocument,
            arguments: document,
          );
        },
      ),
    );
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

class _SectionLoading extends StatelessWidget {
  const _SectionLoading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, subtitle: 'Cargando...'),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _SectionSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_outlined,
              size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message, required this.onRetry});

  final String message;
  final FutureOr<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh),
            label: const Text('Intentar de nuevo'),
          ),
        ],
      ),
    );
  }
}

class _SectionSurface extends StatelessWidget {
  const _SectionSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
