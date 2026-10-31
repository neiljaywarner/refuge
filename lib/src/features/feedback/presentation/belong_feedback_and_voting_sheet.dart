import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/presentation/system_insets.dart';
import '../../storage/data/storage_repository.dart';
import '../application/feedback_attachment_ref.dart';
import '../data/feature_voting_repository.dart';
import '../data/vote_storage_service.dart';
import '../domain/feedback_and_voting_models.dart';
import '../domain/optional_feedback_contact.dart';
import 'feedback_drawing_canvas.dart';

/// State notifier managing community feature votes via the pluggable
/// [FeatureVotingRepository] (`InMemory`, `Serverpod`, `Appwrite`, or `Firebase`).
class FeatureVotingNotifier extends Notifier<List<VotableFeatureItem>> {
  StreamSubscription<List<VotableFeatureItem>>? _subscription;

  @override
  List<VotableFeatureItem> build() {
    final repo = ref.watch(featureVotingRepositoryProvider);
    _subscription?.cancel();
    _subscription = repo.watchFeatures().listen((updatedList) {
      final votedIds = VoteStorageService.instance.getVotedFeatureIds();
      final currentMap = {for (final item in state) item.id: item};
      state = [
        for (final remote in updatedList)
          remote.copyWith(
            userVoted: votedIds.contains(remote.id) || (currentMap[remote.id]?.userVoted ?? false),
          ),
      ];
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return repo.loadInitialFeatures();
  }

  void toggleVote(String featureId) {
    final repo = ref.read(featureVotingRepositoryProvider);
    state = repo.toggleVote(state, featureId);
  }

  void proposeFeature({required String title, required String description}) {
    final repo = ref.read(featureVotingRepositoryProvider);
    state = repo.proposeFeature(state, title: title, description: description);
  }

  Future<FeedbackSubmissionResult> submitFeedback({
    required FeedbackSentiment sentiment,
    required String message,
    int? rating,
    String? contactEmail,
    String? attachmentUrl,
    Uint8List? screenshotAttachment,
  }) {
    final repo = ref.read(featureVotingRepositoryProvider);
    return repo.submitFeedback(
      sentiment: sentiment,
      message: message,
      rating: rating,
      contactEmail: contactEmail,
      attachmentUrl: attachmentUrl,
      screenshotAttachment: screenshotAttachment,
    );
  }
}

/// Provider for the Belong Feature Voting Board.
final featureVotingProvider = NotifierProvider<FeatureVotingNotifier, List<VotableFeatureItem>>(
  FeatureVotingNotifier.new,
);

/// Clean, neurodivergent-affirming modal sheet combining:
/// 1. **Feature Voting & WIP Roadmap** (so members testing the preview tonight
///    can see what is actively in progress before Oct 31 and upvote priorities).
/// 2. **Literal 3-Intent Feedback Funnel ("Private Feedback, Public Praise")**
///    evaluated in ADR-0007 (`docs/adr/0007-neurodivergent-first-ux-and-feedback-evaluation.md`).
class BelongFeedbackAndVotingSheet extends HookConsumerWidget {
  const BelongFeedbackAndVotingSheet({super.key, this.initialTabIndex = 0, this.screenshotBytes});

  final int initialTabIndex;
  final Uint8List? screenshotBytes;

  static Future<void> show(
    BuildContext context, {
    int initialTabIndex = 0,
    Uint8List? screenshotBytes,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => SystemBottomInset(
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: BelongFeedbackAndVotingSheet(
          initialTabIndex: initialTabIndex,
          screenshotBytes: screenshotBytes,
        ),
      ),
    ),
  );

  static String starLiteralDescription(int stars) => switch (stars) {
    5 => '5 ★ · Love it! Works great',
    4 => '4 ★ · Good experience',
    3 => "3 ★ · It's okay, could be better",
    2 => '2 ★ · Frustrating / Needs work',
    _ => '1 ★ · Broken / Very confusing',
  };

  static FeedbackSentiment sentimentForStars(int stars) {
    if (stars >= 4) return FeedbackSentiment.happy;
    if (stars == 3) return FeedbackSentiment.neutral;
    return FeedbackSentiment.sad;
  }

  /// Displays a friendly, neurodivergent-affirming dialog confirming whether
  /// the user wants to discard unsaved feedback text or drawing strokes.
  static Future<bool> confirmDiscardDraft(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          key: const Key('confirm_discard_feedback_dialog'),
          title: const Text('Discard unsaved feedback?'),
          content: const Text(
            'You have written a message or drawn on a screenshot that has not been sent yet. '
            'If you leave now, your draft will be discarded.',
          ),
          actions: [
            TextButton(
              key: const Key('discard_feedback_cancel_button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              key: const Key('discard_feedback_confirm_button'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2, initialIndex: initialTabIndex);
    final selectedSentiment = useState<FeedbackSentiment>(FeedbackSentiment.happy);
    final selectedStarRating = useState<int>(5);
    final userChoseSentiment = useState(false);
    final userChoseStarRating = useState(false);
    final feedbackController = useTextEditingController();
    useListenable(feedbackController);
    final contactController = useTextEditingController();
    final contactError = useState<String?>(null);
    final drawingAttachment = useState<Uint8List?>(null);
    final isSubmitting = useState<bool>(false);
    final submittedMessage = useState<String?>(null);

    final features = ref.watch(featureVotingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = SystemInsets.bottom(MediaQuery.of(context));
    final listPadding = EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset);

    final hasUnsavedDraft =
        feedbackController.text.trim().isNotEmpty || drawingAttachment.value != null;

    return PopScope(
      canPop: !hasUnsavedDraft && !isSubmitting.value,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isSubmitting.value) return;
        final shouldDiscard = await confirmDiscardDraft(context);
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const .fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Icon(Icons.how_to_vote_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        'Belong Roadmap & Feedback',
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '1-tap feature voting + literal, low-pressure feedback',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('close_feedback_sheet_button'),
                  tooltip: 'Close',
                  onPressed: () async {
                    if (isSubmitting.value) return;
                    if (hasUnsavedDraft) {
                      final shouldDiscard = await confirmDiscardDraft(context);
                      if (shouldDiscard && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          TabBar(
            controller: tabController,
            tabs: [
              Tab(
                key: const Key('tab_feature_voting'),
                child: _webLabeledButton(
                  label: 'Vote on Features (WIP)',
                  identifier: 'tab_vote_on_features',
                  onTap: () => tabController.animateTo(0),
                  child: const Text('Vote on Features (WIP)'),
                ),
              ),
              Tab(
                key: const Key('tab_private_feedback'),
                child: _webLabeledButton(
                  label: 'Share Feedback',
                  identifier: 'tab_share_feedback',
                  onTap: () => tabController.animateTo(1),
                  child: const Text('Share Feedback'),
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                // TAB 1: Feature Voting & Active WIP Board
                ListView(
                  padding: listPadding,
                  children: [
                    Container(
                      padding: const .all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                        borderRadius: .circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app_outlined, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tap the thumb to upvote! Features with the most community support are built first.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final item in features)
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: item.userVoted
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: item.userVoted ? 2.0 : 1.0,
                          ),
                          borderRadius: .circular(12),
                        ),
                        margin: const .only(bottom: 12),
                        child: Padding(
                          padding: const .all(14),
                          child: Column(
                            crossAxisAlignment: .start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const .symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: item.stage == FeatureStage.workInProgress
                                            ? colorScheme.primary.withValues(alpha: 0.15)
                                            : colorScheme.surfaceContainerHighest,
                                        borderRadius: .circular(6),
                                      ),
                                      child: Text(
                                        item.stage.badgeLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: item.stage == FeatureStage.workInProgress
                                              ? colorScheme.primary
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _webLabeledButton(
                                    label: item.userVoted
                                        ? 'Remove vote for ${item.title}'
                                        : 'Vote for ${item.title}',
                                    identifier: 'vote_${item.id}',
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      ref.read(featureVotingProvider.notifier).toggleVote(item.id);
                                    },
                                    child: Tooltip(
                                      message: item.userVoted
                                          ? 'Remove vote for ${item.title}'
                                          : 'Vote for ${item.title}',
                                      child: OutlinedButton.icon(
                                        key: Key('vote_button_${item.id}'),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: item.userVoted
                                              ? colorScheme.primaryContainer
                                              : null,
                                        ),
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          ref
                                              .read(featureVotingProvider.notifier)
                                              .toggleVote(item.id);
                                        },
                                        icon: Icon(
                                          item.userVoted
                                              ? Icons.thumb_up
                                              : Icons.thumb_up_alt_outlined,
                                          size: 16,
                                          color: item.userVoted ? colorScheme.primary : null,
                                        ),
                                        label: Text(
                                          '${item.votes}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: item.userVoted ? colorScheme.primary : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // TAB 2: Industry-Standard 1-5 Star Rating + Literal 3-Intent Feedback Funnel (PWA, Web & Mobile)
                ListView(
                  padding: listPadding,
                  children: [
                    // 1-5 Star Rating Card ("How do you like Belong on the Spectrum?")
                    Card(
                      key: const Key('star_rating_bar'),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: colorScheme.outlineVariant),
                        borderRadius: .circular(12),
                      ),
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      margin: const .only(bottom: 12),
                      child: Padding(
                        padding: const .all(14),
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.stars_rounded, color: colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'How do you like Belong on the Spectrum?',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap a star (1–5) or pick a category below. Every star has a clear literal meaning — works on Web, PWA, Android & iOS:',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: .spaceEvenly,
                              children: [
                                for (int star = 1; star <= 5; star++)
                                  IconButton(
                                    key: Key('star_rating_$star'),
                                    tooltip: '',
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      selectedStarRating.value = star;
                                      userChoseStarRating.value = true;
                                      if (!userChoseSentiment.value) {
                                        selectedSentiment.value = sentimentForStars(star);
                                      }
                                      submittedMessage.value = null;
                                    },
                                    iconSize: 32,
                                    icon: Icon(
                                      star <= selectedStarRating.value
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: star <= selectedStarRating.value
                                          ? Colors.amber.shade600
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Container(
                                key: const Key('star_rating_literal_label'),
                                padding: const .symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                                  borderRadius: .circular(999),
                                ),
                                child: Text(
                                  starLiteralDescription(selectedStarRating.value),
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Sentiment Cards (Works Great / Idea / Bug)
                    for (final sentiment in FeedbackSentiment.values)
                      Card(
                        key: Key('sentiment_${sentiment.name}'),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: selectedSentiment.value == sentiment
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: selectedSentiment.value == sentiment ? 2.0 : 1.0,
                          ),
                          borderRadius: .circular(12),
                        ),
                        margin: const .only(bottom: 10),
                        color: selectedSentiment.value == sentiment
                            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : null,
                        child: InkWell(
                          borderRadius: .circular(12),
                          onTap: () {
                            selectedSentiment.value = sentiment;
                            userChoseSentiment.value = true;
                            if (!userChoseStarRating.value) {
                              selectedStarRating.value = switch (sentiment) {
                                FeedbackSentiment.happy => 5,
                                FeedbackSentiment.neutral => 3,
                                FeedbackSentiment.sad => 1,
                              };
                            }
                            feedbackController.clear();
                            submittedMessage.value = null;
                          },
                          child: Padding(
                            padding: const .all(12),
                            child: Row(
                              children: [
                                Text(sentiment.emoji, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      Text(
                                        sentiment.label,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        sentiment.subtitle,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedSentiment.value == sentiment)
                                  Icon(Icons.check_circle, color: colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),
                    // Feedback Form
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: colorScheme.outlineVariant),
                        borderRadius: .circular(12),
                      ),
                      child: Padding(
                        padding: const .all(14),
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              selectedSentiment.value.promptTitle,
                              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              key: const Key('feedback_message_input'),
                              controller: feedbackController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: selectedSentiment.value.promptHint,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              key: const Key('feedback_contact_input'),
                              controller: contactController,
                              onChanged: (value) {
                                contactError.value = OptionalFeedbackContact.errorText(value);
                              },
                              decoration: InputDecoration(
                                labelText: 'Optional name or email (if you would like a reply)',
                                errorText: contactError.value,
                                errorMaxLines: 3,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Scribble / Drawing Attachment affordance
                            if (drawingAttachment.value != null) ...[
                              Container(
                                key: const Key('attached_scribble_preview_container'),
                                padding: const .all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: .circular(10),
                                  border: Border.all(color: colorScheme.outlineVariant),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: .circular(6),
                                      child: Image.memory(
                                        drawingAttachment.value!,
                                        key: const Key('attached_scribble_thumbnail'),
                                        width: 60,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: .start,
                                        mainAxisSize: .min,
                                        children: [
                                          const Text(
                                            'Scribble Annotated Screenshot',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${drawingAttachment.value!.lengthInBytes ~/ 1024} KB kept with this note (not uploaded)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      key: const Key('remove_scribble_attachment_button'),
                                      tooltip: 'Remove scribble',
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => drawingAttachment.value = null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ] else ...[
                              OutlinedButton.icon(
                                key: const Key('open_feedback_drawing_button'),
                                onPressed: () async {
                                  final screenshot =
                                      screenshotBytes ?? await captureEnclosingScreenshot(context);
                                  if (!context.mounted) return;
                                  final result = await FeedbackDrawingDialog.show(
                                    context,
                                    screenshotBytes: screenshot,
                                  );
                                  if (result != null && result.isNotEmpty) {
                                    drawingAttachment.value = result;
                                  }
                                },
                                icon: const Icon(Icons.draw_outlined, size: 18),
                                label: const Text(
                                  'Draw / Annotate on Screenshot',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (submittedMessage.value != null) ...[
                              Container(
                                padding: const .all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: .circular(8),
                                ),
                                child: Semantics(
                                  identifier: 'feedback_submit_result',
                                  label: submittedMessage.value,
                                  container: true,
                                  child: Text(
                                    submittedMessage.value!,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  key: const Key('submit_feedback_button'),
                                  onPressed: isSubmitting.value
                                      ? null
                                      : () async {
                                          final text = feedbackController.text.trim();
                                          final contact = contactController.text.trim();
                                          final contactProblem = OptionalFeedbackContact.errorText(
                                            contact,
                                          );
                                          contactError.value = contactProblem;
                                          if (text.isEmpty) {
                                            submittedMessage.value = 'Please enter a short note above so we can read your thoughts.';
                                            return;
                                          }
                                          if (contactProblem != null) {
                                            submittedMessage.value = null;
                                            return;
                                          }
                                          isSubmitting.value = true;
                                          try {
                                            final sentiment = selectedSentiment.value;
                                            String? attachmentUrl;
                                            final attachmentBytes = drawingAttachment.value;

                                            if (attachmentBytes != null) {
                                              final storageRepo = ref.read(
                                                storageRepositoryProvider,
                                              );
                                              attachmentUrl = await storageRepo
                                                  .uploadFeedbackAttachment(
                                                    bytes: attachmentBytes,
                                                    filename:
                                                        'scribble_${DateTime.now().millisecondsSinceEpoch}.png',
                                                  );
                                            }

                                            final result = await ref
                                                .read(featureVotingProvider.notifier)
                                                .submitFeedback(
                                                  sentiment: sentiment,
                                                  message: text,
                                                  rating: selectedStarRating.value,
                                                  contactEmail: contact.isNotEmpty ? contact : null,
                                                  attachmentUrl: attachmentUrl,
                                                  screenshotAttachment: attachmentBytes,
                                                );

                                            final hostedUpload =
                                                FeedbackAttachmentRef.isHostedUpload(attachmentUrl);
                                            final summary = StringBuffer()
                                              ..writeln(
                                                '[Belong ${selectedStarRating.value}★ · ${sentiment.label} (${sentiment.subtitle})] $text',
                                              );
                                            if (contact.isNotEmpty) {
                                              summary.writeln('From: $contact');
                                            }
                                            if (result.githubIssueNumber != null) {
                                              summary.writeln(
                                                'GitHub triage issue created: belong_feedback#${result.githubIssueNumber}',
                                              );
                                            } else {
                                              summary.writeln(
                                                'Organizer handoff: saved for organizers in Firestore member_feedback. The app did not file a GitHub issue and stores no API token.',
                                              );
                                            }
                                            if (attachmentBytes != null && !hostedUpload) {
                                              summary.writeln(
                                                'Drawing: kept with this note, not uploaded.',
                                              );
                                            } else if (hostedUpload) {
                                              summary.writeln('Attachment: $attachmentUrl');
                                            }
                                            try {
                                              await Clipboard.setData(
                                                ClipboardData(text: summary.toString()),
                                              ).timeout(const Duration(milliseconds: 100));
                                            } catch (_) {}

                                            if (result.githubIssueNumber != null) {
                                              submittedMessage.value =
                                                  'Thank you! Your feedback was routed to our private triage queue (belong_feedback#${result.githubIssueNumber}).';
                                            } else {
                                              final saved = sentiment.isPrivateTriage
                                                  ? 'Thank you. Your note was saved for organizers and copied to the clipboard. It was not sent to GitHub.'
                                                  : 'Thank you for your encouragement! Your praise was recorded and shared with our organizers.';
                                              submittedMessage.value =
                                                  attachmentBytes != null && !hostedUpload
                                                  ? '$saved The drawing stayed with the note and was not uploaded.'
                                                  : saved;
                                            }
                                            feedbackController.clear();
                                            drawingAttachment.value = null;
                                          } catch (e) {
                                            submittedMessage.value =
                                                'Could not submit feedback: $e';
                                          } finally {
                                            isSubmitting.value = false;
                                          }
                                        },
                                  icon: isSubmitting.value
                                      ? const Icon(Icons.hourglass_empty_rounded, size: 18)
                                      : const Icon(Icons.send_rounded, size: 18),
                                  label: Text(
                                    selectedSentiment.value.isPrivateTriage
                                        ? 'Send Private Feedback'
                                        : 'Share Praise & Encouragement',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Web Maestro drops some button labels. This node keeps [label] as the
/// accessible name and [identifier] as the resource id. Mobile is unchanged.
Widget _webLabeledButton({
  required String label,
  required String identifier,
  required VoidCallback onTap,
  required Widget child,
}) {
  if (!kIsWeb) return child;
  return Semantics(
    label: label,
    identifier: identifier,
    button: true,
    container: true,
    excludeSemantics: true,
    onTap: onTap,
    child: child,
  );
}
