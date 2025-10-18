import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

import '../../core/app_export.dart';
import './widgets/app_header_widget.dart';
import './widgets/error_dialog_widget.dart';
import './widgets/instruction_text_widget.dart';
import './widgets/permission_dialog_widget.dart';
import './widgets/scan_button_widget.dart';

class MainScanningScreen extends StatefulWidget {
  const MainScanningScreen({Key? key}) : super(key: key);

  @override
  State<MainScanningScreen> createState() => _MainScanningScreenState();
}

class _MainScanningScreenState extends State<MainScanningScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isPermissionRequested = false;
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameras();
    }
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) {
      return true; // Browser handles permissions
    }

    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied && !_isPermissionRequested) {
      setState(() => _isPermissionRequested = true);
      return await _showPermissionDialog();
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return false;
    }

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  Future<bool> _showPermissionDialog() async {
    final completer = Completer<bool>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PermissionDialogWidget(
          onAllowPressed: () async {
            Navigator.of(context).pop();
            final result = await Permission.camera.request();
            completer.complete(result.isGranted);
          },
          onDenyPressed: () {
            Navigator.of(context).pop();
            completer.complete(false);
          },
        );
      },
    );

    return completer.future;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ErrorDialogWidget(
          title: 'Permiso Denegado',
          message:
              'Para escanear documentos, necesitas habilitar el acceso a la cámara en la configuración de la aplicación.',
          onRetryPressed: () {
            Navigator.of(context).pop();
            _handleScanButtonPressed();
          },
          onSettingsPressed: () async {
            Navigator.of(context).pop();
            await openAppSettings();
          },
        );
      },
    );
  }

  void _showCameraErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ErrorDialogWidget(
          title: 'Error de Cámara',
          message:
              'No se pudo acceder a la cámara. Verifica que no esté siendo utilizada por otra aplicación.',
          onRetryPressed: () {
            Navigator.of(context).pop();
            _handleScanButtonPressed();
          },
        );
      },
    );
  }

  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) {
      _showCameraErrorDialog();
      return;
    }

    try {
      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first)
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first);

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _applySettings();

      if (mounted) {
        Navigator.pushNamed(context, '/camera-scanning-interface');
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _showCameraErrorDialog();
    }
  }

  Future<void> _applySettings() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);

      if (!kIsWeb) {
        try {
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (e) {
          debugPrint('Flash mode not supported: $e');
        }
      }
    } catch (e) {
      debugPrint('Error applying camera settings: $e');
    }
  }

  Future<void> _handleScanButtonPressed() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final hasPermission = await _requestCameraPermission();

      if (!hasPermission) {
        setState(() => _isLoading = false);
        return;
      }

      await _initializeCamera();
    } catch (e) {
      debugPrint('Error handling scan button press: $e');
      _showCameraErrorDialog();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: 100.h -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                SizedBox(height: 4.h),
                const AppHeaderWidget(),
                SizedBox(height: 8.h),
                Expanded(
                  flex: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20.w),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: 'document_scanner',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 20.w,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      ScanButtonWidget(
                        onPressed: _handleScanButtonPressed,
                        isLoading: _isLoading,
                      ),
                      SizedBox(height: 4.h),
                      const InstructionTextWidget(),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFeatureItem(
                            icon: 'auto_awesome',
                            title: 'Detección\nAutomática',
                          ),
                          _buildFeatureItem(
                            icon: 'layers',
                            title: 'Múltiples\nPáginas',
                          ),
                          _buildFeatureItem(
                            icon: 'share',
                            title: 'Compartir\nFácil',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required String icon,
    required String title,
  }) {
    return Column(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.primaryColor,
              size: 6.w,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}