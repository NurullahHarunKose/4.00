import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getTheme(String themeName) {
    switch (themeName) {
      case 'dark':
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.grey,
            brightness: Brightness.dark,
          ),
          fontFamily: 'Consolas', // Desktop app used Consolas for dark theme
        );
      case 'blue':
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5A8DEE),
            background: const Color(0xFFEAF3FF),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF5A8DEE),
            foregroundColor: Colors.white,
          ),
        );
      case 'yellow':
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFCA28),
            background: const Color(0xFFFFF8E1),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFFCA28),
            foregroundColor: Color(0xFF4A3C0A),
          ),
        );
      case 'light':
      default:
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueGrey,
            brightness: Brightness.light,
          ),
        );
    }
  }
}
