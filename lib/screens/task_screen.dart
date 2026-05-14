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
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/task_item.dart';
import 'add_task_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen>
    with AutomaticKeepAliveClientMixin {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await NotificationService.instance.requestPermissions();
    if (!mounted) return;
    final db = Provider.of<DatabaseService>(context, listen: false);
    setState(() => _isLoading = true);
    await db.loadTasks();
    if (!mounted) return;
    setState(() {
      _tasks = db.tasks;
      _isLoading = false;
    });
  }

  Future<void> _toggle(Task task) async {
    HapticFeedback.lightImpact();
    task.isCompleted = !task.isCompleted;
    await DatabaseService.instance.updateTask(task);
    _load();
  }

  Future<void> _delete(Task task) async {
    HapticFeedback.mediumImpact();
    await DatabaseService.instance.deleteTask(task.id!);
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Text('Task deleted',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const LoadingShimmer();

    if (_tasks.isEmpty) {
      return EmptyState(
        icon: Iconsax.task_square,
        title: 'No tasks yet',
        subtitle:
            'Create your first task and start\nyour productive day.',
        buttonLabel: 'Create First Task',
        onAction: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddTaskScreen()));
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
          SliverToBoxAdapter(
            child: _ProgressCard(tasks: _tasks)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            sliver: SliverList.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, i) => TaskItem(
                task: _tasks[i],
                onTap: () => _toggle(_tasks[i]),
                onDelete: () => _delete(_tasks[i]),
                onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddTaskScreen(task: _tasks[i])),
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

// ── Progress hero card ────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final List<Task> tasks;

  const _ProgressCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    final pct = total > 0 ? completed / total : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.xlBR,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Counts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: AppRadius.fullBR,
                        ),
                        child: Text(
                          "Today's Progress",
                          style: AppTypography.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '$completed of $total',
                        style: AppTypography.poppins(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'tasks completed',
                        style: AppTypography.roboto(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Circular progress
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      Text(
                        '${(pct * 100).toInt()}%',
                        style: AppTypography.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 20),
              _WeeklyBar(),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeeklyBar extends StatelessWidget {
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday - 1; // 0 = Mon
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
        const SizedBox(height: 14),
        Text(
          '7-Day Activity',
          style: AppTypography.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.8),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (i) {
            final isToday = i == today;
            // Placeholder heights — future: query actual daily completion
            final heights = [0.4, 0.6, 0.5, 0.8, 0.7, 0.3, 0.9];
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: AppRadius.xsBR,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: heights[i],
                        child: Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.65),
                            borderRadius: AppRadius.xsBR,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _days[i],
                      style: AppTypography.roboto(
                        fontSize: 10,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
