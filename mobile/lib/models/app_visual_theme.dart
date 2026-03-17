enum AppVisualTheme {
  defaultMode,
  darkMode,
  appleMode;

  String get label => switch (this) {
        AppVisualTheme.defaultMode => 'Default',
        AppVisualTheme.darkMode => 'Dark',
        AppVisualTheme.appleMode => 'Apple',
      };

  String get description => switch (this) {
        AppVisualTheme.defaultMode => 'Neon chaos, same as the current app.',
        AppVisualTheme.darkMode => 'Muted contrast with a cleaner night look.',
        AppVisualTheme.appleMode =>
          'Bright glassy surfaces with a polished feel.',
      };
}
