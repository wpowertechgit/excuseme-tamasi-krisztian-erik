import 'alibi_style.dart';
import 'excuse_category.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.truth,
    required this.excuse,
    required this.style,
    required this.detectedLanguage,
    required this.category,
    required this.publishedToWall,
    required this.createdAt,
  });

  final String id;
  final String truth;
  final String excuse;
  final AlibiStyle style;
  final String detectedLanguage;
  final ExcuseCategory category;
  final bool publishedToWall;
  final DateTime createdAt;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String? ?? '',
      truth: json['truth'] as String? ?? '',
      excuse: json['excuse'] as String? ?? '',
      style: AlibiStyle.values.firstWhere(
        (style) => style.apiValue == (json['style'] as String? ?? 'goofy'),
        orElse: () => AlibiStyle.goofy,
      ),
      detectedLanguage: json['detectedLanguage'] as String? ?? 'unknown',
      category: ExcuseCategory.fromApi(json['category'] as String?),
      publishedToWall: json['publishedToWall'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

