import 'package:flutter/material.dart';

class AppColors {
  // Main MediMate purple palette
  static const primary = Color(0xFF8B5CF6);
  static const primaryDark = Color(0xFF6D28D9);
  static const primaryDeep = Color(0xFF5422B8);
  static const secondary = Color(0xFF7C3AED);

  // Background
  static const background = Color(0xFFF4EEFF);
  static const backgroundLight = Color(0xFFFBF9FF);

  // Surfaces
  static const surface = Colors.white;
  static const surfacePurple = Color(0xFFF5F0FF);
  static const surfacePurpleStrong = Color(0xFFEDE4FF);

  // Text
  static const textPrimary = Color(0xFF211738);
  static const textSecondary = Color(0xFF655B78);
  static const textMuted = Color(0xFF8B829B);

  // Borders
  static const border = Color(0xFFDCD0F4);
  static const borderStrong = Color(0xFFC5B3EA);

  // Inputs
  static const inputFill = Color(0xFFF6F2FC);
  static const inputFocus = Color(0xFFEDE4FF);

  // Status
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF16A34A);

  // Main purple gradient
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      primaryDark,
    ],
  );

  // Authentication page background
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEDE5FF),
      Color(0xFFF7F2FF),
      Color(0xFFE8DEFF),
    ],
    stops: [
      0.0,
      0.55,
      1.0,
    ],
  );
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  static const card = 28.0;
  static const field = 16.0;
  static const button = 18.0;
  static const chip = 12.0;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        primaryContainer: AppColors.surfacePurpleStrong,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.surfacePurple,
        error: AppColors.error,
        surface: AppColors.surface,
      ),

      textTheme: _textTheme(base.textTheme),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.field,
          ),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1.2,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.field,
          ),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1.2,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.field,
          ),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.field,
          ),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.4,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.field,
          ),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),

        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),

        floatingLabelStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),

        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),

        prefixIconColor: AppColors.primaryDark,
        suffixIconColor: AppColors.primaryDark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.button,
            ),
          ),

          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,

        backgroundColor: AppColors.textPrimary,

        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        insetPadding: const EdgeInsets.all(16),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),

        fillColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryDark;
            }

            return Colors.transparent;
          },
        ),

        side: const BorderSide(
          color: AppColors.primaryDark,
          width: 1.5,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.card,
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineMedium: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.7,
      ),

      titleMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.5,
      ),

      bodyLarge: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),

      bodyMedium: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),

      labelLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}