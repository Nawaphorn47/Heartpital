// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/screens/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen_scaffold.dart';
import 'services/notification_helper.dart';
import 'package:flutter/foundation.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
    if (!kIsWeb) {
    await NotificationHelper.initialize();
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Patient Management App',
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/main': (context) => const MainScreenScaffold(),
          },
        );
      },
    );
  }
}