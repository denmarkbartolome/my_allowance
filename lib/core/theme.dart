import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0A0B14);
  static const surface = Color(0xFF141628);
  static const surfaceHigh = Color(0xFF1D2040);
  static const primary = Color(0xFF7C5CFF); // violet - brand
  static const primarySoft = Color(0xFF4D8DFF); // blue - gradient partner
  static const secondary = Color(0xFF2DE2B0); // mint - healthy budget
  static const warning = Color(0xFFFFB84D); // amber - getting low
  static const danger = Color(0xFFFF5C8A); // coral - overspent
  static const text = Color(0xFFF2F3FA);
  static const textMuted = Color(0xFF8C90B0);

  static const primaryGradient = LinearGradient(
    colors: [primary, primarySoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  /// A soft coloured glow used behind cards, buttons and icons.
  static List<BoxShadow> glow(
    Color color, {
    double opacity = .35,
    double blur = 30,
    double spread = -6,
  }) =>
      [
        BoxShadow(
          color: color.withOpacity(opacity),
          blurRadius: blur,
          spreadRadius: spread,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    OutlineInputBorder border([Color? c, double w = 0]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: c == null
              ? BorderSide.none
              : BorderSide(color: c, width: w),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: border(),
        enabledBorder: border(),
        focusedBorder: border(AppColors.primary, 1.5),
        errorBorder: border(AppColors.danger, 1.2),
        focusedErrorBorder: border(AppColors.danger, 1.5),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(.22),
        height: 68,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
