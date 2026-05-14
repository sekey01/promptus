import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTypography {
  // Poppins — headings, display text, large numbers
  static TextStyle poppins({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    Color? color,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );

  // Roboto — body copy, labels, descriptions
  static TextStyle roboto({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    Color? color,
  }) =>
      GoogleFonts.roboto(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );

  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle get displayLarge => poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get displayMedium => poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get displaySmall => poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  // ── Headline ──────────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => poppins(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get headlineMedium => poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get headlineSmall => poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  // ── Title ─────────────────────────────────────────────────────────────────
  static TextStyle get titleLarge => poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get titleMedium => poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get titleSmall => poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => roboto(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle get bodyMedium => roboto(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle get bodySmall => roboto(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
      );

  // ── Label ─────────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => roboto(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => roboto(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => roboto(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  // ── Amount / numbers (Poppins bold) ───────────────────────────────────────
  static TextStyle get amountLarge => poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get amountMedium => poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle get amountSmall => poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );

  // ── TextTheme for MaterialApp ─────────────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
