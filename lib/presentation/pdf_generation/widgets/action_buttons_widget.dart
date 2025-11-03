import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onSharePdf;
  final VoidCallback onScanNew;
  final bool isVisible;

  const ActionButtonsWidget({
    super.key,
    required this.onSharePdf,
    required this.onScanNew,
    this.isVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        child: Container(
          width: 85.w,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(3.w),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow
                    .withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary action - Share PDF
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onSharePdf();
                  },
                  icon: CustomIconWidget(
                    iconName: 'share',
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 5.w,
                  ),
                  label: Text(
                    'Compartir PDF',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                    elevation: 2,
                    shadowColor: AppTheme.lightTheme.colorScheme.shadow
                        .withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              // Secondary action - Scan New
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onScanNew();
                  },
                  icon: CustomIconWidget(
                    iconName: 'document_scanner',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 5.w,
                  ),
                  label: Text(
                    'Escanear Nuevo',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.lightTheme.colorScheme.primary,
                    side: BorderSide(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
