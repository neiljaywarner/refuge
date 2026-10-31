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
    this.alsoTrackedIn = const [],
  });

  final String id;
  final String title;
  final String description;
  final FeatureStage stage;
  final int votes;
  final bool userVoted;
  final int? githubIssueNumber;
  final List<int> alsoTrackedIn;

  VotableFeatureItem copyWith({int? votes, bool? userVoted}) => VotableFeatureItem(
    id: id,
    title: title,
    description: description,
    stage: stage,
    votes: votes ?? this.votes,
    userVoted: userVoted ?? this.userVoted,
    githubIssueNumber: githubIssueNumber,
    alsoTrackedIn: alsoTrackedIn,
  );
}

/// Plain-language GitHub tracking line for a voting card.
String formatTrackedGitHubIssues(VotableFeatureItem item) {
  final issues = [
    if (item.githubIssueNumber != null) item.githubIssueNumber!,
    ...item.alsoTrackedIn,
  ];
  if (issues.isEmpty) return '';
  if (issues.length == 1) return 'Tracked in GitHub #${issues.first}';
  final prefix = issues.sublist(0, issues.length - 1).map((n) => '#$n').join(', ');
  return 'Tracked in GitHub $prefix and #${issues.last}';
}

/// Curated roadmap samples — only unfinished, organizer-approved priorities (#733).
const List<VotableFeatureItem> kDefaultBelongVotableFeatures = [
  VotableFeatureItem(
    id: 'planned-autistic-events',
    title: 'Actually Autistic Events Calendar',
    description:
        'Sensory-friendly DFW and online meetups with clear expectations and RSVP. Spaces opens Coming Soon until the live calendar ships.',
    stage: FeatureStage.planned,
    votes: 0,
  ),
  VotableFeatureItem(
    id: 'planned-google-sign-in',
    title: 'Google Sign-In (Good Auth)',
    description:
        'Real Sign in with Google beside email and magic link. The preview-only button today uses a local sample session, not Firebase OAuth.',
    stage: FeatureStage.planned,
    votes: 0,
    githubIssueNumber: 33,
  ),
  VotableFeatureItem(
    id: 'planned-native-store-apps',
    title: 'Native iOS App Store and Google Play Apps',
    description:
        'Installable store apps alongside the website and Add to Home Screen PWA. Play release #45; App Store release #46.',
    stage: FeatureStage.planned,
    votes: 0,
    githubIssueNumber: 45,
    alsoTrackedIn: [46],
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
