import '../domain/post.dart';
import '../domain/reaction_member.dart';

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
  Post finish(Post winner, Post other) {
    final members = retainKnownReactors(
      counts: winner.reactions,
      incoming: winner.reactionMembers,
      known: other.reactionMembers,
    );
    final withMembers = identical(members, winner.reactionMembers)
        ? winner
        : winner.copyWith(reactionMembers: members);
    return withMembers.isSaved == saved ? withMembers : withMembers.copyWith(isSaved: saved);
  }

  if (incoming.timestamp.isAfter(current.timestamp)) {
    return finish(incoming, current);
  }
  if (current.timestamp.isAfter(incoming.timestamp)) {
    return finish(current, incoming);
  }
  final currentScore = current.reactions.values.fold<int>(0, (total, value) => total + value);
  final incomingScore = incoming.reactions.values.fold<int>(0, (total, value) => total + value);
  if (incomingScore >= currentScore) return finish(incoming, current);
  return finish(current, incoming);
}
