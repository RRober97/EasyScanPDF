import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DocumentPreviewWidget extends StatelessWidget {
  final List<Map<String, dynamic>> capturedPages;
  final bool isBlurred;

  const DocumentPreviewWidget({
    super.key,
    required this.capturedPages,
    this.isBlurred = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Background blur overlay
          if (isBlurred)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: AppTheme.lightTheme.colorScheme.surface
                  .withValues(alpha: 0.3),
            ),
          // Document pages grid
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 2.w,
                  mainAxisSpacing: 2.w,
                  childAspectRatio: 0.7,
                ),
                itemCount: capturedPages.length,
                itemBuilder: (context, index) {
                  final page = capturedPages[index];
                  return _buildPagePreview(page, index);
                },
              ),
            ),
          ),
          // Additional blur effect for processing state
          if (isBlurred)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface
                    .withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPagePreview(Map<String, dynamic> page, int index) {
    final bool isProcessed = page['isProcessed'] ?? false;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.w),
        child: Stack(
          children: [
            // Page image
            CustomImageWidget(
              imageUrl: page['imageUrl'] as String,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              semanticLabel: page['semanticLabel'] as String,
            ),
            // Processing overlay
            if (isProcessed)
              Positioned(
                top: 1.w,
                right: 1.w,
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'check',
                    color: AppTheme.lightTheme.colorScheme.onSecondary,
                    size: 4.w,
                  ),
                ),
              ),
            // Page number
            Positioned(
              bottom: 1.w,
              left: 1.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface
                      .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(1.w),
                ),
                child: Text(
                  '${index + 1}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
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
