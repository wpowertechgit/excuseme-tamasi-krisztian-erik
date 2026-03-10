import 'package:flutter/material.dart';

import '../models/alibi_style.dart';
import '../models/excuse_response.dart';
import 'neon_button.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.truth,
    required this.response,
    required this.style,
    required this.onPost,
    required this.onRegenerate,
    this.isPosting = false,
  });

  final String truth;
  final ExcuseResponse response;
  final AlibiStyle style;
  final VoidCallback onPost;
  final VoidCallback onRegenerate;
  final bool isPosting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(style.label)),
                Chip(label: Text(response.detectedLanguage.toUpperCase())),
              ],
            ),
            const SizedBox(height: 16),
            Text('Pathetic truth', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              truth,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Text('Legendary alibi', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              response.excuse,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRegenerate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Roll again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeonButton(
                    onPressed: onPost,
                    label: 'Post to wall',
                    icon: Icons.campaign_outlined,
                    isBusy: isPosting,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
