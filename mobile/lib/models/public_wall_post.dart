import 'alibi_style.dart';
import 'excuse_category.dart';

class PublicWallPost {
  const PublicWallPost({
    required this.id,
    required this.username,
    required this.truth,
    required this.excuse,
    required this.style,
    required this.detectedLanguage,
    required this.category,
    required this.reactions,
    required this.totalReactions,
    required this.createdAt,
    required this.generationId,
  });

  final String id;
  final String username;
  final String truth;
  final String excuse;
  final AlibiStyle style;
  final String detectedLanguage;
  final ExcuseCategory category;
  final Map<String, int> reactions;
  final int totalReactions;
  final DateTime createdAt;
  final String generationId;

  factory PublicWallPost.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'] as Map<String, dynamic>? ?? const {};
    return PublicWallPost(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'anonymous',
      truth: json['truth'] as String? ?? '',
      excuse: json['excuse'] as String? ?? '',
      style: AlibiStyle.values.firstWhere(
        (style) => style.apiValue == (json['style'] as String? ?? 'goofy'),
        orElse: () => AlibiStyle.goofy,
      ),
      detectedLanguage: json['detectedLanguage'] as String? ?? 'unknown',
      category: ExcuseCategory.fromApi(json['category'] as String?),
      reactions: {
        for (final entry in rawReactions.entries)
          entry.key: (entry.value as num?)?.toInt() ?? 0,
      },
      totalReactions: (json['totalReactions'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      generationId: json['generationId'] as String? ?? '',
    );
  }
}
