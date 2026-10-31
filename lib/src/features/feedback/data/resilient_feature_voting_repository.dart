import 'dart:async';
import 'dart:typed_data';

import '../../../core/logging/app_logger.dart';
import '../domain/feedback_and_voting_models.dart';
import 'feature_voting_backend_config.dart';
import 'feature_voting_repository.dart';

/// Production voting adapter: Firestore is canonical; mirrors are optional.
///
/// Members always get optimistic thumb feedback. A down Appwrite endpoint,
/// Serverpod Cloud, or transient Firestore error must not blank the board.
class ResilientFeatureVotingRepository implements FeatureVotingRepository {
  ResilientFeatureVotingRepository({
    required this.target,
    required FirebaseFeatureVotingRepository primary,
    this.mirrorAfterPersist,
  }) : _primary = primary;

  @override
  final BackendTarget target;

  final FirebaseFeatureVotingRepository _primary;

  /// Test hook invoked after a successful Firestore vote transaction.
  final Future<void> Function({
    required String featureId,
    required int votes,
    required List<String> voterIds,
  })? mirrorAfterPersist;

  @override
  List<VotableFeatureItem> loadInitialFeatures() => _primary.loadInitialFeatures();

  @override
  Stream<List<VotableFeatureItem>> watchFeatures() => _primary.watchFeatures();

  @override
  List<VotableFeatureItem> toggleVote(List<VotableFeatureItem> current, String featureId) {
    final next = _primary.toggleVote(current, featureId);
    final item = next.firstWhere(
      (entry) => entry.id == featureId,
      orElse: () => current.firstWhere((entry) => entry.id == featureId),
    );
    unawaited(_mirrorIfConfigured(featureId: featureId, item: item));
    return next;
  }

  Future<void> _mirrorIfConfigured({
    required String featureId,
    required VotableFeatureItem item,
  }) async {
    final hook = mirrorAfterPersist;
    if (hook != null) {
      try {
        await hook(
          featureId: featureId,
          votes: item.votes,
          voterIds: const [],
        );
      } catch (_) {
        // Mirrors must never surface errors to the member.
      }
      return;
    }

    if (!isAppwriteFeatureVotingMirrorEnabled && !isServerpodFeatureVotingMirrorEnabled) {
      return;
    }

    try {
      // Client-side Appwrite tables stay disabled (ADR-0011). Log intent only until
      // a server-held API key path lands in #735 backup/mirror config.
      AppLogger.debug(
        'feature_voting_mirror_skipped featureId=$featureId votes=${item.votes} '
        'appwrite=$isAppwriteFeatureVotingMirrorEnabled serverpod=$isServerpodFeatureVotingMirrorEnabled',
      );
    } catch (_) {
      // Swallow — resilience over telemetry.
    }
  }

  @override
  List<VotableFeatureItem> proposeFeature(
    List<VotableFeatureItem> current, {
    required String title,
    required String description,
  }) =>
      _primary.proposeFeature(current, title: title, description: description);

  @override
  Future<FeedbackSubmissionResult> submitFeedback({
    required FeedbackSentiment sentiment,
    required String message,
    int? rating,
    String? contactEmail,
    String? attachmentUrl,
    Uint8List? screenshotAttachment,
  }) =>
      _primary.submitFeedback(
        sentiment: sentiment,
        message: message,
        rating: rating,
        contactEmail: contactEmail,
        attachmentUrl: attachmentUrl,
        screenshotAttachment: screenshotAttachment,
      );
}
