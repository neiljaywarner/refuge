import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../application/feedback_attachment_ref.dart';
import '../application/private_feedback_router.dart';
import '../domain/feedback_and_voting_models.dart';
import '../domain/feedback_source_stamp.dart';
import 'github_feedback_client.dart';
import 'member_feedback_bridge.dart';
import 'vote_storage_service.dart';

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

  /// Emits real-time reactive updates of the community feature voting board (#303, #309).
  Stream<List<VotableFeatureItem>> watchFeatures();

  /// Applies an optimistic vote toggle and persists to the active backend adapter.
  List<VotableFeatureItem> toggleVote(List<VotableFeatureItem> current, String featureId);

  /// Appends a community-proposed feature and persists to the active backend adapter.
  List<VotableFeatureItem> proposeFeature(
    List<VotableFeatureItem> current, {
    required String title,
    required String description,
  });

  /// Records a literal 3-intent feedback submission (`happy`, `neutral`, `sad`)
  /// alongside an optional 1–5 star rating (`rating`) for unified Web/PWA/Mobile auditing.
  Future<FeedbackSubmissionResult> submitFeedback({
    required FeedbackSentiment sentiment,
    required String message,
    int? rating,
    String? contactEmail,
    String? attachmentUrl,
    Uint8List? screenshotAttachment,
  });
}

