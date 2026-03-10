import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/alibi_style.dart';
import '../models/excuse_response.dart';

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
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000',
            );

  final http.Client _client;
  final String _baseUrl;

  Future<ExcuseResponse> generateExcuse({
    required String truth,
    required AlibiStyle style,
  }) async {
    final trimmedTruth = truth.trim();
    if (trimmedTruth.isEmpty) {
      throw const ExcuseApiException('Truth cannot be empty.');
    }

    final uri = Uri.parse('$_baseUrl/api/excuses/generate');
    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
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
}
