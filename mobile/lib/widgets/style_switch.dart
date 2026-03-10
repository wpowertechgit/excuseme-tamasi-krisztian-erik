import 'package:flutter/material.dart';

import '../models/alibi_style.dart';

class StyleSwitch extends StatelessWidget {
  const StyleSwitch({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AlibiStyle selected;
  final ValueChanged<AlibiStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your lie strategy',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: AlibiStyle.values
              .map(
                (style) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: style == AlibiStyle.goofy ? 8 : 0,
                      left: style == AlibiStyle.serious ? 8 : 0,
                    ),
                    child: _StyleOptionCard(
                      style: style,
                      isSelected: selected == style,
                      onTap: () => onChanged(style),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Text(
          selected.description,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _StyleOptionCard extends StatelessWidget {
  const _StyleOptionCard({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  final AlibiStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = style == AlibiStyle.goofy
        ? const Color(0xFF4DF7FF)
        : const Color(0xFFFF4DB8);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? accent : Colors.white24,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                style == AlibiStyle.goofy
                    ? Icons.auto_awesome
                    : Icons.business_center_outlined,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  style.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
