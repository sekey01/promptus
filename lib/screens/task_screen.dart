import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:promptus/services/notification_service.dart';
import '../models/task_model.dart';
import '../models/theme_model.dart';
import '../services/database_service.dart';
import '../widgets/task_item.dart';
import 'add_task_screen.dart';
import 'profile_screen.dart';

class TaskScreen extends StatefulWidget {
  final ThemeModel themeModel;

  const TaskScreen({Key? key, required this.themeModel}) : super(key: key);

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen>
    with TickerProviderStateMixin {
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  late AnimationController _animationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _progressAnimation;

  // Weekly progress data for trend
  List<double> _weeklyProgress = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
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

    _loadTasks();
    _loadWeeklyProgress();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    if (!_isRefreshing) {
      await NotificationService.instance.requestPermissions();
    }

    if (!_isRefreshing) setState(() => _isLoading = true);

    final tasks = await DatabaseService.instance.getTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
      _isRefreshing = false;
    });

    if (!_isRefreshing) {
      _animationController.forward();
      _progressAnimationController.forward();
    }
  }

  Future<void> _refreshTasks() async {
    setState(() => _isRefreshing = true);
    HapticFeedback.lightImpact();

    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    await _loadTasks();
    await _loadWeeklyProgress();

    // Reset animations for refresh
    _progressAnimationController.reset();
    _progressAnimationController.forward();
  }

  Future<void> _loadWeeklyProgress() async {
    // Simulate weekly progress data - you can implement actual database queries here
    final now = DateTime.now();
    List<double> progress = [];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      // For demo purposes, generating sample data
      // In real implementation, query tasks completed on each day
      final dayProgress = (day.weekday * 0.1 + (i * 0.05)) % 1.0;
      progress.add(dayProgress.clamp(0.0, 1.0));
    }

    setState(() {
      _weeklyProgress = progress;
    });
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    HapticFeedback.lightImpact();

    task.isCompleted = !task.isCompleted;
    await DatabaseService.instance.updateTask(task);
    _loadTasks();
    _loadWeeklyProgress(); // Update weekly progress when task status changes
  }

  Future<void> _deleteTask(Task task) async {
    HapticFeedback.mediumImpact();

    await DatabaseService.instance.deleteTask(task.id!);
    _loadTasks();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Task deleted successfully'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildWeeklyTrendBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Progress Trend',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isToday = index == 6;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white.withOpacity(0.15),
                        ),
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.bottomCenter,
                              heightFactor: _weeklyProgress[index] * _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: isToday
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _weekDays[index],
                        style: TextStyle(
                          color: isToday
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final completedTasks = _tasks.where((task) => task.isCompleted).length;
    final totalTasks = _tasks.length;
    final progressPercentage = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.9),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Today\'s Progress',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '$completedTasks of $totalTasks',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'tasks completed',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: AnimatedBuilder(
                                    animation: _progressAnimation,
                                    builder: (context, child) {
                                      return CircularProgressIndicator(
                                        value: progressPercentage * _progressAnimation.value,
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 6,
                                        strokeCap: StrokeCap.round,
                                      );
                                    },
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _progressAnimation,
                                  builder: (context, child) {
                                    return Text(
                                      '${((progressPercentage * _progressAnimation.value) * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (totalTasks > 0)
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: _buildWeeklyTrendBar(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade50,
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.task_alt_rounded,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'No Tasks Yet',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Start your productive day by creating your first task. Every great journey begins with a single step.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.6,
                      letterSpacing: 0.1,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddTaskScreen()),
                      );
                      _loadTasks();
                    },
                    icon: const Icon(Icons.add_rounded, size: 22),
                    label: const Text(
                      'Create Your First Task',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasksList() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value * (index + 1) * 0.05),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: TaskItem(
                      task: _tasks[index],
                      onTap: () => _toggleTaskCompletion(_tasks[index]),
                      onDelete: () => _deleteTask(_tasks[index]),
                      onEdit: () async {
                        HapticFeedback.lightImpact();
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTaskScreen(task: _tasks[index]),
                          ),
                        );
                        _loadTasks();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalTasks = _tasks.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
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
              'Loading your tasks...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshTasks,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.white,
        displacement: 60,
        strokeWidth: 3,
        child: Column(
          children: [
            if (totalTasks > 0) _buildProgressCard(),
            Expanded(
              child: _tasks.isEmpty
                  ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: _buildEmptyState(),
                ),
              )
                  : _buildTasksList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _isLoading
          ? null
          : Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTaskScreen()),
            );
            _loadTasks();
          },
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'Add Task',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}