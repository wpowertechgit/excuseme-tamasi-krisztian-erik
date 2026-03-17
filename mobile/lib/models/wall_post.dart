import 'package:cloud_firestore/cloud_firestore.dart';

class WallPost {
  const WallPost({
    required this.id,
    required this.truth,
    required this.excuse,
    required this.style,
    required this.language,
    required this.reactions,
    required this.createdAt,
  });

  static const List<String> supportedReactions = ['😂', '🔥', '💀', '🤡'];

  final String id;
  final String truth;
  final String excuse;
  final String style;
  final String language;
  final Map<String, int> reactions;
  final DateTime? createdAt;

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
      truth: data['truth'] as String? ?? '',
      excuse: data['excuse'] as String? ?? '',
      style: data['style'] as String? ?? 'goofy',
      language: data['language'] as String? ?? 'unknown',
      reactions: reactions,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
