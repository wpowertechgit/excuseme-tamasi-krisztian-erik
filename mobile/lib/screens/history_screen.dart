import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/excuse_category.dart';
import '../models/history_entry.dart';
import '../services/excuse_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_logger.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.apiService,
    required this.onReuse,
  });

  final ExcuseApiService apiService;
  final ValueChanged<HistoryEntry> onReuse;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryEntry>> _future;
  ExcuseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.fetchHistory();
  }

  void _reload() {
    logUiAction('Pressed button: Refresh history');
    setState(() {
      _future = widget.apiService.fetchHistory();
    });
  }

  Future<void> _publish(HistoryEntry entry) async {
    logUiAction('Pressed history action: Post to wall for ${entry.id}');
    await widget.apiService.publishGeneration(entry.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My History')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.backgroundGradient,
          ),
        ),
        child: FutureBuilder<List<HistoryEntry>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _HistoryMessage(
                message: 'Could not load your excuse history.',
                action: OutlinedButton(
                  onPressed: _reload,
                  child: const Text('Try again'),
                ),
              );
            }

            final allEntries = snapshot.data ?? const <HistoryEntry>[];
            final entries = _selectedCategory == null
                ? allEntries
                : allEntries
                    .where((entry) => entry.category == _selectedCategory)
                    .toList();
            if (allEntries.isEmpty) {
              return const _HistoryMessage(
                message: 'You have not generated any alibis yet.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        logUiAction('Selected history filter: all');
                        setState(() {
                          _selectedCategory = null;
                        });
                      },
                    ),
                    for (final category in ExcuseCategory.values)
                      FilterChip(
                        label: Text(category.label),
                        selected: _selectedCategory == category,
                        onSelected: (_) {
                          logUiAction(
                            'Selected history filter: ${category.apiValue}',
                          );
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                for (final entry in entries)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text(entry.category.label)),
                              Chip(label: Text(entry.style.label)),
                              Chip(label: Text(entry.detectedLanguage.toUpperCase())),
                              Chip(
                                label: Text(
                                  entry.publishedToWall ? 'Posted' : 'Private',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            entry.excuse,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Truth: ${entry.truth}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: palette.mutedText),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('MMM d, HH:mm')
                                .format(entry.createdAt.toLocal()),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    logUiAction(
                                      'Pressed history action: Reuse ${entry.id}',
                                    );
                                    widget.onReuse(entry);
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.replay_rounded),
                                  label: const Text('Reuse in generator'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: entry.publishedToWall
                                      ? null
                                      : () => _publish(entry),
                                  icon: const Icon(Icons.campaign_outlined),
                                  label: Text(
                                    entry.publishedToWall
                                        ? 'Already posted'
                                        : 'Post to wall',
                                  ),
                                ),
                              ),
                            ],
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

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.message,
    this.action,
  });

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
