import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// Standard surface card.
class PromptusCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const PromptusCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.darkSurface : AppColors.surface;
    final border = dark ? AppColors.darkBorder : AppColors.border;
    final radius = borderRadius ?? AppRadius.xlBR;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: 1),
        boxShadow: AppShadows.level2(dark: dark),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: onTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(20),
                    child: child,
                  ),
                ),
              )
            : Padding(
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              ),
      ),
    );
  }
}

/// Premium gradient card — hero sections, summary cards.
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GradientCard({
    super.key,
    required this.child,
    this.colors,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final gradColors = colors ??
        [AppColors.primaryDark, AppColors.primary, AppColors.accent];
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradColors,
        ),
        borderRadius: AppRadius.xlBR,
        boxShadow: [
          BoxShadow(
            color: gradColors.first.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.xlBR,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        padding: padding ?? const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}
