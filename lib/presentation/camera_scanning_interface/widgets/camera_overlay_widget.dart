import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CameraOverlayWidget extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final int pageCount;
  final bool isDocumentDetected;
  final bool showContinueOptions;
  final VoidCallback? onContinue;
  final VoidCallback? onFinish;

  const CameraOverlayWidget({
    super.key,
    required this.onClose,
    required this.onCapture,
    required this.onGallery,
    required this.pageCount,
    required this.isDocumentDetected,
    required this.showContinueOptions,
    this.onContinue,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top overlay with close button and page counter
        Positioned(
          top: 8.h,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: Colors.white,
                      size: 6.w,
                    ),
                  ),
                ),
                // Page counter
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Página $pageCount',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Document detection frame
        Center(
          child: Container(
            width: 80.w,
            height: 60.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDocumentDetected ? Colors.green : Colors.red,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Animated corner indicators
                ...List.generate(4, (index) => _buildCornerIndicator(index)),
              ],
            ),
          ),
        ),

        // Bottom overlay with controls
        Positioned(
          bottom: 12.h,
          left: 0,
          right: 0,
          child: showContinueOptions
              ? _buildContinueOptions()
              : _buildCaptureControls(),
        ),
      ],
    );
  }

  Widget _buildCornerIndicator(int index) {
    final positions = [
      {'top': 0.0, 'left': 0.0}, // Top-left
      {'top': 0.0, 'right': 0.0}, // Top-right
      {'bottom': 0.0, 'left': 0.0}, // Bottom-left
      {'bottom': 0.0, 'right': 0.0}, // Bottom-right
    ];

    final position = positions[index];

    return Positioned(
      top: position['top'],
      left: position['left'],
      right: position['right'],
      bottom: position['bottom'],
      child: Container(
        width: 6.w,
        height: 6.w,
        decoration: BoxDecoration(
          color: isDocumentDetected ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          GestureDetector(
            onTap: onGallery,
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'photo_library',
                color: Colors.white,
                size: 6.w,
              ),
            ),
          ),

          // Capture button
          GestureDetector(
            onTap: isDocumentDetected ? onCapture : null,
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: isDocumentDetected ? Colors.white : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: CustomIconWidget(
                iconName: 'camera_alt',
                color: isDocumentDetected
                    ? AppTheme.lightTheme.primaryColor
                    : Colors.grey.shade600,
                size: 8.w,
              ),
            ),
          ),

          // Placeholder for symmetry
          SizedBox(width: 12.w),
        ],
      ),
    );
  }

  Widget _buildContinueOptions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Continue button
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Continuar',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Finish button
          ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successLight,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Finalizar',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
