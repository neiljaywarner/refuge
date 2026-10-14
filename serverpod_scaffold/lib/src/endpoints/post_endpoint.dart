/*
  Reference Serverpod Endpoint implementation for Serverpod 4.
  To be placed in sanctuary_server_server/lib/src/endpoints/post_endpoint.dart
*/

/*
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class PostEndpoint extends Endpoint {
  // Fetch initial posts for a quiet space
  Future<List<Post>> getPosts(Session session, {required String spaceKey}) async {
    return await Post.db.find(
      session,
      where: (t) => t.spaceKey.equals(spaceKey),
      orderBy: (t) => t.timestamp,
      orderDescending: true,
    );
  }

  // Publish a reflection and notify listeners in that space
  Future<Post> createPost(Session session, Post post) async {
    final inserted = await Post.db.insertRow(session, post);
    session.messages.postMessage('space_${post.spaceKey}', inserted);
    return inserted;
  }

  // Register qualitative care affirmation (praying / support)
  Future<void> addReaction(
    Session session, {
    required int postId,
    required String reactionType,
  }) async {
    final post = await Post.db.findById(session, postId);
    if (post != null) {
      final updatedReactions = Map<String, int>.from(post.reactions);
      updatedReactions[reactionType] = (updatedReactions[reactionType] ?? 0) + 1;
      post.reactions = updatedReactions;
      await Post.db.updateRow(session, post);
      session.messages.postMessage('space_${post.spaceKey}', post);
    }
  }

  // Stream unhurried reflections in real-time
  Stream<Post> streamPosts(Session session, {required String spaceKey}) async* {
    final stream = session.messages.createStream<Post>('space_$spaceKey');
    await for (final post in stream) {
      yield post;
    }
  }
}
*/
