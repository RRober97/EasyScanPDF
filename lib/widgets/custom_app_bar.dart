import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CustomAppBarVariant {
  primary,
  secondary,
  transparent,
  minimal,
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final CustomAppBarVariant variant;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final bool showShadow;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.variant = CustomAppBarVariant.primary,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.systemOverlayStyle,
    this.onBackPressed,
    this.showBackButton = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine colors based on variant
    Color? appBarBackgroundColor;
    Color? appBarForegroundColor;
    double appBarElevation;
    SystemUiOverlayStyle overlayStyle;

    switch (variant) {
      case CustomAppBarVariant.primary:
        appBarBackgroundColor = backgroundColor ?? colorScheme.surface;
        appBarForegroundColor = foregroundColor ?? colorScheme.onSurface;
        appBarElevation = elevation ?? (showShadow ? 2.0 : 0.0);
        overlayStyle = systemOverlayStyle ??
            (theme.brightness == Brightness.light
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light);
        break;
      case CustomAppBarVariant.secondary:
        appBarBackgroundColor = backgroundColor ?? colorScheme.primaryContainer;
        appBarForegroundColor =
            foregroundColor ?? colorScheme.onPrimaryContainer;
        appBarElevation = elevation ?? (showShadow ? 1.0 : 0.0);
        overlayStyle = systemOverlayStyle ?? SystemUiOverlayStyle.dark;
        break;
      case CustomAppBarVariant.transparent:
        appBarBackgroundColor = backgroundColor ?? Colors.transparent;
        appBarForegroundColor = foregroundColor ?? colorScheme.onSurface;
        appBarElevation = elevation ?? 0.0;
        overlayStyle = systemOverlayStyle ?? SystemUiOverlayStyle.dark;
        break;
      case CustomAppBarVariant.minimal:
        appBarBackgroundColor = backgroundColor ?? colorScheme.surface;
        appBarForegroundColor = foregroundColor ?? colorScheme.onSurface;
        appBarElevation = elevation ?? 0.0;
        overlayStyle = systemOverlayStyle ??
            (theme.brightness == Brightness.light
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light);
        break;
    }

    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      centerTitle: centerTitle,
      backgroundColor: appBarBackgroundColor,
      foregroundColor: appBarForegroundColor,
      elevation: appBarElevation,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: overlayStyle,
      automaticallyImplyLeading: automaticallyImplyLeading && showBackButton,
      leading: leading ??
          (showBackButton && Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  tooltip: 'Atrás',
                )
              : null),
      actions: _buildActions(context),
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        color: appBarForegroundColor,
      ),
      iconTheme: IconThemeData(
        color: appBarForegroundColor,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: appBarForegroundColor,
        size: 24,
      ),
    );
  }

  List<Widget>? _buildActions(BuildContext context) {
    final defaultActions = <Widget>[
      // PDF Generation action
      IconButton(
        icon: const Icon(Icons.picture_as_pdf),
        onPressed: () => Navigator.pushNamed(context, '/pdf-generation'),
        tooltip: 'Generar PDF',
      ),
      // Share Document action
      IconButton(
        icon: const Icon(Icons.share),
        onPressed: () => Navigator.pushNamed(context, '/share-document'),
        tooltip: 'Compartir documento',
      ),
    ];

    if (actions != null) {
      return [...actions!, ...defaultActions];
    }

    return defaultActions;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
