import 'package:flutter/material.dart';

import '../models/stats_overview.dart';
import '../services/excuse_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_logger.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.apiService,
    required this.username,
  });

  final ExcuseApiService apiService;
  final String username;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<StatsOverview> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.fetchStats();
  }

  void _reload() {
    logUiAction('Pressed button: Retry stats');
    setState(() {
      _future = widget.apiService.fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.backgroundGradient,
          ),
        ),
        child: FutureBuilder<StatsOverview>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Could not load your stats.',
                onRetry: _reload,
              );
            }

            final stats = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${widget.username}, here is the damage report.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      label: 'Generated',
                      value: '${stats.totalGenerations}',
                    ),
                    _MetricCard(
                      label: 'Posted',
                      value: '${stats.publishedCount}',
                    ),
                    _MetricCard(
                      label: 'Private',
                      value: '${stats.totalGenerations - stats.publishedCount}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _BucketSection(
                  title: 'Category mix',
                  buckets: stats.categoryBreakdown,
                ),
                const SizedBox(height: 16),
                _BucketSection(
                  title: 'Style split',
                  buckets: stats.styleBreakdown,
                ),
                const SizedBox(height: 16),
                _BucketSection(
                  title: 'Language mix',
                  buckets: stats.languageBreakdown,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent activity',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        if (stats.dailyActivity.isEmpty)
                          const Text('No excuse activity yet.')
                        else
                          for (final point in stats.dailyActivity)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 96,
                                    child: Text(point.date),
                                  ),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: point.count /
                                          stats.dailyActivity
                                              .map((item) => item.count)
                                              .fold<int>(1, (a, b) => a > b ? a : b),
                                      minHeight: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('${point.count}'),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BucketSection extends StatelessWidget {
  const _BucketSection({
    required this.title,
    required this.buckets,
  });

  final String title;
  final List<CountBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxValue = buckets.isEmpty
        ? 1
        : buckets
            .map((bucket) => bucket.value)
            .fold<int>(1, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            if (buckets.isEmpty)
              const Text('Nothing to chart yet.')
            else
              for (final bucket in buckets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 96, child: Text(bucket.label)),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: bucket.value / maxValue,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${bucket.value}'),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
