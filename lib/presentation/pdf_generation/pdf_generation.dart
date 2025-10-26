import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../routes/app_routes.dart';
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
  late Future<StoredPdf> _future;

  @override
  void initState() {
    super.initState();
    _future = _generate();
  }

  Future<StoredPdf> _generate() async {
    final scanSession = ref.read(scanSessionProvider);
    final subscription = ref.read(subscriptionProvider);
    final pdfService = ref.read(pdfServiceProvider);
    final storageService = ref.read(storageServiceProvider);
    final pagesBytes = ref.read(scanSessionProvider.notifier).pagesBytes;

    if (scanSession.pages.isEmpty) {
      throw Exception('No hay páginas capturadas.');
    }

    try {
      final file = await pdfService.buildPdf(
        pagesBytes,
        isPro: subscription.isPro,
      );
      final stored = await storageService.savePdf(
        file,
        isPro: subscription.isPro,
        pageCount: scanSession.pages.length,
      );
      ref.read(scanSessionProvider.notifier).clear();
      Fluttertoast.showToast(msg: 'PDF generado correctamente');
      return stored;
    } on PdfLimitExceededException catch (e) {
      Fluttertoast.showToast(msg: e.message);
      if (mounted) {
        final upgraded = await Navigator.pushNamed<bool>(
          context,
          AppRoutes.paywall,
        );
        if (upgraded == true || ref.read(subscriptionProvider).isPro) {
          return _generate();
        }
      }
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generando PDF'),
      ),
      body: FutureBuilder<StoredPdf>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _GeneratingView();
          }

          if (snapshot.hasError) {
            return _ErrorView(error: snapshot.error.toString());
          }

          final stored = snapshot.data;
          if (stored != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.shareDocument,
                arguments: stored,
              );
            });
            return const _GeneratingView();
          }

          return const _GeneratingView();
        },
      ),
    );
  }
}

class _GeneratingView extends StatelessWidget {
  const _GeneratingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Procesando tu documento...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              'No se pudo generar el PDF',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
