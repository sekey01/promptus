import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:promptus/screens/splash_screen.dart';
import 'package:promptus/services/database_service.dart';
import 'package:promptus/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: true,
      home: MyApp(),
    )
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
///Add provider here
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeService()),
            ChangeNotifierProvider<NotificationService>.value(
              value: NotificationService.instance,
            ),

            // I use this singleton pattern to ensure the same instance is used app-wide
            ChangeNotifierProvider<DatabaseService>.value(
              value: DatabaseService.instance,
            ),
          ],
          child: Consumer<ThemeService>(
            builder: (context, themeService, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                 darkTheme: ThemeService.darkTheme,
                theme: ThemeService.lightTheme,
               // theme: themeService.getThemeData(),
                home: SplashScreen(),
              );
            },
          ),
        ));
  }
}