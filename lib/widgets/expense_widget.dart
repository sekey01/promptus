import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_typography.dart';
import '../models/expense_model.dart';

class ExpenseItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ExpenseItem({
    super.key,
    required this.expense,
    required this.onDelete,
    required this.onEdit,
  });

  String _priorityLabel(int p) => ['', 'Low', 'Medium', 'High'][p.clamp(1, 3)];

  Color _priorityColor(int p) => p == 3
      ? AppColors.error
      : p == 2
          ? AppColors.warning
          : AppColors.success;

  void _showOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OptionsSheet(onEdit: onEdit, onDelete: () {
        _confirm(context);
      }),
    );
  }

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBR),
        title: Text('Delete Expense', style: AppTypography.titleLarge),
        content: Text(
          'Delete "${expense.title}"? This cannot be undone.',
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
    final catColor = AppColors.categoryColor(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.xlBR,
        border: Border.all(
          color: dark ? AppColors.darkBorder : AppColors.border,
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
              children: [
                // Category icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.mdBR,
                  ),
                  child: Icon(_categoryIcon(expense.category),
                      color: catColor, size: 22),
                ),
                const SizedBox(width: 14),
                // Text body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              expense.title,
                              style: AppTypography.titleMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PriorityBadge(
                            label: _priorityLabel(expense.priority),
                            color: _priorityColor(expense.priority),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _CategoryChip(
                              label: expense.category, color: catColor),
                          const Spacer(),
                          Icon(Iconsax.calendar_1,
                              size: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${expense.createdAt.day}/${expense.createdAt.month}/${expense.createdAt.year}',
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
                const SizedBox(width: 12),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₵${expense.amount.toStringAsFixed(2)}',
                      style: AppTypography.amountSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(Iconsax.more,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    const m = {
      'Food & Dining': Iconsax.shopping_cart,
      'Transportation': Iconsax.car,
      'Shopping': Iconsax.bag_2,
      'Entertainment': Iconsax.music,
      'Bills & Utilities': Iconsax.receipt_2,
      'Healthcare': Iconsax.heart,
      'Education': Iconsax.book_1,
      'Travel': Iconsax.airplane,
      'Other': Iconsax.category,
    };
    return m[cat] ?? Iconsax.category;
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
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

// ── Options bottom-sheet ──────────────────────────────────────────────────────

class _OptionsSheet extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OptionsSheet({required this.onEdit, required this.onDelete});

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
            label: 'Edit Expense',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          _SheetTile(
            icon: Iconsax.trash,
            label: 'Delete Expense',
            color: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
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
            style:
                AppTypography.titleMedium.copyWith(color: color)),
        trailing: Icon(Iconsax.arrow_right_3,
            size: 14, color: color.withValues(alpha: 0.5)),
      );
}
