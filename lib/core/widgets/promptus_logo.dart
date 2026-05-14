import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// In-code logo — no image file required. Replace with Image.asset() once
/// a real PNG/SVG is available.
class PromptusLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const PromptusLogo({super.key, this.size = 80, this.showText = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'P',
              style: AppTypography.poppins(
                fontSize: size * 0.52,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.2),
          Text(
            'Promptus',
            style: AppTypography.poppins(
              fontSize: size * 0.3,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
