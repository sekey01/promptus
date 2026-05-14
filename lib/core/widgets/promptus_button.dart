import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Full-width gradient primary button with press-scale feedback.
class PrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => _ctrl.forward(),
      onTapUp: disabled
          ? null
          : (_) {
              _ctrl.reverse();
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: disabled
                ? null
                : AppColors.primaryGradient,
            color: disabled ? AppColors.border : null,
            borderRadius: AppRadius.lgBR,
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize:
                widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool fullWidth;

  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTypography.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
        ),
      ),
    );
  }
}
