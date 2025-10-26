import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/limits.dart';
import '../../routes/app_routes.dart';
import '../../services/draft_service.dart';
import '../../services/scan_session.dart';
import '../../services/subscription_service.dart';
import '../editor/document_editor_page.dart';

class MainScanningScreen extends ConsumerStatefulWidget {
  const MainScanningScreen({super.key});

  @override
  ConsumerState<MainScanningScreen> createState() => _MainScanningScreenState();
}

class _MainScanningScreenState extends ConsumerState<MainScanningScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();

  String? _draftId;
  bool _initializedArgs = false;
  bool _isSavingDraft = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _generateDefaultName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _draftId = args['draftId'] as String?;
      final draftName = args['draftName'] as String?;
      if (draftName != null && draftName.isNotEmpty) {
        _nameController.text = draftName;
      }
    }
    _initializedArgs = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addFromGallery() async {
    if (!await _canAddPage()) return;
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final page = await ref.read(scanSessionProvider.notifier).addPage(bytes);
      if (!mounted) return;
      Fluttertoast.showToast(msg: 'Imagen añadida desde la galería');
      await Navigator.of(context).push(
        DocumentEditorPage.route(
          page.id,
          autoOpenCropper: true,
        ),
      );
    }
  }

  Future<void> _openCamera() async {
    if (!await _canAddPage()) return;
    await Navigator.pushNamed(context, AppRoutes.cameraScanningInterface);
    setState(() {});
  }

  Future<bool> _canAddPage() async {
    final subscription = ref.read(subscriptionProvider);
    final session = ref.read(scanSessionProvider);
    final limit = subscription.isPro
        ? Limits.proMaxPagesPerPdf
        : Limits.normalMaxPagesPerPdf;
    if (session.pages.length >= limit) {
      Fluttertoast.showToast(msg: 'Has alcanzado el límite de páginas.');
      final upgraded = await Navigator.pushNamed<bool>(
        context,
        AppRoutes.paywall,
      );
      return upgraded == true || ref.read(subscriptionProvider).isPro;
    }
    return true;
  }

  Future<void> _showAddOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Usar cámara'),
                  onTap: () {
                    Navigator.pop(context);
                    _openCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Seleccionar de la galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _addFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveDraft() async {
    final session = ref.read(scanSessionProvider);
    if (session.pages.isEmpty) {
      Fluttertoast.showToast(msg: 'Añade páginas antes de guardar un borrador.');
      return;
    }
    setState(() {
      _isSavingDraft = true;
    });
    final id = _draftId ?? DateTime.now().microsecondsSinceEpoch.toString();
    final name = _nameController.text.trim().isEmpty
        ? _generateDefaultName()
        : _nameController.text.trim();
    await ref
        .read(draftStorageServiceProvider)
        .saveDraft(id: id, name: name, pages: session.pages);
    _draftId = id;
    setState(() {
      _isSavingDraft = false;
    });
    Fluttertoast.showToast(msg: 'Borrador guardado');
  }

  void _navigateToEditor(String pageId) {
    Navigator.of(context).push(
      DocumentEditorPage.route(pageId, autoOpenCropper: false),
    );
  }

  String _generateDefaultName() {
    final now = DateTime.now();
    return 'Documento ${now.day}/${now.month} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanSessionProvider);
    final subscription = ref.watch(subscriptionProvider);
    final limit = subscription.isPro
        ? Limits.proMaxPagesPerPdf
        : Limits.normalMaxPagesPerPdf;

    final remaining = limit - session.pages.length;
    final progress = limit == 0 ? 0.0 : session.pages.length / limit;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            FloatingActionButton.extended(
              heroTag: 'export-fab',
              onPressed: session.pages.isEmpty
                  ? () => Fluttertoast.showToast(
                        msg: 'Añade al menos una página para generar el PDF',
                      )
                  : () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.pdfGeneration,
                        arguments: {
                          'name': _nameController.text.trim(),
                          'draftId': _draftId,
                        },
                      );
                    },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Revisar y exportar PDF'),
            ),
            const Spacer(),
            FloatingActionButton.extended(
              heroTag: 'add-page-fab',
              onPressed: _showAddOptions,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Añadir página'),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Volver al inicio',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      Text(
                        'Lienzo de captura',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Nombre del documento',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        tooltip: 'Restablecer nombre sugerido',
                        onPressed: () {
                          _nameController.text = _generateDefaultName();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.layers_outlined,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Páginas ${session.pages.length}/$limit',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              if (!subscription.isPro)
                                FilledButton.tonal(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, AppRoutes.paywall),
                                  child: const Text('Plan Pro'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            remaining > 0
                                ? 'Puedes añadir $remaining páginas más con tu plan actual.'
                                : 'Límite alcanzado. Elimina o mejora tu plan para continuar.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).colorScheme.outline),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isSavingDraft ? null : _saveDraft,
                                icon: _isSavingDraft
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.bookmark_add_outlined),
                                label: Text(_isSavingDraft ? 'Guardando...' : 'Guardar borrador'),
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                onPressed: () =>
                                    Navigator.pushNamed(context, AppRoutes.library),
                                icon: const Icon(Icons.folder_outlined),
                                label: const Text('Biblioteca'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: session.pages.isEmpty
                    ? const _EmptyState()
                    : ReorderableListView.builder(
                        key: const ValueKey('page-list'),
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                        itemCount: session.pages.length,
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) {
                          ref
                              .read(scanSessionProvider.notifier)
                              .reorder(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final page = session.pages[index];
                          return _PageTile(
                            key: ValueKey(page.id),
                            pageId: page.id,
                            index: index,
                            bytes: page.bytes,
                            onOpenEditor: () => _navigateToEditor(page.id),
                            onRemove: () => ref
                                .read(scanSessionProvider.notifier)
                                .removePage(page.id),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    super.key,
    required this.pageId,
    required this.index,
    required this.bytes,
    required this.onOpenEditor,
    required this.onRemove,
  });

  final String pageId;
  final int index;
  final Uint8List bytes;
  final VoidCallback onOpenEditor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpenEditor,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'page-$pageId',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      bytes,
                      width: 78,
                      height: 104,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Página ${index + 1}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pulsa para editar recorte, filtros y rotación',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    IconButton(
                      tooltip: 'Eliminar página',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onRemove,
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle, color: colorScheme.outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.document_scanner_outlined,
                size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Comienza capturando tu documento',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Añade páginas desde la cámara o la galería para aplicar filtros y generar tu PDF.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
