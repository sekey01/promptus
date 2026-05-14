import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'promptus_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: dark ? 0.15 : 0.08),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(icon, size: 56, color: color.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: AppTypography.headlineMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onAction != null) ...[
              const SizedBox(height: 36),
              PrimaryButton(
                label: buttonLabel!,
                icon: Iconsax.add,
                onPressed: onAction,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
