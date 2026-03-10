import 'package:cloud_firestore/cloud_firestore.dart';

class WallPost {
  const WallPost({
    required this.id,
    required this.truth,
    required this.excuse,
    required this.style,
    required this.language,
    required this.lolCount,
    required this.createdAt,
  });

  final String id;
  final String truth;
  final String excuse;
  final String style;
  final String language;
  final int lolCount;
  final DateTime? createdAt;

  factory WallPost.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return WallPost(
      id: doc.id,
      truth: data['truth'] as String? ?? '',
      excuse: data['excuse'] as String? ?? '',
      style: data['style'] as String? ?? 'goofy',
      language: data['language'] as String? ?? 'unknown',
      lolCount: (data['lolCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
