import 'package:flutter/foundation.dart';

/// Literal, neurodivergent-affirming feedback categories ("Private Feedback,
/// Public Praise") designed to eliminate the ambiguity of 1–5 star ratings.
///
/// Evaluated in ADR-0007 (`docs/adr/0007-neurodivergent-first-ux-and-feedback-evaluation.md`).
enum FeedbackSentiment {
  /// 💚 Praise: Celebrates what feels calm, welcoming, or helpful.
  happy(
    emoji: '💚',
    label: 'Works Great',
    subtitle: 'Public Praise',
    promptTitle: 'What feels calm, clear, or welcoming?',
    promptHint: 'Share what you love so our organizers know which features and spaces to protect!',
    isPrivateTriage: false,
  ),

  /// 💡 Idea / Suggestion: Literal, private constructive improvement or sensory tweak.
  neutral(
    emoji: '💡',
    label: 'Idea / Tweak',
    subtitle: 'Private Suggestion',
    promptTitle: 'What would make Belong clearer or calmer for you?',
    promptHint: 'Suggest a feature, a clearer label, or a sensory improvement. Routed directly to our private organizer triage queue.',
    isPrivateTriage: true,
  ),

  /// 🛠️ Bug / Sensory Overload: Direct, judgment-free private triage.
  sad(
    emoji: '🛠️',
    label: 'Bug / Confusing',
    subtitle: 'Private Triage',
    promptTitle: 'What felt broken, confusing, or overwhelming?',
    promptHint: 'Tell us what happened — this goes straight to our private organizer & engineering triage queue.',
    isPrivateTriage: true,
  );

  const FeedbackSentiment({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.promptTitle,
    required this.promptHint,
    required this.isPrivateTriage,
  });

  final String emoji;
  final String label;
  final String subtitle;
  final String promptTitle;
  final String promptHint;
  final bool isPrivateTriage;
}

/// Lifecycle stage of a feature on the community voting board.
enum FeatureStage {
  workInProgress('In Progress'),
  planned('Planned'),
  communityIdea('Community Idea');

  const FeatureStage(this.badgeLabel);
  final String badgeLabel;
}

/// A votable roadmap item shown in the Belong Feature Voting Board.
@immutable
class VotableFeatureItem {
  const VotableFeatureItem({
    required this.id,
    required this.title,
    required this.description,
    required this.stage,
    this.votes = 0,
    this.userVoted = false,
    this.githubIssueNumber,
  });

  final String id;
  final String title;
  final String description;
  final FeatureStage stage;
  final int votes;
  final bool userVoted;
  final int? githubIssueNumber;

  VotableFeatureItem copyWith({int? votes, bool? userVoted}) => VotableFeatureItem(
    id: id,
    title: title,
    description: description,
    stage: stage,
    votes: votes ?? this.votes,
    userVoted: userVoted ?? this.userVoted,
    githubIssueNumber: githubIssueNumber,
  );
}

/// Sane default features + active WIP items for the Oct 24–31 Circle cutover preview.
/// Initialized with 0 votes so community sentiment drives real roadmap prioritization (#304).
const List<VotableFeatureItem> kDefaultBelongVotableFeatures = [
  VotableFeatureItem(
    id: 'wip-direct-messages',
    title: 'Direct Messages (Msgs Tab)',
    description:
        'Calm 1-on-1 member messaging with opt-in boundaries and zero read-receipt pressure.',
    stage: FeatureStage.workInProgress,
    votes: 0,
    githubIssueNumber: 27,
  ),
  VotableFeatureItem(
    id: 'wip-notifications-bell',
    title: 'Calm Notification Bell',
    description:
        'Bundled, predictable updates when someone replies to your post or prayer request.',
    stage: FeatureStage.workInProgress,
    votes: 0,
    githubIssueNumber: 27,
  ),
  VotableFeatureItem(
    id: 'wip-autistic-events',
    title: 'Actually Autistic Events Calendar',
    description: 'Sensory-friendly DFW & online meetups, clear expectations, and 1-tap RSVP.',
    stage: FeatureStage.workInProgress,
    votes: 0,
    githubIssueNumber: 28,
  ),
  VotableFeatureItem(
    id: 'wip-google-apple-auth',
    title: '1-Tap Google & Apple Sign-In',
    description: 'Frictionless single-tap sign-in alongside Stage 1 email/password accounts.',
    stage: FeatureStage.workInProgress,
    votes: 0,
    githubIssueNumber: 33,
  ),
  VotableFeatureItem(
    id: 'planned-native-store-apps',
    title: 'Native iOS App Store & Google Play Apps',
    description: 'Installable store apps alongside our instant Web & Add-to-Home-Screen PWA.',
    stage: FeatureStage.planned,
    votes: 0,
    githubIssueNumber: 45,
  ),
  VotableFeatureItem(
    id: 'idea-realtime-vs-calm-notifications',
    title: 'Real-Time Instant Alerts vs. Calm Batched Digest Toggle',
    description: 'Let members choose: receive immediate chimes/banners for DMs and replies, or batch everything into a calm quiet digest.',
    stage: FeatureStage.communityIdea,
    votes: 0,
    githubIssueNumber: 243,
  ),
  VotableFeatureItem(
    id: 'idea-sensory-audio-rooms',
    title: 'Camera-Off Voice & Text Hangout Rooms',
    description:
        'Low-pressure voice or text-only fellowship rooms where cameras are never required.',
    stage: FeatureStage.communityIdea,
    votes: 0,
  ),
  VotableFeatureItem(
    id: 'idea-special-interest-galleries',
    title: 'Special Interest Showcase Galleries',
    description:
        'Dedicated photo & project albums inside Geek Out! for trains, coding, music, and art.',
    stage: FeatureStage.communityIdea,
    votes: 0,
  ),
  VotableFeatureItem(
    id: 'idea-weekly-calm-digest',
    title: 'Single Weekly Calm Digest Email',
    description: 'Catch up on community highlights once a week without daily notification clutter.',
    stage: FeatureStage.communityIdea,
    votes: 0,
  ),
];

/// Result metadata returned from submitting user feedback.
@immutable
class FeedbackSubmissionResult {
  const FeedbackSubmissionResult({
    required this.isPrivateTriage,
    this.githubIssueNumber,
    this.githubIssueUrl,
    this.savedLocally = true,
  });

  /// Whether this was intended for private triage vs public community praise.
  final bool isPrivateTriage;

  /// The GitHub issue number if created via the direct GitHub client (e.g. 2).
  final int? githubIssueNumber;

  /// The web URL to the created GitHub issue.
  final String? githubIssueUrl;

  /// Whether the submission was saved to Firestore / local audit storage.
  final bool savedLocally;
}
