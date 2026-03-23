import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_logger.dart';
import '../widgets/neon_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  bool _isBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    logUiAction(
      'Submitted auth form: ${_tabController.index == 0 ? 'login' : 'sign_up'}',
    );
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final session = _tabController.index == 0
          ? await widget.authService.login(
              username: _usernameController.text,
              password: _passwordController.text,
            )
          : await widget.authService.signUp(
              username: _usernameController.text,
              password: _passwordController.text,
            );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop<AuthSession>(session);
    } on AuthException catch (error) {
      setState(() {
        _error = error.message;
      });
    } catch (_) {
      setState(() {
        _error = 'The auth gremlin ate your credentials. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Login'),
            Tab(text: 'Sign up'),
          ],
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep your alibis, stats, and wall posts tied to one account.',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              hintText: 'pick a dramatic alias',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              hintText: 'at least 6 characters',
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _error!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: palette.error),
                            ),
                          ],
                          const SizedBox(height: 20),
                          NeonButton(
                            onPressed: _isBusy ? null : _submit,
                            label: _tabController.index == 0
                                ? 'Log in'
                                : 'Create account',
                            icon: Icons.key_rounded,
                            isBusy: _isBusy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
