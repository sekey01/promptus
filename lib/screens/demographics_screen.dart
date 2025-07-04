import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/theme_model.dart';
import '../services/database_service.dart';

class DemographicsScreen extends StatefulWidget {
  final ThemeModel themeModel;

  const DemographicsScreen({Key? key, required this.themeModel}) : super(key: key);

  @override
  _DemographicsScreenState createState() => _DemographicsScreenState();
}

class _DemographicsScreenState extends State<DemographicsScreen>
    with TickerProviderStateMixin {
  // Statistics
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _totalExpenses = 0;
  double _totalExpenseAmount = 0.0;
  double _monthlyExpenseAmount = 0.0;
  Map<String, double> _categoryTotals = {};
  bool _isLoading = true;

  late AnimationController _animationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final tasks = await DatabaseService.instance.getTasks();
      final expenses = await DatabaseService.instance.getExpenses();
      final totalAmount = await DatabaseService.instance.getTotalExpenses();
      final monthlyAmount = await DatabaseService.instance.getMonthlyExpenses();
      final categories = await DatabaseService.instance.getExpensesByCategory();

      setState(() {
        _totalTasks = tasks.length;
        _completedTasks = tasks.where((task) => task.isCompleted).length;
        _pendingTasks = tasks.where((task) => !task.isCompleted).length;
        _totalExpenses = expenses.length;
        _totalExpenseAmount = totalAmount;
        _monthlyExpenseAmount = monthlyAmount;
        _categoryTotals = categories;
        _isLoading = false;
      });

      _animationController.forward();
      _progressAnimationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  Widget _buildOverviewCards() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniCard(
                    'Total Items',
                    '${_totalTasks + _totalExpenses}',
                    Icons.inventory_rounded,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniCard(
                    'Completion Rate',
                    '${_totalTasks > 0 ? ((_completedTasks / _totalTasks) * 100).toInt() : 0}%',
                    Icons.trending_up_rounded,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniCard(
                    'Total Spent',
                    '₵${_totalExpenseAmount.toStringAsFixed(0)}',
                    Icons.account_balance_wallet_rounded,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskAnalytics() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 1.2),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.task_alt_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Task Analytics',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildProgressBar(
                          'Completed',
                          _completedTasks,
                          _totalTasks,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildProgressBar(
                          'Pending',
                          _pendingTasks,
                          _totalTasks,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpenseAnalytics() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 1.4),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, color: Colors.purple),
                      const SizedBox(width: 12),
                      Text(
                        'Expense Analytics',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Expenses',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                final animatedTotal = _totalExpenseAmount * _progressAnimation.value;
                                return Text(
                                  '₵${animatedTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This Month',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              '₵${_monthlyExpenseAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Records',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              '$_totalExpenses',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_categoryTotals.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 1.6),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      Text(
                        'Category Breakdown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._categoryTotals.entries.take(5).map((entry) {
                    final percentage = (_totalExpenseAmount > 0)
                        ? (entry.value / _totalExpenseAmount) * 100
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(entry.key),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    entry.key,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Text(
                                '₵${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: (percentage / 100) * _progressAnimation.value,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation(_getCategoryColor(entry.key)),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductivityInsights() {
    final completionRate = _totalTasks > 0 ? (_completedTasks / _totalTasks) * 100 : 0.0;
    final avgExpensePerRecord = _totalExpenses > 0 ? _totalExpenseAmount / _totalExpenses : 0.0;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 1.8),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Productivity Insights',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInsightItem(
                    '📊',
                    'Task Completion Rate',
                    '${completionRate.toStringAsFixed(1)}% - ${_getCompletionInsight(completionRate)}',
                  ),
                  _buildInsightItem(
                    '💰',
                    'Average Expense',
                    '₵${avgExpensePerRecord.toStringAsFixed(2)} per record',
                  ),
                  _buildInsightItem(
                    '📈',
                    'Most Expensive Category',
                    _getMostExpensiveCategory(),
                  ),
                  _buildInsightItem(
                    '🎯',
                    'Productivity Score',
                    '${_getProductivityScore().toStringAsFixed(0)}/100 - ${_getProductivityLevel()}',
                  ),
                  _buildInsightItem(
                    '📅',
                    'Usage Pattern',
                    _getUsagePattern(),
                  ),
                  _buildInsightItem(
                    '🏆',
                    'Achievement Status',
                    _getAchievementStatus(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: percentage * _progressAnimation.value,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
            );
          },
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food & Dining': Colors.orange,
      'Transportation': Colors.blue,
      'Shopping': Colors.purple,
      'Entertainment': Colors.red,
      'Bills & Utilities': Colors.green,
      'Healthcare': Colors.teal,
      'Education': Colors.indigo,
      'Travel': Colors.amber,
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  String _getCompletionInsight(double rate) {
    if (rate >= 80) return 'Excellent productivity!';
    if (rate >= 60) return 'Good progress';
    if (rate >= 40) return 'Room for improvement';
    return 'Focus on completing tasks';
  }

  String _getMostExpensiveCategory() {
    if (_categoryTotals.isEmpty) return 'No expenses recorded';

    final maxEntry = _categoryTotals.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
    );
    return '${maxEntry.key} (₵${maxEntry.value.toStringAsFixed(2)})';
  }

  double _getProductivityScore() {
    double score = 0;

    // Task completion contributes 60%
    if (_totalTasks > 0) {
      score += (_completedTasks / _totalTasks) * 60;
    }

    // Having both tasks and expenses contributes 20%
    if (_totalTasks > 0 && _totalExpenses > 0) {
      score += 20;
    }

    // Consistent usage (having multiple records) contributes 20%
    if ((_totalTasks + _totalExpenses) >= 10) {
      score += 20;
    } else if ((_totalTasks + _totalExpenses) >= 5) {
      score += 10;
    }

    return score;
  }

  String _getProductivityLevel() {
    final score = _getProductivityScore();
    if (score >= 80) return 'Highly Productive';
    if (score >= 60) return 'Productive';
    if (score >= 40) return 'Moderately Active';
    return 'Getting Started';
  }

  String _getUsagePattern() {
    final totalItems = _totalTasks + _totalExpenses;
    if (totalItems >= 50) return 'Power User - Very Active';
    if (totalItems >= 20) return 'Regular User - Consistent';
    if (totalItems >= 10) return 'Casual User - Moderate';
    if (totalItems >= 5) return 'New User - Getting Started';
    return 'Beginner - Just Started';
  }

  String _getAchievementStatus() {
    if (_completedTasks >= 50) return 'Task Master - 50+ completed tasks!';
    if (_completedTasks >= 25) return 'Task Expert - 25+ completed tasks';
    if (_completedTasks >= 10) return 'Task Achiever - 10+ completed tasks';
    if (_completedTasks >= 5) return 'Task Starter - 5+ completed tasks';
    return 'Just Getting Started';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Analytics & Demographics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadAnalyticsData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analyzing your data...',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadAnalyticsData,
        color: Theme.of(context).colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header Description
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.deepOrange.shade500,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detailed Analytics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Insights into your productivity patterns',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildOverviewCards(),
              const SizedBox(height: 20),
              _buildTaskAnalytics(),
              _buildExpenseAnalytics(),
              _buildCategoryBreakdown(),
              _buildProductivityInsights(),
            ],
          ),
        ),
      ),
    );
  }
}