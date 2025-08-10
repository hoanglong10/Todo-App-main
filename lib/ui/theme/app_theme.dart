import 'package:flutter/material.dart';

class AppTheme {
  // Theme sáng dựa trên màu nhấn
  static ThemeData lightFromAccent(Color accent) {
    final cs = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Theme tối dựa trên màu nhấn
  static ThemeData darkFromAccent(Color accent) {
    final cs = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF0F1116),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Gradient nền đổi theo theme + màu nhấn (nếu muốn dùng)
  static Gradient bgGradient(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base1 = isDark ? const Color(0xFF0F1629) : const Color(0xFFEFF3FF);
    final base2 = isDark ? const Color(0xFF111827) : const Color(0xFFE7ECFF);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [base1, base2, primary.withOpacity(.25)],
      stops: const [0, .6, 1],
    );
  }
}
