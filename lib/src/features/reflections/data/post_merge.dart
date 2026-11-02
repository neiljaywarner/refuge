import '../domain/post.dart';

List<Post> mergePosts(List<Post> base, List<Post> overlay) {
  final byId = <String, Post>{for (final post in base) post.id: post};
  for (final post in overlay) {
    final existing = byId[post.id];
    byId[post.id] = existing == null ? post : preferPost(existing, post);
  }
  final merged = byId.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return merged;
}

/// Keeps the newer reflection. Equal timestamps keep the copy with more care
/// affirmations, so a local tap is not overwritten by a stale cloud row.
/// Also preserves `isSaved` if either copy is marked saved.
Post preferPost(Post current, Post incoming) {
  final saved = current.isSaved || incoming.isSaved;
  Post finish(Post winner) => winner.isSaved == saved ? winner : winner.copyWith(isSaved: saved);
  if (incoming.timestamp.isAfter(current.timestamp)) return finish(incoming);
  if (current.timestamp.isAfter(incoming.timestamp)) return finish(current);
  final currentScore = current.reactions.values.fold<int>(0, (total, value) => total + value);
  final incomingScore = incoming.reactions.values.fold<int>(0, (total, value) => total + value);
  return finish(incomingScore >= currentScore ? incoming : current);
}
