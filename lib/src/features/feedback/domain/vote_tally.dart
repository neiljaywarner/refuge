/// Pure vote tally logic for signed-in Firestore persistence.
class VoteTallyResult {
  const VoteTallyResult({
    required this.votes,
    required this.voterIds,
    required this.changed,
  });

  final int votes;
  final List<String> voterIds;
  final bool changed;
}

/// Applies a member vote toggle without last-write-wins overwrites.
VoteTallyResult applyMemberVote({
  required int votes,
  required List<String> voterIds,
  required String uid,
  required bool wantVoted,
}) {
  final ids = List<String>.from(voterIds);
  final already = ids.contains(uid);

  if (wantVoted) {
    if (already) {
      return VoteTallyResult(votes: votes, voterIds: ids, changed: false);
    }
    ids.add(uid);
    return VoteTallyResult(votes: votes + 1, voterIds: ids, changed: true);
  }

  if (!already) {
    return VoteTallyResult(votes: votes, voterIds: ids, changed: false);
  }
  ids.remove(uid);
  final nextVotes = votes > 0 ? votes - 1 : 0;
  return VoteTallyResult(votes: nextVotes, voterIds: ids, changed: true);
}
