import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../services/scan_session.dart';

enum AspectRatioOption {
  free,
  a4,
  square,
}

extension on AspectRatioOption {
  String get label {
    switch (this) {
      case AspectRatioOption.free:
        return 'Libre';
      case AspectRatioOption.a4:
        return 'A4';
      case AspectRatioOption.square:
        return '1:1';
    }
  }

  double? get ratio {
    switch (this) {
      case AspectRatioOption.free:
        return null;
      case AspectRatioOption.a4:
        return 210 / 297;
      case AspectRatioOption.square:
        return 1;
    }
  }
}

class DocumentEditorPage extends ConsumerStatefulWidget {
  const DocumentEditorPage({
    super.key,
    required this.pageId,
    this.autoOpenCropper = false,
  });

  final String pageId;
  final bool autoOpenCropper;

  static Route<void> route(
    String pageId, {
    bool autoOpenCropper = false,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => DocumentEditorPage(
        pageId: pageId,
        autoOpenCropper: autoOpenCropper,
      ),
      settings: RouteSettings(name: 'document-editor/$pageId'),
    );
  }

  @override
  ConsumerState<DocumentEditorPage> createState() => _DocumentEditorPageState();
}

class _DocumentEditorPageState extends ConsumerState<DocumentEditorPage> {
  final ImagePicker _picker = ImagePicker();
  final CropController _cropController = CropController();

  late Uint8List _originalBytes;
  late Uint8List _currentBytes;
  bool _isProcessing = false;
  bool _showCropper = false;
  AspectRatioOption _aspectRatio = AspectRatioOption.free;

  double _brightness = 0;
  double _contrast = 1;
  bool _grayscale = false;
  bool _textEnhance = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(scanSessionProvider);
    final page = session.pages.firstWhere((page) => page.id == widget.pageId);
    _originalBytes = page.bytes;
    _currentBytes = page.bytes;

