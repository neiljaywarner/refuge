import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/feedback_and_voting_models.dart';
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

/// Formats member feedback for an organizer handoff.
///
/// Public praise stays on the community board. Private notes are saved in
/// Firestore `member_feedback` and can be pasted into
/// `neiljaywarner/belong_feedback` by an organizer. This class does not call
/// the GitHub API and does not store an API token.
class PrivateFeedbackRouter {
  const PrivateFeedbackRouter({
    this.privateRepository = defaultPrivateRepository,
  });

  /// Default private sibling repository for confidential triage.
  static const String defaultPrivateRepository =
      'neiljaywarner/belong_feedback';

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
  }) {
    final now = timestamp ?? DateTime.now();
    final cleanMessage = message.trim();
    final firstLine = cleanMessage.split('\n').first;
    final truncatedTitle = firstLine.length > 60
        ? '${firstLine.substring(0, 57)}...'
        : firstLine;

    final title = '[${sentiment.label}] $truncatedTitle';

    final label = switch (sentiment) {
      FeedbackSentiment.sad => 'bug-report',
      FeedbackSentiment.neutral => 'community-idea',
      FeedbackSentiment.happy => 'praise',
    };

    final buffer = StringBuffer()
      ..writeln('## Community Feedback Submission')
      ..writeln()
      ..writeln(
        '- **Intent**: ${sentiment.emoji} **${sentiment.label}** (${sentiment.subtitle})',
      )
      ..writeln('- **Submitted At**: `${now.toIso8601String()}`')
      ..writeln('- **Target Triage Repo**: `$privateRepository`');

    if (contactEmail != null && contactEmail.trim().isNotEmpty) {
      buffer.writeln('- **Contact Info**: `${contactEmail.trim()}`');
    }

    if (attachmentBytes != null && attachmentBytes.isNotEmpty) {
      final base64Image = base64Encode(attachmentBytes);
      buffer
        ..writeln()
        ..writeln('### Annotated Screenshot / Scribble Attachment')
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
      labels: ['user-feedback', label],
      attachmentUrl: attachmentUrl,
      attachmentBytes: attachmentBytes,
    );
  }
}

/// Riverpod provider for the [PrivateFeedbackRouter].
final privateFeedbackRouterProvider = Provider<PrivateFeedbackRouter>(
  (ref) => const PrivateFeedbackRouter(),
);
