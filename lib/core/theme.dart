import 'package:flutter/material.dart';

class AppColors {
  // Brand colours
  static const Color brand = Color(0xFF4D9FFF);
  static const Color purple = Color(0xFFA78BFA);
  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFEF4444);
  static const Color orange = Color(0xFFF59E0B);

  // Background Layers (darkest -> lightest)
  static const Color bgDeep = Color(0xFF0F1117);
  static const Color bgCard = Color(0xFF1A1F2E);
  static const Color bgInput = Color(0xFF1E2435);
  static const Color bgElevated = Color(0xFF252D3D); // elevated card

  // Text colours
  static const Color textPrimary = Color(0xFFE2E8F0); // main text
  static const Color textMuted = Color(0xFF94A3B8); // secondary text
  static const Color textHint = Color(0xFF64748B); // placeholder text

  // Border
  static const Color border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
}

// The single function that creates the entire app theme.
// Call it once in main.dart - MaterialApp(theme: AppTheme.dark())

class Apptheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.brand,  
        secondary: AppColors.purple, 
        surface: AppColors.bgCard, 
        background: AppColors.bgDeep,
        error: AppColors.red,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        ),

        scaffoldBackgroundColor: AppColors.bgDeep,

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgDeep,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: AppColors.bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(12),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),

        // ElevatedButton - the main action button(sign in, add trade, etc.)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.brand.withOpacity(0.4),
            minimumSize: const Size(double.infinity, 52), // full width by default
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // TextButton - secondary actions (Forgot password?, Register)
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brand,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        // InputDecoration - all TextFormField inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgInput,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIconColor: AppColors.textMuted,
          suffixIconColor: AppColors.textMuted,
          // Border when Not Focused
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          // Border when focused - glows brand value
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
          ),
          // Border when validation fails
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.red, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

        ),
        // Divider used between sections
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
        ),
        // SnackBar - success/error toasts at the bottom
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.bgElevated,
          contentTextStyle: const TextStyle(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),

    );
  }
}
