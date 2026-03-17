import 'package:flutter/material.dart';

import '../models/app_visual_theme.dart';
import '../theme/app_theme.dart';

class ThemeModeSwitch extends StatelessWidget {
  const ThemeModeSwitch({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AppVisualTheme selected;
  final ValueChanged<AppVisualTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App theme',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Pick a vibe without giving up half the screen.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.paletteOf(context).mutedText,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: AppVisualTheme.values
              .map(
                (mode) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ThemeOptionCard(
                    mode: mode,
                    isSelected: selected == mode,
                    onTap: () => onChanged(mode),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final AppVisualTheme mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppTheme.paletteOf(context);
    final preview = AppTheme.paletteFor(mode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? palette.accent.withValues(alpha: 0.12) : palette.panelSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? palette.accent : palette.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _ThemePreviewCircle(
                palette: preview,
                isSelected: isSelected,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isSelected ? Icons.check_circle : Icons.chevron_right,
                color: isSelected ? palette.accent : palette.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewCircle extends StatelessWidget {
  const _ThemePreviewCircle({
    required this.palette,
    required this.isSelected,
  });

  final AppPalette palette;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: isSelected ? 1 : 0.96,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.backgroundGradient,
          ),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
            width: isSelected ? 2.2 : 1.2,
          ),
        ),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.accent,
              boxShadow: [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
