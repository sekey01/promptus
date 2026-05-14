import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

abstract class AppTheme {
  // ── Light ─────────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryLight,
          onPrimaryContainer: AppColors.primaryDark,
          secondary: AppColors.accent,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFEDE9FE),
          onSecondaryContainer: AppColors.accent,
          tertiary: AppColors.accentSecondary,
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFFCE7F3),
          onTertiaryContainer: AppColors.accentSecondary,
          error: AppColors.error,
          onError: Colors.white,
          errorContainer: Color(0xFFFEE2E2),
          onErrorContainer: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppColors.surfaceVariant,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
          outlineVariant: AppColors.divider,
          shadow: AppColors.primary,
          scrim: Colors.black,
          inverseSurface: AppColors.textPrimary,
          onInverseSurface: AppColors.surface,
          inversePrimary: AppColors.primaryLight,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppTypography.textTheme,
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          titleTextStyle: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xlBR,
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: AppTypography.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            textStyle: AppTypography.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTypography.labelLarge,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: AppRadius.lgBR,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgBR,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgBR,
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgBR,
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgBR,
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.primaryLight,
          labelStyle: AppTypography.labelMedium,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.fullBR),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          contentTextStyle:
              AppTypography.bodyMedium.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
          ),
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.textTertiary,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
      );

  // ── Dark ──────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.darkPrimary,
          onPrimary: AppColors.darkBackground,
          primaryContainer: AppColors.darkPrimaryDark,
          onPrimaryContainer: AppColors.darkPrimaryLight,
          secondary: AppColors.darkAccent,
          onSecondary: AppColors.darkBackground,
          secondaryContainer: Color(0xFF3B1F6A),
          onSecondaryContainer: AppColors.darkAccent,
          tertiary: AppColors.darkAccentSecondary,
          onTertiary: AppColors.darkBackground,
          tertiaryContainer: Color(0xFF5C1A3A),
          onTertiaryContainer: AppColors.darkAccentSecondary,
          error: AppColors.darkError,
          onError: AppColors.darkBackground,
          errorContainer: Color(0xFF7F1D1D),
          onErrorContainer: AppColors.darkError,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          surfaceContainerHighest: AppColors.darkSurfaceVariant,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkBorder,
          outlineVariant: AppColors.darkDivider,
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: AppColors.darkTextPrimary,
          onInverseSurface: AppColors.darkBackground,
          inversePrimary: AppColors.darkPrimaryDark,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: AppTypography.textTheme,
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.darkTextPrimary,
          titleTextStyle: AppTypography.headlineMedium.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xlBR,
            side: const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.darkPrimary,
            foregroundColor: AppColors.darkBackground,
            textStyle: AppTypography.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkPrimary,
            side: const BorderSide(color: AppColors.darkPrimary),
            textStyle: AppTypography.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.darkPrimary,
            textStyle: AppTypography.labelLarge,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceVariant,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: AppRadius.lgBR,
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgBR,
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgBR,
            borderSide:
                const BorderSide(color: AppColors.darkPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgBR,
            borderSide: const BorderSide(color: AppColors.darkError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgBR,
            borderSide: const BorderSide(color: AppColors.darkError, width: 2),
          ),
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.darkTextSecondary,
          ),
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.darkTextTertiary,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.darkSurfaceVariant,
          selectedColor: AppColors.darkPrimaryDark,
          labelStyle: AppTypography.labelMedium.copyWith(
            color: AppColors.darkTextPrimary,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.fullBR),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkDivider,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkSurfaceElevated,
          contentTextStyle:
              AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.darkSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
          ),
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkBackground,
          elevation: 0,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.darkBackground
                : AppColors.darkTextTertiary,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.darkPrimary
                : AppColors.darkBorder,
          ),
        ),
      );
}
