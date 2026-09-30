import 'package:flutter/material.dart';

/// MediMate application theme constants.
///
/// These values match the purple/lavender visual language already used
/// throughout the MediMate screens.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color secondary = Color(0xFF9B7BEA);

  static const Color background = Color(0xFFF8F6FF);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE6DDF7);

  static const Color textPrimary = Color(0xFF211738);
  static const Color textSecondary = Color(0xFF716A80);

  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF16A34A);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      primary,
      primaryDark,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFF1EBFF),
      Color(0xFFFAF8FF),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

class AppRadius {
  AppRadius._();

  static const double small = 10;
  static const double medium = 14;
  static const double card = 20;
  static const double button = 16;
  static const double large = 24;
}

/// Optional Material theme for screens that want to use the shared theme.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
