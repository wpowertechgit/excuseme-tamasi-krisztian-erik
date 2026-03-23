import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/excuse_category.dart';
import '../models/public_wall_post.dart';
import '../services/excuse_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_logger.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({
    super.key,
    required this.apiService,
  });

  final ExcuseApiService apiService;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  ExcuseCategory _selected = ExcuseCategory.work;
  late Future<List<PublicWallPost>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.fetchCategoryFeed(_selected);
  }

  void _select(ExcuseCategory category) {
    logUiAction('Selected category feed: ${category.apiValue}');
    setState(() {
      _selected = category;
      _future = widget.apiService.fetchCategoryFeed(category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.backgroundGradient,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in ExcuseCategory.values)
                  ChoiceChip(
                    label: Text(category.label),
                    selected: _selected == category,
                    onSelected: (_) => _select(category),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FutureBuilder<List<PublicWallPost>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('Could not load that category right now.'),
                    ),
                  );
                }
                final posts = snapshot.data ?? const <PublicWallPost>[];
                if (posts.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text('No public excuses in ${_selected.label} yet.'),
                    ),
                  );
                }
                return Column(
                  children: posts
                      .map(
                        (post) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PublicPostCard(post: post),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicPostCard extends StatelessWidget {
  const _PublicPostCard({required this.post});

  final PublicWallPost post;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('@${post.username}')),
                Chip(label: Text(post.category.label)),
                Chip(label: Text(post.style.label)),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.excuse, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Truth: ${post.truth}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: palette.mutedText),
            ),
            const SizedBox(height: 10),
            Text(
              '${post.totalReactions} reactions • ${DateFormat('MMM d, HH:mm').format(post.createdAt.toLocal())}',
            ),
          ],
        ),
      ),
    );
  }
}
