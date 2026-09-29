import 'package:flutter/material.dart';

/// Semantic theme tokens providing unified, consistent color palettes
/// for both Light and Dark modes across all screens and components.
class AppThemeTokens {
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color buttonPrimary;
  final Color buttonText;
  final Color cardBackground;
  final Color chipBackground;
  final bool isDark;

  const AppThemeTokens({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.buttonPrimary,
    required this.buttonText,
    required this.cardBackground,
    required this.chipBackground,
    required this.isDark,
  });

  static const dark = AppThemeTokens(
    backgroundPrimary: Color(0xFF0F172A), // Deep navy / blue-black
    backgroundSecondary: Color(0xFF1E293B), // Blue-gray
    surface: Color(0xFF1E293B),
    surfaceElevated: Color(0xFF273549),
    textPrimary: Color(0xFFF8FAFC), // Soft white text
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    border: Color(0xFF334155),
    accent: Color(0xFF3B82F6), // Restrained blue accent
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    buttonPrimary: Color(0xFF3B82F6),
    buttonText: Color(0xFFFFFFFF),
    cardBackground: Color(0xFF1E293B),
    chipBackground: Color(0x263B82F6),
    isDark: true,
  );

  static const light = AppThemeTokens(
    backgroundPrimary: Color(0xFFFAF7F0), // Warm beige / cream background (NOT pure white)
    backgroundSecondary: Color(0xFFF3EFE6), // Cream / ivory
    surface: Color(0xFFFFFDF8), // Ivory surface
    surfaceElevated: Color(0xFFF5F0E6),
    textPrimary: Color(0xFF1C1917), // Dark readable text
    textSecondary: Color(0xFF57534E),
    textMuted: Color(0xFF8C857B),
    border: Color(0xFFE6E1D5), // Subtle brown/gray border
    accent: Color(0xFF2563EB), // Restrained blue accent
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    buttonPrimary: Color(0xFF2563EB),
    buttonText: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFDF8),
    chipBackground: Color(0x1A2563EB),
    isDark: false,
  );
}

/// Extension on BuildContext for effortless access to semantic theme tokens.
extension ThemeTokensExtension on BuildContext {
  AppThemeTokens get tokens {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark ? AppThemeTokens.dark : AppThemeTokens.light;
  }
}
