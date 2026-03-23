import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/alibi_style.dart';
import '../models/excuse_category.dart';
import '../models/excuse_response.dart';
import '../models/history_entry.dart';
import '../models/public_wall_post.dart';
import '../models/stats_overview.dart';
import '../models/wall_post.dart';

class ExcuseApiException implements Exception {
  const ExcuseApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExcuseApiService {
  ExcuseApiService({
    http.Client? client,
    String? baseUrl,
    String? Function()? authTokenProvider,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000',
            ),
        _authTokenProvider = authTokenProvider;

  final http.Client _client;
  final String _baseUrl;
  final String? Function()? _authTokenProvider;

  Map<String, String> _jsonHeaders({bool authenticated = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      final token = _authTokenProvider?.call();
      if (token == null || token.isEmpty) {
        throw const ExcuseApiException('Sign in to keep generating excuses.');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<ExcuseResponse> generateExcuse({
    required String truth,
    required AlibiStyle style,
  }) async {
    final trimmedTruth = truth.trim();
    if (trimmedTruth.isEmpty) {
      throw const ExcuseApiException('Truth cannot be empty.');
    }

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/excuses/generate'),
          headers: _jsonHeaders(authenticated: true),
          body: jsonEncode({
            'truth': trimmedTruth,
            'style': style.apiValue,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ExcuseApiException(
        json['detail'] as String? ?? 'The alibi engine gave up.',
      );
    }

    return ExcuseResponse.fromJson(json);
  }

  Future<void> publishGeneration(String generationId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/wall/publish/$generationId'),
      headers: _jsonHeaders(authenticated: true),
    );
    final json = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ExcuseApiException(
        json['detail'] as String? ?? 'Publishing failed.',
      );
    }
  }

  Future<List<WallPost>> fetchWallFeed() async {
    final response = await _client.get(Uri.parse('$_baseUrl/api/wall'));
    if (response.statusCode >= 400) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw ExcuseApiException(
        json['detail'] as String? ?? 'Could not load wall posts.',
      );
    }
    final json = jsonDecode(response.body) as List<dynamic>;
    return json.whereType<Map<String, dynamic>>().map(WallPost.fromJson).toList();
  }

  Future<void> incrementWallReaction(String postId, String emoji) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/wall/react/$postId'),
      headers: _jsonHeaders(),
      body: jsonEncode({'emoji': emoji}),
    );
    if (response.statusCode >= 400) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw ExcuseApiException(
        json['detail'] as String? ?? 'Could not update reaction.',
      );
    }
  }

  Future<void> deleteWallPost(String postId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/api/admin/wall/$postId'),
      headers: _jsonHeaders(authenticated: true),
    );
    if (response.statusCode >= 400) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw ExcuseApiException(
        json['detail'] as String? ?? 'Could not delete wall post.',
      );
    }
  }

  Future<List<HistoryEntry>> fetchHistory() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/history'),
      headers: _jsonHeaders(authenticated: true),
    );
    if (response.statusCode >= 400) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw ExcuseApiException(
        json['detail'] as String? ?? 'Could not load excuse history.',
      );
    }
    final json = jsonDecode(response.body) as List<dynamic>;
    return json
        .whereType<Map<String, dynamic>>()
        .map(HistoryEntry.fromJson)
        .toList();
  }

  Future<StatsOverview> fetchStats() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/stats/overview'),
      headers: _jsonHeaders(authenticated: true),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ExcuseApiException(
        json['detail'] as String? ?? 'Could not load statistics.',
      );
    }
    return StatsOverview.fromJson(json);
  }

  Future<List<PublicWallPost>> fetchCategoryFeed(ExcuseCategory category) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/categories/${category.apiValue}'),
    );
    if (response.statusCode >= 400) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw ExcuseApiException(
        json['detail'] as String? ?? 'Could not load category feed.',
      );
    }
    final json = jsonDecode(response.body) as List<dynamic>;
    return json
        .whereType<Map<String, dynamic>>()
        .map(PublicWallPost.fromJson)
        .toList();
  }

  Future<List<PublicWallPost>> fetchLeaderboard({bool weekly = false}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/leaderboard?window=${weekly ? 'week' : 'all'}'),
    );
    if (response.statusCode >= 400) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw ExcuseApiException(
        json['detail'] as String? ?? 'Could not load leaderboard.',
      );
    }
    final json = jsonDecode(response.body) as List<dynamic>;
    return json
        .whereType<Map<String, dynamic>>()
        .map(PublicWallPost.fromJson)
        .toList();
  }
}
