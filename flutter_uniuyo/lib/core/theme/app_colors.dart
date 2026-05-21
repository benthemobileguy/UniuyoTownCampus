import 'package:flutter/material.dart';

/// Professional color palette for Uniuyo Town Campus app
/// Inspired by modern university campus apps (UOB, etc.)
/// Using Material Design 3 color system
class AppColors {
  // ============================================
  // PRIMARY PALETTE (University Brand Colors)
  // ============================================
  // Coral red - matches university logo
  static const Color primary = Color(0xFFFF6B6B); // Coral red (from logo)
  static const Color primaryLight = Color(0xFFFF8A8A);
  static const Color primaryDark = Color(0xFFE55555);
  static const Color primaryContainer = Color(0xFFFFE0E0);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF4D0000);

  // ============================================
  // SECONDARY PALETTE (Academic Green)
  // ============================================
  static const Color secondary = Color(0xFF2E7D32); // Academic green
  static const Color secondaryLight = Color(0xFF4CAF50);
  static const Color secondaryDark = Color(0xFF1B5E20);
  static const Color secondaryContainer = Color(0xFFC8E6C9);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF072100);

  // ============================================
  // TERTIARY PALETTE (Accent Orange)
  // ============================================
  static const Color tertiary = Color(0xFFE65100);
  static const Color tertiaryLight = Color(0xFFFF6F00);
  static const Color tertiaryDark = Color(0xFFBF360C);
  static const Color tertiaryContainer = Color(0xFFFFE0B2);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF311300);

  // ============================================
  // SEMANTIC COLORS (Status & Feedback)
  // ============================================
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFFC8E6C9);

  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFF9800);
  static const Color warningContainer = Color(0xFFFFE0B2);

  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFE53935);
  static const Color errorContainer = Color(0xFFFFCDD2);

  static const Color info = Color(0xFFFF6B6B);
  static const Color infoLight = Color(0xFFFF8A8A);
  static const Color infoContainer = Color(0xFFFFE0E0);

  // ============================================
  // SURFACE & BACKGROUND
  // ============================================
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color surfaceTint = primary;

  static const Color onBackground = Color(0xFF1A1C1E);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF45464F);

  // ============================================
  // OUTLINE & DIVIDER
  // ============================================
  static const Color outline = Color(0xFFE0E0E0);
  static const Color outlineVariant = Color(0xFFF0F0F0);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);

  // ============================================
  // TEXT COLORS
  // ============================================
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textTertiary = Color(0xFF9AA0A6);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================
  // MAP-SPECIFIC COLORS
  // ============================================
  // Buildings
  static const Color buildingDefault = Color(0xFFE1BEE7); // Soft purple
  static const Color buildingAcademic = secondary; // Green for academic
  static const Color buildingHighlight = primary; // Blue highlight

  // Map elements
  static const Color roadColor = Color(0xFF78909C); // Blue-gray
  static const Color pathColor = Color(0xFFBCAAA4); // Warm gray

  // Map opacity values
  static const double buildingFillOpacity = 0.7;
  static const double roadOpacity = 0.8;
  static const double pathOpacity = 0.6;

  // Route colors
  static const Color routeMain = Color(0xFF2196F3); // Bright blue
  static const Color routeBorder = Color(0xFF1565C0); // Darker blue
  static const Color routeStart = success; // Green
  static const Color routeEnd = error; // Red

  // ============================================
  // UTILITY COLORS
  // ============================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Shimmer colors for loading
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ============================================
  // LEGACY COLORS (for backwards compatibility)
  // Keep these for gradual migration
  // ============================================
  static const Color customRed = error; // Map to new error color
  static const Color colorPrimary = primary;
  static const Color colorPrimaryDark = primaryDark;
  static const Color customTextColor = textPrimary;
  static const Color customGreen = secondary;
  static const Color buildingFillColor = buildingDefault;

  // ============================================
  // COLOR UTILITIES
  // ============================================

  /// Get color with opacity
  static Color withAlpha(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get elevation overlay color (for dark mode support later)
  static Color getElevationColor(int elevation) {
    final opacity = (4.5 * elevation + 4) / 100;
    return white.withOpacity(opacity);
  }
}
