import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─── PUnova · Minimal Neutral Design System (Apple / Notion Style) ──

// ═══════════════════════════════════════════════════════════════════════
// COLOR PALETTE — 90% neutral, 10% accent
// ═══════════════════════════════════════════════════════════════════════

class AppColors {
  // ── Core ──
  static const Color primary = Color(0xFF000000);
  static const Color secondary = Color(0xFF6B7280);
  static const Color accent = Color(0xFF2563EB); // Used sparingly

  // ── Backgrounds ──
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgSurface = Color(0xFFF5F5F7);
  static const Color bgCard = Color(0xFFFFFFFF);

  // ── Borders ──
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF0F0F2);

  // ── Text ──
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFFBDBDBD);

  // ── Semantic ──
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);

  // ── Feature Accent Colors (used on icon backgrounds, sparingly) ──
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentRed = Color(0xFFDC2626);

  // ── Dark Mode Colors ──
  static const Color darkBg = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkBorder = Color(0xFF2C2C2E);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);
}

/// Theme-adaptive color resolver — the SINGLE source of truth for colors.
class Tc {
  final bool isDark;
  Tc.of(BuildContext context)
      : isDark = Theme.of(context).brightness == Brightness.dark;

  // ── Core ──
  Color get primary => isDark ? Colors.white : AppColors.primary;
  Color get accent => AppColors.accent;

  // ── Backgrounds ──
  Color get bg => isDark ? AppColors.darkBg : AppColors.bgWhite;
  Color get bgSurface => isDark ? AppColors.darkSurface : AppColors.bgSurface;
  Color get bgCard => isDark ? AppColors.darkCard : AppColors.bgCard;

  // ── Borders ──
  Color get border => isDark ? AppColors.darkBorder : AppColors.border;
  Color get borderLight =>
      isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.borderLight;

  // ── Text ──
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.textMuted;

  // ── Glass compatibility (mapped to flat neutral) ──
  Color get glassFill => isDark ? AppColors.darkSurface : AppColors.bgSurface;
  Color get glassBorder => border;
  Color get glassWhite => isDark ? AppColors.darkCard : AppColors.bgWhite;
  Color get glassHighlight => Colors.transparent;

  // ── Gradients (subtle for neutral style) ──
  LinearGradient get primaryGradient => isDark
      ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)])
      : const LinearGradient(colors: [AppColors.primary, Color(0xFF374151)]);

  LinearGradient get secondaryGradient => isDark
      ? const LinearGradient(colors: [Color(0xFF374151), Color(0xFF4B5563)])
      : const LinearGradient(colors: [AppColors.secondary, Color(0xFF9CA3AF)]);

  LinearGradient get bgGradient => isDark
      ? const LinearGradient(
          colors: [AppColors.darkBg, AppColors.darkBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
      : const LinearGradient(
          colors: [AppColors.bgWhite, AppColors.bgSurface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

  Color get bgMedium => isDark ? AppColors.darkSurface : AppColors.bgSurface;
}

// ═══════════════════════════════════════════════════════════════════════
// THEME DATA
// ═══════════════════════════════════════════════════════════════════════

class AppTheme {
  static final String? _fontFamily = GoogleFonts.inter().fontFamily;

  // ── Light Theme (Primary) ──
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgWhite,
      fontFamily: _fontFamily,
      textTheme: _buildTextTheme(
        primary: AppColors.textPrimary,
        secondary: AppColors.textSecondary,
        muted: AppColors.textMuted,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.bgCard,
        error: AppColors.error,
      ),
      dividerColor: AppColors.border,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  // ── Dark Theme ──
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.white,
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: _fontFamily,
      textTheme: _buildTextTheme(
        primary: AppColors.darkTextPrimary,
        secondary: AppColors.darkTextSecondary,
        muted: AppColors.darkTextMuted,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: AppColors.darkTextSecondary,
        surface: AppColors.darkCard,
        error: AppColors.error,
      ),
      dividerColor: AppColors.darkBorder,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
    required Color muted,
  }) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: muted,
        letterSpacing: 0.5,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // iOS CUPERTINO THEMES
  // ═══════════════════════════════════════════════════════════════════════

  static CupertinoThemeData get lightCupertinoTheme {
    return CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      primaryContrastingColor: AppColors.bgWhite,
      barBackgroundColor: AppColors.bgWhite.withValues(alpha: 0.95),
      scaffoldBackgroundColor: AppColors.bgWhite,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.primary,
        textStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontFamily: _fontFamily,
        ),
        actionTextStyle: TextStyle(
          color: AppColors.accent,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: _fontFamily,
        ),
        tabLabelTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontFamily: _fontFamily,
        ),
        navTitleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: _fontFamily,
        ),
        navLargeTitleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.bold,
          fontFamily: _fontFamily,
        ),
      ),
    );
  }

  static CupertinoThemeData get darkCupertinoTheme {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.white,
      primaryContrastingColor: AppColors.darkBg,
      barBackgroundColor: AppColors.darkCard.withValues(alpha: 0.95),
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: CupertinoTextThemeData(
        primaryColor: Colors.white,
        textStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 17,
          fontFamily: _fontFamily,
        ),
        actionTextStyle: TextStyle(
          color: AppColors.accent,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: _fontFamily,
        ),
        tabLabelTextStyle: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 10,
          fontFamily: _fontFamily,
        ),
        navTitleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: _fontFamily,
        ),
        navLargeTitleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 34,
          fontWeight: FontWeight.bold,
          fontFamily: _fontFamily,
        ),
      ),
    );
  }
}
