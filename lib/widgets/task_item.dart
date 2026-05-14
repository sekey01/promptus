import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_typography.dart';
import '../models/task_model.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  Color _priorityColor() => task.priority == 3
      ? AppColors.error
      : task.priority == 2
          ? AppColors.warning
          : AppColors.success;

  String _priorityLabel() => ['', 'Low', 'Medium', 'High'][task.priority.clamp(1, 3)];

  void _showOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskOptionsSheet(
        onEdit: () {
          Navigator.pop(context);
          onEdit();
        },
        onDelete: () {
          Navigator.pop(context);
          _confirm(context);
        },
      ),
    );
  }

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBR),
        title: Text('Delete Task', style: AppTypography.titleLarge),
        content: Text(
          'Delete "${task.title}"? This cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pColor = _priorityColor();
    final completed = task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.xlBR,
        border: Border.all(
          color: completed
              ? AppColors.success.withValues(alpha: 0.3)
              : (dark ? AppColors.darkBorder : AppColors.border),
        ),
        boxShadow: AppShadows.level2(dark: dark),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.xlBR,
        child: InkWell(
          onTap: () => _showOptions(context),
          borderRadius: AppRadius.xlBR,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed ? AppColors.success : Colors.transparent,
                      border: Border.all(
                        color: completed
                            ? AppColors.success
                            : (dark ? AppColors.darkBorder : AppColors.border),
                        width: 2,
                      ),
                    ),
                    child: completed
                        ? const Icon(Iconsax.tick_circle,
                            size: 15, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: AppTypography.titleMedium.copyWith(
                                color: completed
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.45)
                                    : Theme.of(context).colorScheme.onSurface,
                                decoration: completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.45),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PriorityBadge(
                              label: _priorityLabel(), color: pColor),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          task.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(
                                    alpha: completed ? 0.4 : 0.75),
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (task.reminderTime != null) ...[
                            Icon(Iconsax.alarm,
                                size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${task.reminderTime!.day}/${task.reminderTime!.month} '
                              '${task.reminderTime!.hour.toString().padLeft(2, '0')}:'
                              '${task.reminderTime!.minute.toString().padLeft(2, '0')}',
                              style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(Iconsax.calendar_1,
                              size: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                            style: AppTypography.labelSmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Iconsax.more,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.fullBR,
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _TaskOptionsSheet extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskOptionsSheet({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.xxlBR,
        border: Border.all(
            color: dark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.3),
              borderRadius: AppRadius.fullBR,
            ),
          ),
          _SheetTile(
            icon: Iconsax.edit,
            label: 'Edit Task',
            color: AppColors.primary,
            onTap: onEdit,
          ),
          _SheetTile(
            icon: Iconsax.trash,
            label: 'Delete Task',
            color: AppColors.error,
            onTap: onDelete,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppRadius.mdBR,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: AppTypography.titleMedium.copyWith(color: color)),
        trailing: Icon(Iconsax.arrow_right_3,
            size: 14, color: color.withValues(alpha: 0.5)),
      );
}
