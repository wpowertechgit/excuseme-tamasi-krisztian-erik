import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alibi_style.dart';
import '../models/excuse_response.dart';
import '../models/wall_post.dart';

typedef WallPostsStreamFactory = Stream<List<WallPost>> Function();
typedef WallAddPost = Future<void> Function({
  required String truth,
  required ExcuseResponse excuse,
  required AlibiStyle style,
});
typedef WallIncrementReaction = Future<void> Function(
  String postId,
  String emoji,
);

class WallService {
  WallService({
    FirebaseFirestore? firestore,
    WallPostsStreamFactory? postsStreamFactory,
    WallAddPost? addPostHandler,
    WallIncrementReaction? incrementReactionHandler,
  })  : _firestore = firestore,
        _postsStreamFactory = postsStreamFactory,
        _addPostHandler = addPostHandler,
        _incrementReactionHandler = incrementReactionHandler;

  final FirebaseFirestore? _firestore;
  final WallPostsStreamFactory? _postsStreamFactory;
  final WallAddPost? _addPostHandler;
  final WallIncrementReaction? _incrementReactionHandler;

  CollectionReference<Map<String, dynamic>> get _posts =>
      (_firestore ?? FirebaseFirestore.instance).collection('wall_posts');

  Stream<List<WallPost>> streamPosts() {
    final override = _postsStreamFactory;
    if (override != null) {
      return override();
    }
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WallPost.fromSnapshot).toList());
  }

  Future<void> addPost({
    required String truth,
    required ExcuseResponse excuse,
    required AlibiStyle style,
  }) {
    final override = _addPostHandler;
    if (override != null) {
      return override(
        truth: truth,
        excuse: excuse,
        style: style,
      );
    }
    return _posts.add({
      'truth': truth.trim(),
      'excuse': excuse.excuse,
      'style': style.apiValue,
      'language': excuse.detectedLanguage,
      'reactions': {
        for (final emoji in WallPost.supportedReactions) emoji: 0,
      },
      'lolCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementReaction(String postId, String emoji) {
    final override = _incrementReactionHandler;
    if (override != null) {
      return override(postId, emoji);
    }
    return _posts.doc(postId).update({
      'reactions.$emoji': FieldValue.increment(1),
    });
  }
}
