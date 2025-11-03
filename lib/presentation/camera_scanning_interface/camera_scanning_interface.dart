import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/limits.dart';
import '../../routes/app_routes.dart';
import '../../services/scan_session.dart';
import '../../services/subscription_service.dart';
import '../editor/document_editor_page.dart';

class CameraScanningInterface extends ConsumerStatefulWidget {
  const CameraScanningInterface({super.key});

  @override
  ConsumerState<CameraScanningInterface> createState() =>
      _CameraScanningInterfaceState();
}

class _CameraScanningInterfaceState
    extends ConsumerState<CameraScanningInterface>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isBusy = false;
  String? _error;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        setState(() {
          _error = 'Permiso de cámara denegado';
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No hay cámaras disponibles';
        });
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFocusMode(FocusMode.auto);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al inicializar la cámara';
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isBusy) {
      return;
    }
    if (!await _canAddPage()) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      HapticFeedback.mediumImpact();
      final xFile = await controller.takePicture();
      final bytes = await xFile.readAsBytes();
      await _addPage(bytes);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error al capturar la imagen');
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (!await _canAddPage()) {
      return;
    }
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        await _addPage(bytes);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'No se pudo abrir la galería');
    }
  }

  Future<void> _addPage(Uint8List bytes) async {
    final page = await ref.read(scanSessionProvider.notifier).addPage(bytes);
    if (!mounted) return;
    Fluttertoast.showToast(msg: 'Página añadida');
    await Navigator.of(context).push(
      DocumentEditorPage.route(
        page.id,
        autoOpenCropper: true,
      ),
    );
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
      if (upgraded == true || ref.read(subscriptionProvider).isPro) {
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final session = ref.watch(scanSessionProvider);
    final subscription = ref.watch(subscriptionProvider);
    final limit = subscription.isPro
        ? Limits.proMaxPagesPerPdf
        : Limits.normalMaxPagesPerPdf;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear documento'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Listo'),
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : controller == null || !_isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    CameraPreview(controller),
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _isBusy ? null : _pickFromGallery,
                            iconSize: 36,
                            icon: const Icon(Icons.photo_library_outlined),
                            color: Colors.white,
                          ),
                          GestureDetector(
                            onTap: _isBusy ? null : _capturePhoto,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${session.pages.length}/$limit',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'páginas',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
