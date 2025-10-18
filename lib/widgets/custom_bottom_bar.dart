import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../routes/app_routes.dart';

enum CustomBottomBarVariant {
  navigation,
  action,
  floating,
  minimal,
}

class CustomBottomBar extends StatelessWidget {
  final CustomBottomBarVariant variant;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;
  final bool showLabels;
  final EdgeInsetsGeometry? padding;

  const CustomBottomBar({
    super.key,
    this.variant = CustomBottomBarVariant.navigation,
    this.currentIndex = 0,
    this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
    this.showLabels = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (variant) {
      case CustomBottomBarVariant.navigation:
        return _buildNavigationBar(context, theme, colorScheme);
      case CustomBottomBarVariant.action:
        return _buildActionBar(context, theme, colorScheme);
      case CustomBottomBarVariant.floating:
        return _buildFloatingBar(context, theme, colorScheme);
      case CustomBottomBarVariant.minimal:
        return _buildMinimalBar(context, theme, colorScheme);
    }
  }

  Widget _buildNavigationBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: elevation! * 2,
                  offset: Offset(0, -elevation! / 2),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              HapticFeedback.lightImpact();
              _handleNavigation(context, index);
              onTap?.call(index);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: selectedItemColor ?? colorScheme.primary,
            unselectedItemColor: unselectedItemColor ??
                colorScheme.onSurface.withValues(alpha: 0.6),
            showSelectedLabels: showLabels,
            showUnselectedLabels: showLabels,
            type: BottomNavigationBarType.fixed,
            items: _getNavigationItems(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pushNamed(context, AppRoutes.pdfGeneration);
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  label: const Text('Generar PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pushNamed(context, AppRoutes.shareDocument);
                  },
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text('Compartir'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _getFloatingItems(context, colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _getMinimalItems(context, colorScheme),
          ),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _getNavigationItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.document_scanner),
        activeIcon: Icon(Icons.document_scanner),
        label: 'Escanear',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.picture_as_pdf_outlined),
        activeIcon: Icon(Icons.picture_as_pdf),
        label: 'PDF',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.share_outlined),
        activeIcon: Icon(Icons.share),
        label: 'Compartir',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Ajustes',
      ),
    ];
  }

  List<Widget> _getFloatingItems(
      BuildContext context, ColorScheme colorScheme) {
    return [
      _buildFloatingItem(
        context,
        Icons.document_scanner,
        'Escanear',
        0,
        colorScheme,
      ),
      _buildFloatingItem(
        context,
        Icons.picture_as_pdf,
        'PDF',
        1,
        colorScheme,
        onTap: () => Navigator.pushNamed(context, AppRoutes.pdfGeneration),
      ),
      _buildFloatingItem(
        context,
        Icons.share,
        'Compartir',
        2,
        colorScheme,
        onTap: () => Navigator.pushNamed(context, AppRoutes.shareDocument),
      ),
      _buildFloatingItem(
        context,
        Icons.settings,
        'Ajustes',
        3,
        colorScheme,
      ),
    ];
  }

  List<Widget> _getMinimalItems(BuildContext context, ColorScheme colorScheme) {
    return [
      _buildMinimalItem(
        context,
        Icons.document_scanner,
        0,
        colorScheme,
      ),
      _buildMinimalItem(
        context,
        Icons.picture_as_pdf,
        1,
        colorScheme,
        onTap: () => Navigator.pushNamed(context, AppRoutes.pdfGeneration),
      ),
      _buildMinimalItem(
        context,
        Icons.share,
        2,
        colorScheme,
        onTap: () => Navigator.pushNamed(context, AppRoutes.shareDocument),
      ),
      _buildMinimalItem(
        context,
        Icons.settings,
        3,
        colorScheme,
      ),
    ];
  }

  Widget _buildFloatingItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    ColorScheme colorScheme, {
    VoidCallback? onTap,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? (selectedItemColor ?? colorScheme.primary)
        : (unselectedItemColor ?? colorScheme.onSurface.withValues(alpha: 0.6));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
        this.onTap?.call(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          if (showLabels) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinimalItem(
    BuildContext context,
    IconData icon,
    int index,
    ColorScheme colorScheme, {
    VoidCallback? onTap,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? (selectedItemColor ?? colorScheme.primary)
        : (unselectedItemColor ?? colorScheme.onSurface.withValues(alpha: 0.6));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
        this.onTap?.call(index);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Scanner - stay on current page or navigate to scanner
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.pdfGeneration);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.shareDocument);
        break;
      case 3:
        // Settings - implement settings navigation
        break;
    }
  }
}
