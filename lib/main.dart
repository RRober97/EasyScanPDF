import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'core/app_export.dart';
import 'presentation/main_scanning_screen/main_scanning_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PdfScannerApp());
}

class PdfScannerApp extends StatelessWidget {
  const PdfScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'PDF Scanner',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (_) => const MainScanningScreen(),
          ),
        );
      },
    );
  }
}
