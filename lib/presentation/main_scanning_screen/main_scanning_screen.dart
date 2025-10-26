import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/limits.dart';
import '../../routes/app_routes.dart';
import '../../services/scan_session.dart';
import '../../services/subscription_service.dart';

class MainScanningScreen extends ConsumerStatefulWidget {
  const MainScanningScreen({super.key});

  @override
  ConsumerState<MainScanningScreen> createState() => _MainScanningScreenState();
}

class _MainScanningScreenState extends ConsumerState<MainScanningScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _addFromGallery() async {
    if (!await _canAddPage()) return;
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      await ref.read(scanSessionProvider.notifier).addPage(bytes);
      Fluttertoast.showToast(msg: 'Imagen añadida desde la galería');
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
      builder: (context) {
        return SafeArea(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanSessionProvider);
    final subscription = ref.watch(subscriptionProvider);
    final limit = subscription.isPro
        ? Limits.proMaxPagesPerPdf
        : Limits.normalMaxPagesPerPdf;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lienzo de escaneo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.library),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceVariant,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Páginas: ${session.pages.length}/$limit',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!subscription.isPro)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.paywall);
                    },
                    child: const Text('Mejorar plan'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: session.pages.isEmpty
                ? const _EmptyState()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: session.pages.length,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(scanSessionProvider.notifier)
                          .reorder(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final page = session.pages[index];
                      return _PageTile(
                        key: ValueKey(page.id),
                        index: index,
                        bytes: page.bytes,
                        onRotate: () => ref
                            .read(scanSessionProvider.notifier)
                            .rotatePage(page.id),
                        onDelete: () => ref
                            .read(scanSessionProvider.notifier)
                            .removePage(page.id),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: session.pages.isEmpty
                  ? () => Fluttertoast.showToast(
                        msg: 'Añade al menos una página para generar el PDF',
                      )
                  : () {
                      Navigator.pushNamed(context, AppRoutes.pdfGeneration);
                    },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generar PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    super.key,
    required this.index,
    required this.bytes,
    required this.onRotate,
    required this.onDelete,
  });

  final int index;
  final Uint8List bytes;
  final VoidCallback onRotate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 60,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        title: Text('Página ${index + 1}'),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.rotate_90_degrees_ccw),
              onPressed: onRotate,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Comienza añadiendo páginas desde la cámara o la galería.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
