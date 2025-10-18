import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DocumentDetectionWidget extends StatefulWidget {
  final bool isDetected;
  final String? errorMessage;

  const DocumentDetectionWidget({
    super.key,
    required this.isDetected,
    this.errorMessage,
  });

  @override
  State<DocumentDetectionWidget> createState() =>
      _DocumentDetectionWidgetState();
}

class _DocumentDetectionWidgetState extends State<DocumentDetectionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isDetected) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DocumentDetectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDetected != oldWidget.isDetected) {
      if (widget.isDetected) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 25.h,
      left: 4.w,
      right: 4.w,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isDetected ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: widget.isDetected
                    ? AppTheme.successLight.withValues(alpha: 0.9)
                    : widget.errorMessage != null
                        ? AppTheme.errorLight.withValues(alpha: 0.9)
                        : AppTheme.warningLight.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: widget.isDetected
                        ? 'check_circle'
                        : widget.errorMessage != null
                            ? 'error'
                            : 'warning',
                    color: Colors.white,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _getStatusMessage(),
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getStatusMessage() {
    if (widget.isDetected) {
      return 'Documento detectado - Toca para capturar';
    } else if (widget.errorMessage != null) {
      return widget.errorMessage!;
    } else {
      return 'Posiciona el documento en el marco';
    }
  }
}
