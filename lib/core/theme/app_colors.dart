import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Light Theme ──────────────────────────────────────────────────────────

  // Primary — Deep Indigo
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFFA5B4FC);

  // Accent
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentSecondary = Color(0xFFEC4899);

  // Backgrounds
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Borders
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // ── Dark Theme ────────────────────────────────────────────────────────────

  static const Color darkPrimary = Color(0xFF818CF8);
  static const Color darkPrimaryDark = Color(0xFF6366F1);
  static const Color darkPrimaryLight = Color(0xFFC7D2FE);

  static const Color darkAccent = Color(0xFFA78BFA);
  static const Color darkAccentSecondary = Color(0xFFF472B6);

  static const Color darkBackground = Color(0xFF0F0F14);
  static const Color darkSurface = Color(0xFF1A1A22);
  static const Color darkSurfaceVariant = Color(0xFF24242E);
  static const Color darkSurfaceElevated = Color(0xFF2D2D38);

  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  static const Color darkTextTertiary = Color(0xFF9CA3AF);

  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkInfo = Color(0xFF60A5FA);

  static const Color darkBorder = Color(0xFF374151);
  static const Color darkDivider = Color(0xFF2D2D38);

  // ── Category colours (same across themes) ────────────────────────────────

  static const Color catFood = Color(0xFFF97316);
  static const Color catTransport = Color(0xFF3B82F6);
  static const Color catShopping = Color(0xFF8B5CF6);
  static const Color catEntertainment = Color(0xFFEF4444);
  static const Color catBills = Color(0xFF10B981);
  static const Color catHealthcare = Color(0xFF14B8A6);
  static const Color catEducation = Color(0xFF6366F1);
  static const Color catTravel = Color(0xFFF59E0B);
  static const Color catOther = Color(0xFF6B7280);

  static Color categoryColor(String category) {
    const map = {
      'Food & Dining': catFood,
      'Transportation': catTransport,
      'Shopping': catShopping,
      'Entertainment': catEntertainment,
      'Bills & Utilities': catBills,
      'Healthcare': catHealthcare,
      'Education': catEducation,
      'Travel': catTravel,
      'Other': catOther,
    };
    return map[category] ?? catOther;
  }

  // ── iOS Notes specific ────────────────────────────────────────────────────
  /// Accent used throughout the note editor (back chevron, active icons, etc.)
  static const Color noteRed = Color(0xFF9B1D1D);
  /// iOS dark surface — exact #1C1C1E used for dark mode note background
  static const Color iosDarkSurface = Color(0xFF1C1C1E);
  /// iOS placeholder text color
  static const Color iosPlaceholder = Color(0xFFC7C7CC);
  /// iOS separator / divider (light)
  static const Color iosDivider = Color(0xFFC6C6C8);
  /// iOS separator / divider (dark)
  static const Color iosDarkDivider = Color(0xFF38383A);
  /// iOS secondary label — used for metadata text like "Edited 2 min ago"
  static const Color iosSecondaryLabel = Color(0xFF8E8E93);
  /// iOS grouped background — bottom toolbar background (light)
  static const Color iosToolbarBg = Color(0xFFF2F2F7);
  /// iOS grouped background — bottom toolbar background (dark)
  static const Color iosDarkToolbarBg = Color(0xFF2C2C2E);

  // ── Gradients ─────────────────────────────────────────────────────────────

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF6D28D9)],
    stops: [0.0, 0.55, 1.0],
  );
}
