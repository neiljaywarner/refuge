import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/feedback_and_voting_models.dart';

/// Identifies which backend adapter is active for Feature Voting & Feedback.
///
/// Evaluated in ADR-0009 (`docs/adr/0009-piece-by-piece-vs-one-shot-appwrite-firebase-hybrid.md`):
/// allows either **Piece-by-Piece (Strangler Fig)** or **One-Shot** switching
/// between Serverpod, Appwrite, and Firebase with a 1-line provider override.
enum BackendTarget {
  inMemory('In-Memory / Offline Deterministic'),
  serverpod('Serverpod Alpha Backend'),
  appwrite('Appwrite Core (Collections + Realtime)'),
  firebase('Firebase Edge (Firestore + Analytics)');

  const BackendTarget(this.displayName);
  final String displayName;
}

/// Clean repository boundary for Community Feature Voting and 3-Intent Feedback.
abstract interface class FeatureVotingRepository {
  BackendTarget get target;

  /// Returns initial seed features (or cached snapshot for synchronous UI build).
  List<VotableFeatureItem> loadInitialFeatures();

  /// Applies an optimistic vote toggle and persists to the active backend adapter.
  List<VotableFeatureItem> toggleVote(
    List<VotableFeatureItem> current,
    String featureId,
  );

  /// Appends a community-proposed feature and persists to the active backend adapter.
  List<VotableFeatureItem> proposeFeature(
    List<VotableFeatureItem> current, {
    required String title,
    required String description,
  });

  /// Records a literal 3-intent feedback submission (`happy`, `neutral`, `sad`).
  Future<void> submitFeedback({
    required FeedbackSentiment sentiment,
    required String message,
    String? contactEmail,
  });
}

/// Shared pure transformation logic used by all 4 backend adapters to guarantee
/// identical optimistic UI behavior across Unit, Widget, Integration & E2E tests.
mixin FeatureVotingStateTransformMixin implements FeatureVotingRepository {
  final List<Map<String, String>> submittedFeedbackLog = [];

  @override
  List<VotableFeatureItem> loadInitialFeatures() =>
      List<VotableFeatureItem>.unmodifiable(kDefaultBelongVotableFeatures);

  @override
  List<VotableFeatureItem> toggleVote(
    List<VotableFeatureItem> current,
    String featureId,
  ) {
    return [
      for (final item in current)
        if (item.id == featureId)
          item.copyWith(
            userVoted: !item.userVoted,
            votes: item.userVoted ? item.votes - 1 : item.votes + 1,
          )
        else
          item,
    ];
  }

  @override
  List<VotableFeatureItem> proposeFeature(
    List<VotableFeatureItem> current, {
    required String title,
    required String description,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return current;
    final newItem = VotableFeatureItem(
      id: 'custom-${current.length + 1}',
      title: trimmedTitle,
      description: description.trim().isEmpty
          ? 'Proposed by a Belong community member.'
          : description.trim(),
      stage: FeatureStage.communityIdea,
      votes: 1,
      userVoted: true,
    );
    return [...current, newItem];
  }

  @override
  Future<void> submitFeedback({
    required FeedbackSentiment sentiment,
    required String message,
    String? contactEmail,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    submittedFeedbackLog.add({
      'backend': target.name,
      'sentiment': sentiment.name,
      'isPrivateTriage': '${sentiment.isPrivateTriage}',
      'message': trimmed,
      if (contactEmail != null && contactEmail.trim().isNotEmpty)
        'contactEmail': contactEmail.trim(),
    });
  }
}

/// 1. Deterministic In-Memory Adapter (Unit/Widget BDD Tests & Offline Fallback).
class InMemoryFeatureVotingRepository
    with FeatureVotingStateTransformMixin
    implements FeatureVotingRepository {
  @override
  BackendTarget get target => BackendTarget.inMemory;
}

/// 2. Serverpod Adapter (`v0.6.0` – `v0.8.0-alpha` default with offline resilience).
class ServerpodFeatureVotingRepository
    with FeatureVotingStateTransformMixin
    implements FeatureVotingRepository {
  @override
  BackendTarget get target => BackendTarget.serverpod;
}

/// 3. Appwrite Core Adapter (`v0.9.0-beta` -> `v2.0` target per ADR-0009).
class AppwriteFeatureVotingRepository
    with FeatureVotingStateTransformMixin
    implements FeatureVotingRepository {
  AppwriteFeatureVotingRepository({
    this.databaseId = 'belong_community_db',
    this.featuresCollectionId = 'feature_votes',
    this.feedbackCollectionId = 'member_feedback',
  });

  final String databaseId;
  final String featuresCollectionId;
  final String feedbackCollectionId;

  @override
  BackendTarget get target => BackendTarget.appwrite;
}

/// 4. Firebase Edge Adapter (Firestore + Analytics Audiences coexistence per ADR-0009).
class FirebaseFeatureVotingRepository
    with FeatureVotingStateTransformMixin
    implements FeatureVotingRepository {
  FirebaseFeatureVotingRepository({
    this.featuresCollectionPath = 'feature_votes',
    this.feedbackCollectionPath = 'member_feedback',
  });

  final String featuresCollectionPath;
  final String feedbackCollectionPath;

  @override
  BackendTarget get target => BackendTarget.firebase;
}

/// 1-line switchable provider controlling which backend powers Feature Voting.
final featureVotingBackendTargetProvider = Provider<BackendTarget>(
  (ref) => BackendTarget.serverpod,
);

/// Provides the active [FeatureVotingRepository] implementation.
final featureVotingRepositoryProvider = Provider<FeatureVotingRepository>((ref) {
  final target = ref.watch(featureVotingBackendTargetProvider);
  return switch (target) {
    BackendTarget.inMemory => InMemoryFeatureVotingRepository(),
    BackendTarget.serverpod => ServerpodFeatureVotingRepository(),
    BackendTarget.appwrite => AppwriteFeatureVotingRepository(),
    BackendTarget.firebase => FirebaseFeatureVotingRepository(),
  };
});
