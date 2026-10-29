import 'package:flutter/material.dart';

/// Mini Store palette from the product brief.
abstract final class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryDeep = Color(0xFF1E3A8A);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentContainer = Color(0xFFFEF3C7);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF16A34A);
  static const Color successDark = Color(0xFF15803D);
  static const Color successDeep = Color(0xFF0B5A2B);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFDC2626);

  /// Translucent white used for actions and dividers on coloured surfaces.
  static const Color onColorFaint = Color(0x33FFFFFF);

  /// Brand gradient shared by coloured surfaces such as the Home app bar and
  /// the store promo banner.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Neutral tint used behind product photography.
  static const Color imageBackground = Color(0xFFF3F4F6);

  // Dark theme neutrals. Brand colours (primary, accent, success, error) stay
  // the same in both themes; only surfaces, text, borders, and tinted
  // containers need a dark counterpart.
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceElevated = Color(0xFF1F2937);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkImageBackground = Color(0xFF1F2937);
  static const Color darkPrimaryContainer = Color(0xFF1E3A8A);
  static const Color darkOnPrimaryContainer = Color(0xFFDBEAFE);
  static const Color darkAccentContainer = Color(0xFF78350F);
  static const Color darkOnAccentContainer = Color(0xFFFEF3C7);
  static const Color darkSuccessContainer = Color(0xFF14532D);
  static const Color darkOnSuccessContainer = Color(0xFFDCFCE7);
}
