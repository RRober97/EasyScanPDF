import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../routes/app_routes.dart';
import '../../services/draft_service.dart';
import '../../services/pdf_service.dart';
import '../../services/scan_session.dart';
import '../../services/storage_service.dart';
import '../../services/subscription_service.dart';

class PdfGeneration extends ConsumerStatefulWidget {
  const PdfGeneration({super.key});

  @override
  ConsumerState<PdfGeneration> createState() => _PdfGenerationState();
}

class _PdfGenerationState extends ConsumerState<PdfGeneration> {
  late TextEditingController _nameController;
  bool _isGenerating = false;
  bool _highQuality = true;
  String? _draftId;
  bool _initializedArgs = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final initialName = args['name'] as String?;
      _draftId = args['draftId'] as String?;
      if (initialName != null && initialName.isNotEmpty) {
        _nameController.text = initialName;
      }
    }
    if (_nameController.text.isEmpty) {
      _nameController.text = _suggestedName();
    }
    _initializedArgs = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _suggestedName() {
    final now = DateTime.now();
    return 'PDF_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _generatePdf() async {
    final scanSession = ref.read(scanSessionProvider);
    if (scanSession.pages.isEmpty) {
      Fluttertoast.showToast(msg: 'No hay páginas para exportar');
      return;
    }
    setState(() {
      _isGenerating = true;
    });
    final pdfService = ref.read(pdfServiceProvider);
    final storageService = ref.read(storageServiceProvider);
    final subscription = ref.read(subscriptionProvider);
    final draftService = ref.read(draftStorageServiceProvider);
    final pagesBytes = ref.read(scanSessionProvider.notifier).pagesBytes;
    final name = _nameController.text.trim();

    try {
      final tempFile = await pdfService.buildPdf(
        pagesBytes,
        isPro: subscription.isPro,
        filename: name.isEmpty ? null : '$name.pdf',
        jpegQuality: _highQuality ? 95 : 85,
      );
      final stored = await storageService.savePdf(
        tempFile,
        isPro: subscription.isPro,
        pageCount: scanSession.pages.length,
        desiredName: name,
      );
      ref.read(scanSessionProvider.notifier).clear();
      if (_draftId != null) {
        await draftService.deleteDraft(_draftId!);
      }
      Fluttertoast.showToast(msg: 'PDF generado correctamente');
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.shareDocument,
        arguments: stored,
      );
    } on PdfLimitExceededException catch (e) {
      setState(() {
        _isGenerating = false;
      });
      Fluttertoast.showToast(msg: e.message);
      if (!mounted) return;
      final upgraded = await Navigator.pushNamed<bool>(
        context,
        AppRoutes.paywall,
      );
      if (upgraded == true || ref.read(subscriptionProvider).isPro) {
        _generatePdf();
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar el PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanSessionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisión antes de exportar'),
        actions: [
          IconButton(
            tooltip: 'Editar páginas',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                _InfoCard(
                  nameController: _nameController,
                  pageCount: session.pages.length,
                  isHighQuality: _highQuality,
                  onToggleQuality: (value) {
                    setState(() {
                      _highQuality = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                if (session.pages.isNotEmpty)
                  _PreviewCarousel(pages: session.pages),
                if (session.pages.isEmpty)
                  _EmptyPreview(colorScheme: colorScheme),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isGenerating)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Procesando documento...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isGenerating ? null : _generatePdf,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text(_isGenerating ? 'Generando...' : 'Exportar y compartir'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.nameController,
    required this.pageCount,
    required this.isHighQuality,
    required this.onToggleQuality,
  });

  final TextEditingController nameController;
  final int pageCount;
  final bool isHighQuality;
  final ValueChanged<bool> onToggleQuality;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles del PDF',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del documento',
                hintText: 'Por ejemplo: Contrato Junio',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.layers_outlined, size: 18),
                  label: Text('$pageCount páginas'),
                ),
                const SizedBox(width: 12),
                Chip(
                  avatar: Icon(
                    isHighQuality ? Icons.hd_outlined : Icons.speed_outlined,
                    size: 18,
                  ),
                  label: Text(isHighQuality ? 'Alta calidad' : 'Optimizado'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              title: const Text('Priorizar calidad de imagen'),
              subtitle: const Text('Desactiva para exportar archivos más ligeros.'),
              value: isHighQuality,
              onChanged: onToggleQuality,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCarousel extends StatelessWidget {
  const _PreviewCarousel({required this.pages});

  final List<ScanPage> pages;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vista previa rápida',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final page = pages[index];
              return AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(page.bytes, fit: BoxFit.cover),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.95, 0.95));
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 48, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Aún no has añadido páginas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Vuelve y captura o importa imágenes para generar tu PDF.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
