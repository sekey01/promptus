import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppShadows {
  static List<BoxShadow> level1({bool dark = false}) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> level2({bool dark = false}) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> level3({bool dark = false}) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> level4({bool dark = false}) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.6)
              : AppColors.primary.withValues(alpha: 0.16),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> level5({bool dark = false}) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.7)
              : AppColors.primary.withValues(alpha: 0.20),
          blurRadius: 32,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> colored(Color color, {double opacity = 0.3}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
