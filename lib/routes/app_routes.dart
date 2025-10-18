import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/main_scanning_screen/main_scanning_screen.dart';
import '../presentation/camera_scanning_interface/camera_scanning_interface.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String mainScanning = '/main-scanning-screen';
  static const String cameraScanningInterface = '/camera-scanning-interface';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const MainScanningScreen(),
    splash: (context) => const SplashScreen(),
    mainScanning: (context) => const MainScanningScreen(),
    cameraScanningInterface: (context) => const CameraScanningInterface(),
    // TODO: Add your other routes here
  };
}
