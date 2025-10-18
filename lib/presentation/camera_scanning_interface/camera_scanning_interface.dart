import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/camera_overlay_widget.dart';
import './widgets/camera_preview_widget.dart';
import './widgets/document_detection_widget.dart';

class CameraScanningInterface extends StatefulWidget {
  const CameraScanningInterface({super.key});

  @override
  State<CameraScanningInterface> createState() =>
      _CameraScanningInterfaceState();
}

class _CameraScanningInterfaceState extends State<CameraScanningInterface>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isDocumentDetected = false;
  bool _showContinueOptions = false;
  int _pageCount = 1;
  String? _errorMessage;
  List<XFile> _capturedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  // Mock document detection data
  final List<Map<String, dynamic>> _mockDetectionStates = [
    {
      "isDetected": true,
      "message": "Documento detectado correctamente",
      "confidence": 0.95,
    },
    {
      "isDetected": false,
      "message": "Mejora la iluminación",
      "confidence": 0.3,
    },
    {
      "isDetected": false,
      "message": "Acerca más el documento",
      "confidence": 0.4,
    },
    {
      "isDetected": true,
      "message": "Posición perfecta para escanear",
      "confidence": 0.98,
    },
  ];

  int _currentDetectionIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _startDocumentDetectionSimulation();
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
      _initializeCamera();
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _initializeCamera() async {
    try {
      if (!await _requestCameraPermission()) {
        setState(() {
          _errorMessage = 'Permisos de cámara requeridos';
        });
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No se encontraron cámaras disponibles';
        });
        return;
      }

      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _applySettings();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al inicializar la cámara';
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _applySettings() async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      if (!kIsWeb) {
        try {
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (e) {
          // Flash not supported, continue without it
        }
      }
    } catch (e) {
      // Settings not supported, continue without them
    }
  }

  void _startDocumentDetectionSimulation() {
    // Simulate document detection changes every 3 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _updateDocumentDetection();
        _startDocumentDetectionSimulation();
      }
    });
  }

  void _updateDocumentDetection() {
    final detection = _mockDetectionStates[_currentDetectionIndex];
    setState(() {
      _isDocumentDetected = detection["isDetected"] as bool;
      if (!_isDocumentDetected) {
        _errorMessage = detection["message"] as String;
      } else {
        _errorMessage = null;
      }
    });

    _currentDetectionIndex =
        (_currentDetectionIndex + 1) % _mockDetectionStates.length;
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      final XFile photo = await _cameraController!.takePicture();

      setState(() {
        _capturedImages.add(photo);
        _showContinueOptions = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Página $_pageCount capturada exitosamente',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.successLight,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al capturar la imagen',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _capturedImages.add(image);
          _showContinueOptions = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imagen seleccionada de la galería',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.successLight,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al seleccionar imagen',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }

  void _continueScanning() {
    setState(() {
      _pageCount++;
      _showContinueOptions = false;
    });
  }

  void _finishScanning() {
    // Show PDF generation success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PDF listo - ${_capturedImages.length} páginas procesadas',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.successLight,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Compartir',
          textColor: Colors.white,
          onPressed: _sharePDF,
        ),
      ),
    );

    // Navigate back to main screen
    Navigator.pushReplacementNamed(context, '/main-scanning-screen');
  }

  void _sharePDF() {
    // Simulate PDF sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Compartiendo PDF...',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.primaryColor,
      ),
    );
  }

  void _closeScanning() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            CameraPreviewWidget(
              cameraController: _cameraController,
              isInitialized: _isCameraInitialized,
              errorMessage: _errorMessage,
            ),

            // Camera overlay with controls
            if (_isCameraInitialized && _errorMessage == null)
              CameraOverlayWidget(
                onClose: _closeScanning,
                onCapture: _capturePhoto,
                onGallery: _selectFromGallery,
                pageCount: _pageCount,
                isDocumentDetected: _isDocumentDetected,
                showContinueOptions: _showContinueOptions,
                onContinue: _continueScanning,
                onFinish: _finishScanning,
              ),

            // Document detection status
            if (_isCameraInitialized &&
                _errorMessage == null &&
                !_showContinueOptions)
              DocumentDetectionWidget(
                isDetected: _isDocumentDetected,
                errorMessage: !_isDocumentDetected ? _errorMessage : null,
              ),
          ],
        ),
      ),
    );
  }
}
