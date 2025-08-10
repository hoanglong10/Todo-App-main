import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:uptodo/ui/splash/splash.dart';
import 'package:uptodo/data/settings_service.dart';
import 'package:uptodo/data/settings_controller.dart';
import 'package:uptodo/providers/auth_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting app initialization...');

  try {
    // Initialize Firebase with options
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    print('❌ Firebase initialization failed: $e');
    print('📍 Stack trace: $stackTrace');
  }

  try {
    // Nạp cấu hình đã lưu
    print('⚙️ Loading app settings...');
    final settings = await AppSettings.load();
    print('✅ Settings loaded');

    // Tạo controller và gán vào biến toàn cục
    final controller = SettingsController(settings);
    settingsController = controller;
    print('✅ Settings controller created');

    runApp(MyApp(controller: controller));
  } catch (e, stackTrace) {
    print('❌ App initialization failed: $e');
    print('📍 Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  final SettingsController controller;
  const MyApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Todo List',
            theme: controller.lightTheme,
            darkTheme: controller.darkTheme,
            themeMode: controller.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}