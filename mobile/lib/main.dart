import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'firebase_options.dart';
import 'models/alibi_style.dart';
import 'models/app_visual_theme.dart';
import 'models/excuse_response.dart';
import 'models/wall_post.dart';
import 'services/excuse_api_service.dart';
import 'services/wall_service.dart';
import 'theme/app_theme.dart';
import 'widgets/neon_button.dart';
import 'widgets/result_card.dart';
import 'widgets/style_switch.dart';
import 'widgets/theme_mode_switch.dart';

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

class ExcuseMeApp extends StatefulWidget {
  const ExcuseMeApp({super.key});

  @override
  State<ExcuseMeApp> createState() => _ExcuseMeAppState();
}

class _ExcuseMeAppState extends State<ExcuseMeApp> {
  AppVisualTheme _selectedTheme = AppVisualTheme.defaultMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Excuse Me',
      theme: AppTheme.themeFor(_selectedTheme),
      home: ExcuseHomePage(
        selectedTheme: _selectedTheme,
        onThemeChanged: (theme) {
          setState(() {
            _selectedTheme = theme;
          });
        },
      ),
    );
  }
}

class ExcuseHomePage extends StatefulWidget {
  const ExcuseHomePage({
    super.key,
    this.selectedTheme = AppVisualTheme.defaultMode,
    this.onThemeChanged,
    ExcuseApiService? apiService,
    WallService? wallService,
  })  : _apiService = apiService,
        _wallService = wallService;

  final AppVisualTheme selectedTheme;
  final ValueChanged<AppVisualTheme>? onThemeChanged;
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
    final theme = Theme.of(context);
    final palette = AppTheme.paletteOf(context);

    return Scaffold(
      endDrawer: Drawer(
        backgroundColor: palette.panel,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme studio',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Switch the app look without crowding the main screen.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.mutedText,
                  ),
                ),
                const SizedBox(height: 20),
                ThemeModeSwitch(
                  selected: widget.selectedTheme,
                  onChanged: (nextTheme) {
                    widget.onThemeChanged?.call(nextTheme);
                    Navigator.of(context).maybePop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _BrandLogo(palette: palette),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Excuse Me',
                                      style: GoogleFonts.roboto(
                                        textStyle:
                                            theme.textTheme.headlineMedium,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Turning your pathetic truths into legendary alibis.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: palette.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: palette.shellBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: palette.shellBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${widget.selectedTheme.label} mode'),
                              const SizedBox(width: 8),
                              Builder(
                                builder: (context) => InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => Scaffold.of(context).openEndDrawer(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.accent.withValues(alpha: 0.95),
            palette.accentSecondary.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.28),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: palette.accentSecondary.withValues(alpha: 0.18),
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.panel,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/excuse_me_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.auto_awesome,
                color: palette.accent,
                size: 28,
              ),
            ),
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
    final palette = AppTheme.paletteOf(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.panelSoft,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: palette.border),
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
                    ?.copyWith(color: palette.mutedText),
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
                      ?.copyWith(color: palette.error),
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
    final palette = AppTheme.paletteOf(context);

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
                              ?.copyWith(color: palette.mutedText),
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
                          ?.copyWith(color: palette.mutedText),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'React to this disaster',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final emoji in WallPost.supportedReactions) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  wallService.incrementReaction(post.id, emoji),
                              child: Text(
                                '$emoji ${post.reactions[emoji] ?? 0}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          if (emoji != WallPost.supportedReactions.last)
                            const SizedBox(width: 10),
                        ],
                      ],
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
