import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdf_scanner/platform/file_ops.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../routes/app_routes.dart';
import './widgets/document_preview_widget.dart';
import './widgets/share_options_widget.dart';
import './widgets/share_success_widget.dart';

enum ShareState { preview, sharing, success, error }

class ShareDocument extends StatefulWidget {
  const ShareDocument({super.key});

  @override
  State<ShareDocument> createState() => _ShareDocumentState();
}

class _ShareDocumentState extends State<ShareDocument>
    with TickerProviderStateMixin {
  ShareState _currentState = ShareState.preview;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mock PDF data
  final String _fileName = 'Documento_18-10-2024_17-54.pdf';
  final String _fileSize = '2.4 MB';
  final DateTime _createdDate = DateTime.now();
  String? _pdfFilePath;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateMockPDF();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _generateMockPDF() async {
    try {
      final pdfContent = _generateMockPDFContent();

      final bytes = utf8.encode(pdfContent);
      final file = await saveBytesToAppDocs(_fileName, bytes);
      _pdfFilePath = file.path;
    } catch (e) {
      debugPrint('Error generating mock PDF: $e');
    }
  }

  String _generateMockPDFContent() {
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
/Resources <<
/Font <<
/F1 5 0 R
>>
>>
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
(Documento PDF Escaneado) Tj
ET
endstream
endobj

5 0 obj
<<
/Type /Font
/Subtype /Type1
/BaseFont /Helvetica
>>
endobj

xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000274 00000 n 
0000000369 00000 n 
trailer
<<
/Size 6
/Root 1 0 R
>>
startxref
466
%%EOF''';
  }

  Future<void> _handleShare() async {
    if (_pdfFilePath == null) {
      _showErrorState();
      return;
    }

    setState(() {
      _currentState = ShareState.sharing;
    });

    try {
      await _shareOnMobile();

      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        _currentState = ShareState.success;
      });

      _showSuccessToast();
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      _showErrorState();
    }
  }

  Future<void> _shareOnMobile() async {
    // For mobile, use share_plus
    final result = await Share.shareXFiles(
      [XFile(_pdfFilePath!, mimeType: 'application/pdf')],
      text: 'Documento PDF escaneado',
      subject: 'Compartir documento',
    );

    if (result.status == ShareResultStatus.dismissed) {
      setState(() {
        _currentState = ShareState.preview;
      });
      return;
    }
  }

  void _showSuccessToast() {
    Fluttertoast.showToast(
      msg: "Compartido Exitosamente",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      textColor: AppTheme.lightTheme.colorScheme.onSecondary,
      fontSize: 14.sp,
    );
  }

  void _showErrorState() {
    setState(() {
      _currentState = ShareState.error;
    });

    Fluttertoast.showToast(
      msg: "Error al compartir documento",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.error,
      textColor: AppTheme.lightTheme.colorScheme.onError,
      fontSize: 14.sp,
    );

    // Return to preview after showing error
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentState = ShareState.preview;
        });
      }
    });
  }

  void _handleDone() {
    Navigator.pushReplacementNamed(context, AppRoutes.pdfGeneration);
  }

  void _handleBackPressed() {
    if (_currentState == ShareState.sharing) return;

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Compartir Documento',
        variant: CustomAppBarVariant.primary,
        onBackPressed: _handleBackPressed,
        showBackButton: _currentState != ShareState.sharing,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildBody(),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _currentState == ShareState.preview
          ? const CustomBottomBar(
              variant: CustomBottomBarVariant.minimal,
              currentIndex: 2,
            )
          : null,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              AppBar().preferredSize.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 4.h),
            _buildCurrentStateWidget(),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStateWidget() {
    switch (_currentState) {
      case ShareState.preview:
        return Column(
          children: [
            DocumentPreviewWidget(
              fileName: _fileName,
              fileSize: _fileSize,
              createdDate: _createdDate,
            ),
            SizedBox(height: 3.h),
            ShareOptionsWidget(
              onSharePressed: _handleShare,
              isSharing: false,
            ),
          ],
        );
      case ShareState.sharing:
        return ShareOptionsWidget(
          onSharePressed: () {},
          isSharing: true,
        );
      case ShareState.success:
        return ShareSuccessWidget(
          onDone: _handleDone,
        );
      case ShareState.error:
        return Column(
          children: [
            Container(
              width: 85.w,
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.error
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: 'error_outline',
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 48,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Error al Compartir',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'No se pudo compartir el documento. Inténtalo de nuevo.',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
