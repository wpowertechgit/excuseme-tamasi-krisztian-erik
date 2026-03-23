import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/public_wall_post.dart';
import '../services/excuse_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_logger.dart';

class HallOfFameScreen extends StatefulWidget {
  const HallOfFameScreen({
    super.key,
    required this.apiService,
  });

  final ExcuseApiService apiService;

  @override
  State<HallOfFameScreen> createState() => _HallOfFameScreenState();
}

class _HallOfFameScreenState extends State<HallOfFameScreen> {
  bool _weekly = false;
  late Future<List<PublicWallPost>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.fetchLeaderboard();
  }

  void _reload({required bool weekly}) {
    setState(() {
      _weekly = weekly;
      _future = widget.apiService.fetchLeaderboard(weekly: weekly);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Hall of Fame')),
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
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: false, label: Text('All time')),
                ButtonSegment<bool>(value: true, label: Text('This week')),
              ],
              selected: {_weekly},
              onSelectionChanged: (selection) {
                logUiAction(
                  'Selected leaderboard window: ${selection.first ? 'week' : 'all'}',
                );
                _reload(weekly: selection.first);
              },
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
                      child: Text('Could not load the leaderboard right now.'),
                    ),
                  );
                }
                final posts = snapshot.data ?? const <PublicWallPost>[];
                if (posts.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No public legends yet.'),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < posts.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${i + 1} @${posts[i].username}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                _RankedPostCard(post: posts[i]),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RankedPostCard extends StatelessWidget {
  const _RankedPostCard({required this.post});

  final PublicWallPost post;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(post.category.label)),
            Chip(label: Text(post.style.label)),
            Chip(label: Text('${post.totalReactions} reactions')),
          ],
        ),
        const SizedBox(height: 10),
        Text(post.excuse, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Truth: ${post.truth}',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: palette.mutedText),
        ),
        const SizedBox(height: 8),
        Text(DateFormat('MMM d, HH:mm').format(post.createdAt.toLocal())),
      ],
    );
  }
}
