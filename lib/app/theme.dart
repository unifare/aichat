import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF111827);
  static const surface = Color(0xFF1A2230);
  static const surface2 = Color(0xFF232E42);
  static const surface3 = Color(0xFF2A374F);
  static const border = Color(0xFF2E3B52);
  static const fg = Color(0xFFF1F5F9);
  static const muted = Color(0xFF94A3B8);
  static const muted2 = Color(0xFF64748B);
  static const accent = Color(0xFF10B981);
  static const accent2 = Color(0xFF34D399);
  static const warn = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData dark() {
    const fg = AppColors.fg;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.bg,
        onSurface: AppColors.fg,
        outline: AppColors.border,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF141C2B),
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x0AFFFFFF),
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'JetBrainsMono'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: fg, fontSize: 14, height: 1.6),
        titleMedium: TextStyle(color: fg, fontWeight: FontWeight.w700),
        labelSmall: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6),
      ),
    );
  }
}
