import 'excuse_category.dart';

class ExcuseResponse {
  const ExcuseResponse({
    required this.generationId,
    required this.excuse,
    required this.detectedLanguage,
    required this.style,
    required this.category,
  });

  final String generationId;
  final String excuse;
  final String detectedLanguage;
  final String style;
  final ExcuseCategory category;

  factory ExcuseResponse.fromJson(Map<String, dynamic> json) {
    return ExcuseResponse(
      generationId: json['generationId'] as String? ?? '',
      excuse: json['excuse'] as String? ?? '',
      detectedLanguage: json['detectedLanguage'] as String? ?? 'unknown',
      style: json['style'] as String? ?? 'goofy',
      category: ExcuseCategory.fromApi(json['category'] as String?),
    );
  }
}
