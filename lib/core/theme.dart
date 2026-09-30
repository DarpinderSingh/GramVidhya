import 'package:flutter/material.dart';

/// Semantic theme tokens providing unified, consistent color palettes
/// for both Light and Dark modes across all screens and components.
///
/// LIGHT: Warm Cream/Beige educational theme (#F5F0E6, #FFFDF7, #315A8A, #B96B4B)
/// DARK:  Refined Charcoal & Muted Red theme (#121212, #1E1E1E, #D95C5C, #F4EFE6)
class AppThemeTokens {
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color primary;
  final Color primaryPressed;
  final Color secondaryAccent;
  final Color accent;
  final Color accentLight;
  final Color success;
  final Color warning;
  final Color error;
  final Color buttonPrimary;
  final Color buttonText;
  final Color cardBackground;
  final Color chipBackground;
  final Color heroGradientStart;
  final Color heroGradientEnd;
  final Color navSurface;
  final Color navIndicator;
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
    required this.primary,
    required this.primaryPressed,
    required this.secondaryAccent,
    required this.accent,
    required this.accentLight,
    required this.success,
    required this.warning,
    required this.error,
    required this.buttonPrimary,
    required this.buttonText,
    required this.cardBackground,
    required this.chipBackground,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.navSurface,
    required this.navIndicator,
    required this.isDark,
  });

  List<Color> get heroGradient => [heroGradientStart, heroGradientEnd];
  Color get heroTitleColor => isDark ? const Color(0xFFF4EFE6) : const Color(0xFFFFFDF7);
  Color get heroSubtitleColor => isDark ? const Color(0xFFB8B1A6) : const Color(0xFFDED6C8);
  Color get shadow => isDark ? const Color(0x66000000) : const Color(0x1F716B61);

  /// DARK THEME — Sophisticated Charcoal & Muted Red Theme
  static const dark = AppThemeTokens(
    backgroundPrimary: Color(0xFF121212),
    backgroundSecondary: Color(0xFF1E1E1E),
    surface: Color(0xFF1E1E1E),
    surfaceElevated: Color(0xFF262626),
    textPrimary: Color(0xFFF4EFE6),
    textSecondary: Color(0xFFB8B1A6),
    textMuted: Color(0xFFB8B1A6),
    border: Color(0xFF34312D),
    primary: Color(0xFFD95C5C),
    primaryPressed: Color(0xFFEE7070),
    secondaryAccent: Color(0xFFEE7070),
    accent: Color(0xFFD95C5C),
    accentLight: Color(0xFFEE7070),
    success: Color(0xFF72966F),
    warning: Color(0xFFC89A55),
    error: Color(0xFFE06A67),
    buttonPrimary: Color(0xFFD95C5C),
    buttonText: Color(0xFFF4EFE6),
    cardBackground: Color(0xFF1E1E1E),
    chipBackground: Color(0xFF262626),
    heroGradientStart: Color(0xFF1E1E1E),
    heroGradientEnd: Color(0xFF262626),
    navSurface: Color(0xFF1E1E1E),
    navIndicator: Color(0x33D95C5C),
    isDark: true,
  );

  /// LIGHT THEME — Warm Educational Cream/Beige Theme
  static const light = AppThemeTokens(
    backgroundPrimary: Color(0xFFF5F0E6),   // Warm cream/beige background
    backgroundSecondary: Color(0xFFEFE8DA),  // Slightly deeper cream
    surface: Color(0xFFFFFDF7),              // Lighter ivory card/surface
    surfaceElevated: Color(0xFFFFFDF7),
    textPrimary: Color(0xFF29251F),          // Dark charcoal main text
    textSecondary: Color(0xFF716B61),        // Muted secondary text
    textMuted: Color(0xFF716B61),
    border: Color(0xFFDED6C8),               // Soft beige border
    primary: Color(0xFF315A8A),              // Primary deep blue
    primaryPressed: Color(0xFF24486F),       // Pressed deep blue
    secondaryAccent: Color(0xFFB96B4B),      // Terracotta secondary accent
    accent: Color(0xFF315A8A),               // Accent deep blue
    accentLight: Color(0xFFB96B4B),          // Secondary accent
    success: Color(0xFF4F7654),
    warning: Color(0xFFC28B52),
    error: Color(0xFFB94A48),
    buttonPrimary: Color(0xFF315A8A),
    buttonText: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFDF7),
    chipBackground: Color(0xFFEFE8DA),
    heroGradientStart: Color(0xFF315A8A),
    heroGradientEnd: Color(0xFF24486F),
    navSurface: Color(0xFFFFFDF7),
    navIndicator: Color(0x26315A8A),
    isDark: false,
  );
}

typedef SemanticThemeTokens = AppThemeTokens;

/// Extension on BuildContext for effortless access to semantic theme tokens.
extension ThemeTokensExtension on BuildContext {
  AppThemeTokens get tokens {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark ? AppThemeTokens.dark : AppThemeTokens.light;
  }
}