/// Shared pure transformation logic used by all 4 backend adapters to guarantee
/// identical optimistic UI behavior across Unit, Widget, Integration & E2E tests.
mixin FeatureVotingStateTransformMixin implements FeatureVotingRepository {
  final List<Map<String, String>> submittedFeedbackLog = [];
  StreamController<List<VotableFeatureItem>>? _streamController;

  GitHubFeedbackClient? get gitHubClient => null;

  /// Host stamp written onto every note. Firebase and in-memory adapters can override it.
  FeedbackSourceStamp get feedbackSource => FeedbackSourceStamp.current();

  /// Resolves an explicit 1–5 star rating or falls back to the default rating for [sentiment].
  static int resolveStarRating(FeedbackSentiment sentiment, int? rating) {
    if (rating != null) {
      return rating.clamp(1, 5);
    }
    return switch (sentiment) {
      FeedbackSentiment.happy => 5,
      FeedbackSentiment.neutral => 3,
      FeedbackSentiment.sad => 1,
    };
  }

  /// Shared broadcast stream controller for cross-session real-time notifications.
  StreamController<List<VotableFeatureItem>> get streamController =>
      _streamController ??= StreamController<List<VotableFeatureItem>>.broadcast();

  @override
  Stream<List<VotableFeatureItem>> watchFeatures() => streamController.stream.map((list) {
    final votedIds = VoteStorageService.instance.getVotedFeatureIds();
    return [for (final item in list) item.copyWith(userVoted: votedIds.contains(item.id))];
  });

  @override
  List<VotableFeatureItem> loadInitialFeatures() {
    final votedIds = VoteStorageService.instance.getVotedFeatureIds();
    return [
      for (final item in kDefaultBelongVotableFeatures)
        item.copyWith(
          userVoted: votedIds.contains(item.id),
          // Seed tallies do not include this device's guest vote. Add it
          // back so a reload keeps the count and a second tap removes it.
          votes: item.votes + (votedIds.contains(item.id) ? 1 : 0),
        ),
    ];
  }

  @override
  List<VotableFeatureItem> toggleVote(List<VotableFeatureItem> current, String featureId) {
    final voted = VoteStorageService.instance.toggleFeatureVoted(featureId);
    final next = [
      for (final item in current)
        if (item.id == featureId)
          item.copyWith(
            userVoted: voted,
            votes: voted ? item.votes + 1 : (item.votes > 0 ? item.votes - 1 : 0),
          )
        else
          item,
    ];
    if (_streamController != null && !_streamController!.isClosed) {
      // Remote broadcast reflects updated vote tallies without overriding remote users' local vote flags
      final remotePayload = [for (final item in next) item.copyWith(userVoted: false)];
      _streamController!.add(remotePayload);
    }
    return next;
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
    VoteStorageService.instance.setFeatureVoted(newItem.id, true);
    if (_streamController != null && !_streamController!.isClosed) {
      final remotePayload = [
        for (final item in current) item.copyWith(userVoted: false),
        newItem.copyWith(userVoted: false),
      ];
      _streamController!.add(remotePayload);
    }
    return [...current, newItem];
  }

  PrivateFeedbackRouter get privateRouter => const PrivateFeedbackRouter();

  String _attachmentDelivery(String? attachmentUrl, Uint8List? screenshotAttachment) {
    if (FeedbackAttachmentRef.isHostedUpload(attachmentUrl)) return 'hosted';
    final hasDrawing =
        screenshotAttachment != null || (attachmentUrl != null && attachmentUrl.trim().isNotEmpty);
    if (!hasDrawing) return 'none';
    return 'local_only';
  }

  @override
  Future<FeedbackSubmissionResult> submitFeedback({
    required FeedbackSentiment sentiment,
    required String message,
    int? rating,
    String? contactEmail,
    String? attachmentUrl,
    Uint8List? screenshotAttachment,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return FeedbackSubmissionResult(
        isPrivateTriage: sentiment.isPrivateTriage,
        savedLocally: false,
      );
    }
    final resolvedRating = resolveStarRating(sentiment, rating);
    final destination = privateRouter.resolveDestination(sentiment);
    final stamp = feedbackSource;
    final submittedAt = DateTime.now().toUtc().toIso8601String();

    int? githubIssueNumber;
    String? githubIssueUrl;

    if (sentiment.isPrivateTriage && gitHubClient != null && gitHubClient!.isConfigured) {
      final payload = privateRouter.formatPrivateIssue(
        sentiment: sentiment,
        message: trimmed,
        contactEmail: contactEmail,
        attachmentUrl: attachmentUrl,
        attachmentBytes: screenshotAttachment,
        source: stamp,
      );
      final issueResult = await gitHubClient!.createIssue(
        repository: payload.repository,
        title: payload.title,
        body: payload.body,
        labels: payload.labels,
      );
      if (issueResult != null) {
        githubIssueNumber = issueResult.number;
        githubIssueUrl = issueResult.htmlUrl;
      }
    }

    submittedFeedbackLog.add({
      'backend': target.name,
      'sentiment': sentiment.name,
      'rating': '$resolvedRating',
      'isPrivateTriage': '${sentiment.isPrivateTriage}',
      'destination': destination is PrivateRepoDestination
          ? destination.repository
          : 'public_community_board',
      'message': trimmed,
      if (contactEmail != null && contactEmail.trim().isNotEmpty)
        'contactEmail': contactEmail.trim(),
      if (FeedbackAttachmentRef.isHostedUpload(attachmentUrl))
        'attachmentUrl': attachmentUrl!.trim(),
      if (screenshotAttachment != null) 'hasScreenshotAttachment': 'true',
      'attachmentDelivery': _attachmentDelivery(attachmentUrl, screenshotAttachment),
      'githubIssueCreated': '${githubIssueNumber != null}',
      if (githubIssueNumber != null) 'githubIssueNumber': '$githubIssueNumber',
      'githubIssueUrl': ?githubIssueUrl,
      'sourceEnvironment': stamp.sourceEnvironment,
      'sourceHost': stamp.sourceHost,
      'sourceUrl': stamp.sourceUrl,
      'submittedAt': submittedAt,
      'storedIn': 'member_feedback',
    });

    return FeedbackSubmissionResult(
      isPrivateTriage: sentiment.isPrivateTriage,
      githubIssueNumber: githubIssueNumber,
      githubIssueUrl: githubIssueUrl,
      savedLocally: true,
    );
  }
}

/// 1. Deterministic In-Memory Adapter (Unit/Widget BDD Tests & Offline Fallback).
class InMemoryFeatureVotingRepository
    with FeatureVotingStateTransformMixin
    implements FeatureVotingRepository {
  InMemoryFeatureVotingRepository({
    StreamController<List<VotableFeatureItem>>? customStreamController,
    this.gitHubClient,
    this.sourceStamp,
  }) {
    if (customStreamController != null) {
      _streamController = customStreamController;
    }
  }

  @override
  final GitHubFeedbackClient? gitHubClient;

  final FeedbackSourceStamp? sourceStamp;

  @override
  FeedbackSourceStamp get feedbackSource => sourceStamp ?? super.feedbackSource;

  @override
  BackendTarget get target => BackendTarget.inMemory;
}

