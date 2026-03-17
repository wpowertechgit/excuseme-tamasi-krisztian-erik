import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_visual_theme.dart';

class AppTheme {
  static const AppPalette _defaultPalette = AppPalette(
    backgroundStart: Color(0xFF050816),
    backgroundMiddle: Color(0xFF0B1430),
    backgroundEnd: Color(0xFF1B0937),
    panel: Color(0xFF11162A),
    panelSoft: Color(0x14FFFFFF),
    border: Color(0xFF4DF7FF),
    accent: Color(0xFF4DF7FF),
    accentSecondary: Color(0xFFFF4DB8),
    mutedText: Color(0xB3F3F7FF),
    shellBackground: Color(0x14FFFFFF),
    shellBorder: Color(0xFF4DF7FF),
    buttonText: Color(0xFF07111B),
    buttonShadow: Color(0x664DF7FF),
    error: Color(0xFFFF8FBF),
    goofyAccent: Color(0xFF4DF7FF),
    seriousAccent: Color(0xFFFF4DB8),
  );

  static const AppPalette _darkPalette = AppPalette(
    backgroundStart: Color(0xFF0B0D12),
    backgroundMiddle: Color(0xFF12161C),
    backgroundEnd: Color(0xFF1A1F27),
    panel: Color(0xFF171B22),
    panelSoft: Color(0xFF1E242D),
    border: Color(0xFF384250),
    accent: Color(0xFF9FB3C8),
    accentSecondary: Color(0xFF64748B),
    mutedText: Color(0xFFABB7C5),
    shellBackground: Color(0x1AFFFFFF),
    shellBorder: Color(0xFF4A5563),
    buttonText: Color(0xFFF5F7FA),
    buttonShadow: Color(0x33000000),
    error: Color(0xFFFF7A7A),
    goofyAccent: Color(0xFF7DD3FC),
    seriousAccent: Color(0xFFA78BFA),
  );

  static const AppPalette _applePalette = AppPalette(
    backgroundStart: Color(0xFFF7F8FB),
    backgroundMiddle: Color(0xFFEEF3FF),
    backgroundEnd: Color(0xFFFFFFFF),
    panel: Color(0xFFFDFEFF),
    panelSoft: Color(0xFFF2F5FA),
    border: Color(0xFFD8E0EC),
    accent: Color(0xFF0A84FF),
    accentSecondary: Color(0xFF5E5CE6),
    mutedText: Color(0xFF667085),
    shellBackground: Color(0xCCFFFFFF),
    shellBorder: Color(0xFFD8E0EC),
    buttonText: Color(0xFFFFFFFF),
    buttonShadow: Color(0x330A84FF),
    error: Color(0xFFFF3B30),
    goofyAccent: Color(0xFF0A84FF),
    seriousAccent: Color(0xFFFF9F0A),
  );

  static ThemeData themeFor(AppVisualTheme theme) {
    return switch (theme) {
      AppVisualTheme.defaultMode => _buildTheme(
          brightness: Brightness.dark,
          palette: _defaultPalette,
          textThemeBuilder: GoogleFonts.spaceGroteskTextTheme,
        ),
      AppVisualTheme.darkMode => _buildTheme(
          brightness: Brightness.dark,
          palette: _darkPalette,
          textThemeBuilder: GoogleFonts.ibmPlexSansTextTheme,
        ),
      AppVisualTheme.appleMode => _buildTheme(
          brightness: Brightness.light,
          palette: _applePalette,
          textThemeBuilder: GoogleFonts.manropeTextTheme,
        ),
    };
  }

  static AppPalette paletteFor(AppVisualTheme theme) {
    return switch (theme) {
      AppVisualTheme.defaultMode => _defaultPalette,
      AppVisualTheme.darkMode => _darkPalette,
      AppVisualTheme.appleMode => _applePalette,
    };
  }

