import '../domain/feedback_and_voting_models.dart';

/// Member-facing copy when a signed-in Firestore vote write fails.
const kVoteDidNotSaveMessage = 'Vote did not save. Try again.';

typedef VotePersistFailedHandler = void Function(
  List<VotableFeatureItem> revertedItems,
  String memberMessage,
);

/// Bridges async Firestore failures back to [FeatureVotingNotifier] without a
/// circular provider dependency.
class VotePersistFailureBus {
  VotePersistFailedHandler? handler;

  void report(List<VotableFeatureItem> revertedItems, String memberMessage) {
    handler?.call(revertedItems, memberMessage);
  }
}
