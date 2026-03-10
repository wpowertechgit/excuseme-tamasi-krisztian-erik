import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _bg = Color(0xFF050816);
  static const _panel = Color(0xFF11162A);
  static const _cyan = Color(0xFF4DF7FF);
  static const _pink = Color(0xFFFF4DB8);
  static const _lime = Color(0xFFC8FF64);
  static const _text = Color(0xFFF3F7FF);

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
      bodyColor: _text,
      displayColor: _text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: _bg,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: _cyan,
        secondary: _pink,
        surface: _panel,
        onSurface: _text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _cyan, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _pink, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _cyan, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: _panel.withValues(alpha: 0.95),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: _cyan, width: 1),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: _panel,
        selectedColor: _lime,
        side: const BorderSide(color: _cyan),
      ),
    );
  }
}
