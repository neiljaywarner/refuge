import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/feedback_and_voting_models.dart';
import '../domain/feedback_source_stamp.dart';
import 'feedback_attachment_ref.dart';

/// Destination target for user-submitted feedback.
sealed class FeedbackDestination {
  const FeedbackDestination();
}

/// Confidential triage target routed to the private sibling repository.
class PrivateRepoDestination extends FeedbackDestination {
  const PrivateRepoDestination({required this.repository});
  final String repository;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivateRepoDestination &&
          runtimeType == other.runtimeType &&
          repository == other.repository;

  @override
  int get hashCode => repository.hashCode;
}

/// Public encouragement target shown on community boards and praise counters.
class PublicPraiseDestination extends FeedbackDestination {
  const PublicPraiseDestination();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicPraiseDestination && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Formatted payload prepared for private GitHub Issue triage.
@immutable
class PrivateIssuePayload {
  const PrivateIssuePayload({
    required this.repository,
    required this.title,
    required this.body,
    required this.labels,
    this.attachmentUrl,
    this.attachmentBytes,
  });

  final String repository;
  final String title;
  final String body;
  final List<String> labels;
  final String? attachmentUrl;
  final Uint8List? attachmentBytes;
}

/// Formats member feedback for the private triage issue.
///
/// Public praise stays on the community board. Private notes are saved in
/// Firestore `member_feedback`. The Appwrite function `feedback-forward`
/// files the GitHub issue with `FEEDBACK_GITHUB_PAT`. This class does not
/// call GitHub and does not store an API token.
class PrivateFeedbackRouter {
  const PrivateFeedbackRouter({this.privateRepository = defaultPrivateRepository});

  /// Default private sibling repository for confidential triage.
  static const String defaultPrivateRepository = 'neiljaywarner/belong_feedback';

  /// GitHub REST API enforces a 65,536-character maximum on issue bodies.
  static const int maxGitHubIssueBodyLength = 65536;
  static const int _maxDuplicateBase64Length = 28000;
  static const int _maxSingleInlineBase64Length = 60000;

  final String privateRepository;

  /// Resolves the intended routing destination based on sentiment privacy.
  FeedbackDestination resolveDestination(FeedbackSentiment sentiment) {
    if (sentiment.isPrivateTriage) {
      return PrivateRepoDestination(repository: privateRepository);
    }
    return const PublicPraiseDestination();
  }

  /// Formats a confidential issue payload suitable for the private feedback repo.
  PrivateIssuePayload formatPrivateIssue({
    required FeedbackSentiment sentiment,
    required String message,
    String? contactEmail,
    String? attachmentUrl,
    Uint8List? attachmentBytes,
    DateTime? timestamp,
    FeedbackSourceStamp? source,
  }) {
    final now = timestamp ?? DateTime.now();
    final stamp = source ?? FeedbackSourceStamp.current();
    final cleanMessage = message.trim();
    final firstLine = cleanMessage.split('\n').first;
    final truncatedTitle = firstLine.length > 60 ? '${firstLine.substring(0, 57)}...' : firstLine;
    final host = stamp.sourceHost.trim().isEmpty ? 'unknown host' : stamp.sourceHost.trim();
    final sourceUrl = stamp.sourceUrl.trim().isEmpty ? 'unknown' : stamp.sourceUrl.trim();

    final title = '${stamp.titlePrefix}[${sentiment.label}] $truncatedTitle';

    final label = switch (sentiment) {
      FeedbackSentiment.sad => 'bug-report',
      FeedbackSentiment.neutral => 'community-idea',
      FeedbackSentiment.happy => 'praise',
    };

    final buffer = StringBuffer()
      ..writeln('## Community Feedback Submission')
      ..writeln()
      ..writeln('- **Intent**: ${sentiment.emoji} **${sentiment.label}** (${sentiment.subtitle})')
      ..writeln('- **Submitted At**: `${now.toIso8601String()}`')
      ..writeln('- **Target Triage Repo**: `$privateRepository`')
      ..writeln('- **Source environment**: `${stamp.sourceEnvironment}` (`$host`)')
      ..writeln('- **Source URL**: `$sourceUrl`');

    if (contactEmail != null && contactEmail.trim().isNotEmpty) {
      buffer.writeln('- **Contact Info**: `${contactEmail.trim()}`');
    }

    if (attachmentBytes != null && attachmentBytes.isNotEmpty) {
      final base64Image = base64Encode(attachmentBytes);
      buffer
        ..writeln()
        ..writeln('### Annotated Screenshot / Scribble Attachment');
      if (base64Image.length <= _maxDuplicateBase64Length) {
        buffer
          ..writeln(
            '<img src="data:image/png;base64,$base64Image" alt="Annotated Screenshot" width="400" />',
          )
          ..writeln()
          ..writeln('<details><summary>Raw Base64 PNG</summary>')
          ..writeln()
          ..writeln('```')
          ..writeln(base64Image)
          ..writeln('```')
          ..writeln('</details>');
      } else if (base64Image.length <= _maxSingleInlineBase64Length) {
        buffer.writeln(
          '<img src="data:image/png;base64,$base64Image" alt="Annotated Screenshot" width="400" />',
        );
      } else {
        final kb = (attachmentBytes.lengthInBytes / 1024).toStringAsFixed(1);
        buffer.writeln(
          'Annotated screenshot (${kb} KB PNG) exceeded GitHub inline 65 KB issue body limit '
          'and is stored in Firestore `member_feedback`.',
        );
      }
    } else if (attachmentUrl != null && attachmentUrl.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Annotated Screenshot / Scribble Attachment');
      if (FeedbackAttachmentRef.isHostedUpload(attachmentUrl)) {
        buffer.writeln('![Annotated Screenshot]($attachmentUrl)');
      } else {
        buffer.writeln(
          'A drawing was kept with this note for an organizer handoff. '
          'It was not uploaded, and this text is not a download link.',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('### Feedback Note')
      ..writeln(cleanMessage);

    return PrivateIssuePayload(
      repository: privateRepository,
      title: title,
      body: buffer.toString(),
      labels: ['user-feedback', label, ...stamp.issueLabels],
      attachmentUrl: attachmentUrl,
      attachmentBytes: attachmentBytes,
    );
  }
}

/// Riverpod provider for the [PrivateFeedbackRouter].
final privateFeedbackRouterProvider = Provider<PrivateFeedbackRouter>(
  (ref) => const PrivateFeedbackRouter(),
);
