import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    _boot();
  }

  Future<void> _boot() async {
    // Initialise services while animations play
    final db = Provider.of<DatabaseService>(context, listen: false);
    try {
      await db.database;
      await Future.wait([
        db.loadTasks(),
        db.loadExpenses(),
        db.loadFolders(),
        db.loadNotes(),
        NotificationService.instance.init(),
      ]);
    } catch (_) {}

    // Minimum splash duration for brand impression
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ));
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Main content ──────────────────────────────────────────────
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Real app icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.30),
                              blurRadius: 32,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                          .scale(
                            begin: const Offset(0.6, 0.6),
                            end: const Offset(1, 1),
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                          ),

                      const SizedBox(height: 36),

                      // App name
                      Text(
                        'Promptus',
                        style: AppTypography.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      )
                          .animate(delay: 400.ms)
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                      const SizedBox(height: 10),

                      // Tagline
                      Text(
                        'Track. Plan. Prosper.',
                        style: AppTypography.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.5,
                        ),
                      )
                          .animate(delay: 600.ms)
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                    ],
                  ),
                ),
              ),

              // ── Bottom ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 56),
                child: Column(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(
                          Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Version 2.0.0',
                      style: AppTypography.roboto(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
