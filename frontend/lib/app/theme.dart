import 'package:flutter/material.dart';

class AppColors {
  static const seed = Color(0xFF3F6AF6);
  static const success = Color(0xFF2FB380);
  static const warning = Color(0xFFF2A93B);
  static const danger = Color(0xFFE0526A);
  static const bgLight = Color(0xFFF6F7FB);
  static const cardLight = Colors.white;
}

class AppTheme {
  static ThemeData light() {
    final base = ColorScheme.fromSeed(seedColor: AppColors.seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.bgLight,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: base.surfaceContainerHighest.withValues(alpha: 0.5),
        selectedColor: base.primary.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.seed,
        unselectedItemColor: Color(0xFF9AA3B2),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: Color(0xFF5C6472)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEDEFF4), space: 1),
    );
  }
}
