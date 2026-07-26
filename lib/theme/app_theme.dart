import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: Brightness.light,
      primary: AppColors.primaryGreen,
      onPrimary: Colors.white,
      secondary: AppColors.darkGreen,
      surface: AppColors.card,
      onSurface: AppColors.primaryText,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'sans-serif',
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.display,
        headlineLarge: AppTextStyles.display,
        headlineMedium: AppTextStyles.pageTitle,
        headlineSmall: TextStyle(
          fontSize: 22,
          height: 1.18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.45,
          color: AppColors.primaryText,
        ),
        titleLarge: AppTextStyles.sectionTitle,
        titleMedium: AppTextStyles.cardTitle,
        titleSmall: TextStyle(
          fontSize: 14.5,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.bodyMuted,
        bodySmall: AppTextStyles.small,
        labelLarge: TextStyle(
          fontSize: 15,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.small,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 68,
        centerTitle: false,
        titleTextStyle: AppTextStyles.sectionTitle,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadow,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 19,
        ),
        labelStyle: AppTextStyles.bodyMuted,
        hintStyle: AppTextStyles.bodyMuted,
        floatingLabelStyle: const TextStyle(
          color: AppColors.darkGreen,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: AppColors.primaryGreen,
        suffixIconColor: AppColors.secondaryText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 1.6,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(58),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkGreen,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          side: const BorderSide(color: AppColors.primaryGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkGreen,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.border),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: AppTextStyles.sectionTitle,
        contentTextStyle: AppTextStyles.bodyMuted.copyWith(fontSize: 14.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryText,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.lightGreen,
        height: 70,
        iconTheme: WidgetStatePropertyAll(IconThemeData(size: 24)),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11.5, height: 1.15, fontWeight: FontWeight.w700),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryGreen,
        linearMinHeight: 8,
      ),
    );
  }
}
