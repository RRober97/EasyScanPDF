import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import 'package:universal_html/html.dart' as html;

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../routes/app_routes.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/document_preview_widget.dart';
import './widgets/error_dialog_widget.dart';
import './widgets/processing_progress_widget.dart';
import 'widgets/action_buttons_widget.dart';
import 'widgets/document_preview_widget.dart';
import 'widgets/error_dialog_widget.dart';
import 'widgets/processing_progress_widget.dart';

class PdfGeneration extends StatefulWidget {
  const PdfGeneration({super.key});

  @override
  State<PdfGeneration> createState() => _PdfGenerationState();
}

class _PdfGenerationState extends State<PdfGeneration>
    with TickerProviderStateMixin {
  // Processing state
  double _progress = 0.0;
  bool _isProcessing = true;
  bool _isCompleted = false;
  String _statusText = 'Generando PDF...';
  String? _generatedPdfPath;

  // Animation controllers
  late AnimationController _progressAnimationController;
  late Timer _progressTimer;

  // Mock captured document pages
  final List<Map<String, dynamic>> _capturedPages = [
    {
      'id': 1,
      'imageUrl':
          'https://images.unsplash.com/photo-1660718404466-66bfe12ffe37',
      'semanticLabel':
          'Scanned document page showing business contract with text and signature lines on white paper',
      'isProcessed': false,
    },
    {
      'id': 2,
      'imageUrl':
          'https://images.unsplash.com/photo-1556155092-8707de31f9c4',
      'semanticLabel':
          'Scanned document page displaying financial report with charts and numerical data in black text',
      'isProcessed': false,
    },
    {
      'id': 3,
      'imageUrl':
          'https://images.unsplash.com/photo-1493058860074-764a7792d336',
      'semanticLabel':
          'Scanned document page containing legal agreement with multiple paragraphs and bullet points',
      'isProcessed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeProcessing();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _progressTimer.cancel();
    super.dispose();
  }

  void _initializeProcessing() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Start PDF generation process
    _startPdfGeneration();
  }

  void _startPdfGeneration() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _progress += 0.02; // Increment progress by 2% every 100ms

        // Update page processing status
        if (_progress >= 0.33 && !_capturedPages[0]['isProcessed']) {
          _capturedPages[0]['isProcessed'] = true;
          _statusText = 'Procesando página 2...';
        } else if (_progress >= 0.66 && !_capturedPages[1]['isProcessed']) {
          _capturedPages[1]['isProcessed'] = true;
          _statusText = 'Procesando página 3...';
        } else if (_progress >= 0.90 && !_capturedPages[2]['isProcessed']) {
          _capturedPages[2]['isProcessed'] = true;
          _statusText = 'Finalizando PDF...';
        }

        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          _completePdfGeneration();
        }
      });
    });
  }

  void _completePdfGeneration() async {
    try {
      // Generate actual PDF file
      final pdfPath = await _generatePdfFile();

      if (pdfPath != null) {
        // Add haptic feedback for success
        HapticFeedback.heavyImpact();

        setState(() {
          _isProcessing = false;
          _isCompleted = true;
          _statusText = 'PDF Listo';
          _generatedPdfPath = pdfPath;
        });
      } else {
        _handleProcessingError('Error al generar PDF',
            'No se pudo crear el archivo PDF. Verifica el espacio disponible.');
      }
    } catch (e) {
      _handleProcessingError('Error inesperado',
          'Ocurrió un error durante la generación del PDF.');
    }
  }

  Future<String?> _generatePdfFile() async {
    try {
      if (kIsWeb) {
        return await _generatePdfForWeb();
      } else {
        return await _generatePdfForMobile();
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> _generatePdfForWeb() async {
    try {
      // Create PDF content for web
      final pdfContent = _createPdfContent();
      final bytes = Uint8List.fromList(pdfContent.codeUnits);

      // Create blob and download link
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Store URL for sharing
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _generatePdfForMobile() async {
    try {
      // Request storage permission
      if (!await _requestStoragePermission()) {
        return null;
      }

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'ScanPDF_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';

      // Create PDF file
      final file = File(filePath);
      final pdfContent = _createPdfContent();
      await file.writeAsString(pdfContent);

      return filePath;
    } catch (e) {
      return null;
    }
  }

  String _createPdfContent() {
    // Simple PDF content creation (in real implementation, use pdf package)
    final timestamp = DateTime.now().toString();
    return '''%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj

2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj

3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj

4 0 obj
<<
/Length 44
>>
stream
BT
/F1 12 Tf
72 720 Td
(ScanPDF Document - $timestamp) Tj
ET
endstream
endobj

xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000206 00000 n 
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
300
%%EOF''';
  }

  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
      return true; // iOS handles permissions automatically
    } catch (e) {
      return false;
    }
  }

  void _handleProcessingError(String title, String message) {
    setState(() {
      _isProcessing = false;
      _isCompleted = false;
    });

    ErrorDialogWidget.show(
      context,
      title: title,
      message: message,
      onRetry: () {
        Navigator.of(context).pop();
        _retryPdfGeneration();
      },
      onCancel: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop(); // Return to previous screen
      },
    );
  }

  void _retryPdfGeneration() {
    setState(() {
      _progress = 0.0;
      _isProcessing = true;
      _isCompleted = false;
      _statusText = 'Generando PDF...';
      _generatedPdfPath = null;

      // Reset page processing status
      for (var page in _capturedPages) {
        page['isProcessed'] = false;
      }
    });

    _startPdfGeneration();
  }

  void _sharePdf() async {
    if (_generatedPdfPath == null) return;

    try {
      if (kIsWeb) {
        // Web sharing - trigger download
        final anchor = html.AnchorElement(href: _generatedPdfPath!)
          ..setAttribute('download',
              'ScanPDF_${DateTime.now().millisecondsSinceEpoch}.pdf')
          ..click();
      } else {
        // Mobile sharing - navigate to share screen
        Navigator.pushNamed(
          context,
          AppRoutes.shareDocument,
          arguments: {'pdfPath': _generatedPdfPath},
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error al compartir PDF');
    }
  }

  void _scanNewDocument() {
    // Return to camera/scanner screen
    Navigator.of(context).pop();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(4.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Background document preview
            DocumentPreviewWidget(
              capturedPages: _capturedPages,
              isBlurred: _isProcessing || _isCompleted,
            ),

            // Main content overlay
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Processing progress indicator
                  ProcessingProgressWidget(
                    progress: _progress,
                    statusText: _statusText,
                    isCompleted: _isCompleted,
                  ),

                  SizedBox(height: 8.h),

                  // Action buttons (shown when completed)
                  ActionButtonsWidget(
                    onSharePdf: _sharePdf,
                    onScanNew: _scanNewDocument,
                    isVisible: _isCompleted,
                  ),
                ],
              ),
            ),

            // Back button
            Positioned(
              top: 2.h,
              left: 4.w,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface
                      .withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightTheme.colorScheme.shadow
                          .withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  icon: CustomIconWidget(
                    iconName: 'arrow_back',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 6.w,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}