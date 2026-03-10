class ExcuseResponse {
  const ExcuseResponse({
    required this.excuse,
    required this.detectedLanguage,
    required this.style,
  });

  final String excuse;
  final String detectedLanguage;
  final String style;

  factory ExcuseResponse.fromJson(Map<String, dynamic> json) {
    return ExcuseResponse(
      excuse: json['excuse'] as String? ?? '',
      detectedLanguage: json['detectedLanguage'] as String? ?? 'unknown',
      style: json['style'] as String? ?? 'goofy',
    );
  }
}
