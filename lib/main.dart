import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';

import 'core/theme/app_theme.dart';
import 'features/home/pages/home_page.dart';
import 'firebase_options.dart';

/// Entry point của ứng dụng.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  MediaKit.ensureInitialized();

  runApp(const MyApp());
}

/// Widget gốc của ứng dụng.
class MyApp extends StatelessWidget {
  /// Khởi tạo widget [MyApp].
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Editor',
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}