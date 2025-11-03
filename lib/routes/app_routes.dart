import 'package:flutter/material.dart';
import '../presentation/camera_scanning_interface/camera_scanning_interface.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/library/library_screen.dart';
import '../presentation/main_scanning_screen/main_scanning_screen.dart';
import '../presentation/paywall/paywall_screen.dart';
import '../presentation/pdf_generation/pdf_generation.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/share_document/share_document.dart';
import '../presentation/splash_screen/splash_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String home = '/home';
  static const String splash = '/splash-screen';
  static const String mainScanning = '/main-scanning-screen';
  static const String cameraScanningInterface = '/camera-scanning-interface';
  static const String pdfGeneration = '/pdf-generation';
  static const String shareDocument = '/share-document';
  static const String library = '/library';
  static const String paywall = '/paywall';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const HomeScreen(),
    home: (context) => const HomeScreen(),
    splash: (context) => const SplashScreen(),
    mainScanning: (context) => const MainScanningScreen(),
    cameraScanningInterface: (context) => const CameraScanningInterface(),
    pdfGeneration: (context) => const PdfGeneration(),
    shareDocument: (context) => const ShareDocument(),
    library: (context) => const LibraryScreen(),
    paywall: (context) => const PaywallScreen(),
    settings: (context) => const SettingsScreen(),
    // TODO: Add your other routes here
  };
}
