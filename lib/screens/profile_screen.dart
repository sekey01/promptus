import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_typography.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../services/wake_word_service.dart';
import 'demographics_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'User';
  final _nameController = TextEditingController();

  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _totalExpenses = 0;
  double _totalExpenseAmount = 0.0;
  bool _wakeWordRunning = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
    _loadWakeWordState();
  }

  Future<void> _loadWakeWordState() async {
    final running = await WakeWordService.isRunning();
    if (!mounted) return;
    setState(() => _wakeWordRunning = running);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _nameController.text = _userName;
    });
  }

  Future<void> _loadStats() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final totalAmount = await DatabaseService.instance.getTotalExpenses();
    if (!mounted) return;
    setState(() {
      _totalTasks = db.tasks.length;
      _completedTasks = db.tasks.where((t) => t.isCompleted).length;
      _pendingTasks = db.tasks.where((t) => !t.isCompleted).length;
      _totalExpenses = db.expenses.length;
      _totalExpenseAmount = totalAmount;
    });
  }

  Future<void> _saveUserName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          _snack('Name cannot be empty', isError: true));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text.trim());
    if (!mounted) return;
    setState(() => _userName = _nameController.text.trim());
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(_snack('Name updated successfully'));
  }

  SnackBar _snack(String msg, {bool isError = false}) => SnackBar(
        content: Row(children: [
          Icon(
            isError ? Iconsax.close_circle : Iconsax.tick_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(msg,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
        ]),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
        margin: const EdgeInsets.all(16),
      );

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBR),
        title: Text('Edit Name', style: AppTypography.titleLarge),
        content: TextField(
          controller: _nameController,
          style: AppTypography.bodyMedium,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            prefixIcon:
                const Icon(Iconsax.user, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: AppRadius.lgBR),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.lgBR,
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: _saveUserName,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBR),
        title: Row(children: [
          const Icon(Iconsax.warning_2,
              color: AppColors.error, size: 26),
          const SizedBox(width: 10),
          Text('Delete Account', style: AppTypography.titleLarge),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will permanently delete:',
                style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            ...[
              'All tasks and reminders',
              'All expense records',
              'Your profile information',
              'All app preferences',
            ].map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Iconsax.minus,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text(s, style: AppTypography.bodySmall),
                  ]),
                )),
            const SizedBox(height: 12),
            Text('This action cannot be undone.',
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
            ),
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await DatabaseService.instance.deleteAllUserData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context)
          .showSnackBar(_snack('Account deleted successfully'));
      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          _snack('Failed to delete. Please try again.', isError: true));
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBR),
        title: Row(children: [
          const Icon(Iconsax.info_circle, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('About Promptus', style: AppTypography.titleLarge),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Version 2.0.0', style: AppTypography.bodyMedium),
              const SizedBox(height: 8),
              Text(
                'A premium productivity app to manage tasks and track expenses.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('Features',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.primary)),
              const SizedBox(height: 8),
              ...[
                'Task management with priorities',
                'Expense tracking with categories',
                'Smart notifications & alarms',
                'Analytics & insights',
                'Light / Dark / System theme',
              ].map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Iconsax.tick_circle,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(f, style: AppTypography.bodySmall),
                    ]),
                  )),
              const SizedBox(height: 12),
              Text('Built with Flutter & SQLite',
                  style: AppTypography.labelSmall.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.primary.withValues(alpha: 0.7))),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final completionRate = _totalTasks > 0
        ? (_completedTasks / _totalTasks * 100).toInt()
        : 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
        ),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2, color: cs.onSurface),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Profile',
          style: AppTypography.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          children: [
            // ── Hero card ────────────────────────────────────────────────
            _HeroCard(userName: _userName, onEditName: _showEditNameDialog)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // ── Stats row ────────────────────────────────────────────────
            Row(
              children: [
                _StatTile('Tasks', '$_totalTasks',
                    Iconsax.task_square, AppColors.primary, dark),
                const SizedBox(width: 12),
                _StatTile('Expenses', '$_totalExpenses',
                    Iconsax.wallet_2, AppColors.accent,
                    dark),
                const SizedBox(width: 12),
                _StatTile('Done', '$_completedTasks',
                    Iconsax.tick_circle, AppColors.success, dark),
              ],
            )
                .animate(delay: 60.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // ── Overview card ────────────────────────────────────────────
            _SectionCard(
              dark: dark,
              icon: Iconsax.element_4,
              title: 'Quick Overview',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _OverviewItem('Completion',
                      '$completionRate%', Iconsax.trend_up,
                      AppColors.success),
                  _OverviewItem('Total Spent',
                      '₵${_totalExpenseAmount.toStringAsFixed(0)}',
                      Iconsax.money_2, AppColors.error),
                  _OverviewItem('Pending', '$_pendingTasks',
                      Iconsax.clock, AppColors.warning),
                ],
              ),
            )
                .animate(delay: 120.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // ── Analytics button ─────────────────────────────────────────
            _AnalyticsButton(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => DemographicsScreen()));
              },
            )
                .animate(delay: 180.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // ── Theme toggle ─────────────────────────────────────────────
            _ThemeCard(dark: dark)
                .animate(delay: 240.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // ── Wake word ─────────────────────────────────────────────────
            _WakeWordCard(
              dark: dark,
              initialRunning: _wakeWordRunning,
              onStateChanged: (running) =>
                  setState(() => _wakeWordRunning = running),
            )
                .animate(delay: 270.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // ── Account + About ──────────────────────────────────────────
            _SectionCard(
              dark: dark,
              icon: Iconsax.profile_2user,
              title: 'Account',
              child: Column(
                children: [
                  _ActionTile(
                    icon: Iconsax.info_circle,
                    label: 'App Information',
                    subtitle: 'Version, features & credits',
                    color: AppColors.primary,
                    onTap: _showAboutDialog,
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Iconsax.trash,
                    label: 'Delete All Data',
                    subtitle: 'Permanently erase your account',
                    color: AppColors.error,
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // ── Brand footer ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.accent.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: AppRadius.xlBR,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text('Promptus',
                      style: AppTypography.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    'Track. Plan. Prosper.',
                    style: AppTypography.roboto(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            )
                .animate(delay: 360.ms)
                .fadeIn(duration: 350.ms),
          ],
        ),
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String userName;
  final VoidCallback onEditName;

  const _HeroCard({required this.userName, required this.onEditName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.accent],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: AppRadius.xlBR,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
            ),
            child: const Icon(Iconsax.user,
                size: 46, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: AppTypography.poppins(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Promptus User',
            style: AppTypography.roboto(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onEditName,
            icon: const Icon(Iconsax.edit, size: 16),
            label: const Text('Edit Name'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape:
                  RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
              elevation: 0,
              textStyle: AppTypography.labelLarge
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat tile ─────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool dark;

  const _StatTile(this.label, this.value, this.icon, this.color, this.dark);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.lgBR,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overview item ─────────────────────────────────────────────────────────────

class _OverviewItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewItem(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.smBR,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Analytics button ──────────────────────────────────────────────────────────

class _AnalyticsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AnalyticsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
        ),
        borderRadius: AppRadius.xlBR,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.xlBR,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.xlBR,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Iconsax.chart_1,
                    color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Analytics & Demographics',
                          style: AppTypography.titleMedium
                              .copyWith(color: Colors.white)),
                      Text('View detailed insights',
                          style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                Icon(Iconsax.arrow_right_3,
                    color: Colors.white.withValues(alpha: 0.7), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Theme card ────────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  final bool dark;

  const _ThemeCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    IconData modeIcon(AppThemeMode m) {
      switch (m) {
        case AppThemeMode.light:
          return Iconsax.sun_1;
        case AppThemeMode.dark:
          return Iconsax.moon;
        case AppThemeMode.system:
          return Iconsax.setting_2;
      }
    }

    String modeLabel(AppThemeMode m) {
      switch (m) {
        case AppThemeMode.light:
          return 'Light';
        case AppThemeMode.dark:
          return 'Dark';
        case AppThemeMode.system:
          return 'System';
      }
    }

    return _SectionCard(
      dark: dark,
      icon: Iconsax.paintbucket,
      title: 'Appearance',
      child: Row(
        children: AppThemeMode.values.map((mode) {
          final isSelected = themeService.mode == mode;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<ThemeService>().setMode(mode);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: AppRadius.mdBR,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (dark ? AppColors.darkBorder : AppColors.border),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        modeIcon(mode),
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        modeLabel(mode),
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.05),
      borderRadius: AppRadius.mdBR,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBR,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smBR,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTypography.titleMedium.copyWith(color: color)),
                    Text(subtitle,
                        style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Iconsax.arrow_right_3,
                  size: 14, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wake word card ────────────────────────────────────────────────────────────

class _WakeWordCard extends StatefulWidget {
  final bool dark;
  final bool initialRunning;
  final ValueChanged<bool> onStateChanged;

  const _WakeWordCard({
    required this.dark,
    required this.initialRunning,
    required this.onStateChanged,
  });

  @override
  State<_WakeWordCard> createState() => _WakeWordCardState();
}

class _WakeWordCardState extends State<_WakeWordCard> {
  late bool _running;
  bool _busy = false;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _running = widget.initialRunning;
    WakeWordService.isModelReady()
        .then((ready) { if (mounted) setState(() => _modelReady = ready); });
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      if (_running) {
        await WakeWordService.stop();
        setState(() => _running = false);
        widget.onStateChanged(false);
      } else {
        await WakeWordService.start();
        setState(() { _running = true; _modelReady = true; });
        widget.onStateChanged(true);
      }
    } on WakeWordError catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Iconsax.close_circle, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(msg,
                style:
                    AppTypography.bodySmall.copyWith(color: Colors.white))),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF7C3AED); // violet
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.dark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.xlBR,
        border: Border.all(
          color: _running
              ? accent.withValues(alpha: 0.5)
              : (widget.dark ? AppColors.darkBorder : AppColors.border),
          width: _running ? 1.5 : 1,
        ),
        boxShadow: AppShadows.level2(dark: widget.dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smBR,
                ),
                child: Icon(Iconsax.microphone, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wake Word', style: AppTypography.titleMedium),
                    Text(
                      _running
                          ? 'Listening for "Promptus"…'
                          : 'Say "Promptus" to open the app',
                      style: AppTypography.labelSmall.copyWith(
                        color: _running
                            ? accent
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Status dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _running
                      ? AppColors.success
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.3),
                  boxShadow: _running
                      ? [
                          BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.5),
                              blurRadius: 6)
                        ]
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Model status ──────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (_modelReady ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.08),
              borderRadius: AppRadius.smBR,
              border: Border.all(
                color: (_modelReady ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _modelReady
                      ? Iconsax.tick_circle
                      : Iconsax.receive_square,
                  size: 15,
                  color: _modelReady ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ready — uses Google Speech, no download needed',
                    style: AppTypography.labelSmall.copyWith(
                      color: _modelReady ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Toggle button ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _toggle,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(
                      _running ? Iconsax.stop_circle : Iconsax.microphone,
                      size: 18),
              label: Text(_running ? 'Stop Listening' : 'Start Listening'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _running ? AppColors.error : accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
                elevation: 0,
                textStyle: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Info note ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: AppRadius.smBR,
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Iconsax.info_circle, size: 14, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Powered by Google Speech Recognition — no setup needed. '
                    'A notification will appear when "Promptus" is heard.',
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared section card ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.dark,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.xlBR,
        border: Border.all(
            color: dark ? AppColors.darkBorder : AppColors.border),
        boxShadow: AppShadows.level2(dark: dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smBR,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
