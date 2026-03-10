import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'firebase_options.dart';
import 'models/alibi_style.dart';
import 'models/excuse_response.dart';
import 'models/wall_post.dart';
import 'services/excuse_api_service.dart';
import 'services/wall_service.dart';
import 'theme/app_theme.dart';
import 'widgets/neon_button.dart';
import 'widgets/result_card.dart';
import 'widgets/style_switch.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Allow the app shell to run even before Firebase credentials are configured.
  }
  runApp(const ExcuseMeApp());
}

class ExcuseMeApp extends StatelessWidget {
  const ExcuseMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Excuse Me',
      theme: AppTheme.darkTheme,
      home: const ExcuseHomePage(),
    );
  }
}

class ExcuseHomePage extends StatefulWidget {
  const ExcuseHomePage({
    super.key,
    ExcuseApiService? apiService,
    WallService? wallService,
  })  : _apiService = apiService,
        _wallService = wallService;

  final ExcuseApiService? _apiService;
  final WallService? _wallService;

  @override
  State<ExcuseHomePage> createState() => _ExcuseHomePageState();
}

class _ExcuseHomePageState extends State<ExcuseHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _truthController;
  late final ExcuseApiService _apiService;
  late final WallService _wallService;

  AlibiStyle _selectedStyle = AlibiStyle.goofy;
  ExcuseResponse? _response;
  bool _isGenerating = false;
  bool _isPosting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _truthController = TextEditingController()..addListener(_handleTextChange);
    _apiService = widget._apiService ?? ExcuseApiService();
    _wallService = widget._wallService ?? WallService();
  }

  void _handleTextChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _truthController
      ..removeListener(_handleTextChange)
      ..dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final response = await _apiService.generateExcuse(
        truth: _truthController.text,
        style: _selectedStyle,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _response = response;
      });
    } on TimeoutException {
      setState(() {
        _error = 'The liar on the server took too long. Try again.';
      });
    } on ExcuseApiException catch (error) {
      setState(() {
        _error = error.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Something broke between your shame and the server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _postCurrent() async {
    final response = _response;
    if (response == null) {
      return;
    }

    setState(() {
      _isPosting = true;
      _error = null;
    });

    try {
      await _wallService.addPost(
        truth: _truthController.text,
        excuse: response,
        style: _selectedStyle,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your nonsense is now public.')),
      );
      _tabController.animateTo(1);
    } catch (_) {
      setState(() {
        _error = 'Posting failed. Firebase is probably not configured yet.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050816),
              Color(0xFF0B1430),
              Color(0xFF1B0937),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXCUSE ME',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Turning your pathetic truths into legendary alibis.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF4DF7FF)),
                      ),
                      child: const Text('XD mode enabled'),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Generator'),
                  Tab(text: 'Wall of Shame'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _GeneratorTab(
                      truthController: _truthController,
                      selectedStyle: _selectedStyle,
                      onStyleChanged: (style) {
                        setState(() {
                          _selectedStyle = style;
                        });
                      },
                      onGenerate: _generate,
                      response: _response,
                      error: _error,
                      isGenerating: _isGenerating,
                      isPosting: _isPosting,
                      onPost: _postCurrent,
                    ),
                    _WallTab(wallService: _wallService),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneratorTab extends StatelessWidget {
  const _GeneratorTab({
    required this.truthController,
    required this.selectedStyle,
    required this.onStyleChanged,
    required this.onGenerate,
    required this.response,
    required this.error,
    required this.isGenerating,
    required this.isPosting,
    required this.onPost,
  });

  final TextEditingController truthController;
  final AlibiStyle selectedStyle;
  final ValueChanged<AlibiStyle> onStyleChanged;
  final VoidCallback onGenerate;
  final ExcuseResponse? response;
  final String? error;
  final bool isGenerating;
  final bool isPosting;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confess the truth',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Example: "I am late because I was on the toilet."',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: truthController,
                maxLines: 5,
                maxLength: 240,
                decoration: const InputDecoration(
                  hintText: 'Dump your humiliating truth here.',
                ),
              ),
              const SizedBox(height: 12),
              StyleSwitch(
                selected: selectedStyle,
                onChanged: onStyleChanged,
              ),
              const SizedBox(height: 20),
              NeonButton(
                onPressed:
                    truthController.text.trim().isEmpty ? null : onGenerate,
                label: 'SAVE ME',
                icon: Icons.bolt,
                isBusy: isGenerating,
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(
                  error!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xFFFF8FBF)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (response != null)
          ResultCard(
            truth: truthController.text.trim(),
            response: response!,
            style: selectedStyle,
            onRegenerate: onGenerate,
            onPost: onPost,
            isPosting: isPosting,
          ),
      ],
    );
  }
}

class _WallTab extends StatelessWidget {
  const _WallTab({required this.wallService});

  final WallService wallService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WallPost>>(
      stream: wallService.streamPosts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Firestore is not ready yet.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!;
        if (posts.isEmpty) {
          return const Center(
            child: Text('No public humiliation yet. Be the first.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final post = posts[index];
            final stamp = post.createdAt == null
                ? 'just now'
                : DateFormat('MMM d, HH:mm').format(post.createdAt!.toLocal());
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(label: Text(post.style.toUpperCase())),
                        const SizedBox(width: 8),
                        Text(
                          stamp,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.excuse,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Original truth: ${post.truth}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => wallService.incrementLol(post.id),
                        icon: const Icon(Icons.sentiment_very_satisfied),
                        label: Text('LOL ${post.lolCount}'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
