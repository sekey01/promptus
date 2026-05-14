import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_typography.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedCategory = 'Food & Dining';
  int _priority = 1;
  late bool _isEditing;

  static const _categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Other',
  ];

  static const _categoryIcons = <String, IconData>{
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

  @override
  void initState() {
    super.initState();
    _isEditing = widget.expense != null;
    if (_isEditing) {
      _titleController.text = widget.expense!.title;
      _descriptionController.text = widget.expense!.description;
      _amountController.text = widget.expense!.amount.toString();
      _selectedCategory = widget.expense!.category;
      _priority = widget.expense!.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Color _priorityColor(int p) => p == 3
      ? AppColors.error
      : p == 2
          ? AppColors.warning
          : AppColors.success;

  String _priorityLabel(int p) => ['', 'Low', 'Medium', 'High'][p.clamp(1, 3)];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final db = Provider.of<DatabaseService>(context, listen: false);
    final expense = Expense(
      id: _isEditing ? widget.expense!.id : null,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      createdAt: _isEditing ? widget.expense!.createdAt : DateTime.now(),
      priority: _priority,
    );
    try {
      if (_isEditing) {
        await db.updateExpense(expense);
      } else {
        await db.addExpense(expense);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_snack(
          _isEditing ? 'Expense updated' : 'Expense saved'));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(_snack('Error: $e', isError: true));
    }
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
          _isEditing ? 'Edit Expense' : 'Add Expense',
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
              _DetailsCard(
                dark: dark,
                titleController: _titleController,
                amountController: _amountController,
                descriptionController: _descriptionController,
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              _CategoryCard(
                dark: dark,
                selected: _selectedCategory,
                categories: _categories,
                icons: _categoryIcons,
                onSelect: (c) => setState(() => _selectedCategory = c),
              )
                  .animate(delay: 60.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              _PriorityCard(
                dark: dark,
                priority: _priority,
                priorityColor: _priorityColor,
                priorityLabel: _priorityLabel,
                onSelect: (p) => setState(() => _priority = p),
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

// ── Details card ──────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final bool dark;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController descriptionController;

  const _DetailsCard({
    required this.dark,
    required this.titleController,
    required this.amountController,
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
          color: dark ? AppColors.darkBorder : AppColors.border,
        ),
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
      icon: Iconsax.wallet_2,
      title: 'Expense Details',
      child: Column(
        children: [
          TextFormField(
            controller: titleController,
            style: AppTypography.bodyMedium,
            decoration: _input(
                context, 'Expense Title', 'e.g. Lunch at KFC', Iconsax.text),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: amountController,
            style: AppTypography.bodyMedium,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: _input(context, 'Amount (₵)', '0.00',
                Iconsax.money_2),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Amount is required';
              if (double.tryParse(v) == null) return 'Enter a valid number';
              if (double.parse(v) <= 0) return 'Must be greater than 0';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: descriptionController,
            style: AppTypography.bodyMedium,
            maxLines: 2,
            decoration: _input(context, 'Description (Optional)',
                'Add more details...', Iconsax.note),
          ),
        ],
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final bool dark;
  final String selected;
  final List<String> categories;
  final Map<String, IconData> icons;
  final ValueChanged<String> onSelect;

  const _CategoryCard({
    required this.dark,
    required this.selected,
    required this.categories,
    required this.icons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      dark: dark,
      icon: Iconsax.category,
      title: 'Category',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories.map((cat) {
          final isSelected = cat == selected;
          final color = AppColors.categoryColor(cat);
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onSelect(cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icons[cat] ?? Iconsax.category,
                    size: 15,
                    color: isSelected
                        ? color
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat,
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
          );
        }).toList(),
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
                      if (isSelected)
                        Icon(Iconsax.tick_circle,
                            color: color, size: 18)
                      else
                        Icon(Iconsax.record_circle,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 18),
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
