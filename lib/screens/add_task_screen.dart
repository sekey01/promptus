import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_typography.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;

  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _reminderTime;
  int _priority = 1;
  bool _isAlarmStyle = true;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.task != null;
    if (_isEditing) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _reminderTime = widget.task!.reminderTime;
      _priority = widget.task!.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _priorityColor(int p) => p == 3
      ? AppColors.error
      : p == 2
          ? AppColors.warning
          : AppColors.success;

  String _priorityLabel(int p) =>
      ['', 'Low', 'Medium', 'High'][p.clamp(1, 3)];

  Future<void> _selectReminderTime() async {
    HapticFeedback.lightImpact();
    final date = await showDatePicker(
      context: context,
      initialDate:
          _reminderTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _reminderTime ?? DateTime.now().add(const Duration(hours: 1))),
    );
    if (time == null) return;
    setState(() {
      _reminderTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    final db = Provider.of<DatabaseService>(context, listen: false);
    final task = Task(
      id: _isEditing ? widget.task!.id : null,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      reminderTime: _reminderTime,
      priority: _priority,
      isCompleted: _isEditing ? widget.task!.isCompleted : false,
    );

    if (_isEditing) {
      await db.updateTask(task);
      await db.loadTasks();
    } else {
      final id = await db.addTask(task);
      await db.loadTasks();
      task.id = id;
    }

    if (_reminderTime != null && _reminderTime!.isAfter(DateTime.now())) {
      final success =
          await NotificationService.instance.scheduleNotification(
        id: task.id!,
        title: task.title,
        body: task.description,
        scheduledTime: _reminderTime!,
        payload: 'task_${task.id}',
        isAlarmStyle: _isAlarmStyle,
      );
      if (!mounted) return;
      final type = _isAlarmStyle ? 'alarm' : 'reminder';
      ScaffoldMessenger.of(context).showSnackBar(
        _snack(
          success
              ? 'Task saved with $type set'
              : 'Task saved — reminder could not be scheduled',
          isError: !success,
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  SnackBar _snack(String msg, {bool isError = false}) => SnackBar(
        content: Row(children: [
          Icon(
            isError ? Iconsax.warning_2 : Iconsax.tick_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(msg,
                  style:
                      AppTypography.bodyMedium.copyWith(color: Colors.white))),
        ]),
        backgroundColor: isError ? AppColors.warning : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

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
          _isEditing ? 'Edit Task' : 'Create Task',
          style: AppTypography.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: _save,
              icon: Icon(
                  _isEditing ? Iconsax.refresh : Iconsax.save_2,
                  size: 18),
              label: Text(_isEditing ? 'Update' : 'Save'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBR),
                textStyle: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _TaskDetailsCard(dark: dark,
                titleController: _titleController,
                descriptionController: _descriptionController,
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              _PriorityCard(
                dark: dark,
                priority: _priority,
                priorityColor: _priorityColor,
                priorityLabel: _priorityLabel,
                onSelect: (p) => setState(() => _priority = p),
              )
                  .animate(delay: 60.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              _ReminderCard(
                dark: dark,
                reminderTime: _reminderTime,
                isAlarmStyle: _isAlarmStyle,
                onSetReminder: _selectReminderTime,
                onClearReminder: () => setState(() => _reminderTime = null),
                onAlarmToggle: (v) => setState(() => _isAlarmStyle = v),
              )
                  .animate(delay: 120.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Task details card ─────────────────────────────────────────────────────────

class _TaskDetailsCard extends StatelessWidget {
  final bool dark;
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  const _TaskDetailsCard({
    required this.dark,
    required this.titleController,
    required this.descriptionController,
  });

  InputDecoration _input(BuildContext context, String label, String hint,
      IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      border: OutlineInputBorder(borderRadius: AppRadius.lgBR),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgBR,
        borderSide: BorderSide(
            color: dark ? AppColors.darkBorder : AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgBR,
        borderSide:
            const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgBR,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgBR,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      filled: true,
      fillColor:
          dark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
      labelStyle: AppTypography.bodyMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant),
      hintStyle: AppTypography.bodyMedium.copyWith(
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      dark: dark,
      icon: Iconsax.task_square,
      title: 'Task Details',
      child: Column(
        children: [
          TextFormField(
            controller: titleController,
            style: AppTypography.bodyMedium,
            decoration: _input(context, 'Task Title',
                'Enter a descriptive task title', Iconsax.text),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Title is required'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: descriptionController,
            style: AppTypography.bodyMedium,
            maxLines: 3,
            decoration: _input(
                context,
                'Description (Optional)',
                'Add more details about your task...',
                Iconsax.note),
          ),
        ],
      ),
    );
  }
}

// ── Priority card ─────────────────────────────────────────────────────────────

class _PriorityCard extends StatelessWidget {
  final bool dark;
  final int priority;
  final Color Function(int) priorityColor;
  final String Function(int) priorityLabel;
  final ValueChanged<int> onSelect;

  const _PriorityCard({
    required this.dark,
    required this.priority,
    required this.priorityColor,
    required this.priorityLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      dark: dark,
      icon: Iconsax.flag_2,
      title: 'Priority Level',
      child: Row(
        children: [1, 2, 3].map((p) {
          final isSelected = priority == p;
          final color = priorityColor(p);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelect(p);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: AppRadius.mdBR,
                    border: Border.all(
                      color: isSelected
                          ? color
                          : (dark ? AppColors.darkBorder : AppColors.border),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isSelected
                            ? Iconsax.tick_circle
                            : Iconsax.record_circle,
                        color: isSelected
                            ? color
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priorityLabel(p),
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? color
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

// ── Reminder card ─────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final bool dark;
  final DateTime? reminderTime;
  final bool isAlarmStyle;
  final VoidCallback onSetReminder;
  final VoidCallback onClearReminder;
  final ValueChanged<bool> onAlarmToggle;

  const _ReminderCard({
    required this.dark,
    required this.reminderTime,
    required this.isAlarmStyle,
    required this.onSetReminder,
    required this.onClearReminder,
    required this.onAlarmToggle,
  });

  String _format(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} at '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hasReminder = reminderTime != null;
    return _FormCard(
      dark: dark,
      icon: hasReminder ? Iconsax.alarm : Iconsax.alarm,
      title: 'Reminder',
      child: Column(
        children: [
          // Current state display
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              borderRadius: AppRadius.mdBR,
              border: Border.all(
                  color: dark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.clock,
                  color: hasReminder
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasReminder
                        ? _format(reminderTime!)
                        : 'No reminder set',
                    style: AppTypography.bodyMedium.copyWith(
                      color: hasReminder
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.7),
                      fontWeight: hasReminder ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (hasReminder) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onClearReminder,
                    icon: const Icon(Iconsax.close_circle, size: 16),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdBR),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSetReminder,
                    icon: const Icon(Iconsax.edit, size: 16),
                    label: const Text('Change'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdBR),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Alarm style toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAlarmStyle
                    ? AppColors.warning.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: AppRadius.mdBR,
                border: Border.all(
                  color: isAlarmStyle
                      ? AppColors.warning.withValues(alpha: 0.4)
                      : (dark ? AppColors.darkBorder : AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isAlarmStyle ? AppColors.warning : Colors.grey)
                          .withValues(alpha: 0.12),
                      borderRadius: AppRadius.smBR,
                    ),
                    child: Icon(
                      isAlarmStyle
                          ? Iconsax.alarm
                          : Iconsax.notification,
                      color: isAlarmStyle ? AppColors.warning : Colors.grey,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alarm Style',
                            style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600)),
                        Text(
                          isAlarmStyle
                              ? 'Persistent with snooze & dismiss'
                              : 'Standard notification',
                          style: AppTypography.labelSmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isAlarmStyle,
                    onChanged: (v) {
                      HapticFeedback.lightImpact();
                      onAlarmToggle(v);
                    },
                    activeThumbColor: AppColors.warning,
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSetReminder,
                icon: const Icon(Iconsax.alarm, size: 20),
                label: const Text('Set Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdBR),
                  elevation: 0,
                  textStyle: AppTypography.labelLarge
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared form card shell ────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final String title;
  final Widget child;

  const _FormCard({
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
