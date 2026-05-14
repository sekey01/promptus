import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/loading_shimmer.dart';
import '../services/database_service.dart';

class DemographicsScreen extends StatefulWidget {
  const DemographicsScreen({super.key});

  @override
  State<DemographicsScreen> createState() => _DemographicsScreenState();
}

class _DemographicsScreenState extends State<DemographicsScreen>
    with SingleTickerProviderStateMixin {
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _totalExpenses = 0;
  double _totalExpenseAmount = 0.0;
  double _monthlyExpenseAmount = 0.0;
  Map<String, double> _categoryTotals = {};
  bool _isLoading = true;

  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnim = CurvedAnimation(
        parent: _progressCtrl, curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final totalAmount =
          await DatabaseService.instance.getTotalExpenses();
      final monthlyAmount =
          await DatabaseService.instance.getMonthlyExpenses();
      final categories =
          await DatabaseService.instance.getExpensesByCategory();
      final db = Provider.of<DatabaseService>(context, listen: false);
      if (!mounted) return;
      setState(() {
        _totalTasks = db.tasks.length;
        _completedTasks = db.tasks.where((t) => t.isCompleted).length;
        _pendingTasks = db.tasks.where((t) => !t.isCompleted).length;
        _totalExpenses = db.expenses.length;
        _totalExpenseAmount = totalAmount;
        _monthlyExpenseAmount = monthlyAmount;
        _categoryTotals = categories;
        _isLoading = false;
      });
      _progressCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  // ── Insight helpers ────────────────────────────────────────────────────────

  String _completionInsight(double rate) {
    if (rate >= 80) return 'Excellent productivity!';
    if (rate >= 60) return 'Good progress';
    if (rate >= 40) return 'Room for improvement';
    return 'Focus on completing tasks';
  }

  String _mostExpensiveCategory() {
    if (_categoryTotals.isEmpty) return 'No expenses recorded';
    final max = _categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${max.key} (₵${max.value.toStringAsFixed(2)})';
  }

  double _productivityScore() {
    double score = 0;
    if (_totalTasks > 0) score += (_completedTasks / _totalTasks) * 60;
    if (_totalTasks > 0 && _totalExpenses > 0) score += 20;
    final total = _totalTasks + _totalExpenses;
    if (total >= 10) score += 20;
    else if (total >= 5) score += 10;
    return score;
  }

  String _productivityLevel() {
    final s = _productivityScore();
    if (s >= 80) return 'Highly Productive';
    if (s >= 60) return 'Productive';
    if (s >= 40) return 'Moderately Active';
    return 'Getting Started';
  }

  String _usagePattern() {
    final total = _totalTasks + _totalExpenses;
    if (total >= 50) return 'Power User — Very Active';
    if (total >= 20) return 'Regular User — Consistent';
    if (total >= 10) return 'Casual User — Moderate';
    if (total >= 5) return 'New User — Getting Started';
    return 'Beginner — Just Started';
  }

  String _achievementStatus() {
    if (_completedTasks >= 50) return 'Task Master — 50+ tasks done!';
    if (_completedTasks >= 25) return 'Task Expert — 25+ tasks done';
    if (_completedTasks >= 10) return 'Task Achiever — 10+ tasks done';
    if (_completedTasks >= 5) return 'Task Starter — 5+ tasks done';
    return 'Just Getting Started';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final completionRate =
        _totalTasks > 0 ? (_completedTasks / _totalTasks) * 100.0 : 0.0;

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
          'Analytics',
          style: AppTypography.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh_2, color: AppColors.primary),
            onPressed: () {
              HapticFeedback.lightImpact();
              _load();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingShimmer()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  children: [
                    // ── Hero ─────────────────────────────────────────────
                    _HeroBanner()
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),

                    // ── Overview row ──────────────────────────────────────
                    Row(
                      children: [
                        _MiniStat(
                            'Total Items',
                            '${_totalTasks + _totalExpenses}',
                            Iconsax.box,
                            AppColors.primary,
                            dark),
                        const SizedBox(width: 12),
                        _MiniStat(
                            'Completion',
                            '${completionRate.toInt()}%',
                            Iconsax.trend_up,
                            AppColors.success,
                            dark),
                        const SizedBox(width: 12),
                        _MiniStat(
                            'Total Spent',
                            '₵${_totalExpenseAmount.toStringAsFixed(0)}',
                            Iconsax.wallet_2,
                            AppColors.accent,
                            dark),
                      ],
                    )
                        .animate(delay: 60.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),

                    // ── Task analytics ────────────────────────────────────
                    _AnalyticsCard(
                      dark: dark,
                      icon: Iconsax.task_square,
                      iconColor: AppColors.primary,
                      title: 'Task Analytics',
                      child: Row(
                        children: [
                          Expanded(
                            child: _AnimatedBar(
                              label: 'Completed',
                              value: _completedTasks,
                              total: _totalTasks,
                              color: AppColors.success,
                              animation: _progressAnim,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _AnimatedBar(
                              label: 'Pending',
                              value: _pendingTasks,
                              total: _totalTasks,
                              color: AppColors.warning,
                              animation: _progressAnim,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 120.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),

                    // ── Expense analytics ─────────────────────────────────
                    _AnalyticsCard(
                      dark: dark,
                      icon: Iconsax.wallet_2,
                      iconColor: AppColors.accent,
                      title: 'Expense Analytics',
                      child: Row(
                        children: [
                          _ExpenseFigure('Total',
                              _totalExpenseAmount, AppColors.error, _progressAnim),
                          _ExpenseFigure('This Month',
                              _monthlyExpenseAmount, AppColors.success, null),
                          _ExpenseFigure('Records',
                              _totalExpenses.toDouble(), AppColors.primary, null,
                              isInt: true),
                        ],
                      ),
                    )
                        .animate(delay: 180.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),

                    // ── Category breakdown ────────────────────────────────
                    if (_categoryTotals.isNotEmpty) ...[
                      _AnalyticsCard(
                        dark: dark,
                        icon: Iconsax.chart_21,
                        iconColor: AppColors.warning,
                        title: 'Category Breakdown',
                        child: Column(
                          children:
                              _categoryTotals.entries.take(5).map((e) {
                            final pct = _totalExpenseAmount > 0
                                ? e.value / _totalExpenseAmount
                                : 0.0;
                            final color = AppColors.categoryColor(e.key);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(e.key,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                      ),
                                      Text(
                                        '₵${e.value.toStringAsFixed(2)} '
                                        '(${(pct * 100).toStringAsFixed(1)}%)',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                                color: cs.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedBuilder(
                                    animation: _progressAnim,
                                    builder: (_, __) =>
                                        ClipRRect(
                                          borderRadius: AppRadius.fullBR,
                                          child: LinearProgressIndicator(
                                            value: pct * _progressAnim.value,
                                            minHeight: 6,
                                            backgroundColor: color
                                                .withValues(alpha: 0.12),
                                            valueColor:
                                                AlwaysStoppedAnimation(color),
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      )
                          .animate(delay: 240.ms)
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                    ],

                    // ── Insights ──────────────────────────────────────────
                    _AnalyticsCard(
                      dark: dark,
                      icon: Iconsax.lamp_on,
                      iconColor: AppColors.primary,
                      title: 'Productivity Insights',
                      isGradient: true,
                      child: Column(
                        children: [
                          _InsightRow('Task Completion',
                              '${completionRate.toStringAsFixed(1)}% — ${_completionInsight(completionRate)}'),
                          _InsightRow('Avg Expense',
                              _totalExpenses > 0
                                  ? '₵${(_totalExpenseAmount / _totalExpenses).toStringAsFixed(2)} per record'
                                  : 'No expenses yet'),
                          _InsightRow('Top Category',
                              _mostExpensiveCategory()),
                          _InsightRow('Productivity',
                              '${_productivityScore().toStringAsFixed(0)}/100 — ${_productivityLevel()}'),
                          _InsightRow('Usage', _usagePattern()),
                          _InsightRow('Achievement',
                              _achievementStatus()),
                        ],
                      ),
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Hero banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          const Icon(Iconsax.chart_1,
              color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detailed Analytics',
                    style: AppTypography.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(
                  'Insights into your productivity patterns',
                  style: AppTypography.roboto(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini stat ─────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool dark;

  const _MiniStat(this.label, this.value, this.icon, this.color, this.dark);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.lgBR,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.poppins(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Analytics card shell ──────────────────────────────────────────────────────

class _AnalyticsCard extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final bool isGradient;

  const _AnalyticsCard({
    required this.dark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.isGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isGradient
            ? LinearGradient(colors: [
                AppColors.primary.withValues(alpha: 0.07),
                AppColors.accent.withValues(alpha: 0.07),
              ])
            : null,
        color: isGradient ? null : (dark ? AppColors.darkSurface : AppColors.surface),
        borderRadius: AppRadius.xlBR,
        border: Border.all(
            color: isGradient
                ? AppColors.primary.withValues(alpha: 0.2)
                : (dark ? AppColors.darkBorder : AppColors.border)),
        boxShadow: isGradient ? null : AppShadows.level2(dark: dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smBR,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ── Animated progress bar ─────────────────────────────────────────────────────

class _AnimatedBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final Animation<double> animation;

  const _AnimatedBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTypography.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
            Text(
              '$value',
              style: AppTypography.bodySmall
                  .copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: animation,
          builder: (_, __) => ClipRRect(
            borderRadius: AppRadius.fullBR,
            child: LinearProgressIndicator(
              value: pct * animation.value,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Expense figure ────────────────────────────────────────────────────────────

class _ExpenseFigure extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final Animation<double>? animation;
  final bool isInt;

  const _ExpenseFigure(this.label, this.value, this.color, this.animation,
      {this.isInt = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          animation != null
              ? AnimatedBuilder(
                  animation: animation!,
                  builder: (_, __) {
                    final v = value * animation!.value;
                    return Text(
                      isInt ? '${v.toInt()}' : '₵${v.toStringAsFixed(2)}',
                      style: AppTypography.amountSmall.copyWith(color: color),
                    );
                  },
                )
              : Text(
                  isInt
                      ? '${value.toInt()}'
                      : '₵${value.toStringAsFixed(2)}',
                  style: AppTypography.amountSmall.copyWith(color: color),
                ),
        ],
      ),
    );
  }
}

// ── Insight row ───────────────────────────────────────────────────────────────

class _InsightRow extends StatelessWidget {
  final String title;
  final String description;

  const _InsightRow(this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
