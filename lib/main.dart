import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/landing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const SahajMudraApp());
}

class SahajMudraApp extends StatelessWidget {
  const SahajMudraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SahajMudra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LandingScreen(),
    );
  }
}