    if (widget.autoOpenCropper) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showCropper = true;
        });
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _applyCrop() async {
    setState(() {
      _isProcessing = true;
    });
    _cropController.crop();
  }

  Future<void> _onCropped(Uint8List bytes) async {
    setState(() {
      _currentBytes = bytes;
      _showCropper = false;
      _isProcessing = false;
    });
  }

  Future<void> _applyRotation(int degrees) async {
    setState(() {
      _isProcessing = true;
    });
    final rotated = await compute(_rotateImage, _ImageRotationPayload(_currentBytes, degrees));
    setState(() {
      _currentBytes = rotated;
      _isProcessing = false;
    });
  }

  Future<void> _applyAdjustments() async {
    setState(() {
      _isProcessing = true;
    });
    final adjusted = await compute(
      _applyImageAdjustments,
      _ImageAdjustmentPayload(
        bytes: _currentBytes,
        brightness: _brightness,
        contrast: _contrast,
        grayscale: _grayscale,
        enhanceText: _textEnhance,
      ),
    );
    setState(() {
      _currentBytes = adjusted;
      _isProcessing = false;
    });
  }

  Future<void> _replacePage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _currentBytes = bytes;
      _originalBytes = bytes;
      _brightness = 0;
      _contrast = 1;
      _grayscale = false;
      _textEnhance = false;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isProcessing = true;
    });
    await ref
        .read(scanSessionProvider.notifier)
        .updatePage(widget.pageId, _currentBytes);
    setState(() {
      _isProcessing = false;
    });
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _resetAdjustments() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentBytes = _originalBytes;
      _brightness = 0;
      _contrast = 1;
      _grayscale = false;
      _textEnhance = false;
      _showCropper = false;
    });
  }

  void _toggleCropSheet() {
    setState(() {
      _showCropper = !_showCropper;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanSessionProvider);
    final index = session.pages.indexWhere((page) => page.id == widget.pageId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar página ${index + 1}'),
        actions: [
          IconButton(
            tooltip: 'Reemplazar imagen',
            onPressed: _isProcessing ? null : _replacePage,
            icon: const Icon(Icons.photo_library_outlined),
          ),
          IconButton(
            tooltip: 'Eliminar página',
            onPressed: () {
              ref.read(scanSessionProvider.notifier).removePage(widget.pageId);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _showCropper
                  ? Stack(
                      children: [
                        Center(
                          child: Crop(
                            key: const ValueKey('cropper'),
                            controller: _cropController,
                            image: _currentBytes,
                            aspectRatio: _aspectRatio.ratio,
                            withCircleUi: false,
                            baseColor: Theme.of(context).colorScheme.surface,
                            maskColor: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.8),
                            onCropped: _onCropped,
                          ).animate().fadeIn(duration: 300.ms),
                        ),
                        if (_isProcessing)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : InteractiveViewer(
                      key: const ValueKey('preview'),
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Hero(
                          tag: 'page-${widget.pageId}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.memory(
                              _currentBytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          _EditorControls(
            brightness: _brightness,
            contrast: _contrast,
            grayscale: _grayscale,
            textEnhance: _textEnhance,
            aspectRatio: _aspectRatio,
            showCropper: _showCropper,
            isProcessing: _isProcessing,
            onAspectRatioChanged: (value) {
              setState(() {
                _aspectRatio = value;
              });
            },
            onToggleCropper: _toggleCropSheet,
            onApplyCrop: _applyCrop,
            onBrightnessChanged: (value) {
              setState(() {
                _brightness = value;
              });
            },
            onContrastChanged: (value) {
              setState(() {
                _contrast = value;
              });
            },
            onGrayscaleChanged: (value) {
              setState(() {
                _grayscale = value;
              });
            },
            onTextEnhanceChanged: (value) {
              setState(() {
                _textEnhance = value;
              });
            },
            onApplyAdjustments: _applyAdjustments,
            onRotateLeft: () => _applyRotation(-90),
            onRotateRight: () => _applyRotation(90),
            onReset: _resetAdjustments,
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _saveChanges,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorControls extends StatelessWidget {
  const _EditorControls({
    required this.brightness,
    required this.contrast,
    required this.grayscale,
    required this.textEnhance,
    required this.aspectRatio,
    required this.showCropper,
    required this.isProcessing,
    required this.onAspectRatioChanged,
    required this.onToggleCropper,
    required this.onApplyCrop,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onGrayscaleChanged,
    required this.onTextEnhanceChanged,
    required this.onApplyAdjustments,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onReset,
  });

  final double brightness;
  final double contrast;
  final bool grayscale;
  final bool textEnhance;
  final AspectRatioOption aspectRatio;
  final bool showCropper;
  final bool isProcessing;
  final ValueChanged<AspectRatioOption> onAspectRatioChanged;
  final VoidCallback onToggleCropper;
  final VoidCallback onApplyCrop;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<bool> onGrayscaleChanged;
  final ValueChanged<bool> onTextEnhanceChanged;
  final VoidCallback onApplyAdjustments;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.45),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Ajustes rápidos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: isProcessing ? null : onReset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restablecer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ControlSection(
              title: 'Recorte',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<AspectRatioOption>(
                    showSelectedIcon: false,
                    segments: AspectRatioOption.values
                        .map(
                          (option) => ButtonSegment(
                            value: option,
                            label: Text(option.label),
                          ),
                        )
                        .toList(),
                    selected: {aspectRatio},
                    onSelectionChanged: (selection) {
                      onAspectRatioChanged(selection.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () {
                                  onToggleCropper();
                                },
                          icon: const Icon(Icons.crop),
                          label: Text(showCropper ? 'Ajustar recorte' : 'Iniciar recorte'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: showCropper && !isProcessing ? onApplyCrop : null,
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ControlSection(
              title: 'Rotación',
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing ? null : onRotateLeft,
                      icon: const Icon(Icons.rotate_90_degrees_ccw),
                      label: const Text('90° Izq'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing ? null : onRotateRight,
                      icon: const Icon(Icons.rotate_90_degrees_cw),
                      label: const Text('90° Der'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ControlSection(
              title: 'Filtros',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SliderTile(
                    title: 'Brillo',
                    value: brightness,
                    min: -0.4,
                    max: 0.4,
                    onChanged: onBrightnessChanged,
                  ),
                  _SliderTile(
                    title: 'Contraste',
                    value: contrast,
                    min: 0.5,
                    max: 1.6,
                    onChanged: onContrastChanged,
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Escala de grises'),
                    value: grayscale,
                    onChanged: isProcessing ? null : onGrayscaleChanged,
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Realce de texto'),
                    subtitle: const Text('Aumenta contraste y reduce ruido'),
                    value: textEnhance,
                    onChanged: isProcessing ? null : onTextEnhanceChanged,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: isProcessing ? null : onApplyAdjustments,
                      icon: const Icon(Icons.auto_fix_high_outlined),
                      label: const Text('Aplicar filtros'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlSection extends StatelessWidget {
  const _ControlSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            Text(value.toStringAsFixed(2),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ImageRotationPayload {
  _ImageRotationPayload(this.bytes, this.degrees);

  final Uint8List bytes;
  final int degrees;
}

Uint8List _rotateImage(_ImageRotationPayload payload) {
  final decoded = img.decodeImage(payload.bytes);
  if (decoded == null) {
    return payload.bytes;
  }
  final rotated = img.copyRotate(decoded, angle: payload.degrees);
  return Uint8List.fromList(img.encodeJpg(rotated, quality: 95));
}

class _ImageAdjustmentPayload {
  _ImageAdjustmentPayload({
    required this.bytes,
    required this.brightness,
    required this.contrast,
    required this.grayscale,
    required this.enhanceText,
  });

  final Uint8List bytes;
  final double brightness;
  final double contrast;
  final bool grayscale;
  final bool enhanceText;
}

Uint8List _applyImageAdjustments(_ImageAdjustmentPayload payload) {
  final decoded = img.decodeImage(payload.bytes);
  if (decoded == null) {
    return payload.bytes;
  }
  img.Image working = img.Image.from(decoded);
  if (payload.brightness != 0 || payload.contrast != 1) {
    working = img.adjustColor(
      working,
      brightness: payload.brightness,
      contrast: payload.contrast,
    );
  }
  if (payload.grayscale) {
    working = img.grayscale(working);
  }
  if (payload.enhanceText) {
    working = img.adjustColor(
      working,
      contrast: payload.contrast * 1.25,
      brightness: payload.brightness + 0.05,
    );
    working = img.smooth(working, weight: 1.25);
  }
  return Uint8List.fromList(img.encodeJpg(working, quality: 95));
}
