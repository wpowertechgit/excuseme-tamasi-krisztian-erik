import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    http.Client? client,
    SharedPreferences? preferences,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _preferences = preferences,
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000',
            );

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'auth_username';
  static const _isAdminKey = 'auth_is_admin';

  final http.Client _client;
  final SharedPreferences? _preferences;
  final String _baseUrl;

  Future<SharedPreferences> get _prefs async {
    final preferences = _preferences;
    if (preferences != null) {
      return preferences;
    }
    return SharedPreferences.getInstance();
  }

  Future<AuthSession?> loadSession() async {
    final prefs = await _prefs;
    final token = prefs.getString(_tokenKey);
    final username = prefs.getString(_usernameKey);
    final isAdmin = prefs.getBool(_isAdminKey) ?? false;
    if (token == null || username == null || token.isEmpty || username.isEmpty) {
      return null;
    }
    return AuthSession(
      token: token,
      username: username,
      isAdmin: isAdmin,
    );
  }

  Future<AuthSession> signUp({
    required String username,
    required String password,
  }) {
    return _authenticate(
      path: '/api/auth/signup',
      username: username,
      password: password,
    );
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    return _authenticate(
      path: '/api/auth/login',
      username: username,
      password: password,
    );
  }

  Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_isAdminKey);
  }

  Future<AuthSession> _authenticate({
    required String path,
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
      }),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(
        json['detail'] as String? ?? 'Authentication failed.',
      );
    }
    final session = AuthSession(
      token: json['token'] as String? ?? '',
      username: json['username'] as String? ?? username.trim(),
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_usernameKey, session.username);
    await prefs.setBool(_isAdminKey, session.isAdmin);
    return session;
  }
}