/// 2. Serverpod Adapter (`v0.6.0` – `v0.8.0-alpha` default with offline resilience).
class ServerpodFeatureVotingRepository
    with FeatureVotingStateTransformMixin
    implements FeatureVotingRepository {
  ServerpodFeatureVotingRepository({this.gitHubClient});

  @override
  final GitHubFeedbackClient? gitHubClient;

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
    this.gitHubClient,
  });

  final String databaseId;
  final String featuresCollectionId;
  final String feedbackCollectionId;

  @override
  final GitHubFeedbackClient? gitHubClient;

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
    this.customFirestore,
    this.gitHubClient,
    this.sourceStamp,
    this.feedbackForward,
    this.memberId,
    this.persistFeedbackDocument,
  });

  final String featuresCollectionPath;
  final String feedbackCollectionPath;
  final FirebaseFirestore? customFirestore;
  final FeedbackSourceStamp? sourceStamp;
  final MemberFeedbackForward? feedbackForward;
  final String? Function()? memberId;

  /// Test hook that stores the note and returns its id. Production uses Firestore.
  final Future<String?> Function(Map<String, dynamic> data)? persistFeedbackDocument;

  @override
  final GitHubFeedbackClient? gitHubClient;

  @override
  FeedbackSourceStamp get feedbackSource => sourceStamp ?? super.feedbackSource;

  FirebaseFirestore? get firestore {
    if (customFirestore != null) return customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  BackendTarget get target => BackendTarget.firebase;

  @override
  Stream<List<VotableFeatureItem>> watchFeatures() {
    final fs = firestore;
    if (fs == null) {
      return super.watchFeatures();
    }
    try {
      return fs.collection(featuresCollectionPath).snapshots().map((snapshot) {
        final remoteVotes = <String, int>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data.containsKey('votes')) {
            remoteVotes[doc.id] = (data['votes'] as num).toInt();
          }
        }
        final base = loadInitialFeatures();
        final votedIds = VoteStorageService.instance.getVotedFeatureIds();
        return [
          for (final item in base)
            if (remoteVotes.containsKey(item.id))
              item.copyWith(votes: remoteVotes[item.id]!, userVoted: votedIds.contains(item.id))
            else
              item.copyWith(userVoted: votedIds.contains(item.id)),
        ];
      });
    } catch (_) {
      return super.watchFeatures();
    }
  }

  @override
  List<VotableFeatureItem> toggleVote(List<VotableFeatureItem> current, String featureId) {
    final next = super.toggleVote(current, featureId);
    final targetItem = next.firstWhere(
      (e) => e.id == featureId,
      orElse: () => current.firstWhere((e) => e.id == featureId),
    );

    final fs = firestore;
    if (fs != null) {
      try {
        fs.collection(featuresCollectionPath).doc(featureId).set({
          'id': featureId,
          'title': targetItem.title,
          'description': targetItem.description,
          'votes': targetItem.votes,
          'lastVotedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Resilient offline fallback
      }
    }
    return next;
  }

  @override
  Future<FeedbackSubmissionResult> submitFeedback({
    required FeedbackSentiment sentiment,
    required String message,
    int? rating,
    String? contactEmail,
    String? attachmentUrl,
    Uint8List? screenshotAttachment,
  }) async {
    final result = await super.submitFeedback(
      sentiment: sentiment,
      message: message,
      rating: rating,
      contactEmail: contactEmail,
      attachmentUrl: attachmentUrl,
      screenshotAttachment: screenshotAttachment,
    );

    final fs = firestore;
    final writer = persistFeedbackDocument;
    String? createdId;
    if (writer != null || fs != null) {
      try {
        final resolvedRating = FeatureVotingStateTransformMixin.resolveStarRating(
          sentiment,
          rating,
        );
        final destination = privateRouter.resolveDestination(sentiment);
        final stamp = feedbackSource;
        final loggedAt = submittedFeedbackLog.isEmpty
            ? null
            : submittedFeedbackLog.last['submittedAt'];
        String? uid;
        try {
          final rawUid = (memberId ?? readCurrentMemberId)()?.trim();
          uid = rawUid == null || rawUid.isEmpty ? null : rawUid;
        } catch (_) {
          uid = null;
        }
        final docData = <String, dynamic>{
          'sentiment': sentiment.name,
          'rating': resolvedRating,
          'isPrivateTriage': sentiment.isPrivateTriage,
          'targetRepository': destination is PrivateRepoDestination ? destination.repository : null,
          'message': message.trim(),
          if (contactEmail != null && contactEmail.trim().isNotEmpty)
            'contactEmail': contactEmail.trim(),
          if (FeedbackAttachmentRef.isHostedUpload(attachmentUrl))
            'attachmentUrl': attachmentUrl!.trim(),
          if (screenshotAttachment != null) 'hasScreenshotAttachment': true,
          if (screenshotAttachment != null)
            'attachmentBytesBase64': base64Encode(screenshotAttachment),
          'attachmentDelivery': _attachmentDelivery(attachmentUrl, screenshotAttachment),
          'githubIssueCreated': result.githubIssueNumber != null,
          if (result.githubIssueNumber != null) 'githubIssueNumber': result.githubIssueNumber,
          if (result.githubIssueUrl != null) 'githubIssueUrl': result.githubIssueUrl,
          'sourceEnvironment': stamp.sourceEnvironment,
          'sourceHost': stamp.sourceHost,
          'sourceUrl': stamp.sourceUrl,
          'submittedAt': loggedAt ?? DateTime.now().toUtc().toIso8601String(),
          'userId': ?uid,
          'authorId': ?uid,
          'storedIn': feedbackCollectionPath,
          'createdAt': FieldValue.serverTimestamp(),
        };
        if (writer != null) {
          createdId = await writer(docData);
        } else {
          final created = await fs!
              .collection(feedbackCollectionPath)
              .add(docData)
              .timeout(const Duration(seconds: 6));
          createdId = created.id;
        }
      } catch (_) {
        // Resilient offline fallback. A missing document id skips the forward.
        createdId = null;
      }
    }

    if (!sentiment.isPrivateTriage || result.githubIssueNumber != null) {
      return result;
    }
    final forwarded = await _forwardStored(createdId);
    if (forwarded == null) return result;
    _recordForwardedIssue(forwarded);
    return FeedbackSubmissionResult(
      isPrivateTriage: true,
      githubIssueNumber: forwarded.number,
      githubIssueUrl: forwarded.htmlUrl,
      savedLocally: result.savedLocally,
    );
  }

  Future<({int number, String htmlUrl})?> _forwardStored(String? feedbackId) async {
    final id = feedbackId?.trim() ?? '';
    if (id.isEmpty) return null;
    try {
      final forward = feedbackForward ?? forwardMemberFeedback;
      return await forward(id);
    } catch (_) {
      return null;
    }
  }

  void _recordForwardedIssue(({int number, String htmlUrl}) forwarded) {
    if (submittedFeedbackLog.isEmpty) return;
    final last = submittedFeedbackLog.last;
    last['githubIssueCreated'] = 'true';
    last['githubIssueNumber'] = '${forwarded.number}';
    if (forwarded.htmlUrl.isNotEmpty) {
      last['githubIssueUrl'] = forwarded.htmlUrl;
    }
  }
}

/// 1-line switchable provider controlling which backend powers Feature Voting.
/// Defaults to [BackendTarget.firebase] for v0.8.0-alpha shared cloud persistence.
final featureVotingBackendTargetProvider = Provider<BackendTarget>((ref) => BackendTarget.firebase);

/// Provides the active [FeatureVotingRepository] implementation.
final featureVotingRepositoryProvider = Provider<FeatureVotingRepository>((ref) {
  final target = ref.watch(featureVotingBackendTargetProvider);
  final gitHubClient = ref.watch(gitHubFeedbackClientProvider);
  return switch (target) {
    BackendTarget.inMemory => InMemoryFeatureVotingRepository(gitHubClient: gitHubClient),
    BackendTarget.serverpod => ServerpodFeatureVotingRepository(gitHubClient: gitHubClient),
    BackendTarget.appwrite => AppwriteFeatureVotingRepository(gitHubClient: gitHubClient),
    BackendTarget.firebase => FirebaseFeatureVotingRepository(gitHubClient: gitHubClient),
  };
});
