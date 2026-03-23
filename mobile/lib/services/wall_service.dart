import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alibi_style.dart';
import '../models/excuse_response.dart';
import '../models/wall_post.dart';
import 'excuse_api_service.dart';

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
typedef WallDeletePost = Future<void> Function(String postId);

class WallService {
  WallService({
    FirebaseFirestore? firestore,
    WallPostsStreamFactory? postsStreamFactory,
    WallAddPost? addPostHandler,
    WallIncrementReaction? incrementReactionHandler,
    WallDeletePost? deletePostHandler,
    ExcuseApiService? apiService,
  })  : _firestore = firestore,
        _postsStreamFactory = postsStreamFactory,
        _addPostHandler = addPostHandler,
        _incrementReactionHandler = incrementReactionHandler,
        _deletePostHandler = deletePostHandler,
        _apiService = apiService;

  final FirebaseFirestore? _firestore;
  final WallPostsStreamFactory? _postsStreamFactory;
  final WallAddPost? _addPostHandler;
  final WallIncrementReaction? _incrementReactionHandler;
  final WallDeletePost? _deletePostHandler;
  final ExcuseApiService? _apiService;

  CollectionReference<Map<String, dynamic>> get _posts =>
      (_firestore ?? FirebaseFirestore.instance).collection('wall_posts');

  Stream<List<WallPost>> streamPosts() {
    final override = _postsStreamFactory;
    if (override != null) {
      return override();
    }
    final apiService = _apiService;
    if (apiService != null) {
      return (() async* {
        yield await apiService.fetchWallFeed();
        yield* Stream.periodic(const Duration(seconds: 3)).asyncMap(
          (_) => apiService.fetchWallFeed(),
        );
      })();
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
    final apiService = _apiService;
    if (apiService == null || excuse.generationId.isEmpty) {
      throw const ExcuseApiException(
        'Posting needs a saved generation and an authenticated API client.',
      );
    }
    return apiService.publishGeneration(excuse.generationId);
  }

  Future<void> incrementReaction(String postId, String emoji) {
    final override = _incrementReactionHandler;
    if (override != null) {
      return override(postId, emoji);
    }
    final apiService = _apiService;
    if (apiService != null) {
      return apiService.incrementWallReaction(postId, emoji);
    }
    return _posts.doc(postId).update({
      'reactions.$emoji': FieldValue.increment(1),
    });
  }

  Future<void> deletePost(String postId) {
    final override = _deletePostHandler;
    if (override != null) {
      return override(postId);
    }
    final apiService = _apiService;
    if (apiService != null) {
      return apiService.deleteWallPost(postId);
    }
    return _posts.doc(postId).delete();
  }
}
