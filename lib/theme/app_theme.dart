import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─── PUnova · Apple Liquid Glass Design System ─────────────────────

class AppColors {
  // ── Core backgrounds ──
  static const Color bgDark = Color(0xFF050A18);
  static const Color bgMedium = Color(0xFF0C1228);
  static const Color bgCard = Color(0xFF111833);

  // ── Liquid Glass colors ──
  static const Color glassWhite = Color(0x14FFFFFF); // 8%
  static const Color glassFill = Color(0x1AFFFFFF); // 10%
  static const Color glassBorder = Color(0x28FFFFFF); // 16%
  static const Color glassHighlight = Color(0x0AFFFFFF); // 4%
  static const Color glassInner = Color(0x08FFFFFF); // 3%

  // ── Liquid Accents ──
  static const Color accentTeal = Color(0xFF00D4FF);
  static const Color accentCyan = Color(0xFF00F5D4);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFFF8C00);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentAmber = Color(0xFFF59E0B);

  // ── Text ──
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFF475569);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentTeal, Color(0xFF00C4E0), accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [accentPurple, Color(0xFFA78BFA), accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF8C00), Color(0xFFFF6B35), Color(0xFFFF5E00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x12FFFFFF), Color(0x08FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [bgDark, Color(0xFF080E24), bgMedium],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient meshGradient = LinearGradient(
    colors: [
      Color(0xFF050A18),
      Color(0xFF0A1030),
      Color(0xFF080D22),
      Color(0xFF050A18),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Light-mode color overrides
class LightColors {
  static const Color bgLight = Color(0xFFF5F5F7);
  static const Color bgMedium = Color(0xFFE8E8ED);
  static const Color bgCard = Color(0xFFFFFFFF);

  static const Color glassWhite = Color(0x0A000000);
  static const Color glassFill = Color(0x10000000);
  static const Color glassBorder = Color(0x14000000);
  static const Color glassHighlight = Color(0x05000000);

  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textMuted = Color(0xFF8E8E93);

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFF5F5F7), Color(0xFFF0F0F2), Color(0xFFE8E8ED)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Theme-adaptive color resolver
class Tc {
  final bool isDark;
  Tc.of(BuildContext context)
      : isDark = Theme.of(context).brightness == Brightness.dark;

  Color get textPrimary =>
      isDark ? AppColors.textPrimary : LightColors.textPrimary;
  Color get textSecondary =>
      isDark ? AppColors.textSecondary : LightColors.textSecondary;
  Color get textMuted => isDark ? AppColors.textMuted : LightColors.textMuted;
  Color get bg => isDark ? AppColors.bgDark : LightColors.bgLight;
  Color get bgCard => isDark ? AppColors.bgCard : LightColors.bgCard;
  Color get bgMedium => isDark ? AppColors.bgMedium : LightColors.bgMedium;
  Color get glassWhite =>
      isDark ? AppColors.glassWhite : LightColors.glassWhite;
  Color get glassFill => isDark ? AppColors.glassFill : LightColors.glassFill;
  Color get glassBorder =>
      isDark ? AppColors.glassBorder : LightColors.glassBorder;
  Color get glassHighlight =>
      isDark ? AppColors.glassHighlight : LightColors.glassHighlight;
  LinearGradient get bgGradient =>
      isDark ? AppColors.bgGradient : LightColors.bgGradient;
}

class AppTheme {
  static final String? _sfFamily = GoogleFonts.inter().fontFamily;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.accentTeal,
      scaffoldBackgroundColor: AppColors.bgDark,
      fontFamily: _sfFamily,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.accentTeal,
        ),
        labelSmall: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentTeal,
        secondary: AppColors.accentPurple,
        surface: AppColors.bgCard,
        error: AppColors.accentRed,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.accentTeal,
      scaffoldBackgroundColor: LightColors.bgLight,
      fontFamily: _sfFamily,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: LightColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: LightColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: LightColors.textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: LightColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: LightColors.textSecondary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: LightColors.textSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: LightColors.textMuted,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.accentTeal,
        ),
        labelSmall: TextStyle(
          fontFamily: _sfFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: LightColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentTeal,
        secondary: AppColors.accentPurple,
        surface: LightColors.bgCard,
        error: AppColors.accentRed,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
