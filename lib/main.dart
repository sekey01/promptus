import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:promptus/screens/splash_screen.dart';
import 'package:promptus/services/database_service.dart';
import 'package:promptus/services/notification_service.dart';
import 'package:promptus/services/wake_word_background.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initWakeWordService();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider<NotificationService>.value(
          value: NotificationService.instance,
        ),
        ChangeNotifierProvider<DatabaseService>.value(
          value: DatabaseService.instance,
        ),
      ],
      child: const PromptusApp(),
    ),
  );
}

class PromptusApp extends StatelessWidget {
  const PromptusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Promptus',
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      themeMode: themeService.flutterThemeMode,
      home: const SplashScreen(),
    );
  }
}
