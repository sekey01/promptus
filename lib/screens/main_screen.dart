import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_typography.dart';
import '../services/theme_service.dart';
import 'add_expenses_screen.dart';
import 'add_note_screen.dart';
import 'add_task_screen.dart';
import 'expenses_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import 'task_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFabPressed() {
    HapticFeedback.mediumImpact();
    if (_selectedIndex == 0) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
    } else if (_selectedIndex == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
    } else {
      // Notes tab — show action sheet: New Note or New Folder
      _showNotesAction();
    }
  }

  void _showNotesAction() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotesActionSheet(
        onNewNote: () {
          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AddNoteScreen()));
        },
        onNewFolder: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => const NewFolderSheet(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(dark, cs),
      body: TabBarView(
        controller: _tabController,
        children: const [ExpensesScreen(), TaskScreen(), NotesScreen()],
      ),
      floatingActionButton: _buildFab(cs),
    );
  }

  PreferredSizeWidget _buildAppBar(bool dark, ColorScheme cs) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      ),
      titleSpacing: 20,
      title: Text(
        'Promptus',
        style: AppTypography.poppins(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        _ActionChip(
          icon: _themeIcon(context.watch<ThemeService>().mode),
          onTap: () => context.read<ThemeService>().cycleMode(),
        ),
        const SizedBox(width: 8),
        _ActionChip(
          icon: Iconsax.user,
          onTap: () async {
            HapticFeedback.lightImpact();
            await Navigator.push(
                context, MaterialPageRoute(builder: (_) => ProfileScreen()));
          },
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _buildTabBar(dark, cs),
      ),
    );
  }

  IconData _themeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Iconsax.sun_1;
      case AppThemeMode.dark:
        return Iconsax.moon;
      case AppThemeMode.system:
        return Iconsax.setting_2;
    }
  }

  Widget _buildTabBar(bool dark, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: AppRadius.lgBR,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient:
              dark ? AppColors.darkPrimaryGradient : AppColors.primaryGradient,
          borderRadius: AppRadius.mdBR,
        ),
        indicatorPadding: EdgeInsets.zero,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: AppTypography.labelMedium
            .copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.labelMedium,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.wallet_2, size: 16),
                SizedBox(width: 6),
                Text('Expenses'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.task_square, size: 16),
                SizedBox(width: 6),
                Text('Tasks'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.note_text, size: 16),
                SizedBox(width: 6),
                Text('Notes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(ColorScheme cs) {
    final labels = ['Add Expense', 'Add Task', 'New'];
    final icons = [Iconsax.add, Iconsax.add_square, Iconsax.add];

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.xlBR,
      ),
      child: FloatingActionButton.extended(
        onPressed: _onFabPressed,
        icon: Icon(icons[_selectedIndex], size: 22),
        label: Text(
          labels[_selectedIndex],
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBR),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: dark
              ? AppColors.darkSurfaceVariant
              : AppColors.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}

// ── Notes action sheet ───────────────────────────────────────────────────────

class _NotesActionSheet extends StatelessWidget {
  final VoidCallback onNewNote;
  final VoidCallback onNewFolder;

  const _NotesActionSheet(
      {required this.onNewNote, required this.onNewFolder});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _SheetAction(
            icon: Iconsax.note_add,
            label: 'New Note',
            onTap: onNewNote,
            cs: cs,
          ),
          const SizedBox(height: 12),
          _SheetAction(
            icon: Iconsax.folder_add,
            label: 'New Folder',
            onTap: onNewFolder,
            cs: cs,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _SheetAction(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
      borderRadius: AppRadius.mdBR,
      child: InkWell(
        borderRadius: AppRadius.mdBR,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(width: 14),
              Text(label,
                  style: AppTypography.bodyMedium
                      .copyWith(color: cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}
