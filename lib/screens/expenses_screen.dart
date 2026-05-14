import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/loading_shimmer.dart';
import '../core/widgets/promptus_card.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import '../widgets/expense_widget.dart';
import 'add_expenses_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with AutomaticKeepAliveClientMixin {
  List<Expense> _expenses = [];
  bool _isLoading = true;
  double _totalExpenses = 0;
  double _monthlyExpenses = 0;
  Map<String, double> _categoryTotals = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await db.loadExpenses();
      final total = await db.getTotalExpenses();
      final monthly = await db.getMonthlyExpenses();
      final cats = await db.getExpensesByCategory();
      if (!mounted) return;
      setState(() {
        _expenses = db.expenses;
        _totalExpenses = total;
        _monthlyExpenses = monthly;
        _categoryTotals = cats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(Expense e) async {
    HapticFeedback.mediumImpact();
    await DatabaseService.instance.deleteExpense(e.id!);
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(_snack('Expense deleted'));
  }

  SnackBar _snack(String msg, {bool isError = false}) => SnackBar(
        content: Row(children: [
          Icon(
            isError ? Iconsax.close_circle : Iconsax.tick_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(msg, style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
        ]),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
        margin: const EdgeInsets.all(16),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const LoadingShimmer();

    if (_expenses.isEmpty) {
      return EmptyState(
        icon: Iconsax.wallet_2,
        title: 'No expenses yet',
        subtitle: 'Start tracking your spending\nto better manage your finances.',
        buttonLabel: 'Add First Expense',
        onAction: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
          _load();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _SummaryCard(
            total: _totalExpenses,
            monthly: _monthlyExpenses,
            count: _expenses.length,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0)),

          if (_categoryTotals.isNotEmpty)
            SliverToBoxAdapter(
              child: _CategoryBreakdown(totals: _categoryTotals)
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            sliver: SliverList.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, i) => ExpenseItem(
                expense: _expenses[i],
                onDelete: () => _delete(_expenses[i]),
                onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddExpenseScreen(expense: _expenses[i])),
                  );
                  _load();
                },
              )
                  .animate(delay: Duration(milliseconds: 60 * i))
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary hero card ─────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double total;
  final double monthly;
  final int count;

  const _SummaryCard(
      {required this.total, required this.monthly, required this.count});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Expenses',
                      style: AppTypography.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₵${total.toStringAsFixed(2)}',
                      style: AppTypography.amountLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This month: ₵${monthly.toStringAsFixed(2)}',
                      style: AppTypography.roboto(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25), width: 2),
                ),
                child: const Icon(
                  Iconsax.wallet_2,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Iconsax.receipt_2,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                '$count expense${count == 1 ? '' : 's'} recorded',
                style: AppTypography.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category breakdown ────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, double> totals;

  const _CategoryBreakdown({required this.totals});

  @override
  Widget build(BuildContext context) {
    return PromptusCard(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smBR,
                ),
                child: const Icon(Iconsax.chart_21,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 12),
              Text('By Category', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          ...totals.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.categoryColor(e.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.key,
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      '₵${e.value.toStringAsFixed(2)}',
                      style: AppTypography.amountSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
