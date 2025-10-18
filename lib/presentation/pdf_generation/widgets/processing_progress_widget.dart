import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProcessingProgressWidget extends StatefulWidget {
  final double progress;
  final String statusText;
  final bool isCompleted;

  const ProcessingProgressWidget({
    super.key,
    required this.progress,
    required this.statusText,
    this.isCompleted = false,
  });

  @override
  State<ProcessingProgressWidget> createState() =>
      _ProcessingProgressWidgetState();
}

class _ProcessingProgressWidgetState extends State<ProcessingProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    if (widget.isCompleted) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ProcessingProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80.w,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.isCompleted
              ? _buildCompletedIndicator()
              : _buildProgressIndicator(),
          SizedBox(height: 4.h),
          Text(
            widget.statusText,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: widget.isCompleted
                  ? AppTheme.lightTheme.colorScheme.secondary
                  : AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (!widget.isCompleted) ...[
            SizedBox(height: 2.h),
            Text(
              '${(widget.progress * 100).toInt()}%',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 20.w,
      height: 20.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              value: widget.progress,
              strokeWidth: 1.w,
              backgroundColor: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          CustomIconWidget(
            iconName: 'picture_as_pdf',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 8.w,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedIndicator() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'check',
              color: AppTheme.lightTheme.colorScheme.onSecondary,
              size: 10.w,
            ),
          ),
        );
      },
    );
  }
}
