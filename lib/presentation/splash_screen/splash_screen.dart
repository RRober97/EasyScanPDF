import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitializing = true;
  String _statusMessage = 'Inicializando...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Check camera permissions
      setState(() {
        _statusMessage = 'Verificando permisos...';
      });

      bool hasPermission = await _requestCameraPermission();

      if (!hasPermission) {
        setState(() {
          _statusMessage = 'Permisos de cámara requeridos';
        });
        await Future.delayed(const Duration(seconds: 1));
        _navigateToPermissionFlow();
        return;
      }

      // Initialize camera services
      setState(() {
        _statusMessage = 'Inicializando cámara...';
      });

      await _initializeCameraServices();

      // Load user preferences
      setState(() {
        _statusMessage = 'Cargando configuración...';
      });

      await _loadUserPreferences();

      // Initialize PDF generation libraries
      setState(() {
        _statusMessage = 'Preparando servicios PDF...';
      });

      await _initializePDFServices();

      // Complete initialization
      setState(() {
        _statusMessage = 'Listo';
        _isInitializing = false;
      });

      await Future.delayed(const Duration(milliseconds: 800));
      _navigateToMainScreen();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error de inicialización';
        _isInitializing = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      _showRetryOption();
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) {
      return true; // Browser handles permissions
    }

    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<void> _initializeCameraServices() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      // Camera initialization successful
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('Camera initialization failed');
    }
  }

  Future<void> _loadUserPreferences() async {
    // Simulate loading user preferences
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _initializePDFServices() async {
    // Simulate PDF library initialization
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _navigateToMainScreen() {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _navigateToPermissionFlow() {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _showRetryOption() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Error de Inicialización',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            'No se pudo inicializar la aplicación. ¿Desea intentar nuevamente?',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryInitialization();
              },
              child: const Text('Reintentar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToMainScreen();
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  void _retryInitialization() {
    setState(() {
      _isInitializing = true;
      _statusMessage = 'Reintentando...';
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.lightTheme.colorScheme.surface,
                AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // App Logo and Branding
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Logo Container
                    Container(
                      width: 25.w,
                      height: 25.w,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4.w),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'document_scanner',
                          color: Colors.white,
                          size: 12.w,
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // App Title
                    Text(
                      'Escanear PDF',
                      style: AppTheme.lightTheme.textTheme.headlineMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),

                    SizedBox(height: 1.h),

                    // Subtitle
                    Text(
                      'Digitaliza documentos al instante',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Loading Indicator and Status
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Loading Indicator
                    _isInitializing
                        ? SizedBox(
                            width: 8.w,
                            height: 8.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.primary,
                              ),
                            ),
                          )
                        : Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.tertiary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'check',
                                color: Colors.white,
                                size: 4.w,
                              ),
                            ),
                          ),

                    SizedBox(height: 3.h),

                    // Status Message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusMessage,
                        key: ValueKey(_statusMessage),
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Version Info
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Text(
                    'Versión 1.0.0',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
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