  static AppPalette paletteOf(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? _defaultPalette;
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppPalette palette,
    required TextTheme Function(TextTheme) textThemeBuilder,
  }) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final textColor = brightness == Brightness.dark
        ? const Color(0xFFF3F7FF)
        : const Color(0xFF101318);
    final textTheme = textThemeBuilder(base.textTheme).apply(
      bodyColor: textColor,
      displayColor: textColor,
    );
    final colorScheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: palette.accent,
            secondary: palette.accentSecondary,
            surface: palette.panel,
            onSurface: textColor,
            onPrimary: palette.buttonText,
            error: palette.error,
          )
        : ColorScheme.light(
            primary: palette.accent,
            secondary: palette.accentSecondary,
            surface: palette.panel,
            onSurface: textColor,
            onPrimary: palette.buttonText,
            error: palette.error,
          );

    return base.copyWith(
      scaffoldBackgroundColor: palette.backgroundStart,
      textTheme: textTheme,
      colorScheme: colorScheme,
      dividerColor: palette.border,
      extensions: <ThemeExtension<dynamic>>[palette],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.panel,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: palette.accent, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: palette.accent, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.panel
            .withValues(alpha: brightness == Brightness.dark ? 0.95 : 0.98),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: palette.border, width: 1),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.panelSoft,
        selectedColor: palette.accent.withValues(alpha: 0.18),
        side: BorderSide(color: palette.border),
        labelStyle: textTheme.labelLarge,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          foregroundColor: textColor,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: textColor,
        unselectedLabelColor: palette.mutedText,
        indicatorColor: palette.accent,
      ),
    );
  }
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.backgroundStart,
    required this.backgroundMiddle,
    required this.backgroundEnd,
    required this.panel,
    required this.panelSoft,
    required this.border,
    required this.accent,
    required this.accentSecondary,
    required this.mutedText,
    required this.shellBackground,
    required this.shellBorder,
    required this.buttonText,
    required this.buttonShadow,
    required this.error,
    required this.goofyAccent,
    required this.seriousAccent,
  });

  final Color backgroundStart;
  final Color backgroundMiddle;
  final Color backgroundEnd;
  final Color panel;
  final Color panelSoft;
  final Color border;
  final Color accent;
  final Color accentSecondary;
  final Color mutedText;
  final Color shellBackground;
  final Color shellBorder;
  final Color buttonText;
  final Color buttonShadow;
  final Color error;
  final Color goofyAccent;
  final Color seriousAccent;

  List<Color> get backgroundGradient => [
        backgroundStart,
        backgroundMiddle,
        backgroundEnd,
      ];

  @override
  AppPalette copyWith({
    Color? backgroundStart,
    Color? backgroundMiddle,
    Color? backgroundEnd,
    Color? panel,
    Color? panelSoft,
    Color? border,
    Color? accent,
    Color? accentSecondary,
    Color? mutedText,
    Color? shellBackground,
    Color? shellBorder,
    Color? buttonText,
    Color? buttonShadow,
    Color? error,
    Color? goofyAccent,
    Color? seriousAccent,
  }) {
    return AppPalette(
      backgroundStart: backgroundStart ?? this.backgroundStart,
      backgroundMiddle: backgroundMiddle ?? this.backgroundMiddle,
      backgroundEnd: backgroundEnd ?? this.backgroundEnd,
      panel: panel ?? this.panel,
      panelSoft: panelSoft ?? this.panelSoft,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      mutedText: mutedText ?? this.mutedText,
      shellBackground: shellBackground ?? this.shellBackground,
      shellBorder: shellBorder ?? this.shellBorder,
      buttonText: buttonText ?? this.buttonText,
      buttonShadow: buttonShadow ?? this.buttonShadow,
      error: error ?? this.error,
      goofyAccent: goofyAccent ?? this.goofyAccent,
      seriousAccent: seriousAccent ?? this.seriousAccent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      backgroundStart: Color.lerp(backgroundStart, other.backgroundStart, t)!,
      backgroundMiddle:
          Color.lerp(backgroundMiddle, other.backgroundMiddle, t)!,
      backgroundEnd: Color.lerp(backgroundEnd, other.backgroundEnd, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelSoft: Color.lerp(panelSoft, other.panelSoft, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      shellBackground: Color.lerp(shellBackground, other.shellBackground, t)!,
      shellBorder: Color.lerp(shellBorder, other.shellBorder, t)!,
      buttonText: Color.lerp(buttonText, other.buttonText, t)!,
      buttonShadow: Color.lerp(buttonShadow, other.buttonShadow, t)!,
      error: Color.lerp(error, other.error, t)!,
      goofyAccent: Color.lerp(goofyAccent, other.goofyAccent, t)!,
      seriousAccent: Color.lerp(seriousAccent, other.seriousAccent, t)!,
    );
  }
}
