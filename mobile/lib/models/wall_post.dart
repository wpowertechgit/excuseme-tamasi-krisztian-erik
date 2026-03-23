import 'package:cloud_firestore/cloud_firestore.dart';

import 'excuse_category.dart';

class WallPost {
  const WallPost({
    required this.id,
    required this.username,
    required this.truth,
    required this.excuse,
    required this.style,
    required this.language,
    required this.category,
    required this.generationId,
    required this.reactions,
    required this.createdAt,
  });

  static const List<String> supportedReactions = ['😂', '🔥', '💀', '🤡'];

  final String id;
  final String username;
  final String truth;
  final String excuse;
  final String style;
  final String language;
  final ExcuseCategory category;
  final String generationId;
  final Map<String, int> reactions;
  final DateTime? createdAt;

  int get totalReactions =>
      reactions.values.fold<int>(0, (sum, value) => sum + value);

  factory WallPost.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'] as Map<String, dynamic>? ?? const {};
    return WallPost(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'anonymous',
      truth: json['truth'] as String? ?? '',
      excuse: json['excuse'] as String? ?? '',
      style: json['style'] as String? ?? 'goofy',
      language: json['detectedLanguage'] as String? ?? 'unknown',
      category: ExcuseCategory.fromApi(json['category'] as String?),
      generationId: json['generationId'] as String? ?? '',
      reactions: {
        for (final emoji in supportedReactions)
          emoji: (rawReactions[emoji] as num?)?.toInt() ?? 0,
      },
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  factory WallPost.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawReactions = data['reactions'] as Map<String, dynamic>?;
    final legacyLolCount = (data['lolCount'] as num?)?.toInt() ?? 0;
    final reactions = <String, int>{
      for (final emoji in supportedReactions) emoji: 0,
    };

    if (rawReactions != null) {
      for (final emoji in supportedReactions) {
        reactions[emoji] = (rawReactions[emoji] as num?)?.toInt() ?? 0;
      }
    } else {
      reactions['😂'] = legacyLolCount;
    }

    return WallPost(
      id: doc.id,
      username: data['username'] as String? ?? 'anonymous',
      truth: data['truth'] as String? ?? '',
      excuse: data['excuse'] as String? ?? '',
      style: data['style'] as String? ?? 'goofy',
      language: data['language'] as String? ?? 'unknown',
      category: ExcuseCategory.fromApi(data['category'] as String?),
      generationId: data['generationId'] as String? ?? '',
      reactions: reactions,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
